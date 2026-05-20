import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/profile_service.dart';
import 'profile_repository_provider.dart';
import 'supabase_profile_service.dart';

final profileServiceProvider = Provider<ProfileService>((ref) {
  return SupabaseProfileService(
    repository: ref.watch(profileRepositoryProvider),
  );
});
