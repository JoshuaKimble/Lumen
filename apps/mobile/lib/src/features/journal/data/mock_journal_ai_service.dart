import '../domain/ai_results.dart';
import '../domain/journal_ai_service.dart';
import '../domain/journal_theme.dart';
import '../domain/rewrite_personalization.dart';
import '../domain/study_guide.dart';

class MockJournalAiService implements JournalAiService {
  const MockJournalAiService();

  @override
  Future<EntrySummaryResult> summarizeEntry({
    required String originalText,
  }) async {
    final normalizedText = originalText.trim();

    return EntrySummaryResult(
      title: _titleFor(normalizedText),
      summary: _summaryFor(normalizedText),
    );
  }

  @override
  Future<RewriteResult> rewriteEntry({
    required String originalText,
    JournalRewriteSource source = JournalRewriteSource.unspecified,
    RewritePersonalization? personalization,
  }) async {
    final normalizedText = originalText.trim();
    final summary = _summaryFor(normalizedText);

    return RewriteResult(
      rewrittenText: _rewrite(normalizedText, source),
      title: _titleFor(normalizedText),
      summary: summary,
    );
  }

  @override
  Future<ThemeDetectionResult> detectThemes({required String text}) async {
    final normalizedText = text.toLowerCase();
    final themes = <JournalTheme>[];

    for (final candidate in _themeCandidates) {
      if (candidate.matches(normalizedText)) {
        themes.add(candidate.theme);
      }
    }

    if (themes.isEmpty) {
      themes.add(
        const JournalTheme(
          id: 'reflection',
          name: 'reflection',
          displayName: 'Reflection',
        ),
      );
    }

    return ThemeDetectionResult(themes: themes);
  }

  @override
  Future<StudyGuide> generateStudyGuide({
    required String entryId,
    required String originalText,
    required List<JournalTheme> themes,
    required String providerKey,
  }) async {
    final normalizedText = originalText.trim();
    final guideThemes = normalizedText.isEmpty || themes.isEmpty
        ? const [
            JournalTheme(
              id: 'reflection',
              name: 'reflection',
              displayName: 'Reflection',
            ),
          ]
        : themes;
    final items = <StudyGuideItem>[];
    var position = 0;

    for (final theme in guideThemes) {
      final candidate = _guideCandidates[theme.id.toLowerCase()];
      if (candidate == null) {
        continue;
      }

      if (items.any((item) => item.id == candidate.id)) {
        continue;
      }

      items.add(
        candidate.toGuideItem(theme.displayName, providerKey, position),
      );
      position += 1;
      if (items.length >= 3) {
        break;
      }
    }

    if (items.isEmpty) {
      items.add(_fallbackCandidate.toGuideItem('Reflection', providerKey, 0));
    }

    final previewText = items.length == 1
        ? items.single.title
        : '${items.first.title} and ${items.length - 1} more resource${items.length - 1 == 1 ? '' : 's'}';

    return StudyGuide(
      id: 'study-guide-$entryId',
      entryId: entryId,
      providerKey: providerKey,
      generatedAt: DateTime.utc(2026, 6, 11, 12),
      overview: 'A gospel study guide built from this reflection.',
      previewText: previewText,
      items: items,
      reflectionPrompt: StudyGuidePrompt(
        text: _reflectionPromptFor(guideThemes),
      ),
    );
  }

  String _rewrite(String text, JournalRewriteSource source) {
    if (text.isEmpty) {
      return '';
    }

    return '[Flutter mock: ${source.mockLabel}] I am noticing this more clearly: $text';
  }

  String _titleFor(String text) {
    if (text.isEmpty) {
      return 'Untitled entry';
    }

    final firstSentence = text.split(RegExp(r'[.!?]')).first.trim();
    final words = firstSentence.split(RegExp(r'\s+')).take(6).join(' ');

    return words.isEmpty ? 'Untitled entry' : words;
  }

  String _summaryFor(String text) {
    if (text.isEmpty) {
      return 'A short reflection.';
    }

    final words = text.split(RegExp(r'\s+'));
    final summaryWords = words.take(14).join(' ');

    return words.length > 14 ? '$summaryWords...' : summaryWords;
  }
}

String _reflectionPromptFor(List<JournalTheme> themes) {
  if (themes.isEmpty) {
    return 'As you study these resources, what feels most worth carrying into the rest of your day?';
  }

  final themeNames = themes
      .take(2)
      .map((theme) => theme.displayName.toLowerCase())
      .join(' and ');
  return 'As you study these resources, what do you notice about $themeNames in your life right now?';
}

class _GuideCandidate {
  const _GuideCandidate({
    required this.id,
    required this.kind,
    required this.title,
    required this.contextLine,
    required this.reference,
    required this.url,
    required this.precision,
    this.focusText,
    this.quote,
    this.author,
    this.publishedContext,
  });

  final String id;
  final String kind;
  final String title;
  final String contextLine;
  final String reference;
  final Uri url;
  final StudyGuideDestinationPrecision precision;
  final String? focusText;
  final String? quote;
  final String? author;
  final String? publishedContext;

