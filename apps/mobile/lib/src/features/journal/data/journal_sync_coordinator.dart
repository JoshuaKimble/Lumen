import 'dart:developer';

import '../domain/journal_entry.dart';
import '../domain/journal_cloud_store.dart';
import '../domain/journal_sync_diagnostics.dart';
import '../domain/journal_sync_operation.dart';
import 'journal_sync_diagnostics_sink.dart';
import 'journal_sync_queue_store.dart';

typedef JournalSyncClock = DateTime Function();
typedef CurrentJournalSyncUserId = String? Function();

class JournalSyncCoordinator {
  JournalSyncCoordinator({
    required JournalSyncQueueStore queueStore,
    required JournalCloudStore cloudStore,
    required CurrentJournalSyncUserId currentUserId,
    required JournalSyncDiagnosticsSink diagnosticsSink,
    JournalSyncClock clock = _defaultClock,
  }) : _queueStore = queueStore,
       _cloudStore = cloudStore,
       _currentUserId = currentUserId,
       _diagnosticsSink = diagnosticsSink,
       _clock = clock;

  final JournalSyncQueueStore _queueStore;
  final JournalCloudStore _cloudStore;
  final CurrentJournalSyncUserId _currentUserId;
  final JournalSyncDiagnosticsSink _diagnosticsSink;
  final JournalSyncClock _clock;

  bool _isFlushing = false;

  Future<void> enqueueSave(JournalEntry entry) async {
    final userId = _currentUserId();
    if (userId == null) {
      return;
    }

    final now = _clock();
    final operation = JournalSyncOperation(
      queueKey: JournalSyncOperation.queueKeyFor(
        userId: userId,
        entryId: entry.id,
      ),
      userId: userId,
      entryId: entry.id,
      type: JournalSyncOperationType.upsert,
      entry: entry,
      enqueuedAt: now,
      nextAttemptAt: now,
      attemptCount: 0,
    );
    await _replaceOperation(operation);
    await flushPendingWrites();
  }

  Future<void> enqueueDelete(String entryId) async {
    final userId = _currentUserId();
    if (userId == null) {
      return;
    }

    final now = _clock();
    final operation = JournalSyncOperation(
      queueKey: JournalSyncOperation.queueKeyFor(
        userId: userId,
        entryId: entryId,
      ),
      userId: userId,
      entryId: entryId,
      type: JournalSyncOperationType.delete,
      enqueuedAt: now,
      nextAttemptAt: now,
      attemptCount: 0,
    );
    await _replaceOperation(operation);
    await flushPendingWrites();
  }

