import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumen/src/features/auth/domain/auth_session.dart';
import 'package:lumen/src/features/profiles/data/current_user_profile_controller.dart';
import 'package:lumen/src/features/profiles/data/profile_service_provider.dart';
import 'package:lumen/src/features/profiles/domain/profile_service.dart';
import 'package:lumen/src/features/profiles/domain/rewrite_tone_preference.dart';
import 'package:lumen/src/features/profiles/domain/user_profile.dart';
import 'package:lumen/src/features/settings/domain/scripture_app_preference.dart';
import 'package:lumen/src/features/settings/domain/theme_preference.dart';

void main() {
  group('CurrentUserProfileController', () {
    test('hydrates profile for signed-in session', () async {
      final profile = _sampleProfile();
      final container = ProviderContainer(
        overrides: [
          profileServiceProvider.overrideWithValue(
            _FakeProfileService(profile: profile),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(currentUserProfileControllerProvider.future);
      final returned = await container
          .read(currentUserProfileControllerProvider.notifier)
          .hydrateForSession(_sampleSession());

      expect(returned, profile);
      expect(
        container.read(currentUserProfileControllerProvider).value,
        profile,
      );
    });

    test('clears hydrated profile when session is removed', () async {
      final profile = _sampleProfile();
      final container = ProviderContainer(
        overrides: [
          profileServiceProvider.overrideWithValue(
            _FakeProfileService(profile: profile),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(currentUserProfileControllerProvider.future);
      await container
          .read(currentUserProfileControllerProvider.notifier)
          .hydrateForSession(_sampleSession());

      await container
          .read(currentUserProfileControllerProvider.notifier)
          .hydrateForSession(null);

      expect(
        container.read(currentUserProfileControllerProvider).value,
        isNull,
      );
    });
  });
}

AuthSession _sampleSession() {
  return const AuthSession(
    userId: 'user-1',
    email: 'user@example.com',
    emailVerified: true,
  );
}

UserProfile _sampleProfile() {
  return UserProfile(
    id: 'user-1',
    email: 'user@example.com',
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

  final UserProfile profile;

  @override
  Future<UserProfile> getOrCreateProfile(AuthSession session) async {
    return profile;
  }
}
