import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/supabase_config.dart';
import '../domain/user_capabilities_service.dart';
import 'supabase_user_capabilities_service.dart';

final userCapabilitiesServiceProvider = Provider<UserCapabilitiesService>((
  ref,
) {
  final config = ref.watch(supabaseClientConfigProvider);
  if (!config.enabled) {
    throw StateError(
      'User capabilities are unavailable when Supabase auth is disabled.',
    );
  }

  return SupabaseUserCapabilitiesService(client: Supabase.instance.client);
});