  StudyGuideItem toGuideItem(
    String themeName,
    String providerKey,
    int position,
  ) {
    return StudyGuideItem(
      id: id,
      kind: kind,
      title: title,
      contextLine:
          '$contextLine ${themeName.isEmpty ? '' : 'It connects to $themeName in your reflection.'}'
              .trim(),
      position: position,
      destination: StudyGuideDestination(
        providerKey: providerKey,
        contentType: kind,
        reference: reference,
        url: url,
        precision: precision,
      ),
      focusText: focusText,
      quote: quote,
      author: author,
      publishedContext: publishedContext,
    );
  }
}

final Map<String, _GuideCandidate> _guideCandidates = {
  'faith': _GuideCandidate(
    id: 'faith-scripture-psalm-46-10',
    kind: 'scripture',
    title: 'Psalm 46:10',
    contextLine: 'A quiet anchor when you need steadiness.',
    reference: 'Psalm 46:10',
    url: Uri.parse(
      'https://www.churchofjesuschrist.org/study/scriptures/ot/ps/46?lang=eng',
    ),
    precision: StudyGuideDestinationPrecision.chapter,
    focusText: 'Focus on the chapter’s reminder to be still and trust God.',
  ),
  'stress': _GuideCandidate(
    id: 'stress-scripture-alma-37-6',
    kind: 'scripture',
    title: 'Alma 37:6',
    contextLine: 'A reminder that small, faithful acts matter.',
    reference: 'Alma 37:6',
    url: Uri.parse(
      'https://www.churchofjesuschrist.org/study/scriptures/bofm/alma/37?lang=eng',
    ),
    precision: StudyGuideDestinationPrecision.chapter,
    focusText:
        'Notice how small and simple things can become spiritually meaningful.',
  ),
  'work': _GuideCandidate(
    id: 'work-talk-nourish-roots',
    kind: 'conference_talk',
    title: 'Nourish the Roots, and the Branches Will Grow',
    contextLine: 'A conference talk about steady spiritual growth.',
    quote: 'Keep nourishing the roots of faith.',
    reference: 'General Conference, October 2024',
    url: Uri.parse(
      'https://www.churchofjesuschrist.org/study/general-conference/2024/10/51uchtdorf?lang=eng',
    ),
    precision: StudyGuideDestinationPrecision.document,
    author: 'Dieter F. Uchtdorf',
    publishedContext: 'General Conference, October 2024',
  ),
  'reflection': _GuideCandidate(
    id: 'reflection-scripture-3-nephi-1',
    kind: 'scripture',
    title: '3 Nephi 1',
    contextLine:
        'A chapter that reminds you to hold to faith when the path is uncertain.',
    reference: '3 Nephi 1:6-12',
    url: Uri.parse(
      'https://www.churchofjesuschrist.org/study/scriptures/bofm/3-ne/1?lang=eng',
    ),
    precision: StudyGuideDestinationPrecision.chapter,
    focusText:
        'Read verses 6-12 for the way faith holds steady under pressure.',
  ),
};

final _fallbackCandidate = _GuideCandidate(
  id: 'reflection-scripture-psalm-46-10',
  kind: 'scripture',
  title: 'Psalm 46:10',
  contextLine: 'A quiet anchor when you need steadiness.',
  reference: 'Psalm 46:10',
  url: Uri.parse(
    'https://www.churchofjesuschrist.org/study/scriptures/ot/ps/46?lang=eng',
  ),
  precision: StudyGuideDestinationPrecision.chapter,
  focusText: 'Focus on the chapter’s reminder to be still and trust God.',
);

extension on JournalRewriteSource {
  String get mockLabel {
    return switch (this) {
      JournalRewriteSource.typedCreate => 'typed create',
      JournalRewriteSource.typedEditSave => 'typed edit save',
      JournalRewriteSource.regenerate => 'regenerate',
      JournalRewriteSource.voiceSave => 'voice save',
      JournalRewriteSource.unspecified => 'unspecified flow',
    };
  }
}

class _MockThemeCandidate {
  const _MockThemeCandidate({required this.theme, required this.keywords});

  final JournalTheme theme;
  final List<String> keywords;

  bool matches(String text) {
    return keywords.any(text.contains);
  }
}

const _themeCandidates = [
  _MockThemeCandidate(
    theme: JournalTheme(id: 'family', name: 'family', displayName: 'Family'),
    keywords: ['family', 'parent', 'child', 'kid', 'spouse', 'wife', 'husband'],
  ),
  _MockThemeCandidate(
    theme: JournalTheme(id: 'work', name: 'work', displayName: 'Work'),
    keywords: ['work', 'job', 'meeting', 'project', 'deadline', 'career'],
  ),
  _MockThemeCandidate(
    theme: JournalTheme(id: 'stress', name: 'stress', displayName: 'Stress'),
    keywords: ['stress', 'tense', 'overwhelmed', 'rushed', 'anxious'],
  ),
  _MockThemeCandidate(
    theme: JournalTheme(
      id: 'gratitude',
      name: 'gratitude',
      displayName: 'Gratitude',
    ),
    keywords: ['grateful', 'thankful', 'gratitude', 'appreciate'],
  ),
  _MockThemeCandidate(
    theme: JournalTheme(id: 'faith', name: 'faith', displayName: 'Faith'),
    keywords: ['faith', 'pray', 'prayer', 'god', 'scripture'],
  ),
  _MockThemeCandidate(
    theme: JournalTheme(id: 'health', name: 'health', displayName: 'Health'),
    keywords: ['health', 'sleep', 'exercise', 'walk', 'doctor'],
  ),
];
