import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/domain/auth_session.dart';
import '../domain/user_profile.dart';
import 'profile_service_provider.dart';

final currentUserProfileControllerProvider =
    AsyncNotifierProvider<CurrentUserProfileController, UserProfile?>(
      CurrentUserProfileController.new,
    );

class CurrentUserProfileController extends AsyncNotifier<UserProfile?> {
  @override
  Future<UserProfile?> build() async {
    return null;
  }

  Future<UserProfile?> hydrateForSession(AuthSession? session) async {
    if (session == null) {
      state = const AsyncData(null);
      return null;
    }

    final previousProfile = state.asData?.value;
    state = const AsyncLoading();
    try {
      final profile = await ref
          .read(profileServiceProvider)
          .getOrCreateProfile(session);
      state = AsyncData(profile);
      return profile;
    } catch (_) {
      state = AsyncData(previousProfile);
      rethrow;
    }
  }

  void clear() {
    state = const AsyncData(null);
  }

  Future<UserProfile> saveProfile(UserProfile profile) async {
    final previousProfile = state.asData?.value;
    try {
      final savedProfile = await ref
          .read(profileServiceProvider)
          .saveProfile(profile);
      state = AsyncData(savedProfile);
      return savedProfile;
    } catch (_) {
      state = AsyncData(previousProfile);
      rethrow;
    }
  }
}
