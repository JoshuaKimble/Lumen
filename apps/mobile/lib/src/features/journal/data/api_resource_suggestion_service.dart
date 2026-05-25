import 'package:lumen/src/api/generated/lumen_api_client.dart';

import '../../settings/domain/scripture_app_preference.dart';
import '../domain/related_resource.dart';
import '../domain/resource_suggestion_service.dart';
import 'scripture_resource_link_resolver.dart';

class ApiResourceSuggestionService implements ResourceSuggestionService {
  const ApiResourceSuggestionService({
    required this.client,
    this.scriptureLinkResolver = const ScriptureResourceLinkResolver(),
  });

  final LumenApiClient client;
  final ScriptureResourceLinkResolver scriptureLinkResolver;

  @override
  Future<List<RelatedResource>> suggest({
    required String text,
    List<String> themeIds = const [],
    ScriptureAppPreference preference = ScriptureAppPreference.none,
  }) async {
    final response = await client.suggestResources(
      SuggestResourcesRequest(
        text: text,
        themeIds: themeIds.isEmpty ? null : themeIds,
      ),
    );

    return response.suggestions
        .map(
          (suggestion) => RelatedResource(
            id: suggestion.id,
            title: suggestion.title,
            type: suggestion.type,
            sourceType: suggestion.sourceType,
            matchReason: suggestion.matchReason,
            confidence: suggestion.confidence,
            description: suggestion.description,
            url: suggestion.url == null ? null : Uri.parse(suggestion.url!),
            entryId: suggestion.entryId,
            themeId: suggestion.themeId,
          ),
        )
        .map(
          (resource) => resource.copyWith(
            url: scriptureLinkResolver.resolve(
              resource,
              preference: preference,
            ),
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<void> submitFeedback({
    required String resourceId,
    required ResourceFeedbackAction action,
    String? entryId,
    String? themeId,
  }) async {
    await client.submitResourceFeedback(
      ResourceFeedbackRequest(
        resourceId: resourceId,
        action: switch (action) {
          ResourceFeedbackAction.save => 'save',
          ResourceFeedbackAction.dismiss => 'dismiss',
          ResourceFeedbackAction.notHelpful => 'not_helpful',
        },
        entryId: entryId,
        themeId: themeId,
      ),
    );
  }
}
