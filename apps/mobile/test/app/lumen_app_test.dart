import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumen/src/app/lumen_app.dart';
import 'package:lumen/src/features/journal/data/in_memory_journal_repository.dart';
import 'package:lumen/src/features/journal/data/journal_repository_provider.dart';
import 'package:lumen/src/features/journal/domain/entry_source.dart';
import 'package:lumen/src/features/journal/domain/journal_entry.dart';
import 'package:lumen/src/features/journal/domain/journal_theme.dart';
import 'package:lumen/src/features/journal/domain/related_resource.dart';

void main() {
  testWidgets('renders the journal home screen', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          journalRepositoryProvider.overrideWithValue(
            InMemoryJournalRepository(),
          ),
        ],
        child: const LumenApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Lumen'), findsOneWidget);
    expect(find.text('Welcome to Lumen'), findsOneWidget);
    expect(find.text('A quiet place for daily reflection.'), findsOneWidget);
  });

  testWidgets('renders entry list content', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          journalRepositoryProvider.overrideWithValue(
            InMemoryJournalRepository(seedEntries: [_sampleEntry]),
          ),
        ],
        child: const LumenApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('May 7, 2026'), findsOneWidget);
    expect(find.text('A difficult but honest morning'), findsOneWidget);
    expect(find.text('Family'), findsOneWidget);
    expect(
      find.text('A morning reflection about family stress.'),
      findsOneWidget,
    );
  });

  testWidgets('opens entry detail and separates original from rewrite', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          journalRepositoryProvider.overrideWithValue(
            InMemoryJournalRepository(seedEntries: [_sampleEntry]),
          ),
        ],
        child: const LumenApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('A difficult but honest morning'));
    await tester.pumpAndSettle();

    expect(find.text('Journal entry'), findsOneWidget);
    expect(find.text('Original'), findsOneWidget);
    expect(find.text('AI rewrite'), findsOneWidget);
    expect(
      find.text('I was irritated and rushed this morning.'),
      findsOneWidget,
    );
    expect(
      find.text('I noticed I was tense before breakfast.'),
      findsOneWidget,
    );
    expect(find.text('Morning reflection prompt'), findsOneWidget);
  });

  testWidgets('renders a calm empty state', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          journalRepositoryProvider.overrideWithValue(
            InMemoryJournalRepository(seedEntries: const []),
          ),
        ],
        child: const LumenApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No journal entries yet'), findsOneWidget);
    expect(
      find.text('Your reflections will appear here after you save them.'),
      findsOneWidget,
    );
  });
}

final _sampleEntry = JournalEntry(
  id: 'entry-1',
  createdAt: DateTime.utc(2026, 5, 7, 15, 30),
  updatedAt: DateTime.utc(2026, 5, 7, 15, 45),
  source: EntrySource.voice,
  originalText: 'I was irritated and rushed this morning.',
  rewrittenText: 'I noticed I was tense before breakfast.',
  themes: const [
    JournalTheme(id: 'family', name: 'family', displayName: 'Family'),
  ],
  resources: [
    RelatedResource(
      id: 'resource-1',
      title: 'Morning reflection prompt',
      type: 'prompt',
    ),
  ],
  title: 'A difficult but honest morning',
  summary: 'A morning reflection about family stress.',
);
