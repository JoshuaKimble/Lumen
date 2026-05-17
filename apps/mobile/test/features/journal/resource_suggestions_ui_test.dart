import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumen/src/app/lumen_app.dart';
import 'package:lumen/src/features/journal/data/in_memory_journal_repository.dart';
import 'package:lumen/src/features/journal/data/journal_repository_provider.dart';
import 'package:lumen/src/features/journal/data/resource_feedback_repository.dart';
import 'package:lumen/src/features/journal/data/resource_suggestion_service_provider.dart';
import 'package:lumen/src/features/journal/domain/entry_source.dart';
import 'package:lumen/src/features/journal/domain/journal_entry.dart';
import 'package:lumen/src/features/journal/domain/journal_theme.dart';
import 'package:lumen/src/features/journal/domain/related_resource.dart';
import 'package:lumen/src/features/journal/domain/resource_suggestion_service.dart';
import 'package:lumen/src/features/journal/presentation/resource_suggestions_provider.dart';

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

    await tester.tap(find.text('Dismiss').first);
    await tester.pumpAndSettle();

    expect(
      find.text('What boundary would reduce your stress this week?'),
      findsNothing,
    );
  });
}

class _FakeSuggestionService implements ResourceSuggestionService {
  const _FakeSuggestionService();

  @override
  Future<List<RelatedResource>> suggest({
    required String text,
    List<String> themeIds = const [],
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
