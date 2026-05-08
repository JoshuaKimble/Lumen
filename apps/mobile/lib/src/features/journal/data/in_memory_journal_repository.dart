import '../domain/journal_entry.dart';
import '../domain/journal_repository.dart';

class InMemoryJournalRepository implements JournalRepository {
  const InMemoryJournalRepository();

  @override
  Future<List<JournalEntry>> listEntries() async {
    return const [
      JournalEntry(
        id: 'welcome',
        title: 'Welcome to Lumen',
        body: 'A quiet place for daily reflection.',
      ),
    ];
  }
}
