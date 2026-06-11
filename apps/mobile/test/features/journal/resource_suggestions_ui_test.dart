import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumen/src/app/lumen_app.dart';
import 'package:lumen/src/features/journal/data/in_memory_journal_repository.dart';
import 'package:lumen/src/features/journal/data/journal_repository_provider.dart';
import 'package:lumen/src/features/journal/data/resource_feedback_repository.dart';
import 'package:lumen/src/features/journal/data/resource_link_opener.dart';
import 'package:lumen/src/features/journal/data/resource_suggestion_service_provider.dart';
import 'package:lumen/src/features/journal/domain/entry_source.dart';
import 'package:lumen/src/features/journal/domain/journal_entry.dart';
import 'package:lumen/src/features/journal/domain/journal_theme.dart';
import 'package:lumen/src/features/journal/domain/related_resource.dart';
import 'package:lumen/src/features/journal/domain/resource_suggestion_service.dart';
import 'package:lumen/src/features/journal/presentation/resource_suggestions_provider.dart';
import 'package:lumen/src/features/settings/data/scripture_app_preference_provider.dart';
import 'package:lumen/src/features/settings/domain/scripture_app_preference.dart';
import 'package:lumen/src/features/settings/domain/scripture_app_preference_repository.dart';

void main() {
  testWidgets('renders suggestions and dismiss hides them', (tester) async {
    tester.view.physicalSize = const Size(1200, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = InMemoryJournalRepository(
      seedEntries: [
        JournalEntry(
          id: 'entry-1',
          createdAt: DateTime.utc(2026, 5, 17),
          updatedAt: DateTime.utc(2026, 5, 17),
          source: EntrySource.text,
          originalText: 'Work was intense today.',
          rewrittenText: 'Work felt intense today.',
          themes: const [
            JournalTheme(id: 'work', name: 'work', displayName: 'Work'),
          ],
          resources: const [],
          title: 'Work entry',
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          journalRepositoryProvider.overrideWithValue(repository),
          resourceSuggestionServiceProvider.overrideWithValue(
            const _FakeSuggestionService(),
          ),
          resourceFeedbackRepositoryProvider.overrideWithValue(
            _InMemoryFeedbackRepository(),
          ),
        ],
        child: const LumenApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Work entry'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('What boundary would reduce your stress this week?'),
      120,
    );

    expect(
      find.text('What boundary would reduce your stress this week?'),
      findsOneWidget,
    );
    expect(find.text('Open'), findsNothing);

    await tester.tap(find.text('Dismiss').first);
    await tester.pumpAndSettle();

    expect(
      find.text('What boundary would reduce your stress this week?'),
      findsNothing,
    );
  });

  testWidgets('opens scripture links using selected scripture preference', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final opener = _FakeResourceLinkOpener();
    final scripturePreferenceRepository =
        _InMemoryScriptureAppPreferenceRepository(
          initial: ScriptureAppPreference.gospelLibrary,
        );
    final repository = InMemoryJournalRepository(
      seedEntries: [
        JournalEntry(
          id: 'entry-2',
          createdAt: DateTime.utc(2026, 5, 17),
          updatedAt: DateTime.utc(2026, 5, 17),
          source: EntrySource.text,
          originalText: 'I read scripture before bed.',
          rewrittenText: 'I made time for scripture before bed.',
          themes: const [
            JournalTheme(id: 'faith', name: 'faith', displayName: 'Faith'),
          ],
          resources: const [],
          title: 'Faith entry',
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          journalRepositoryProvider.overrideWithValue(repository),
          resourceSuggestionServiceProvider.overrideWithValue(
            const _ScriptureSuggestionService(),
          ),
          resourceFeedbackRepositoryProvider.overrideWithValue(
            _InMemoryFeedbackRepository(),
          ),
          scriptureAppPreferenceRepositoryProvider.overrideWithValue(
            scripturePreferenceRepository,
          ),
          resourceLinkOpenerProvider.overrideWithValue(opener),
        ],
        child: const LumenApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Faith entry'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Psalm 46:10'), 120);
    await tester.scrollUntilVisible(find.text('Open').first, 120);
    await tester.tap(find.text('Open').first);
    await tester.pumpAndSettle();

    expect(opener.openedUrls, hasLength(1));
    expect(opener.openedUrls.single.host, 'www.churchofjesuschrist.org');
  });
}

class _FakeSuggestionService implements ResourceSuggestionService {
  const _FakeSuggestionService();

  @override
  Future<List<RelatedResource>> suggest({
    required String text,
    List<String> themeIds = const [],
    ScriptureAppPreference preference = ScriptureAppPreference.none,
  }) async {
    return const [
      RelatedResource(
        id: 'work-prompt-review-boundaries',
        title: 'What boundary would reduce your stress this week?',
        type: 'reflection_prompt',
        sourceType: 'ai_mapped',
        matchReason: 'Detected work-related pressure.',
        confidence: 0.91,
      ),
    ];
  }

  @override
  Future<void> submitFeedback({
    required String resourceId,
    required ResourceFeedbackAction action,
    String? entryId,
    String? themeId,
  }) async {}
}

class _ScriptureSuggestionService implements ResourceSuggestionService {
  const _ScriptureSuggestionService();

  @override
  Future<List<RelatedResource>> suggest({
    required String text,
    List<String> themeIds = const [],
    ScriptureAppPreference preference = ScriptureAppPreference.none,
  }) async {
    return const [
      RelatedResource(
        id: 'faith-scripture-psalm-46-10',
        title: 'Psalm 46:10',
        scriptureReference: 'Psalm 46:10',
        type: 'scripture',
        sourceType: 'curated',
        matchReason: 'faith match',
        confidence: 0.82,
      ),
    ];
  }

  @override
  Future<void> submitFeedback({
    required String resourceId,
    required ResourceFeedbackAction action,
    String? entryId,
    String? themeId,
  }) async {}
}

class _InMemoryFeedbackRepository implements ResourceFeedbackRepository {
  final Map<String, ResourceFeedbackAction> _values = {};

  @override
  Future<Map<String, ResourceFeedbackAction>> loadAll() async {
    return Map<String, ResourceFeedbackAction>.from(_values);
  }

  @override
  Future<void> save({
    required String resourceId,
    required ResourceFeedbackAction action,
  }) async {
    _values[resourceId] = action;
  }
}

class _InMemoryScriptureAppPreferenceRepository
    implements ScriptureAppPreferenceRepository {
  _InMemoryScriptureAppPreferenceRepository({required this.initial});

  final ScriptureAppPreference initial;
  late ScriptureAppPreference _value = initial;

  @override
  Future<ScriptureAppPreference> load() async {
    return _value;
  }

  @override
  Future<void> save(ScriptureAppPreference preference) async {
    _value = preference;
  }
}

class _FakeResourceLinkOpener implements ResourceLinkOpener {
  final List<Uri> openedUrls = [];

  @override
  Future<bool> open(Uri url) async {
    openedUrls.add(url);
    return true;
  }
}
