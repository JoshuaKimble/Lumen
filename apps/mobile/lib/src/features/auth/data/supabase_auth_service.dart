import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/auth_failure.dart';
import '../domain/auth_service.dart';
import '../domain/auth_session.dart';

abstract class SupabaseAuthAdapter {
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  });

  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  });

  Future<void> signOut();

  Future<void> resetPasswordForEmail(String email);

  Future<UserResponse> updateUser(UserAttributes attributes);

  Future<void> resendSignup({required String email});

  Session? get currentSession;
}

class SupabaseClientAuthAdapter implements SupabaseAuthAdapter {
  SupabaseClientAuthAdapter(this._client);

  final SupabaseClient _client;

  @override
  Session? get currentSession => _client.auth.currentSession;

  @override
  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  @override
  Future<void> signOut() {
    return _client.auth.signOut();
  }

  @override
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) {
    return _client.auth.signUp(email: email, password: password);
  }

  @override
  Future<void> resetPasswordForEmail(String email) {
    return _client.auth.resetPasswordForEmail(email);
  }

  @override
  Future<UserResponse> updateUser(UserAttributes attributes) {
    return _client.auth.updateUser(attributes);
  }

  @override
  Future<void> resendSignup({required String email}) async {
    await _client.auth.resend(type: OtpType.signup, email: email);
  }
}

class SupabaseAuthService implements AuthService {
  SupabaseAuthService({required SupabaseAuthAdapter adapter})
    : _adapter = adapter;

  final SupabaseAuthAdapter _adapter;

  @override
  Future<AuthSession?> getCurrentSession() async {
    return _toAuthSession(_adapter.currentSession);
  }

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _adapter.signInWithPassword(
        email: email,
        password: password,
      );
      final authSession = _toAuthSession(response.session);
      if (authSession == null) {
        throw const AuthFailure(
          code: AuthFailureCode.invalidCredentials,
          message: 'Unable to start a session with these credentials.',
        );
      }
      if (!authSession.emailVerified) {
        throw const AuthFailure(
          code: AuthFailureCode.emailNotVerified,
          message: 'Please verify your email before continuing.',
        );
      }

      return authSession;
    } catch (error) {
      throw mapSupabaseAuthError(error);
    }
  }

  @override
  Future<AuthSession> register({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _adapter.signUp(email: email, password: password);
      final authSession = _toAuthSession(response.session);
      if (authSession != null) {
        return authSession;
      }

      final user = response.user;
      if (user == null) {
        throw const AuthFailure(
          code: AuthFailureCode.unknown,
          message: 'Unable to create account.',
        );
      }

      return AuthSession(
        userId: user.id,
        email: user.email,
        emailVerified: user.emailConfirmedAt != null,
      );
    } catch (error) {
      throw mapSupabaseAuthError(error);
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _adapter.signOut();
    } catch (error) {
      throw mapSupabaseAuthError(error);
    }
  }

  @override
  Future<void> requestPasswordReset({required String email}) async {
    try {
      await _adapter.resetPasswordForEmail(email);
    } catch (error) {
      throw mapSupabaseAuthError(error);
    }
  }

  @override
  Future<void> updatePassword({required String newPassword}) async {
    try {
      await _adapter.updateUser(UserAttributes(password: newPassword));
    } catch (error) {
      throw mapSupabaseAuthError(error);
    }
  }

  @override
  Future<void> resendVerificationEmail({required String email}) async {
    try {
      await _adapter.resendSignup(email: email);
    } catch (error) {
      throw mapSupabaseAuthError(error);
    }
  }

  AuthSession? _toAuthSession(Session? session) {
    final user = session?.user;
    if (user == null) {
      return null;
    }

    return AuthSession(
      userId: user.id,
      email: user.email,
      emailVerified: user.emailConfirmedAt != null,
    );
  }
}

AuthFailure mapSupabaseAuthError(Object error) {
  if (error is AuthFailure) {
    return error;
  }

  if (error is TimeoutException) {
    return const AuthFailure(
      code: AuthFailureCode.networkUnavailable,
      message: 'Network unavailable. Please retry.',
    );
  }

  if (error is AuthException) {
    final message = error.message.toLowerCase();
    final statusCode = (error.statusCode ?? '').toString();

    if (message.contains('invalid login credentials') || statusCode == '400') {
      return const AuthFailure(
        code: AuthFailureCode.invalidCredentials,
        message: 'Invalid email or password.',
      );
    }
    if (message.contains('already registered') ||
        message.contains('user already')) {
      return const AuthFailure(
        code: AuthFailureCode.emailAlreadyRegistered,
        message: 'An account with this email already exists.',
      );
    }
    if (message.contains('email not confirmed')) {
      return const AuthFailure(
        code: AuthFailureCode.emailNotVerified,
        message: 'Please verify your email before signing in.',
      );
    }
    if (message.contains('weak password') ||
        message.contains('password should')) {
      return const AuthFailure(
        code: AuthFailureCode.weakPassword,
        message: 'Password does not meet minimum strength requirements.',
      );
    }
    if (message.contains('expired') || message.contains('invalid token')) {
      return const AuthFailure(
        code: AuthFailureCode.expiredOrInvalidLink,
        message: 'This link is expired or invalid. Request a new one.',
      );
    }
    if (message.contains('network') ||
        message.contains('connection') ||
        statusCode == '503') {
      return const AuthFailure(
        code: AuthFailureCode.networkUnavailable,
        message: 'Network unavailable. Please retry.',
      );
    }
  }

  return const AuthFailure(
    code: AuthFailureCode.unknown,
    message: 'Authentication failed. Please try again.',
  );
}
