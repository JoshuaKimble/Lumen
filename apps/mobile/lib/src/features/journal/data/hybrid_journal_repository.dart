import '../domain/journal_cloud_store.dart';
import '../domain/journal_entry.dart';
import '../domain/journal_local_store.dart';
import '../domain/journal_repository.dart';
import 'journal_hydration_controller.dart';
import 'journal_sync_coordinator.dart';

class HybridJournalRepository implements JournalRepository {
  const HybridJournalRepository({
    required JournalLocalStore localStore,
    JournalCloudStore? cloudStore,
    JournalSyncCoordinator? syncCoordinator,
    JournalHydrationController? hydrationController,
  }) : _localStore = localStore,
       _cloudStore = cloudStore,
       _syncCoordinator = syncCoordinator,
       _hydrationController = hydrationController;

  final JournalLocalStore _localStore;
  final JournalCloudStore? _cloudStore;
  final JournalSyncCoordinator? _syncCoordinator;
  final JournalHydrationController? _hydrationController;

  bool get hasCloudStore => _cloudStore != null;

  Future<void> hydrateFromCloud() async {
    await _hydrationController?.hydrateFromCloud();
  }

  @override
  Future<void> deleteEntry(String id) async {
    await _localStore.deleteEntry(id);
    await _syncCoordinator?.enqueueDelete(id);
  }

  @override
  Future<JournalEntry?> getEntry(String id) {
    return _localStore.getEntry(id);
  }

  @override
  Future<List<JournalEntry>> listEntries() {
    return _localStore.listEntries();
  }

  @override
  Future<List<JournalEntry>> listEntriesByTheme(String themeId) {
    return _localStore.listEntriesByTheme(themeId);
  }

  @override
  Future<void> saveEntry(JournalEntry entry) async {
    await _localStore.saveEntry(entry);
    await _syncCoordinator?.enqueueSave(entry);
  }
}
