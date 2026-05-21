import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:lumen/src/api/generated/lumen_api_client.dart';
import 'package:lumen/src/features/profiles/data/current_user_profile_controller.dart';

import '../domain/journal_ai_service.dart';
import '../domain/rewrite_personalization.dart';
import 'api_base_url.dart';
import 'api_journal_ai_service.dart';
import 'mock_journal_ai_service.dart';
import 'profile_aware_journal_ai_service.dart';

const _useApiAi = bool.fromEnvironment('LUMEN_USE_API_AI');

final journalAiServiceProvider = Provider<JournalAiService>((ref) {
  final profile = ref.watch(currentUserProfileControllerProvider).asData?.value;
  final defaultPersonalization = profile == null
      ? RewritePersonalization.defaults
      : RewritePersonalization(
          rewriteTone: profile.rewriteTone,
          preserveVoice: profile.preserveVoice,
        );
  final delegate = _useApiAi
      ? ApiJournalAiService(
          client: LumenApiClient(
            baseUri: Uri.parse(resolveApiBaseUrl()),
            httpClient: http.Client(),
          ),
        )
      : const MockJournalAiService();

  return ProfileAwareJournalAiService(
    delegate: delegate,
    defaultPersonalization: defaultPersonalization,
  );
});
