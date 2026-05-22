import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lumen/src/app/supabase_config.dart';
import 'package:lumen/src/features/auth/data/auth_service_provider.dart';
import 'package:lumen/src/features/auth/data/auth_session_controller.dart';
import 'package:lumen/src/features/auth/domain/auth_service.dart';
import 'package:lumen/src/features/auth/domain/auth_session.dart';
import 'package:lumen/src/features/profiles/data/current_user_profile_controller.dart';
import 'package:lumen/src/features/profiles/data/profile_service_provider.dart';
import 'package:lumen/src/features/profiles/domain/profile_service.dart';
import 'package:lumen/src/features/profiles/domain/rewrite_tone_preference.dart';
import 'package:lumen/src/features/profiles/domain/user_profile.dart';
import 'package:lumen/src/features/settings/domain/scripture_app_preference.dart';
import 'package:lumen/src/features/settings/domain/theme_preference.dart';

void main() {
  group('AuthSessionController', () {
    test('build returns null when supabase is disabled', () async {
      final container = ProviderContainer(
        overrides: [
          supabaseClientConfigProvider.overrideWithValue(
            const SupabaseClientConfig(
              enabled: false,
              url: '',
              publishableKey: '',
            ),
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
              publishableKey: 'sb_publishable_example',
            ),
          ),
          authServiceProvider.overrideWithValue(
            _FakeAuthService(loginResult: expected),
          ),
          profileServiceProvider.overrideWithValue(
            _FakeProfileService(profile: _sampleProfile()),
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
      expect(
        container.read(currentUserProfileControllerProvider).value?.id,
        'u-1',
      );
    });

    test('logout clears current user profile state', () async {
      const session = AuthSession(
        userId: 'u-logout',
        email: 'logout@example.com',
        emailVerified: true,
      );
      final container = ProviderContainer(
        overrides: [
          supabaseClientConfigProvider.overrideWithValue(
            const SupabaseClientConfig(
              enabled: true,
              url: 'https://example.supabase.co',
              publishableKey: 'sb_publishable_example',
            ),
          ),
          authServiceProvider.overrideWithValue(
            _FakeAuthService(loginResult: session),
          ),
          profileServiceProvider.overrideWithValue(
            _FakeProfileService(
              profile: _sampleProfile(
                id: 'u-logout',
                email: 'logout@example.com',
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authSessionControllerProvider.future);
      await container
          .read(authSessionControllerProvider.notifier)
          .login(email: 'logout@example.com', password: 'password123');
      await container.read(authSessionControllerProvider.notifier).logout();

      expect(container.read(authSessionControllerProvider).value, isNull);
      expect(
        container.read(currentUserProfileControllerProvider).value,
        isNull,
      );
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

UserProfile _sampleProfile({
  String id = 'u-1',
  String email = 'user@example.com',
}) {
  return UserProfile(
    id: id,
    email: email,
    displayName: 'User',
    rewriteTone: RewriteTonePreference.balanced,
    preserveVoice: true,
    preferredScriptureApp: ScriptureAppPreference.none,
    themePreference: ThemePreference.system,
    onboardingCompleted: false,
    createdAt: DateTime.parse('2026-05-19T09:00:00Z'),
    updatedAt: DateTime.parse('2026-05-19T10:00:00Z'),
  );
}

class _FakeProfileService implements ProfileService {
  _FakeProfileService({required this.profile});

  UserProfile profile;

  @override
  Future<UserProfile> getOrCreateProfile(AuthSession session) async {
    return profile;
  }

  @override
  Future<UserProfile> saveProfile(UserProfile nextProfile) async {
    profile = nextProfile;
    return profile;
  }
}
