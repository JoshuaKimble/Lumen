import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lumen/src/app/supabase_config.dart';
import 'package:lumen/src/features/auth/data/auth_service_provider.dart';
import 'package:lumen/src/features/auth/data/auth_session_controller.dart';
import 'package:lumen/src/features/auth/domain/auth_service.dart';
import 'package:lumen/src/features/auth/domain/auth_session.dart';

void main() {
  group('AuthSessionController', () {
    test('build returns null when supabase is disabled', () async {
      final container = ProviderContainer(
        overrides: [
          supabaseClientConfigProvider.overrideWithValue(
            const SupabaseClientConfig(enabled: false, url: '', anonKey: ''),
          ),
          authServiceProvider.overrideWithValue(_FakeAuthService()),
        ],
      );
      addTearDown(container.dispose);

      final session = await container.read(
        authSessionControllerProvider.future,
      );

      expect(session, isNull);
    });

    test('login updates session state', () async {
      final expected = const AuthSession(
        userId: 'u-1',
        email: 'user@example.com',
        emailVerified: true,
      );
      final container = ProviderContainer(
        overrides: [
          supabaseClientConfigProvider.overrideWithValue(
            const SupabaseClientConfig(
              enabled: true,
              url: 'https://example.supabase.co',
              anonKey: 'anon-key',
            ),
          ),
          authServiceProvider.overrideWithValue(
            _FakeAuthService(loginResult: expected),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authSessionControllerProvider.future);
      final returned = await container
          .read(authSessionControllerProvider.notifier)
          .login(email: 'user@example.com', password: 'password123');

      expect(returned, expected);
      expect(container.read(authSessionControllerProvider).value, expected);
    });
  });
}

class _FakeAuthService implements AuthService {
  _FakeAuthService({this.loginResult});

  final AuthSession? loginResult;

  @override
  Future<AuthSession?> getCurrentSession() async => null;

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    return loginResult ??
        AuthSession(userId: 'u-login', email: email, emailVerified: true);
  }

  @override
  Future<void> logout() async {}

  @override
  Future<AuthSession> register({
    required String email,
    required String password,
  }) async {
    return AuthSession(
      userId: 'u-register',
      email: email,
      emailVerified: false,
    );
  }

  @override
  Future<void> requestPasswordReset({required String email}) async {}

  @override
  Future<void> resendVerificationEmail({required String email}) async {}

  @override
  Future<void> updatePassword({required String newPassword}) async {}
}
