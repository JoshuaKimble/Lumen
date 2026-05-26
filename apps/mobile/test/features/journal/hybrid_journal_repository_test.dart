import 'package:flutter_test/flutter_test.dart';
import 'package:lumen/src/features/journal/data/hybrid_journal_repository.dart';
import 'package:lumen/src/features/journal/data/journal_hydration_controller.dart';
import 'package:lumen/src/features/journal/data/in_memory_journal_repository.dart';
import 'package:lumen/src/features/journal/data/journal_sync_coordinator.dart';
import 'package:lumen/src/features/journal/data/journal_sync_diagnostics_sink.dart';
import 'package:lumen/src/features/journal/data/journal_sync_queue_store.dart';
import 'package:lumen/src/features/journal/domain/entry_source.dart';
import 'package:lumen/src/features/journal/domain/journal_cloud_entry_page.dart';
import 'package:lumen/src/features/journal/domain/journal_cloud_store.dart';
import 'package:lumen/src/features/journal/domain/journal_entry.dart';
import 'package:lumen/src/features/journal/domain/journal_sync_diagnostics.dart';
import 'package:lumen/src/features/journal/domain/journal_sync_operation.dart';

void main() {
  test('delegates CRUD operations to the local store', () async {
    final repository = HybridJournalRepository(
      localStore: InMemoryJournalRepository(seedEntries: const []),
    );
    final timestamp = DateTime.utc(2026, 5, 25, 20, 55);
    final entry = JournalEntry(
      id: 'entry-1',
      createdAt: timestamp,
      updatedAt: timestamp,
      source: EntrySource.text,
      originalText: 'Original text',
      rewrittenText: 'Rewritten text',
      themes: const [],
      resources: const [],
      title: 'A title',
    );

    await repository.saveEntry(entry);

    expect((await repository.getEntry('entry-1'))?.title, 'A title');
    expect((await repository.listEntries()).map((item) => item.id), [
      'entry-1',
    ]);
    expect(repository.hasCloudStore, isFalse);

    await repository.deleteEntry('entry-1');

    expect(await repository.getEntry('entry-1'), isNull);
  });

  test('preserves local save when queued cloud sync fails', () async {
    final localStore = InMemoryJournalRepository(seedEntries: const []);
    final queueStore = _InMemoryJournalSyncQueueStore();
    final repository = HybridJournalRepository(
      localStore: localStore,
      cloudStore: _FailingJournalCloudStore(),
      syncCoordinator: JournalSyncCoordinator(
        queueStore: queueStore,
        cloudStore: _FailingJournalCloudStore(),
        currentUserId: () => 'user-1',
        diagnosticsSink: _TestJournalSyncDiagnosticsSink(),
        clock: () => DateTime.utc(2026, 5, 25, 21, 0),
      ),
    );
    final timestamp = DateTime.utc(2026, 5, 25, 20, 55);
    final entry = JournalEntry(
      id: 'entry-2',
      createdAt: timestamp,
      updatedAt: timestamp,
      source: EntrySource.text,
      originalText: 'Original text',
      rewrittenText: '',
      themes: const [],
      resources: const [],
    );

    await repository.saveEntry(entry);

    expect(
      (await repository.getEntry('entry-2'))?.originalText,
      'Original text',
    );
    expect(await queueStore.loadOperations(), hasLength(1));
    expect(
      (await queueStore.loadOperations()).single.type,
      JournalSyncOperationType.upsert,
    );
  });

  test('hydrates cloud entries into the local store', () async {
    final localStore = InMemoryJournalRepository(seedEntries: const []);
    final repository = HybridJournalRepository(
      localStore: localStore,
      cloudStore: _PagedJournalCloudStore(
        pages: [
          JournalCloudEntryPage(
            entries: [_entry(id: 'cloud-1', originalText: 'Cloud text')],
            hasMore: false,
          ),
        ],
      ),
      hydrationController: JournalHydrationController(
        localStore: localStore,
        cloudStore: _PagedJournalCloudStore(
          pages: [
            JournalCloudEntryPage(
              entries: [_entry(id: 'cloud-1', originalText: 'Cloud text')],
              hasMore: false,
            ),
          ],
        ),
        queueStore: _InMemoryJournalSyncQueueStore(),
        currentUserId: () => 'user-1',
      ),
    );

    await repository.hydrateFromCloud();

    expect((await repository.listEntries()).map((entry) => entry.id), [
      'cloud-1',
    ]);
  });
}

class _InMemoryJournalSyncQueueStore implements JournalSyncQueueStore {
  List<JournalSyncOperation> _operations = const [];

  @override
  Future<List<JournalSyncOperation>> loadOperations() async => _operations;

  @override
  Future<void> saveOperations(List<JournalSyncOperation> operations) async {
    _operations = operations;
  }
}

class _FailingJournalCloudStore implements JournalCloudStore {
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
    throw StateError('offline');
  }
}

class _PagedJournalCloudStore implements JournalCloudStore {
  _PagedJournalCloudStore({required List<JournalCloudEntryPage> pages})
    : _pages = pages;

  final List<JournalCloudEntryPage> _pages;
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

class _TestJournalSyncDiagnosticsSink implements JournalSyncDiagnosticsSink {
  @override
  JournalSyncDiagnostics currentDiagnostics =
      const JournalSyncDiagnostics.idle();

  @override
  void updateDiagnostics(JournalSyncDiagnostics diagnostics) {
    currentDiagnostics = diagnostics;
  }
}

JournalEntry _entry({
  required String id,
  required String originalText,
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  final timestamp = createdAt ?? updatedAt ?? DateTime.utc(2026, 5, 25, 21, 5);
  return JournalEntry(
    id: id,
    createdAt: createdAt ?? timestamp,
    updatedAt: updatedAt ?? timestamp,
    source: EntrySource.text,
    originalText: originalText,
    rewrittenText: '',
    themes: const [],
    resources: const [],
  );
}
