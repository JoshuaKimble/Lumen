import 'auth_session.dart';
import 'user_capabilities.dart';

abstract interface class UserCapabilitiesService {
  Future<UserCapabilities> getForSession(AuthSession session);
}
