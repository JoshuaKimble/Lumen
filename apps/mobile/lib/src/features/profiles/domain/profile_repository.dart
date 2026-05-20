import 'user_profile.dart';

abstract interface class ProfileRepository {
  Future<UserProfile?> getProfile(String userId);

  Future<void> saveProfile(UserProfile profile);
}
