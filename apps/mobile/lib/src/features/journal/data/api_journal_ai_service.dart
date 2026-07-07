import 'package:lumen/src/api/generated/lumen_api_client.dart';

import '../domain/ai_results.dart';
import '../domain/journal_ai_service.dart';
import '../domain/journal_theme.dart';
import '../domain/rewrite_personalization.dart';
import '../domain/study_guide.dart';

class ApiJournalAiService implements JournalAiService {
  const ApiJournalAiService({required this.client});

  final LumenApiClient client;

  @override
  Future<EntrySummaryResult> summarizeEntry({
    required String originalText,
  }) async {
    final response = await client.summarizeEntry(
      SummarizeEntryRequest(originalText: originalText),
    );

    return EntrySummaryResult(title: response.title, summary: response.summary);
  }

  @override
  Future<RewriteResult> rewriteEntry({
    required String originalText,
    JournalRewriteSource source = JournalRewriteSource.unspecified,
    RewritePersonalization? personalization,
  }) async {
    final response = await client.rewriteEntry(
      RewriteEntryRequest(
        originalText: originalText,
        personalization: ApiRewritePersonalization.fromJson(
          (personalization ?? RewritePersonalization.defaults).toApiJson(),
        ),
      ),
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

  @override
  Future<StudyGuide> generateStudyGuide({
    required String entryId,
    required String originalText,
    required List<JournalTheme> themes,
    required String providerKey,
  }) async {
    final response = await client.generateStudyGuide(
      GenerateStudyGuideRequest(
        entryId: entryId,
        originalText: originalText,
        providerKey: providerKey,
        themeIds: themes.map((theme) => theme.id).toList(growable: false),
      ),
    );
    return StudyGuide(
      id: response.guideId,
      entryId: response.entryId,
      providerKey: response.providerKey,
      generatedAt: response.generatedAt,
      overview: response.overview,
      previewText: response.previewText,
      items: response.items
          .map(
            (item) => StudyGuideItem(
              id: item.id,
              kind: item.kind,
              title: item.title,
              contextLine: item.contextLine,
              position: item.position,
              destination: StudyGuideDestination(
                providerKey: item.destination.providerKey,
                contentType: item.destination.contentType,
                reference: item.destination.reference,
                url: item.destination.url == null
                    ? null
                    : Uri.parse(item.destination.url!),
                precision: StudyGuideDestinationPrecision.values.byName(
                  item.destination.precision,
                ),
              ),
              focusText: item.focusText,
              quote: item.quote,
              author: item.author,
              publishedContext: item.publishedContext,
            ),
          )
          .toList(growable: false),
      reflectionPrompt: StudyGuidePrompt(text: response.reflectionPrompt.text),
    );
  }
}
