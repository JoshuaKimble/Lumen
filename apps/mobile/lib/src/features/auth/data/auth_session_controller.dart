import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/supabase_config.dart';
import '../domain/auth_session.dart';
import 'auth_service_provider.dart';

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

    return ref.read(authServiceProvider).getCurrentSession();
  }

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final authService = ref.read(authServiceProvider);
    final session = await authService.login(email: email, password: password);
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
    state = AsyncData(session);
    return session;
  }

  Future<void> logout() async {
    final authService = ref.read(authServiceProvider);
    await authService.logout();
    state = const AsyncData(null);
  }

  Future<void> refreshSession() async {
    final authService = ref.read(authServiceProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(authService.getCurrentSession);
  }
}
