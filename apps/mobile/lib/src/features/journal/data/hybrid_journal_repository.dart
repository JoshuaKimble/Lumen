import '../domain/journal_cloud_store.dart';
import '../domain/journal_entry.dart';
import '../domain/journal_local_store.dart';
import '../domain/journal_repository.dart';

class HybridJournalRepository implements JournalRepository {
  const HybridJournalRepository({
    required JournalLocalStore localStore,
    JournalCloudStore? cloudStore,
  }) : _localStore = localStore,
       _cloudStore = cloudStore;

  final JournalLocalStore _localStore;
  final JournalCloudStore? _cloudStore;

  bool get hasCloudStore => _cloudStore != null;

  @override
  Future<void> deleteEntry(String id) {
    return _localStore.deleteEntry(id);
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
  Future<void> saveEntry(JournalEntry entry) {
    // Write-through sync lands in later M6 issues. For now, the hybrid layer
    // centralizes composition while preserving the current local-first UX.
    return _localStore.saveEntry(entry);
  }
}
