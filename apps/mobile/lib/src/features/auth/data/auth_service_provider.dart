import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/supabase_config.dart';
import '../domain/auth_service.dart';
import 'supabase_auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  final config = loadSupabaseClientConfig();
  if (!config.enabled) {
    throw StateError(
      'Auth service requested while LUMEN_USE_SUPABASE is disabled.',
    );
  }

  return SupabaseAuthService(
    adapter: SupabaseClientAuthAdapter(Supabase.instance.client),
  );
});
