import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lumen/src/app/router.dart';
import 'package:lumen/src/features/auth/data/auth_service_provider.dart';
import 'package:lumen/src/features/auth/domain/auth_failure.dart';
import 'package:lumen/src/features/auth/domain/auth_session.dart';
import 'package:lumen/src/features/auth/domain/auth_service.dart';
import 'package:lumen/src/features/auth/presentation/login_screen.dart';
import 'package:lumen/src/features/auth/presentation/register_screen.dart';
import 'package:lumen/src/features/auth/presentation/verify_pending_screen.dart';

void main() {
  group('auth screens', () {
    testWidgets('login validates required fields', (tester) async {
      await tester.pumpWidget(
        _buildHarness(
          initialLocation: loginRoutePath,
          authService: _FakeAuthService(),
          routes: [
            GoRoute(
              name: loginRouteName,
              path: loginRoutePath,
              builder: (context, state) => const LoginScreen(),
            ),
          ],
        ),
      );

      await tester.tap(find.text('Sign in'));
      await tester.pump();

      expect(find.text('Email is required.'), findsOneWidget);
      expect(find.text('Password is required.'), findsOneWidget);
    });

    testWidgets('register routes to verify pending when email is unverified', (
      tester,
    ) async {
      final authService = _FakeAuthService(
        registerResult: const AuthSession(
          userId: 'user-1',
          email: 'new@example.com',
          emailVerified: false,
        ),
      );

      await tester.pumpWidget(
        _buildHarness(
          initialLocation: registerRoutePath,
          authService: authService,
          routes: [
            GoRoute(
              name: registerRouteName,
              path: registerRoutePath,
              builder: (context, state) => const RegisterScreen(),
            ),
            GoRoute(
              name: verifyPendingRouteName,
              path: verifyPendingRoutePath,
              builder: (context, state) => VerifyPendingScreen(
                email: state.uri.queryParameters['email'] ?? '',
              ),
            ),
          ],
        ),
      );

      await tester.enterText(
        find.byType(TextFormField).at(0),
        'new@example.com',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'password123');
      await tester.enterText(find.byType(TextFormField).at(2), 'password123');
      await tester.tap(find.byIcon(Icons.person_add_alt_1));
      await tester.pumpAndSettle();

      expect(find.text('Verify your email'), findsOneWidget);
      expect(find.textContaining('new@example.com'), findsOneWidget);
    });

    testWidgets('login surfaces explicit auth failures', (tester) async {
      await tester.pumpWidget(
        _buildHarness(
          initialLocation: loginRoutePath,
          authService: _FakeAuthService(
            loginError: const AuthFailure(
              code: AuthFailureCode.invalidCredentials,
              message: 'Invalid email or password.',
            ),
          ),
          routes: [
            GoRoute(
              name: loginRouteName,
              path: loginRoutePath,
              builder: (context, state) => const LoginScreen(),
            ),
          ],
        ),
      );

      await tester.enterText(
        find.byType(TextFormField).at(0),
        'bad@example.com',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'wrong');
      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle();

      expect(find.text('Invalid email or password.'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('register routes to verify pending when signup is rate limited', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildHarness(
          initialLocation: registerRoutePath,
          authService: _FakeAuthService(
            registerError: const AuthFailure(
              code: AuthFailureCode.rateLimited,
              message:
                  'A verification or reset email was sent recently. Please wait a moment before trying again.',
            ),
          ),
          routes: [
            GoRoute(
              name: registerRouteName,
              path: registerRoutePath,
              builder: (context, state) => const RegisterScreen(),
            ),
            GoRoute(
              name: verifyPendingRouteName,
              path: verifyPendingRoutePath,
              builder: (context, state) => VerifyPendingScreen(
                email: state.uri.queryParameters['email'] ?? '',
                initialStatusText: state.uri.queryParameters['status'] ==
                        'email-sent-recently'
                    ? 'A verification email was already sent recently. Please wait a moment, then use resend if needed.'
                    : null,
              ),
            ),
          ],
        ),
      );

      await tester.enterText(
        find.byType(TextFormField).at(0),
        'new@example.com',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'password123');
      await tester.enterText(find.byType(TextFormField).at(2), 'password123');
      await tester.tap(find.byIcon(Icons.person_add_alt_1));
      await tester.pumpAndSettle();

      expect(find.text('Verify your email'), findsOneWidget);
      expect(find.textContaining('already sent recently'), findsOneWidget);
    });
  });
}

Widget _buildHarness({
  required String initialLocation,
  required AuthService authService,
  required List<RouteBase> routes,
}) {
  final router = GoRouter(initialLocation: initialLocation, routes: routes);

  return ProviderScope(
    overrides: [authServiceProvider.overrideWithValue(authService)],
    child: MaterialApp.router(routerConfig: router),
  );
}

class _FakeAuthService implements AuthService {
  _FakeAuthService({this.registerResult, this.registerError, this.loginError});

  final AuthSession? registerResult;
  final Object? registerError;
  final Object? loginError;

  @override
  Future<AuthSession?> getCurrentSession() async => null;

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final error = loginError;
    if (error != null) {
      throw error;
    }
    return AuthSession(userId: '2', email: email, emailVerified: true);
  }

  @override
  Future<void> logout() async {}

  @override
  Future<AuthSession> register({
    required String email,
    required String password,
  }) async {
    final error = registerError;
    if (error != null) {
      throw error;
    }
    return registerResult ??
        AuthSession(userId: '1', email: email, emailVerified: true);
  }

  @override
  Future<void> requestPasswordReset({required String email}) async {}

  @override
  Future<void> resendVerificationEmail({required String email}) async {}

  @override
  Future<void> updatePassword({required String newPassword}) async {}
}
