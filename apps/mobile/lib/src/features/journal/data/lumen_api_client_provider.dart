import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:lumen/src/api/generated/lumen_api_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/supabase_config.dart';
import 'api_base_url.dart';

final lumenApiHttpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

final lumenApiClientProvider = Provider<LumenApiClient>((ref) {
  final supabaseConfig = ref.watch(supabaseClientConfigProvider);

  return LumenApiClient(
    baseUri: Uri.parse(resolveApiBaseUrl()),
    httpClient: ref.watch(lumenApiHttpClientProvider),
    accessTokenProvider: supabaseConfig.enabled
        ? () async => Supabase.instance.client.auth.currentSession?.accessToken
        : null,
  );
});
