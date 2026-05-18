import 'auth_session.dart';

abstract class AuthService {
  Future<AuthSession?> getCurrentSession();

  Future<AuthSession> register({
    required String email,
    required String password,
  });

  Future<AuthSession> login({required String email, required String password});

  Future<void> logout();

  Future<void> requestPasswordReset({required String email});

  Future<void> updatePassword({required String newPassword});

  Future<void> resendVerificationEmail({required String email});
}
