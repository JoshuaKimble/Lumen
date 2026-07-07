import '../domain/journal_cloud_store.dart';
import '../domain/journal_entry.dart';
import '../domain/journal_entry_conflict_resolver.dart';
import '../domain/journal_entry_sync_snapshot.dart';
import '../domain/journal_local_store.dart';
import '../domain/journal_sync_operation.dart';
import 'journal_sync_queue_store.dart';

typedef CurrentJournalHydrationUserId = String? Function();
typedef JournalHydrationDataChanged = void Function();

class JournalHydrationController {
  JournalHydrationController({
    required JournalLocalStore localStore,
    required JournalCloudStore cloudStore,
    required JournalSyncQueueStore queueStore,
    required CurrentJournalHydrationUserId currentUserId,
    this.onDataChanged,
    JournalEntryConflictResolver conflictResolver =
        const JournalEntryConflictResolver(),
    this.pageSize = 25,
  }) : _localStore = localStore,
       _cloudStore = cloudStore,
       _queueStore = queueStore,
       _currentUserId = currentUserId,
       _conflictResolver = conflictResolver;

  final JournalLocalStore _localStore;
  final JournalCloudStore _cloudStore;
  final JournalSyncQueueStore _queueStore;
  final CurrentJournalHydrationUserId _currentUserId;
  final JournalHydrationDataChanged? onDataChanged;
  final JournalEntryConflictResolver _conflictResolver;
  final int pageSize;

  bool _isHydrating = false;

  Future<void> hydrateFromCloud() async {
    if (_isHydrating) {
      return;
    }

    final userId = _currentUserId();
    if (userId == null) {
      return;
    }

    _isHydrating = true;
    try {
      final pendingOperations = await _queueStore.loadOperations();
      final pendingByQueueKey = {
        for (final operation in pendingOperations)
          operation.queueKey: operation,
      };

      DateTime? beforeCreatedAt;
      while (true) {
        final page = await _cloudStore.listEntriesPage(
          userId: userId,
          limit: pageSize,
          beforeCreatedAt: beforeCreatedAt,
        );
        if (page.entries.isEmpty) {
          break;
        }

        var changed = false;
        for (final cloudEntry in page.entries) {
          final queueKey = JournalSyncOperation.queueKeyFor(
            userId: userId,
            entryId: cloudEntry.id,
          );
          final pendingOperation = pendingByQueueKey[queueKey];
          if (pendingOperation?.type == JournalSyncOperationType.delete) {
            continue;
          }

          final localEntry = await _localStore.getEntry(cloudEntry.id);
          if (localEntry == null) {
            await _localStore.saveEntry(cloudEntry);
            changed = true;
            continue;
          }

          final effectiveLocalEntry =
              pendingOperation?.type == JournalSyncOperationType.upsert &&
                  pendingOperation?.entry != null
              ? pendingOperation!.entry!
              : localEntry;
          final resolution = _conflictResolver.resolve(
            local: JournalEntrySyncSnapshot(
              entry: effectiveLocalEntry,
              clientUpdatedAt: effectiveLocalEntry.updatedAt,
              version: 1,
            ),
            cloud: JournalEntrySyncSnapshot(
              entry: cloudEntry,
              clientUpdatedAt: cloudEntry.updatedAt,
              version: 1,
            ),
          );
          if (_sameEntry(localEntry, resolution.entry)) {
            continue;
          }

          await _localStore.saveEntry(resolution.entry);
          changed = true;
        }

        if (changed) {
          onDataChanged?.call();
        }

        if (!page.hasMore || page.nextBeforeCreatedAt == null) {
          break;
        }

        beforeCreatedAt = page.nextBeforeCreatedAt;
        await Future<void>.delayed(Duration.zero);
      }
    } finally {
      _isHydrating = false;
    }
  }

  bool _sameEntry(JournalEntry left, JournalEntry right) {
    if (left.id != right.id ||
        left.createdAt != right.createdAt ||
        left.updatedAt != right.updatedAt ||
        left.source != right.source ||
        left.originalText != right.originalText ||
        left.rewrittenText != right.rewrittenText ||
        left.title != right.title ||
        left.summary != right.summary ||
        left.lastRegeneratedAt != right.lastRegeneratedAt ||
        left.studyGuide != right.studyGuide) {
      return false;
    }

    if (left.themes.length != right.themes.length ||
        left.resources.length != right.resources.length) {
      return false;
    }

    for (var index = 0; index < left.themes.length; index++) {
      final leftTheme = left.themes[index];
      final rightTheme = right.themes[index];
      if (leftTheme.id != rightTheme.id ||
          leftTheme.name != rightTheme.name ||
          leftTheme.displayName != rightTheme.displayName ||
          leftTheme.weight != rightTheme.weight) {
        return false;
      }
    }

    for (var index = 0; index < left.resources.length; index++) {
      final leftResource = left.resources[index];
      final rightResource = right.resources[index];
      if (leftResource.id != rightResource.id ||
          leftResource.title != rightResource.title ||
          leftResource.type != rightResource.type ||
          leftResource.sourceType != rightResource.sourceType ||
          leftResource.matchReason != rightResource.matchReason ||
          leftResource.confidence != rightResource.confidence ||
          leftResource.url != rightResource.url ||
          leftResource.scriptureReference != rightResource.scriptureReference ||
          leftResource.entryId != rightResource.entryId ||
          leftResource.themeId != rightResource.themeId ||
          leftResource.description != rightResource.description) {
        return false;
      }
    }

    return true;
  }
}
