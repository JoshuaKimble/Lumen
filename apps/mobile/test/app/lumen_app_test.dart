import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumen/src/app/lumen_app.dart';
import 'package:lumen/src/features/journal/data/journal_ai_service_provider.dart';
import 'package:lumen/src/features/journal/data/in_memory_journal_repository.dart';
import 'package:lumen/src/features/journal/data/journal_repository_provider.dart';
import 'package:lumen/src/features/journal/domain/ai_results.dart';
import 'package:lumen/src/features/journal/domain/entry_source.dart';
import 'package:lumen/src/features/journal/domain/journal_ai_service.dart';
import 'package:lumen/src/features/journal/domain/journal_entry.dart';
import 'package:lumen/src/features/journal/domain/journal_theme.dart';
import 'package:lumen/src/features/journal/domain/related_resource.dart';
import 'package:lumen/src/features/journal/domain/voice_recorder.dart';
import 'package:lumen/src/features/journal/domain/voice_recording.dart';
import 'package:lumen/src/features/journal/data/voice_recorder_provider.dart';

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
    expect(find.byTooltip('Record voice entry'), findsOneWidget);
    expect(find.byTooltip('New text entry'), findsOneWidget);
    expect(find.text('Journal'), findsOneWidget);
    expect(find.text('Voice'), findsOneWidget);
  });

  testWidgets('navigates between top-level pages', (tester) async {
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

    await tester.tap(find.text('Voice'));
    await tester.pumpAndSettle();

    expect(find.text('Voice entry'), findsOneWidget);
    expect(find.text('Capture a voice entry'), findsOneWidget);

    await tester.tap(find.text('Journal'));
    await tester.pumpAndSettle();

    expect(find.text('Lumen'), findsOneWidget);
    expect(find.text('Welcome to Lumen'), findsOneWidget);
  });

  testWidgets('shows navigation on entry detail pages', (tester) async {
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
    expect(find.text('Journal'), findsOneWidget);
    expect(find.text('Voice'), findsOneWidget);

    await tester.tap(find.text('Journal'));
    await tester.pumpAndSettle();

    expect(find.text('Lumen'), findsOneWidget);
    expect(find.text('A difficult but honest morning'), findsOneWidget);
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
    await tester.scrollUntilVisible(
      find.text('Morning reflection prompt'),
      120,
    );
    expect(find.text('Morning reflection prompt'), findsOneWidget);
    expect(find.text('Regenerate rewrite'), findsOneWidget);
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

  testWidgets('creates a typed journal entry', (tester) async {
    final repository = InMemoryJournalRepository(seedEntries: const []);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          journalRepositoryProvider.overrideWithValue(repository),
          journalAiServiceProvider.overrideWithValue(
            const _ImmediateAiService(
              rewrittenText: 'Generated typed rewrite.',
              theme: JournalTheme(
                id: 'reflection',
                name: 'reflection',
                displayName: 'Reflection',
              ),
            ),
          ),
        ],
        child: const LumenApp(),
      ),
    );
    await tester.pumpAndSettle();

    const originalText = '  These are my exact typed words.  ';

    await tester.tap(find.byTooltip('New text entry'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Typed entry');
    await tester.enterText(find.byType(TextFormField).at(1), originalText);
    await tester.tap(find.text('Save entry'));
    await tester.pumpAndSettle();

    final entries = await repository.listEntries();

    expect(entries, hasLength(1));
    expect(entries.single.title, 'Typed entry');
    expect(entries.single.originalText, originalText);
    expect(entries.single.rewrittenText, 'Generated typed rewrite.');
    expect(entries.single.themes.single.displayName, 'Reflection');
    expect(find.text('Typed entry'), findsOneWidget);
    expect(find.text(originalText), findsOneWidget);
    expect(find.text('Generated typed rewrite.'), findsOneWidget);
  });

  testWidgets('saves a new entry when initial rewrite generation fails', (
    tester,
  ) async {
    final repository = InMemoryJournalRepository(seedEntries: const []);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          journalRepositoryProvider.overrideWithValue(repository),
          journalAiServiceProvider.overrideWithValue(const _FailingAiService()),
        ],
        child: const LumenApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('New text entry'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Fallback entry');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'Original still saves.',
    );
    await tester.tap(find.text('Save entry'));
    await tester.pumpAndSettle();

    final entries = await repository.listEntries();

    expect(entries, hasLength(1));
    expect(entries.single.title, 'Fallback entry');
    expect(entries.single.originalText, 'Original still saves.');
    expect(entries.single.rewrittenText, isEmpty);
    expect(entries.single.themes, isEmpty);
    expect(find.text('No rewrite yet.'), findsOneWidget);
  });

  testWidgets('edits a typed journal entry', (tester) async {
    final repository = InMemoryJournalRepository(seedEntries: [_sampleEntry]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [journalRepositoryProvider.overrideWithValue(repository)],
        child: const LumenApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('A difficult but honest morning'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Edit entry'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Updated title');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'Updated original text.',
    );
    await tester.tap(find.text('Save entry'));
    await tester.pumpAndSettle();

    final entry = await repository.getEntry('entry-1');

    expect(entry?.title, 'Updated title');
    expect(entry?.originalText, 'Updated original text.');
    expect(find.text('Updated title'), findsOneWidget);
    expect(find.text('Updated original text.'), findsWidgets);
  });

  testWidgets('regenerates rewrite and themes when edited text changes', (
    tester,
  ) async {
    final repository = InMemoryJournalRepository(seedEntries: [_sampleEntry]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          journalRepositoryProvider.overrideWithValue(repository),
          journalAiServiceProvider.overrideWithValue(
            _ImmediateAiService(
              rewrittenText: 'Updated generated rewrite.',
              theme: const JournalTheme(
                id: 'stress',
                name: 'stress',
                displayName: 'Stress',
              ),
            ),
          ),
        ],
        child: const LumenApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('A difficult but honest morning'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Edit entry'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(1), 'Changed text.');
    await tester.tap(find.text('Save entry'));
    await tester.pumpAndSettle();

    final entry = await repository.getEntry('entry-1');

    expect(entry?.originalText, 'Changed text.');
    expect(entry?.rewrittenText, 'Updated generated rewrite.');
    expect(entry?.themes.single.displayName, 'Stress');
    expect(find.text('Updated generated rewrite.'), findsOneWidget);
    expect(find.text('Stress'), findsOneWidget);
  });

  testWidgets('deletes a journal entry', (tester) async {
    final repository = InMemoryJournalRepository(seedEntries: [_sampleEntry]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [journalRepositoryProvider.overrideWithValue(repository)],
        child: const LumenApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('A difficult but honest morning'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Delete entry'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(await repository.listEntries(), isEmpty);
    expect(find.text('No journal entries yet'), findsOneWidget);
  });

  testWidgets('generates mock rewrite and themes for an entry', (tester) async {
    final repository = InMemoryJournalRepository(
      seedEntries: [_unprocessedEntry],
    );
    final aiService = _ControlledAiService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          journalRepositoryProvider.overrideWithValue(repository),
          journalAiServiceProvider.overrideWithValue(aiService),
        ],
        child: const LumenApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('A raw work note'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Regenerate rewrite'));
    await tester.pump();

    expect(find.text('Generating rewrite'), findsOneWidget);

    aiService.completeRewrite();
    await tester.pumpAndSettle();

    final entry = await repository.getEntry('entry-2');

    expect(entry?.rewrittenText, 'A clearer mock rewrite.');
    expect(entry?.themes.single.displayName, 'Work');
    expect(find.text('A clearer mock rewrite.'), findsOneWidget);
    expect(find.text('Work'), findsOneWidget);
  });

  testWidgets('shows an error when mock rewrite generation fails', (
    tester,
  ) async {
    final repository = InMemoryJournalRepository(
      seedEntries: [_unprocessedEntry],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          journalRepositoryProvider.overrideWithValue(repository),
          journalAiServiceProvider.overrideWithValue(const _FailingAiService()),
        ],
        child: const LumenApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('A raw work note'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Regenerate rewrite'));
    await tester.pumpAndSettle();

    final entry = await repository.getEntry('entry-2');

    expect(entry?.rewrittenText, isEmpty);
    expect(
      find.text('Unable to generate a rewrite right now.'),
      findsOneWidget,
    );
  });

  testWidgets('starts and stops a voice recording', (tester) async {
    final recorder = _FakeVoiceRecorder();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          journalRepositoryProvider.overrideWithValue(
            InMemoryJournalRepository(seedEntries: const []),
          ),
          voiceRecorderProvider.overrideWithValue(recorder),
        ],
        child: const LumenApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Record voice entry'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start recording'));
    await tester.pumpAndSettle();

    expect(recorder.didStart, isTrue);
    expect(find.text('Recording'), findsOneWidget);

    await tester.tap(find.text('Stop recording'));
    await tester.pumpAndSettle();

    expect(recorder.didStop, isTrue);
    expect(find.text('Recording captured'), findsOneWidget);
    expect(find.text('Temporary audio saved'), findsOneWidget);
    expect(find.text('memory://recording.m4a'), findsOneWidget);
  });

  testWidgets('handles denied microphone permission', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          journalRepositoryProvider.overrideWithValue(
            InMemoryJournalRepository(seedEntries: const []),
          ),
          voiceRecorderProvider.overrideWithValue(
            _FakeVoiceRecorder(hasPermissionValue: false),
          ),
        ],
        child: const LumenApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Record voice entry'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start recording'));
    await tester.pumpAndSettle();

    expect(find.text('Microphone access is needed'), findsOneWidget);
    expect(
      find.text(
        'Allow microphone access in your browser or device settings to record journal entries.',
      ),
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

final _unprocessedEntry = JournalEntry(
  id: 'entry-2',
  createdAt: DateTime.utc(2026, 5, 8, 16),
  updatedAt: DateTime.utc(2026, 5, 8, 16),
  source: EntrySource.text,
  originalText: 'I had a rushed work meeting.',
  rewrittenText: '',
  themes: const [],
  resources: const [],
  title: 'A raw work note',
);

class _ControlledAiService implements JournalAiService {
  final _rewrite = Completer<RewriteResult>();

  void completeRewrite() {
    _rewrite.complete(
      const RewriteResult(
        rewrittenText: 'A clearer mock rewrite.',
        title: 'Generated title',
        summary: 'Generated summary',
      ),
    );
  }

  @override
  Future<ThemeDetectionResult> detectThemes({required String text}) async {
    return const ThemeDetectionResult(
      themes: [JournalTheme(id: 'work', name: 'work', displayName: 'Work')],
    );
  }

  @override
  Future<RewriteResult> rewriteEntry({required String originalText}) async {
    return _rewrite.future;
  }
}

class _ImmediateAiService implements JournalAiService {
  const _ImmediateAiService({required this.rewrittenText, required this.theme});

  final String rewrittenText;
  final JournalTheme theme;

  @override
  Future<ThemeDetectionResult> detectThemes({required String text}) async {
    return ThemeDetectionResult(themes: [theme]);
  }

  @override
  Future<RewriteResult> rewriteEntry({required String originalText}) async {
    return RewriteResult(
      rewrittenText: rewrittenText,
      title: 'Updated generated title',
      summary: 'Updated generated summary',
    );
  }
}

class _FailingAiService implements JournalAiService {
  const _FailingAiService();

  @override
  Future<ThemeDetectionResult> detectThemes({required String text}) async {
    return const ThemeDetectionResult(themes: []);
  }

  @override
  Future<RewriteResult> rewriteEntry({required String originalText}) async {
    throw StateError('AI unavailable');
  }
}

class _FakeVoiceRecorder implements VoiceRecorder {
  _FakeVoiceRecorder({this.hasPermissionValue = true});

  final bool hasPermissionValue;
  bool didStart = false;
  bool didStop = false;
  DateTime? _startedAt;

  @override
  Future<void> dispose() async {}

  @override
  Future<bool> hasPermission() async {
    return hasPermissionValue;
  }

  @override
  Future<void> start({required DateTime startedAt}) async {
    didStart = true;
    _startedAt = startedAt;
  }

  @override
  Future<VoiceRecording?> stop({required DateTime stoppedAt}) async {
    didStop = true;

    return VoiceRecording(
      uri: 'memory://recording.m4a',
      startedAt: _startedAt ?? stoppedAt,
      stoppedAt: stoppedAt,
    );
  }
}
