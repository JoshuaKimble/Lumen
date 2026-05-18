class SupabaseClientConfig {
  const SupabaseClientConfig({
    required this.enabled,
    required this.url,
    required this.anonKey,
  });

  final bool enabled;
  final String url;
  final String anonKey;
}

const _useSupabase = bool.fromEnvironment('LUMEN_USE_SUPABASE');
const _supabaseUrl = String.fromEnvironment('LUMEN_SUPABASE_URL');
const _supabaseAnonKey = String.fromEnvironment('LUMEN_SUPABASE_ANON_KEY');

SupabaseClientConfig loadSupabaseClientConfig() {
  if (!_useSupabase) {
    return const SupabaseClientConfig(enabled: false, url: '', anonKey: '');
  }

  if (_supabaseUrl.trim().isEmpty) {
    throw StateError(
      'Missing required dart-define LUMEN_SUPABASE_URL when LUMEN_USE_SUPABASE=true.',
    );
  }

  if (_supabaseAnonKey.trim().isEmpty) {
    throw StateError(
      'Missing required dart-define LUMEN_SUPABASE_ANON_KEY when LUMEN_USE_SUPABASE=true.',
    );
  }

  return const SupabaseClientConfig(
    enabled: true,
    url: _supabaseUrl,
    anonKey: _supabaseAnonKey,
  );
}
