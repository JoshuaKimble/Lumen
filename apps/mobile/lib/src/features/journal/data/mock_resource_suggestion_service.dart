import '../domain/related_resource.dart';
import '../domain/resource_suggestion_service.dart';

class MockResourceSuggestionService implements ResourceSuggestionService {
  const MockResourceSuggestionService();

  @override
  Future<List<RelatedResource>> suggest({
    required String text,
    List<String> themeIds = const [],
  }) async {
    final normalizedText = text.toLowerCase();
    final matchedIds = <String>{...themeIds};

    for (final candidate in _themeCandidates) {
      if (candidate.keywords.any(normalizedText.contains)) {
        matchedIds.add(candidate.id);
      }
    }

    if (matchedIds.isEmpty) {
      matchedIds.add('reflection');
    }

    final suggestions =
        matchedIds
            .expand((id) => _resourcesByTheme[id] ?? const <RelatedResource>[])
            .where((resource) => resource.confidence >= 0.65)
            .toList(growable: false)
          ..sort((a, b) => b.confidence.compareTo(a.confidence));

    return suggestions.take(5).toList(growable: false);
  }

  @override
  Future<void> submitFeedback({
    required String resourceId,
    required ResourceFeedbackAction action,
    String? entryId,
    String? themeId,
  }) async {}
}

class _ThemeCandidate {
  const _ThemeCandidate({required this.id, required this.keywords});

  final String id;
  final List<String> keywords;
}

const _themeCandidates = [
  _ThemeCandidate(
    id: 'work',
    keywords: ['work', 'deadline', 'meeting', 'project'],
  ),
  _ThemeCandidate(
    id: 'stress',
    keywords: ['stress', 'tense', 'anxious', 'overwhelmed'],
  ),
  _ThemeCandidate(
    id: 'family',
    keywords: ['family', 'spouse', 'parent', 'child'],
  ),
  _ThemeCandidate(
    id: 'faith',
    keywords: ['faith', 'scripture', 'pray', 'prayer'],
  ),
];

final _resourcesByTheme = {
  'work': [
    RelatedResource(
      id: 'work-prompt-review-boundaries',
      title: 'What boundary would reduce your stress this week?',
      type: 'reflection_prompt',
      sourceType: 'ai_mapped',
      matchReason: 'Detected work-related pressure and deadline language.',
      confidence: 0.91,
      themeId: 'work',
      description:
          'Name one boundary you can hold this week and one way to communicate it clearly.',
    ),
  ],
  'stress': [
    RelatedResource(
      id: 'stress-prompt-body-signal',
      title: 'Where did stress show up in your body today?',
      type: 'reflection_prompt',
      sourceType: 'ai_mapped',
      matchReason: 'Detected stress, tension, or anxiety keywords.',
      confidence: 0.88,
      themeId: 'stress',
      description:
          'Describe what you felt physically and what was happening right before it.',
    ),
  ],
  'faith': [
    RelatedResource(
      id: 'faith-scripture-psalm-46-10',
      title: 'Psalm 46:10',
      type: 'scripture',
      sourceType: 'curated',
      matchReason: 'Matches faith-oriented reflection language.',
      confidence: 0.78,
      themeId: 'faith',
      scriptureReference: 'Psalm 46:10',
      description: 'Be still, and know that I am God.',
      url: Uri.parse('https://www.churchofjesuschrist.org/study/scriptures'),
    ),
    RelatedResource(
      id: 'faith-talk-endure-well',
      title: 'General conference: Endure Well',
      type: 'talk_or_article',
      sourceType: 'curated',
      matchReason: 'Supports reflective faith-centered review.',
      confidence: 0.72,
      themeId: 'faith',
      description: 'A conference-style talk for patient, steady discipleship.',
      url: Uri.parse(
        'https://www.churchofjesuschrist.org/study/general-conference',
      ),
    ),
  ],
  'reflection': [
    RelatedResource(
      id: 'reflection-prompt-next-honest-step',
      title: 'What is your next honest step?',
      type: 'reflection_prompt',
      sourceType: 'curated',
      matchReason: 'Fallback reflection prompt when themes are unclear.',
      confidence: 0.75,
      themeId: 'reflection',
      description:
          'Write one sentence about the most honest next step you can take today.',
    ),
  ],
};
