import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/domain/auth_session.dart';
import '../../settings/domain/scripture_app_preference.dart';
import '../../settings/domain/theme_preference.dart';
import '../domain/profile_failure.dart';
import '../domain/profile_repository.dart';
import '../domain/profile_service.dart';
import '../domain/rewrite_tone_preference.dart';
import '../domain/user_profile.dart';

class SupabaseProfileService implements ProfileService {
  SupabaseProfileService({required ProfileRepository repository})
    : _repository = repository;

  final ProfileRepository _repository;

  @override
  Future<UserProfile> getOrCreateProfile(AuthSession session) async {
    final email = session.email;
    if (email == null || email.trim().isEmpty) {
      throw const ProfileFailure(
        code: ProfileFailureCode.missingEmail,
        message:
            'Your account is missing an email address. Sign out and back in to recover your profile.',
      );
    }

    try {
      final existingProfile = await _repository.getProfile(session.userId);
      if (existingProfile != null) {
        return existingProfile;
      }

      final now = DateTime.now().toUtc();
      final recoveredProfile = await _repository.saveProfile(
        UserProfile(
          id: session.userId,
          email: email.trim(),
          displayName: null,
          rewriteTone: RewriteTonePreference.balanced,
          preserveVoice: true,
          preferredScriptureApp: ScriptureAppPreference.none,
          themePreference: ThemePreference.system,
          onboardingCompleted: false,
          createdAt: now,
          updatedAt: now,
        ),
      );

      return recoveredProfile;
    } catch (error) {
      throw mapProfileError(error);
    }
  }
}

ProfileFailure mapProfileError(Object error) {
  if (error is ProfileFailure) {
    return error;
  }

  if (error is PostgrestException) {
    return const ProfileFailure(
      code: ProfileFailureCode.hydrationFailed,
      message:
          'Unable to load your profile right now. Please retry or sign out and back in.',
    );
  }

  return const ProfileFailure(
    code: ProfileFailureCode.hydrationFailed,
    message:
        'Unable to recover your profile automatically. Please sign out and back in.',
  );
}
