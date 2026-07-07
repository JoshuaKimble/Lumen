import '../domain/ai_results.dart';
import '../domain/journal_ai_service.dart';
import '../domain/journal_theme.dart';
import '../domain/rewrite_personalization.dart';
import '../domain/study_guide.dart';

class ProfileAwareJournalAiService implements JournalAiService {
  const ProfileAwareJournalAiService({
    required this.delegate,
    required this.defaultPersonalization,
  });

  final JournalAiService delegate;
  final RewritePersonalization defaultPersonalization;

  @override
  Future<EntrySummaryResult> summarizeEntry({required String originalText}) {
    return delegate.summarizeEntry(originalText: originalText);
  }

  @override
  Future<RewriteResult> rewriteEntry({
    required String originalText,
    JournalRewriteSource source = JournalRewriteSource.unspecified,
    RewritePersonalization? personalization,
  }) {
    return delegate.rewriteEntry(
      originalText: originalText,
      source: source,
      personalization: personalization ?? defaultPersonalization,
    );
  }

  @override
  Future<ThemeDetectionResult> detectThemes({required String text}) {
    return delegate.detectThemes(text: text);
  }

  @override
  Future<StudyGuide> generateStudyGuide({
    required String entryId,
    required String originalText,
    required List<JournalTheme> themes,
    required String providerKey,
  }) {
    return delegate.generateStudyGuide(
      entryId: entryId,
      originalText: originalText,
      themes: themes,
      providerKey: providerKey,
    );
  }
}
