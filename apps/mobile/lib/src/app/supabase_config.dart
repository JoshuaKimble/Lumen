import 'package:flutter_riverpod/flutter_riverpod.dart';

class SupabaseClientConfig {
  const SupabaseClientConfig({
    required this.enabled,
    required this.url,
    required this.publishableKey,
  });

  final bool enabled;
  final String url;
  final String publishableKey;
}

const _useSupabase = bool.fromEnvironment('LUMEN_USE_SUPABASE');
const _supabaseUrl = String.fromEnvironment('LUMEN_SUPABASE_URL');
const _supabasePublishableKey = String.fromEnvironment(
  'LUMEN_SUPABASE_PUBLISHABLE_KEY',
);

SupabaseClientConfig loadSupabaseClientConfig() {
  if (!_useSupabase) {
    return const SupabaseClientConfig(
      enabled: false,
      url: '',
      publishableKey: '',
    );
  }

  if (_supabaseUrl.trim().isEmpty) {
    throw StateError(
      'Missing required dart-define LUMEN_SUPABASE_URL when LUMEN_USE_SUPABASE=true.',
    );
  }

  if (_supabasePublishableKey.trim().isEmpty) {
    throw StateError(
      'Missing required dart-define LUMEN_SUPABASE_PUBLISHABLE_KEY when LUMEN_USE_SUPABASE=true.',
    );
  }

  return const SupabaseClientConfig(
    enabled: true,
    url: _supabaseUrl,
    publishableKey: _supabasePublishableKey,
  );
}

final supabaseClientConfigProvider = Provider<SupabaseClientConfig>((ref) {
  return loadSupabaseClientConfig();
});
