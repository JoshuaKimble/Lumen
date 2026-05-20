import 'package:flutter_test/flutter_test.dart';
import 'package:lumen/src/features/profiles/data/user_profile_mapper.dart';
import 'package:lumen/src/features/profiles/domain/rewrite_tone_preference.dart';
import 'package:lumen/src/features/profiles/domain/user_profile.dart';
import 'package:lumen/src/features/settings/domain/scripture_app_preference.dart';
import 'package:lumen/src/features/settings/domain/theme_preference.dart';

void main() {
  test('maps a Supabase row into a typed user profile', () {
    final profile = UserProfileMapper.fromRow({
      'id': 'b9cd46fd-cf47-4bf3-bf68-fde5a2c74cdc',
      'email': 'test@example.com',
      'display_name': 'Test User',
      'rewrite_tone': 'encouraging',
      'preserve_voice': false,
      'preferred_scripture_app': 'you_version',
      'theme_preference': 'dark',
      'onboarding_completed': true,
      'created_at': '2026-05-19T09:00:00Z',
      'updated_at': '2026-05-19T10:00:00Z',
    });

    expect(profile.id, 'b9cd46fd-cf47-4bf3-bf68-fde5a2c74cdc');
    expect(profile.email, 'test@example.com');
    expect(profile.displayName, 'Test User');
    expect(profile.rewriteTone, RewriteTonePreference.encouraging);
    expect(profile.preserveVoice, isFalse);
    expect(profile.preferredScriptureApp, ScriptureAppPreference.youVersion);
    expect(profile.themePreference, ThemePreference.dark);
    expect(profile.onboardingCompleted, isTrue);
    expect(profile.createdAt, DateTime.parse('2026-05-19T09:00:00Z'));
    expect(profile.updatedAt, DateTime.parse('2026-05-19T10:00:00Z'));
  });

  test('serializes a typed user profile into a Supabase row', () {
    final profile = UserProfile(
      id: 'b9cd46fd-cf47-4bf3-bf68-fde5a2c74cdc',
      email: 'test@example.com',
      displayName: 'Test User',
      rewriteTone: RewriteTonePreference.gentle,
      preserveVoice: true,
      preferredScriptureApp: ScriptureAppPreference.gospelLibrary,
      themePreference: ThemePreference.light,
      onboardingCompleted: false,
      createdAt: DateTime.parse('2026-05-19T09:00:00Z'),
      updatedAt: DateTime.parse('2026-05-19T10:00:00Z'),
    );

    expect(UserProfileMapper.toRow(profile), {
      'id': 'b9cd46fd-cf47-4bf3-bf68-fde5a2c74cdc',
      'email': 'test@example.com',
      'display_name': 'Test User',
      'rewrite_tone': 'gentle',
      'preserve_voice': true,
      'preferred_scripture_app': 'gospel_library',
      'theme_preference': 'light',
      'onboarding_completed': false,
      'created_at': '2026-05-19T09:00:00.000Z',
      'updated_at': '2026-05-19T10:00:00.000Z',
    });
  });
}
