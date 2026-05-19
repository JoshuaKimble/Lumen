import 'package:flutter_test/flutter_test.dart';
import 'package:lumen/src/features/auth/data/supabase_auth_service.dart';
import 'package:lumen/src/features/auth/domain/auth_failure.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

void main() {
  group('mapSupabaseAuthError', () {
    test('maps invalid credentials', () {
      final failure = mapSupabaseAuthError(
        const AuthException('Invalid login credentials'),
      );

      expect(failure.code, AuthFailureCode.invalidCredentials);
    });

    test('maps already registered', () {
      final failure = mapSupabaseAuthError(
        const AuthException('User already registered'),
      );

      expect(failure.code, AuthFailureCode.emailAlreadyRegistered);
    });

    test('maps email not verified', () {
      final failure = mapSupabaseAuthError(
        const AuthException('Email not confirmed'),
      );

      expect(failure.code, AuthFailureCode.emailNotVerified);
    });

    test('maps weak password', () {
      final failure = mapSupabaseAuthError(
        const AuthException('Weak password'),
      );

      expect(failure.code, AuthFailureCode.weakPassword);
    });

    test('maps expired or invalid links', () {
      final failure = mapSupabaseAuthError(
        const AuthException('Expired token'),
      );

      expect(failure.code, AuthFailureCode.expiredOrInvalidLink);
    });

    test('maps network failures', () {
      final failure = mapSupabaseAuthError(
        const AuthException('Network connection error'),
      );

      expect(failure.code, AuthFailureCode.networkUnavailable);
    });

    test('maps unknown failures', () {
      final failure = mapSupabaseAuthError(Exception('boom'));

      expect(failure.code, AuthFailureCode.unknown);
    });

    test('maps timeout failures to network unavailable', () {
      final failure = mapSupabaseAuthError(TimeoutException('timeout'));

      expect(failure.code, AuthFailureCode.networkUnavailable);
    });
  });

  group('SupabaseAuthService', () {
    test('returns null session when adapter has no session', () async {
      final service = SupabaseAuthService(adapter: _FakeSupabaseAuthAdapter());

      final session = await service.getCurrentSession();

      expect(session, isNull);
    });

    test('maps login errors through normalized AuthFailure', () async {
      final adapter = _FakeSupabaseAuthAdapter(
        onSignInWithPassword: ({required email, required password}) async {
          throw const AuthException('Invalid login credentials');
        },
      );
      final service = SupabaseAuthService(adapter: adapter);

      final future = service.login(email: 'user@example.com', password: 'bad');

      await expectLater(
        future,
        throwsA(
          isA<AuthFailure>().having(
            (e) => e.code,
            'code',
            AuthFailureCode.invalidCredentials,
          ),
        ),
      );
    });

    test('maps register errors through normalized AuthFailure', () async {
      final adapter = _FakeSupabaseAuthAdapter(
        onSignUp: ({required email, required password}) async {
          throw const AuthException('User already registered');
        },
      );
      final service = SupabaseAuthService(adapter: adapter);

      final future = service.register(
        email: 'existing@example.com',
        password: 'password123',
      );

      await expectLater(
        future,
        throwsA(
          isA<AuthFailure>().having(
            (e) => e.code,
            'code',
            AuthFailureCode.emailAlreadyRegistered,
          ),
        ),
      );
    });
  });
}

class _FakeSupabaseAuthAdapter implements SupabaseAuthAdapter {
  _FakeSupabaseAuthAdapter({this.onSignUp, this.onSignInWithPassword});

  final Future<AuthResponse> Function({
    required String email,
    required String password,
  })?
  onSignUp;
  final Future<AuthResponse> Function({
    required String email,
    required String password,
  })?
  onSignInWithPassword;

  @override
  Session? get currentSession => null;

  @override
  Future<void> resetPasswordForEmail(String email) async {}

  @override
  Future<void> resendSignup({required String email}) async {
    throw UnimplementedError();
  }

  @override
  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) {
    final handler = onSignInWithPassword;
    if (handler == null) {
      throw UnimplementedError();
    }
    return handler(email: email, password: password);
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) {
    final handler = onSignUp;
    if (handler == null) {
      throw UnimplementedError();
    }
    return handler(email: email, password: password);
  }

  @override
  Future<UserResponse> updateUser(UserAttributes attributes) async {
    throw UnimplementedError();
  }
}
