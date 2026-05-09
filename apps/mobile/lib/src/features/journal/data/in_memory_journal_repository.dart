import '../domain/journal_entry.dart';
import '../domain/journal_repository.dart';
import '../domain/entry_source.dart';
import '../domain/journal_theme.dart';

class InMemoryJournalRepository implements JournalRepository {
  InMemoryJournalRepository({List<JournalEntry>? seedEntries})
    : _entries = seedEntries == null ? _starterEntries() : [...seedEntries];

  final List<JournalEntry> _entries;

  @override
  Future<void> deleteEntry(String id) async {
    _entries.removeWhere((entry) => entry.id == id);
  }

  @override
  Future<JournalEntry?> getEntry(String id) async {
    for (final entry in _entries) {
      if (entry.id == id) {
        return entry;
      }
    }

    return null;
  }

  @override
  Future<List<JournalEntry>> listEntries() async {
    return _sortedEntries(_entries);
  }

  @override
  Future<List<JournalEntry>> listEntriesByTheme(String themeId) async {
    final entries = await listEntries();

    return entries
        .where((entry) => entry.themes.any((theme) => theme.id == themeId))
        .toList(growable: false);
  }

  @override
  Future<void> saveEntry(JournalEntry entry) async {
    _entries.removeWhere((existingEntry) => existingEntry.id == entry.id);
    _entries.add(entry);
  }

  List<JournalEntry> _sortedEntries(List<JournalEntry> entries) {
    return [...entries]
      ..sort((left, right) => right.createdAt.compareTo(left.createdAt));
  }

  static List<JournalEntry> _starterEntries() {
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
