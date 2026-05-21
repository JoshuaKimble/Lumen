import '../domain/ai_results.dart';
import '../domain/journal_ai_service.dart';
import '../domain/rewrite_personalization.dart';

class ProfileAwareJournalAiService implements JournalAiService {
  const ProfileAwareJournalAiService({
    required this.delegate,
    required this.defaultPersonalization,
  });

  final JournalAiService delegate;
  final RewritePersonalization defaultPersonalization;

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
}
