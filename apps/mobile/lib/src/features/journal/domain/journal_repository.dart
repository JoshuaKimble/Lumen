import 'journal_entry.dart';

abstract interface class JournalRepository {
  Future<void> deleteEntry(String id);

  Future<JournalEntry?> getEntry(String id);

  Future<List<JournalEntry>> listEntries();

  Future<List<JournalEntry>> listEntriesByTheme(String themeId);

  Future<void> saveEntry(JournalEntry entry);
}
