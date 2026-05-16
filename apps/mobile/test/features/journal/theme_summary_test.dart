import 'package:flutter_test/flutter_test.dart';
import 'package:lumen/src/features/journal/domain/entry_source.dart';
import 'package:lumen/src/features/journal/domain/journal_entry.dart';
import 'package:lumen/src/features/journal/domain/journal_theme.dart';
import 'package:lumen/src/features/journal/domain/theme_summary.dart';

void main() {
  test('aggregates themes by entry count and significance', () {
    final summaries = summarizeThemes([
      _entry(
        id: '1',
        themes: const [
          JournalTheme(id: 'work', name: 'work', displayName: 'Work'),
          JournalTheme(id: 'family', name: 'family', displayName: 'Family'),
        ],
      ),
      _entry(
        id: '2',
        themes: const [
          JournalTheme(id: 'work', name: 'work', displayName: 'Work'),
          JournalTheme(
            id: 'stress',
            name: 'stress',
            displayName: 'Stress',
            weight: 3,
          ),
        ],
      ),
      _entry(
        id: '3',
        themes: const [
          JournalTheme(id: 'family', name: 'family', displayName: 'Family'),
          JournalTheme(id: 'family', name: 'family', displayName: 'Family'),
        ],
      ),
    ]);

    expect(summaries.map((summary) => summary.displayName), [
      'Stress',
      'Family',
      'Work',
    ]);
    expect(summaries[0].score, 3);
    expect(summaries[1].entryCount, 2);
    expect(summaries[1].score, 2);
    expect(summaries[2].entryCount, 2);
  });
}

JournalEntry _entry({required String id, required List<JournalTheme> themes}) {
  final createdAt = DateTime.utc(2026, 5, 14);

  return JournalEntry(
    id: id,
    createdAt: createdAt,
    updatedAt: createdAt,
    source: EntrySource.text,
    originalText: 'Original text',
    rewrittenText: 'Rewritten text',
    themes: themes,
    resources: const [],
  );
}
