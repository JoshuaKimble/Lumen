import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumen/src/features/journal/data/journal_sync_coordinator.dart';
import 'package:lumen/src/features/journal/data/journal_sync_diagnostics_controller.dart';
import 'package:lumen/src/features/journal/data/journal_sync_queue_store.dart';
import 'package:lumen/src/features/journal/domain/entry_source.dart';
import 'package:lumen/src/features/journal/domain/journal_cloud_entry_page.dart';
import 'package:lumen/src/features/journal/domain/journal_cloud_store.dart';
import 'package:lumen/src/features/journal/domain/journal_entry.dart';
import 'package:lumen/src/features/journal/domain/journal_sync_operation.dart';

void main() {
  test('flushes queued upserts and clears diagnostics failure state', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final queueStore = _InMemoryJournalSyncQueueStore();
    final cloudStore = _RecordingJournalCloudStore();
    final coordinator = JournalSyncCoordinator(
      queueStore: queueStore,
      cloudStore: cloudStore,
      currentUserId: () => 'user-1',
      diagnosticsSink: container.read(journalSyncDiagnosticsProvider.notifier),
      clock: () => DateTime.utc(2026, 5, 25, 22, 0),
    );

    await coordinator.enqueueSave(_entry(id: 'entry-1'));

    expect(cloudStore.savedEntries.map((entry) => entry.id), ['entry-1']);
    expect(await queueStore.loadOperations(), isEmpty);

    final diagnostics = container.read(journalSyncDiagnosticsProvider);
    expect(diagnostics.pendingOperationCount, 0);
    expect(diagnostics.lastFailureMessage, isNull);
    expect(diagnostics.lastSuccessfulSyncAt, DateTime.utc(2026, 5, 25, 22, 0));
  });

  test(
    'deduplicates repeated saves to the same entry before flushing',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final queueStore = _InMemoryJournalSyncQueueStore();
      final cloudStore = _RecordingJournalCloudStore(throwOnSave: true);
      var now = DateTime.utc(2026, 5, 25, 22, 5);
      final coordinator = JournalSyncCoordinator(
        queueStore: queueStore,
        cloudStore: cloudStore,
        currentUserId: () => 'user-1',
        diagnosticsSink: container.read(
          journalSyncDiagnosticsProvider.notifier,
        ),
        clock: () => now,
      );

      await coordinator.enqueueSave(
        _entry(id: 'entry-1', originalText: 'Draft 1'),
      );
      now = now.add(const Duration(minutes: 1));
      await coordinator.enqueueSave(
        _entry(id: 'entry-1', originalText: 'Draft 2'),
      );

      final queuedOperations = await queueStore.loadOperations();
      expect(queuedOperations, hasLength(1));
      expect(queuedOperations.single.type, JournalSyncOperationType.upsert);
      expect(queuedOperations.single.entry?.originalText, 'Draft 2');
    },
  );

  test('schedules retry with backoff when sync fails', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final queueStore = _InMemoryJournalSyncQueueStore();
    final cloudStore = _RecordingJournalCloudStore(throwOnSave: true);
    final baseTime = DateTime.utc(2026, 5, 25, 22, 10);
    final coordinator = JournalSyncCoordinator(
      queueStore: queueStore,
      cloudStore: cloudStore,
      currentUserId: () => 'user-1',
      diagnosticsSink: container.read(journalSyncDiagnosticsProvider.notifier),
      clock: () => baseTime,
    );

    await coordinator.enqueueSave(_entry(id: 'entry-1'));

    final queuedOperations = await queueStore.loadOperations();
    expect(queuedOperations, hasLength(1));
    expect(queuedOperations.single.attemptCount, 1);
    expect(
      queuedOperations.single.nextAttemptAt,
      baseTime.add(const Duration(seconds: 5)),
    );

    final diagnostics = container.read(journalSyncDiagnosticsProvider);
    expect(diagnostics.pendingOperationCount, 1);
    expect(diagnostics.lastFailureMessage, contains('sync save failed'));
    expect(
      diagnostics.nextScheduledRetryAt,
      queuedOperations.single.nextAttemptAt,
    );
  });

  test('flushes deletes and skips syncing when signed out', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final queueStore = _InMemoryJournalSyncQueueStore();
    final cloudStore = _RecordingJournalCloudStore();
    String? currentUserId = 'user-1';
    final coordinator = JournalSyncCoordinator(
      queueStore: queueStore,
      cloudStore: cloudStore,
      currentUserId: () => currentUserId,
      diagnosticsSink: container.read(journalSyncDiagnosticsProvider.notifier),
      clock: () => DateTime.utc(2026, 5, 25, 22, 20),
    );

    await coordinator.enqueueDelete('entry-1');
    expect(cloudStore.deletedEntryIds, ['entry-1']);

    currentUserId = null;
    await coordinator.enqueueDelete('entry-2');

    expect(cloudStore.deletedEntryIds, ['entry-1']);
    expect(await queueStore.loadOperations(), isEmpty);
  });
}

class _InMemoryJournalSyncQueueStore implements JournalSyncQueueStore {
  List<JournalSyncOperation> _operations = const [];

  @override
  Future<List<JournalSyncOperation>> loadOperations() async {
    return _operations;
  }

  @override
  Future<void> saveOperations(List<JournalSyncOperation> operations) async {
    _operations = operations;
  }
}

class _RecordingJournalCloudStore implements JournalCloudStore {
  _RecordingJournalCloudStore({this.throwOnSave = false});

  final bool throwOnSave;
  final List<JournalEntry> savedEntries = <JournalEntry>[];
  final List<String> deletedEntryIds = <String>[];

  @override
  Future<void> deleteEntry({
    required String userId,
    required String entryId,
  }) async {
    deletedEntryIds.add(entryId);
  }

  @override
  Future<JournalEntry?> getEntry({
    required String userId,
    required String entryId,
  }) async {
    return null;
  }

  @override
  Future<List<JournalEntry>> listEntries({required String userId}) async {
    return const [];
  }

  @override
  Future<JournalCloudEntryPage> listEntriesPage({
    required String userId,
    required int limit,
    DateTime? beforeCreatedAt,
  }) async {
    return const JournalCloudEntryPage(entries: [], hasMore: false);
  }

  @override
  Future<void> saveEntry({
    required String userId,
    required JournalEntry entry,
  }) async {
    if (throwOnSave) {
      throw StateError('sync save failed for ${entry.id}');
    }

    savedEntries.add(entry);
  }
}

JournalEntry _entry({
  required String id,
  String originalText = 'Original text',
}) {
  final timestamp = DateTime.utc(2026, 5, 25, 21, 55);
  return JournalEntry(
    id: id,
    createdAt: timestamp,
    updatedAt: timestamp,
    source: EntrySource.text,
    originalText: originalText,
    rewrittenText: '',
    themes: const [],
    resources: const [],
  );
}