  Future<void> flushPendingWrites() async {
    if (_isFlushing) {
      return;
    }

    final activeUserId = _currentUserId();
    final existingOperations = await _queueStore.loadOperations();
    if (activeUserId == null) {
      _publish(
        _currentDiagnostics.copyWith(
          pendingOperationCount: existingOperations.length,
          isSyncInProgress: false,
        ),
      );
      return;
    }

    _isFlushing = true;
    final now = _clock();
    var operations = existingOperations;
    _publish(
      JournalSyncDiagnostics(
        pendingOperationCount: operations.length,
        isSyncInProgress: true,
        lastAttemptedAt: now,
        lastSuccessfulSyncAt: _currentDiagnostics.lastSuccessfulSyncAt,
        lastFailureAt: _currentDiagnostics.lastFailureAt,
        lastFailureMessage: _currentDiagnostics.lastFailureMessage,
        nextScheduledRetryAt: _currentDiagnostics.nextScheduledRetryAt,
      ),
    );

    try {
      final dueOperations =
          operations
              .where(
                (operation) =>
                    operation.userId == activeUserId &&
                    !operation.nextAttemptAt.isAfter(now),
              )
              .toList(growable: false)
            ..sort(
              (left, right) => left.enqueuedAt.compareTo(right.enqueuedAt),
            );

      for (final operation in dueOperations) {
        try {
          await _flushOperation(operation);
          operations = operations
              .where((item) => item.queueKey != operation.queueKey)
              .toList(growable: false);
          await _queueStore.saveOperations(operations);
          _publish(
            _currentDiagnostics.copyWith(
              pendingOperationCount: operations.length,
              lastSuccessfulSyncAt: _clock(),
              clearLastFailure: true,
              nextScheduledRetryAt: operations
                  .map((item) => item.nextAttemptAt)
                  .fold<DateTime?>(null, _earliest),
            ),
          );
        } catch (error, stackTrace) {
          final failedOperation = operation.copyWith(
            attemptCount: operation.attemptCount + 1,
            nextAttemptAt: _clock().add(
              _backoffForAttempt(operation.attemptCount + 1),
            ),
            lastErrorMessage: error.toString(),
          );
          operations = [
            for (final item in operations)
              if (item.queueKey == failedOperation.queueKey)
                failedOperation
              else
                item,
          ];
          await _queueStore.saveOperations(operations);
          log(
            'Journal sync operation failed for ${operation.queueKey}',
            name: 'lumen.journal.sync',
            error: error,
            stackTrace: stackTrace,
          );
          _publish(
            _currentDiagnostics.copyWith(
              pendingOperationCount: operations.length,
              lastFailureAt: _clock(),
              lastFailureMessage: error.toString(),
              nextScheduledRetryAt: failedOperation.nextAttemptAt,
            ),
          );
          break;
        }
      }
    } finally {
      final latestOperations = await _queueStore.loadOperations();
      _publish(
        _currentDiagnostics.copyWith(
          pendingOperationCount: latestOperations.length,
          isSyncInProgress: false,
          nextScheduledRetryAt: latestOperations
              .map((item) => item.nextAttemptAt)
              .fold<DateTime?>(null, _earliest),
        ),
      );
      _isFlushing = false;
    }
  }

  JournalSyncDiagnostics get _currentDiagnostics =>
      _diagnosticsSink.currentDiagnostics;

  Future<void> _replaceOperation(JournalSyncOperation operation) async {
    final operations = await _queueStore.loadOperations();
    final updatedOperations = [
      for (final item in operations)
        if (item.queueKey != operation.queueKey) item,
      operation,
    ]..sort((left, right) => left.enqueuedAt.compareTo(right.enqueuedAt));
    await _queueStore.saveOperations(updatedOperations);
    _publish(
      _currentDiagnostics.copyWith(
        pendingOperationCount: updatedOperations.length,
        nextScheduledRetryAt: updatedOperations
            .map((item) => item.nextAttemptAt)
            .fold<DateTime?>(null, _earliest),
      ),
    );
  }

  Future<void> _flushOperation(JournalSyncOperation operation) async {
    switch (operation.type) {
      case JournalSyncOperationType.upsert:
        final entry = operation.entry;
        if (entry == null) {
          throw StateError(
            'Upsert operation ${operation.queueKey} is missing entry payload.',
          );
        }
        await _cloudStore.saveEntry(userId: operation.userId, entry: entry);
      case JournalSyncOperationType.delete:
        await _cloudStore.deleteEntry(
          userId: operation.userId,
          entryId: operation.entryId,
        );
    }
  }

  void _publish(JournalSyncDiagnostics diagnostics) {
    _diagnosticsSink.updateDiagnostics(diagnostics);
  }

  static DateTime _defaultClock() => DateTime.now().toUtc();

  static DateTime? _earliest(DateTime? current, DateTime next) {
    if (current == null || next.isBefore(current)) {
      return next;
    }
    return current;
  }

  Duration _backoffForAttempt(int attemptCount) {
    final seconds = switch (attemptCount) {
      <= 1 => 5,
      2 => 15,
      3 => 30,
      4 => 60,
      _ => 300,
    };
    return Duration(seconds: seconds);
  }
}
