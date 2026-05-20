import 'package:flutter_test/flutter_test.dart';
import 'package:lumen/src/features/auth/domain/auth_session.dart';
import 'package:lumen/src/features/profiles/data/supabase_profile_service.dart';
import 'package:lumen/src/features/profiles/domain/profile_failure.dart';
import 'package:lumen/src/features/profiles/domain/profile_repository.dart';
import 'package:lumen/src/features/profiles/domain/rewrite_tone_preference.dart';
import 'package:lumen/src/features/profiles/domain/user_profile.dart';
import 'package:lumen/src/features/settings/domain/scripture_app_preference.dart';
import 'package:lumen/src/features/settings/domain/theme_preference.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('SupabaseProfileService', () {
    test('returns existing profile when one is already stored', () async {
      final existingProfile = _sampleProfile();
      final service = SupabaseProfileService(
        repository: _FakeProfileRepository(profile: existingProfile),
      );

      final profile = await service.getOrCreateProfile(_sampleSession());

      expect(profile, existingProfile);
    });

    test('creates a default profile when none exists yet', () async {
      final repository = _FakeProfileRepository();
      final service = SupabaseProfileService(repository: repository);

      final profile = await service.getOrCreateProfile(_sampleSession());

      expect(repository.savedProfiles, hasLength(1));
      expect(profile.id, 'user-1');
      expect(profile.email, 'user@example.com');
      expect(profile.displayName, isNull);
      expect(profile.rewriteTone, RewriteTonePreference.balanced);
      expect(profile.preserveVoice, isTrue);
      expect(profile.preferredScriptureApp, ScriptureAppPreference.none);
      expect(profile.themePreference, ThemePreference.system);
      expect(profile.onboardingCompleted, isFalse);
    });

    test('throws clear failure when session email is missing', () async {
      final service = SupabaseProfileService(
        repository: _FakeProfileRepository(),
      );

      await expectLater(
        service.getOrCreateProfile(
          const AuthSession(userId: 'user-1', email: null, emailVerified: true),
        ),
        throwsA(
          isA<ProfileFailure>()
              .having((e) => e.code, 'code', ProfileFailureCode.missingEmail)
              .having(
                (e) => e.message,
                'message',
                contains('Sign out and back in'),
              ),
        ),
      );
    });

    test('maps repository errors to recovery guidance', () async {
      final service = SupabaseProfileService(
        repository: _FakeProfileRepository(
          getError: const PostgrestException(message: 'boom'),
        ),
      );

      await expectLater(
        service.getOrCreateProfile(_sampleSession()),
        throwsA(
          isA<ProfileFailure>()
              .having((e) => e.code, 'code', ProfileFailureCode.hydrationFailed)
              .having(
                (e) => e.message,
                'message',
                contains('retry or sign out and back in'),
              ),
        ),
      );
    });

    test('saves profile updates through repository', () async {
      final repository = _FakeProfileRepository();
      final service = SupabaseProfileService(repository: repository);
      final profile = _sampleProfile();

      final savedProfile = await service.saveProfile(profile);

      expect(savedProfile, profile);
      expect(repository.savedProfiles.single, profile);
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
    rewriteTone: RewriteTonePreference.reflective,
    preserveVoice: false,
    preferredScriptureApp: ScriptureAppPreference.catholic,
    themePreference: ThemePreference.dark,
    onboardingCompleted: true,
    createdAt: DateTime.parse('2026-05-19T09:00:00Z'),
    updatedAt: DateTime.parse('2026-05-19T10:00:00Z'),
  );
}

class _FakeProfileRepository implements ProfileRepository {
  _FakeProfileRepository({this.profile, this.getError});

  final UserProfile? profile;
  final Object? getError;
  final List<UserProfile> savedProfiles = [];

  @override
  Future<UserProfile?> getProfile(String userId) async {
    final error = getError;
    if (error != null) {
      throw error;
    }

    return profile;
  }

  @override
  Future<UserProfile> saveProfile(UserProfile profile) async {
    savedProfiles.add(profile);
    return profile;
  }
}
