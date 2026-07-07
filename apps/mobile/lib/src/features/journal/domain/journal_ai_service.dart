import 'ai_results.dart';
import 'journal_theme.dart';
import 'rewrite_personalization.dart';
import 'study_guide.dart';

enum JournalRewriteSource {
  unspecified,
  typedCreate,
  typedEditSave,
  regenerate,
  voiceSave,
}

abstract interface class JournalAiService {
  Future<EntrySummaryResult> summarizeEntry({required String originalText});

  Future<RewriteResult> rewriteEntry({
    required String originalText,
    JournalRewriteSource source = JournalRewriteSource.unspecified,
    RewritePersonalization? personalization,
  });

  Future<ThemeDetectionResult> detectThemes({required String text});

  Future<StudyGuide> generateStudyGuide({
    required String entryId,
    required String originalText,
    required List<JournalTheme> themes,
    required String providerKey,
  });
}
