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

    state = const AsyncLoading();
    try {
      final profile = await ref
          .read(profileServiceProvider)
          .getOrCreateProfile(session);
      state = AsyncData(profile);
      return profile;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  void clear() {
    state = const AsyncData(null);
  }
}
