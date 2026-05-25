import '../domain/journal_sync_operation.dart';

abstract interface class JournalSyncQueueStore {
  Future<List<JournalSyncOperation>> loadOperations();

  Future<void> saveOperations(List<JournalSyncOperation> operations);
}
