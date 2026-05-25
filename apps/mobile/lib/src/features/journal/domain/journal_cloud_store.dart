import 'journal_entry.dart';

abstract interface class JournalCloudStore {
  Future<void> deleteEntry({required String userId, required String entryId});

  Future<JournalEntry?> getEntry({
    required String userId,
    required String entryId,
  });

  Future<List<JournalEntry>> listEntries({required String userId});

  Future<void> saveEntry({required String userId, required JournalEntry entry});
}
