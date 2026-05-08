import 'journal_entry.dart';

abstract interface class JournalRepository {
  Future<List<JournalEntry>> listEntries();
}
