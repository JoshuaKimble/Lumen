import 'ai_results.dart';

abstract interface class JournalAiService {
  Future<RewriteResult> rewriteEntry({required String originalText});

  Future<ThemeDetectionResult> detectThemes({required String text});
}
