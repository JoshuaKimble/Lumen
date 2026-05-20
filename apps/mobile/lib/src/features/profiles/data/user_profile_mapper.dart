import '../domain/rewrite_tone_preference.dart';
import '../domain/user_profile.dart';
import '../../settings/domain/scripture_app_preference.dart';
import '../../settings/domain/theme_preference.dart';

typedef ProfileRow = Map<String, Object?>;

class UserProfileMapper {
  const UserProfileMapper._();

  static UserProfile fromRow(Map<String, dynamic> row) {
    return UserProfile(
      id: row['id']! as String,
      email: row['email']! as String,
      displayName: row['display_name'] as String?,
      rewriteTone: RewriteTonePreference.fromStorageValue(
        row['rewrite_tone'] as String?,
      ),
      preserveVoice: row['preserve_voice']! as bool,
      preferredScriptureApp: ScriptureAppPreferenceX.fromStorageValue(
        row['preferred_scripture_app'] as String?,
      ),
      themePreference: ThemePreference.fromStorageValue(
        row['theme_preference'] as String?,
      ),
      onboardingCompleted: row['onboarding_completed']! as bool,
      createdAt: DateTime.parse(row['created_at']! as String).toUtc(),
      updatedAt: DateTime.parse(row['updated_at']! as String).toUtc(),
    );
  }

  static ProfileRow toRow(UserProfile profile) {
    return <String, Object?>{
      'id': profile.id,
      'email': profile.email,
      'display_name': profile.displayName,
      'rewrite_tone': profile.rewriteTone.storageValue,
      'preserve_voice': profile.preserveVoice,
      'preferred_scripture_app': profile.preferredScriptureApp.storageValue,
      'theme_preference': profile.themePreference.storageValue,
      'onboarding_completed': profile.onboardingCompleted,
      'created_at': profile.createdAt.toUtc().toIso8601String(),
      'updated_at': profile.updatedAt.toUtc().toIso8601String(),
    };
  }
}
