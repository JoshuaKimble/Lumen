import 'ai_results.dart';

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
  });

  Future<ThemeDetectionResult> detectThemes({required String text});
}
