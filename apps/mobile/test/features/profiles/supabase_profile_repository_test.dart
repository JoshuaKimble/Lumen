import 'package:flutter_test/flutter_test.dart';
import 'package:lumen/src/features/profiles/data/supabase_profile_repository.dart';
import 'package:lumen/src/features/profiles/domain/rewrite_tone_preference.dart';
import 'package:lumen/src/features/profiles/domain/user_profile.dart';
import 'package:lumen/src/features/settings/domain/scripture_app_preference.dart';
import 'package:lumen/src/features/settings/domain/theme_preference.dart';

void main() {
  test('reads the authenticated user profile', () async {
    final repository = SupabaseProfileRepository(
      adapter: _FakeSupabaseProfilesAdapter(
        fetchResult: {
          'id': 'user-1',
          'email': 'user@example.com',
          'display_name': 'Jordan',
          'rewrite_tone': 'balanced',
          'preserve_voice': true,
          'preferred_scripture_app': 'none',
          'theme_preference': 'system',
          'onboarding_completed': true,
          'created_at': '2026-05-19T09:00:00Z',
          'updated_at': '2026-05-19T10:00:00Z',
        },
      ),
      currentUserId: () => 'user-1',
    );

    final profile = await repository.getProfile('user-1');

    expect(profile?.id, 'user-1');
    expect(profile?.displayName, 'Jordan');
  });

  test('rejects profile reads for another user id', () async {
    final repository = SupabaseProfileRepository(
      adapter: _FakeSupabaseProfilesAdapter(),
      currentUserId: () => 'user-1',
    );

    await expectLater(
      repository.getProfile('user-2'),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('authenticated user'),
        ),
      ),
    );
  });

  test('rejects profile writes without an authenticated user', () async {
    final repository = SupabaseProfileRepository(
      adapter: _FakeSupabaseProfilesAdapter(),
      currentUserId: () => null,
    );

    await expectLater(
      repository.saveProfile(_sampleProfile()),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('authenticated user session'),
        ),
      ),
    );
  });
}

class _FakeSupabaseProfilesAdapter implements SupabaseProfilesAdapter {
  _FakeSupabaseProfilesAdapter({this.fetchResult});

  final Map<String, dynamic>? fetchResult;

  @override
  Future<Map<String, dynamic>?> fetchProfile(String userId) async {
    return fetchResult;
  }

  @override
  Future<Map<String, dynamic>> upsertProfile(Map<String, Object?> row) async {
    return Map<String, dynamic>.from(row);
  }
}

UserProfile _sampleProfile() {
  return UserProfile(
    id: 'user-1',
    email: 'user@example.com',
    displayName: 'Jordan',
    rewriteTone: RewriteTonePreference.balanced,
    preserveVoice: true,
    preferredScriptureApp: ScriptureAppPreference.none,
    themePreference: ThemePreference.system,
    onboardingCompleted: true,
    createdAt: DateTime.parse('2026-05-19T09:00:00Z'),
    updatedAt: DateTime.parse('2026-05-19T10:00:00Z'),
  );
}
