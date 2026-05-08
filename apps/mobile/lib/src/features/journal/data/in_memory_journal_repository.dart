import '../domain/journal_entry.dart';
import '../domain/journal_repository.dart';
import '../domain/entry_source.dart';
import '../domain/journal_theme.dart';

class InMemoryJournalRepository implements JournalRepository {
  const InMemoryJournalRepository();

  @override
  Future<List<JournalEntry>> listEntries() async {
    final createdAt = DateTime.utc(2026, 5, 6, 22, 12);

    return [
      JournalEntry(
        id: 'welcome',
        createdAt: createdAt,
        updatedAt: createdAt,
        source: EntrySource.text,
        originalText: 'A quiet place for daily reflection.',
        rewrittenText: 'A quiet place for daily reflection.',
        themes: [
          JournalTheme(
            id: 'reflection',
            name: 'reflection',
            displayName: 'Reflection',
          ),
        ],
        resources: [],
        title: 'Welcome to Lumen',
      ),
    ];
  }
}
