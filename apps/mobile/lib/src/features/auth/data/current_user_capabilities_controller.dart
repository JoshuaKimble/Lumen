import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/supabase_config.dart';
import '../domain/auth_session.dart';
import '../domain/user_capabilities.dart';
import 'user_capabilities_service_provider.dart';

final currentUserCapabilitiesControllerProvider =
    AsyncNotifierProvider<CurrentUserCapabilitiesController, UserCapabilities>(
      CurrentUserCapabilitiesController.new,
    );

class CurrentUserCapabilitiesController
    extends AsyncNotifier<UserCapabilities> {
  @override
  Future<UserCapabilities> build() async {
    return UserCapabilities.none;
  }

  Future<UserCapabilities> hydrateForSession(AuthSession? session) async {
    if (session == null || !ref.read(supabaseClientConfigProvider).enabled) {
      state = const AsyncData(UserCapabilities.none);
      return UserCapabilities.none;
    }

    final previous = state.asData?.value ?? UserCapabilities.none;
    state = const AsyncLoading();
    try {
      final capabilities = await ref
          .read(userCapabilitiesServiceProvider)
          .getForSession(session);
      state = AsyncData(capabilities);
      return capabilities;
    } catch (_) {
      state = AsyncData(previous);
      rethrow;
    }
  }

  void clear() {
    state = const AsyncData(UserCapabilities.none);
  }
}
