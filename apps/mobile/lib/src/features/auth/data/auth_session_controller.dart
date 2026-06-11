import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/supabase_config.dart';
import '../domain/auth_session.dart';
import 'current_user_capabilities_controller.dart';
import 'auth_service_provider.dart';
import '../../profiles/data/current_user_profile_controller.dart';

final authSessionControllerProvider =
    AsyncNotifierProvider<AuthSessionController, AuthSession?>(
      AuthSessionController.new,
    );

class AuthSessionController extends AsyncNotifier<AuthSession?> {
  @override
  Future<AuthSession?> build() async {
    final config = ref.watch(supabaseClientConfigProvider);
    if (!config.enabled) {
      return null;
    }

    final session = await ref.read(authServiceProvider).getCurrentSession();
    unawaited(_syncProfileForSession(session, swallowFailure: true));
    return session;
  }

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final authService = ref.read(authServiceProvider);
    final session = await authService.login(email: email, password: password);
    await _syncProfileForSession(session);
    state = AsyncData(session);
    return session;
  }

  Future<AuthSession> register({
    required String email,
    required String password,
  }) async {
    final authService = ref.read(authServiceProvider);
    final session = await authService.register(
      email: email,
      password: password,
    );
    await _syncProfileForSession(session);
    state = AsyncData(session);
    return session;
  }

  Future<void> logout() async {
    final authService = ref.read(authServiceProvider);
    await authService.logout();
    ref.read(currentUserProfileControllerProvider.notifier).clear();
    ref.read(currentUserCapabilitiesControllerProvider.notifier).clear();
    state = const AsyncData(null);
  }

  Future<void> refreshSession() async {
    final authService = ref.read(authServiceProvider);
    state = const AsyncLoading();
    final session = await authService.getCurrentSession();
    await _syncProfileForSession(session, swallowFailure: true);
    state = AsyncData(session);
  }

  Future<void> requestPasswordResetForCurrentUser() async {
    final authService = ref.read(authServiceProvider);
    final session =
        state.asData?.value ?? await authService.getCurrentSession();
    if (session == null) {
      throw StateError(
        'Cannot request password reset without an active session.',
      );
    }

    final email = session.email;
    if (email == null || email.isEmpty) {
      throw StateError(
        'Cannot request password reset without an email on the current session.',
      );
    }

    await authService.requestPasswordReset(email: email);
  }

  Future<void> _syncProfileForSession(
    AuthSession? session, {
    bool swallowFailure = false,
  }) async {
    final profileController = ref.read(
      currentUserProfileControllerProvider.notifier,
    );
    final capabilitiesController = ref.read(
      currentUserCapabilitiesControllerProvider.notifier,
    );

    if (session == null) {
      profileController.clear();
      capabilitiesController.clear();
      return;
    }

    if (!ref.read(supabaseClientConfigProvider).enabled) {
      profileController.clear();
      capabilitiesController.clear();
      return;
    }

    if (!swallowFailure) {
      await profileController.hydrateForSession(session);
      await capabilitiesController.hydrateForSession(session);
      return;
    }

    try {
      await profileController.hydrateForSession(session);
    } catch (_) {
      // Preserve the auth session on restore even if profile hydration fails.
    }

    try {
      await capabilitiesController.hydrateForSession(session);
    } catch (_) {
      // Preserve the auth session on restore even if capability hydration fails.
    }
  }
}
