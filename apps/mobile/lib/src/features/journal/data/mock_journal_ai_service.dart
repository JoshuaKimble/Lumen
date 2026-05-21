import '../domain/ai_results.dart';
import '../domain/journal_ai_service.dart';
import '../domain/journal_theme.dart';
import '../domain/rewrite_personalization.dart';

class MockJournalAiService implements JournalAiService {
  const MockJournalAiService();

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
