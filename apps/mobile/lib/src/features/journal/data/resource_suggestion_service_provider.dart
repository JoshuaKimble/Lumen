import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/resource_suggestion_service.dart';
import 'api_resource_suggestion_service.dart';
import 'lumen_api_client_provider.dart';
import 'mock_resource_suggestion_service.dart';
import 'resource_link_opener.dart';
import 'scripture_resource_link_resolver.dart';

const _useApiAi = bool.fromEnvironment('LUMEN_USE_API_AI');

final resourceSuggestionServiceProvider = Provider<ResourceSuggestionService>((
  ref,
) {
  if (_useApiAi) {
    return ApiResourceSuggestionService(
      client: ref.watch(lumenApiClientProvider),
    );
  }

  return const MockResourceSuggestionService();
});

final scriptureResourceLinkResolverProvider =
    Provider<ScriptureResourceLinkResolver>((ref) {
      return const ScriptureResourceLinkResolver();
    });

final resourceLinkOpenerProvider = Provider<ResourceLinkOpener>((ref) {
  return const UrlLauncherResourceLinkOpener();
});
