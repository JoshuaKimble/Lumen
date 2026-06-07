import 'package:flutter_test/flutter_test.dart';
import 'package:lumen/src/features/auth/data/auth_email_redirect_urls.dart';
import 'package:lumen/src/features/auth/data/supabase_auth_service.dart';
import 'package:lumen/src/features/auth/domain/auth_failure.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

void main() {
  group('AuthEmailRedirectUrls', () {
    test('builds auth redirects from the current web origin', () {
      final redirects = AuthEmailRedirectUrls.forCurrentOrigin(
        Uri.parse('https://lumen-50b.pages.dev/auth/register'),
      );

      expect(
        redirects.emailConfirmation,
        'https://lumen-50b.pages.dev/auth/login',
      );
      expect(
        redirects.passwordReset,
        'https://lumen-50b.pages.dev/auth/reset-password',
      );
    });

    test('returns empty redirects for non-http origins', () {
      final redirects = AuthEmailRedirectUrls.forCurrentOrigin(
        Uri.parse('file:///app/index.html'),
      );

      expect(redirects.emailConfirmation, isNull);
      expect(redirects.passwordReset, isNull);
    });
  });

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

    test('maps rate limited auth errors', () {
      final failure = mapSupabaseAuthError(
        const AuthException(
          '429: For security purposes, you can only request this after 14 seconds.',
          statusCode: '429',
        ),
      );

      expect(failure.code, AuthFailureCode.rateLimited);
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
        onSignUp: ({required email, required password, emailRedirectTo}) async {
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

    test(
      'passes explicit auth email redirects to signup, resend, and reset',
      () async {
        final adapter = _FakeSupabaseAuthAdapter(
          onSignUp:
              ({required email, required password, emailRedirectTo}) async {
                throw const AuthException('boom');
              },
        );
        final service = SupabaseAuthService(
          adapter: adapter,
          emailRedirectUrls: const AuthEmailRedirectUrls(
            emailConfirmation: 'https://lumen.test/auth/login',
            passwordReset: 'https://lumen.test/auth/reset-password',
          ),
        );

        await expectLater(
          service.register(email: 'new@example.com', password: 'password123'),
          throwsA(
            isA<AuthFailure>().having(
              (e) => e.code,
              'code',
              AuthFailureCode.unknown,
            ),
          ),
        );
        await service.resendVerificationEmail(email: 'new@example.com');
        await service.requestPasswordReset(email: 'new@example.com');

        expect(
          adapter.lastSignUpEmailRedirectTo,
          'https://lumen.test/auth/login',
        );
        expect(
          adapter.lastResendEmailRedirectTo,
          'https://lumen.test/auth/login',
        );
        expect(
          adapter.lastPasswordResetRedirectTo,
          'https://lumen.test/auth/reset-password',
        );
      },
    );
  });
}

class _FakeSupabaseAuthAdapter implements SupabaseAuthAdapter {
  _FakeSupabaseAuthAdapter({this.onSignUp, this.onSignInWithPassword});

  final Future<AuthResponse> Function({
    required String email,
    required String password,
    String? emailRedirectTo,
  })?
  onSignUp;
  final Future<AuthResponse> Function({
    required String email,
    required String password,
  })?
  onSignInWithPassword;

  @override
  Session? get currentSession => null;

  String? lastPasswordResetRedirectTo;
  String? lastResendEmailRedirectTo;
  String? lastSignUpEmailRedirectTo;

  @override
  Future<void> resetPasswordForEmail(String email, {String? redirectTo}) async {
    lastPasswordResetRedirectTo = redirectTo;
  }

  @override
  Future<void> resendSignup({
    required String email,
    String? emailRedirectTo,
  }) async {
    lastResendEmailRedirectTo = emailRedirectTo;
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
    String? emailRedirectTo,
  }) {
    lastSignUpEmailRedirectTo = emailRedirectTo;
    final handler = onSignUp;
    if (handler == null) {
      throw UnimplementedError();
    }
    return handler(
      email: email,
      password: password,
      emailRedirectTo: emailRedirectTo,
    );
  }

  @override
  Future<UserResponse> updateUser(UserAttributes attributes) async {
    throw UnimplementedError();
  }
}
