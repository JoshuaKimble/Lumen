import '../../auth/domain/auth_session.dart';
import 'user_profile.dart';

abstract interface class ProfileService {
  Future<UserProfile> getOrCreateProfile(AuthSession session);
}
