import 'package:lumen/src/api/generated/lumen_api_client.dart';

import '../domain/ai_results.dart';
import '../domain/journal_ai_service.dart';
import '../domain/journal_theme.dart';

class ApiJournalAiService implements JournalAiService {
  const ApiJournalAiService({required this.client});

  final LumenApiClient client;

  @override
  Future<RewriteResult> rewriteEntry({required String originalText}) async {
    final response = await client.rewriteEntry(
      RewriteEntryRequest(originalText: originalText),
    );

    return RewriteResult(
      rewrittenText: response.rewrittenText,
      title: response.title,
      summary: response.summary,
    );
  }

  @override
  Future<ThemeDetectionResult> detectThemes({required String text}) async {
    final response = await client.detectEntryThemes(
      DetectThemesRequest(text: text),
    );

    return ThemeDetectionResult(
      themes: response.themes
          .map(
            (theme) => JournalTheme(
              id: theme.id,
              name: theme.name,
              displayName: theme.displayName,
              weight: theme.weight,
            ),
          )
          .toList(growable: false),
    );
  }
}
