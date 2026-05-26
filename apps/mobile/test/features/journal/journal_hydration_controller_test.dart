import 'package:flutter_test/flutter_test.dart';
import 'package:lumen/src/features/journal/data/in_memory_journal_repository.dart';
import 'package:lumen/src/features/journal/data/journal_hydration_controller.dart';
import 'package:lumen/src/features/journal/data/journal_sync_queue_store.dart';
import 'package:lumen/src/features/journal/domain/entry_source.dart';
import 'package:lumen/src/features/journal/domain/journal_cloud_entry_page.dart';
import 'package:lumen/src/features/journal/domain/journal_cloud_store.dart';
import 'package:lumen/src/features/journal/domain/journal_entry.dart';
import 'package:lumen/src/features/journal/domain/journal_sync_operation.dart';

void main() {
  test('hydrates cloud-only entries into local storage', () async {
    final localStore = InMemoryJournalRepository(seedEntries: const []);
    var changeCount = 0;
    final controller = JournalHydrationController(
      localStore: localStore,
      cloudStore: _TestJournalCloudStore(
        pages: [
          JournalCloudEntryPage(
            entries: [_entry(id: 'cloud-1', originalText: 'Cloud text')],
            hasMore: false,
          ),
        ],
      ),
      queueStore: _InMemoryJournalSyncQueueStore(),
      currentUserId: () => 'user-1',
      onDataChanged: () {
        changeCount += 1;
      },
    );

    await controller.hydrateFromCloud();

    expect((await localStore.listEntries()).map((entry) => entry.id), [
      'cloud-1',
    ]);
    expect(changeCount, 1);
  });

  test('keeps local pending delete over cloud entry', () async {
    final localStore = InMemoryJournalRepository(
      seedEntries: [_entry(id: 'entry-1', originalText: 'Local text')],
    );
    final queueStore = _InMemoryJournalSyncQueueStore(
      operations: [
        JournalSyncOperation(
          queueKey: JournalSyncOperation.queueKeyFor(
            userId: 'user-1',
            entryId: 'entry-1',
          ),
          userId: 'user-1',
          entryId: 'entry-1',
          type: JournalSyncOperationType.delete,
          enqueuedAt: DateTime.utc(2026, 5, 25, 22, 0),
          nextAttemptAt: DateTime.utc(2026, 5, 25, 22, 0),
          attemptCount: 0,
        ),
      ],
    );
    final controller = JournalHydrationController(
      localStore: localStore,
      cloudStore: _TestJournalCloudStore(
        pages: [
          JournalCloudEntryPage(
            entries: [_entry(id: 'entry-1', originalText: 'Cloud text')],
            hasMore: false,
          ),
        ],
      ),
      queueStore: queueStore,
      currentUserId: () => 'user-1',
    );

    await controller.hydrateFromCloud();

    expect((await localStore.getEntry('entry-1'))?.originalText, 'Local text');
  });

  test('replaces stale local entry when cloud is newer', () async {
    final localStore = InMemoryJournalRepository(
      seedEntries: [
        _entry(
          id: 'entry-1',
          originalText: 'Local older',
          updatedAt: DateTime.utc(2026, 5, 25, 20, 0),
        ),
      ],
    );
    final controller = JournalHydrationController(
      localStore: localStore,
      cloudStore: _TestJournalCloudStore(
        pages: [
          JournalCloudEntryPage(
            entries: [
              _entry(
                id: 'entry-1',
                originalText: 'Cloud newer',
                updatedAt: DateTime.utc(2026, 5, 25, 21, 0),
              ),
            ],
            hasMore: false,
          ),
        ],
      ),
      queueStore: _InMemoryJournalSyncQueueStore(),
      currentUserId: () => 'user-1',
    );

    await controller.hydrateFromCloud();

    expect((await localStore.getEntry('entry-1'))?.originalText, 'Cloud newer');
  });

  test('hydrates incrementally across paged cloud batches', () async {
    final localStore = InMemoryJournalRepository(seedEntries: const []);
    final cloudStore = _TestJournalCloudStore(
      pages: [
        JournalCloudEntryPage(
          entries: [_entry(id: 'entry-1')],
          hasMore: true,
          nextBeforeCreatedAt: DateTime.utc(2026, 5, 25, 20, 0),
        ),
        JournalCloudEntryPage(
          entries: [
            _entry(id: 'entry-2', createdAt: DateTime.utc(2026, 5, 24)),
          ],
          hasMore: false,
        ),
      ],
    );
    final controller = JournalHydrationController(
      localStore: localStore,
      cloudStore: cloudStore,
      queueStore: _InMemoryJournalSyncQueueStore(),
      currentUserId: () => 'user-1',
      pageSize: 1,
    );

    await controller.hydrateFromCloud();

    expect(cloudStore.requestedLimits, [1, 1]);
    expect((await localStore.listEntries()).map((entry) => entry.id), [
      'entry-1',
      'entry-2',
    ]);
  });
}

class _InMemoryJournalSyncQueueStore implements JournalSyncQueueStore {
  _InMemoryJournalSyncQueueStore({
    List<JournalSyncOperation> operations = const [],
  }) : _operations = operations;

  List<JournalSyncOperation> _operations;

  @override
  Future<List<JournalSyncOperation>> loadOperations() async => _operations;

  @override
  Future<void> saveOperations(List<JournalSyncOperation> operations) async {
    _operations = operations;
  }
}

class _TestJournalCloudStore implements JournalCloudStore {
  _TestJournalCloudStore({required List<JournalCloudEntryPage> pages})
    : _pages = pages;

  final List<JournalCloudEntryPage> _pages;
  final List<int> requestedLimits = <int>[];
  int _index = 0;

  @override
  Future<void> deleteEntry({
    required String userId,
    required String entryId,
  }) async {}

  @override
  Future<JournalEntry?> getEntry({
    required String userId,
    required String entryId,
  }) async {
    return null;
  }

  @override
  Future<List<JournalEntry>> listEntries({required String userId}) async {
    return _pages.expand((page) => page.entries).toList(growable: false);
  }

  @override
  Future<JournalCloudEntryPage> listEntriesPage({
    required String userId,
    required int limit,
    DateTime? beforeCreatedAt,
  }) async {
    requestedLimits.add(limit);
    if (_index >= _pages.length) {
      return const JournalCloudEntryPage(entries: [], hasMore: false);
    }
    final page = _pages[_index];
    _index += 1;
    return page;
  }

  @override
  Future<void> saveEntry({
    required String userId,
    required JournalEntry entry,
  }) async {}
}

JournalEntry _entry({
  required String id,
  String originalText = 'Original text',
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  final created = createdAt ?? DateTime.utc(2026, 5, 25, 20, 0);
  final updated = updatedAt ?? created;
  return JournalEntry(
    id: id,
    createdAt: created,
    updatedAt: updated,
    source: EntrySource.text,
    originalText: originalText,
    rewrittenText: '',
    themes: const [],
    resources: const [],
  );
}
