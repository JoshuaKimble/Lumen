import 'ai_results.dart';
import 'rewrite_personalization.dart';

enum JournalRewriteSource {
  unspecified,
  typedCreate,
  typedEditSave,
  regenerate,
  voiceSave,
}

abstract interface class JournalAiService {
  Future<RewriteResult> rewriteEntry({
    required String originalText,
    JournalRewriteSource source = JournalRewriteSource.unspecified,
    RewritePersonalization? personalization,
  });

  Future<ThemeDetectionResult> detectThemes({required String text});
}
