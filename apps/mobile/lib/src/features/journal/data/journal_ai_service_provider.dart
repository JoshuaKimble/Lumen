import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:lumen/src/api/generated/lumen_api_client.dart';

import '../domain/journal_ai_service.dart';
import 'api_journal_ai_service.dart';
import 'mock_journal_ai_service.dart';

const _useApiAi = bool.fromEnvironment('LUMEN_USE_API_AI');
const _apiBaseUrl = String.fromEnvironment(
  'LUMEN_API_BASE_URL',
  defaultValue: 'http://localhost:3000',
);

final journalAiServiceProvider = Provider<JournalAiService>((ref) {
  if (_useApiAi) {
    return ApiJournalAiService(
      client: LumenApiClient(
        baseUri: Uri.parse(_apiBaseUrl),
        httpClient: http.Client(),
      ),
    );
  }

  return const MockJournalAiService();
});
