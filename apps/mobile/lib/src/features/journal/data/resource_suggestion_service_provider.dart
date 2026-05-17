import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:lumen/src/api/generated/lumen_api_client.dart';

import '../domain/resource_suggestion_service.dart';
import 'api_base_url.dart';
import 'api_resource_suggestion_service.dart';
import 'mock_resource_suggestion_service.dart';

const _useApiAi = bool.fromEnvironment('LUMEN_USE_API_AI');

final resourceSuggestionServiceProvider = Provider<ResourceSuggestionService>((
  ref,
) {
  if (_useApiAi) {
    return ApiResourceSuggestionService(
      client: LumenApiClient(
        baseUri: Uri.parse(resolveApiBaseUrl()),
        httpClient: http.Client(),
      ),
    );
  }

  return const MockResourceSuggestionService();
});
