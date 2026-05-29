import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/supabase_config.dart';
import '../domain/profile_repository.dart';
import 'supabase_profile_repository.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final config = ref.watch(supabaseClientConfigProvider);
  if (!config.enabled) {
    throw StateError(
      'Profile repository requested while LUMEN_USE_SUPABASE is disabled.',
    );
  }

  return SupabaseProfileRepository(
    adapter: SupabaseClientProfilesAdapter(Supabase.instance.client),
    currentUserId: () => Supabase.instance.client.auth.currentUser?.id,
  );
});
