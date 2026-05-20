import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/data/auth_session_controller.dart';
import '../features/auth/domain/auth_session.dart';
import '../features/auth/presentation/auth_loading_screen.dart';
import '../features/auth/presentation/forgot_password_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/auth/presentation/reset_password_screen.dart';
import '../features/auth/presentation/verify_pending_screen.dart';
import '../features/journal/presentation/journal_entry_detail_screen.dart';
import '../features/journal/presentation/journal_entry_editor_screen.dart';
import '../features/journal/presentation/journal_home_screen.dart';
import '../features/journal/presentation/theme_cloud_screen.dart';
import '../features/journal/presentation/theme_detail_screen.dart';
import '../features/journal/presentation/voice_recording_screen.dart';
import '../features/profiles/data/current_user_profile_controller.dart';
import '../features/profiles/domain/user_profile.dart';
import '../features/profiles/presentation/profile_onboarding_screen.dart';
import '../features/profiles/presentation/profile_settings_screen.dart';
import '../features/settings/presentation/theme_settings_screen.dart';
import 'supabase_config.dart';

const journalHomeRouteName = 'journal-home';
const journalHomeRoutePath = '/';
const journalEntryCreateRouteName = 'journal-entry-create';
const journalEntryCreateRoutePath = '/entries/new';
const journalEntryDetailRouteName = 'journal-entry-detail';
const journalEntryDetailRoutePath = '/entries/:entryId';
const journalEntryEditRouteName = 'journal-entry-edit';
const journalEntryEditRoutePath = '/entries/:entryId/edit';
const themeCloudRouteName = 'theme-cloud';
const themeCloudRoutePath = '/themes';
const themeDetailRouteName = 'theme-detail';
const themeDetailRoutePath = '/themes/:themeId';
const voiceRecordingRouteName = 'voice-recording';
const voiceRecordingRoutePath = '/voice/new';
const settingsRouteName = 'settings';
const settingsRoutePath = '/settings';
const loginRouteName = 'login';
const loginRoutePath = '/auth/login';
const registerRouteName = 'register';
const registerRoutePath = '/auth/register';
const forgotPasswordRouteName = 'forgot-password';
const forgotPasswordRoutePath = '/auth/forgot-password';
const resetPasswordRouteName = 'reset-password';
const resetPasswordRoutePath = '/auth/reset-password';
const verifyPendingRouteName = 'verify-pending';
const verifyPendingRoutePath = '/auth/verify-pending';
const profileOnboardingRouteName = 'profile-onboarding';
const profileOnboardingRoutePath = '/onboarding/profile';
const profileSettingsRouteName = 'profile-settings';
const profileSettingsRoutePath = '/settings/profile';
const authLoadingRouteName = 'auth-loading';
const authLoadingRoutePath = '/auth/loading';
final appInitialLocationProvider = Provider<String>((ref) {
  return journalHomeRoutePath;
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = ValueNotifier<int>(0);
  ref.onDispose(refreshNotifier.dispose);
  ref.listen<AsyncValue<AuthSession?>>(authSessionControllerProvider, (_, __) {
    refreshNotifier.value++;
  });
  ref.listen<AsyncValue<UserProfile?>>(currentUserProfileControllerProvider, (
    _,
    __,
  ) {
    refreshNotifier.value++;
  });

  final supabaseEnabled = ref.watch(supabaseClientConfigProvider).enabled;

  return GoRouter(
    refreshListenable: refreshNotifier,
    initialLocation: ref.watch(appInitialLocationProvider),
    redirect: (context, state) {
      if (!supabaseEnabled) {
        return null;
      }

      final location = state.matchedLocation;
      final isAuthRoute = location.startsWith('/auth');
      final isOnboardingRoute = location == profileOnboardingRoutePath;
      final isProtectedRoute = !isAuthRoute && !isOnboardingRoute;

      final authState = ref.read(authSessionControllerProvider);
      if (authState.isLoading || authState.isRefreshing) {
        if (location != authLoadingRoutePath) {
          return authLoadingRoutePath;
        }
        return null;
      }

      final authSession = authState.asData?.value;
      if (authSession == null) {
        if (isProtectedRoute) {
          return loginRoutePath;
        }
        return null;
      }

      if (!authSession.emailVerified) {
        if (location != verifyPendingRoutePath) {
          return Uri(
            path: verifyPendingRoutePath,
            queryParameters: {'email': authSession.email ?? ''},
          ).toString();
        }
        return null;
      }

      final profileState = ref.read(currentUserProfileControllerProvider);
      if (profileState.isLoading || profileState.isRefreshing) {
        if (location != authLoadingRoutePath) {
          return authLoadingRoutePath;
        }
        return null;
      }

      final profile = profileState.asData?.value;
      if (profile == null) {
        if (location != profileOnboardingRoutePath) {
          return profileOnboardingRoutePath;
        }
        return null;
      }

      if (!profile.onboardingCompleted) {
        if (location != profileOnboardingRoutePath) {
          return profileOnboardingRoutePath;
        }
        return null;
      }

      if (isOnboardingRoute) {
        return journalHomeRoutePath;
      }

      if (isAuthRoute) {
        return journalHomeRoutePath;
      }

      return null;
    },
    routes: [
      GoRoute(
        name: authLoadingRouteName,
        path: authLoadingRoutePath,
        builder: (context, state) => const AuthLoadingScreen(),
      ),
      GoRoute(
        name: loginRouteName,
        path: loginRoutePath,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        name: registerRouteName,
        path: registerRoutePath,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        name: forgotPasswordRouteName,
        path: forgotPasswordRoutePath,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        name: resetPasswordRouteName,
        path: resetPasswordRoutePath,
        builder: (context, state) => const ResetPasswordScreen(),
      ),
      GoRoute(
        name: verifyPendingRouteName,
        path: verifyPendingRoutePath,
        builder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          return VerifyPendingScreen(email: email);
        },
      ),
      GoRoute(
        name: profileOnboardingRouteName,
        path: profileOnboardingRoutePath,
        builder: (context, state) => const ProfileOnboardingScreen(),
      ),
      GoRoute(
        name: profileSettingsRouteName,
        path: profileSettingsRoutePath,
        builder: (context, state) => const ProfileSettingsScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return LumenNavigationScaffold(
            location: state.uri.path,
            child: child,
          );
        },
        routes: [
          GoRoute(
            name: journalHomeRouteName,
            path: journalHomeRoutePath,
            builder: (context, state) => const JournalHomeScreen(),
          ),
          GoRoute(
            name: voiceRecordingRouteName,
            path: voiceRecordingRoutePath,
            builder: (context, state) => const VoiceRecordingScreen(),
          ),
          GoRoute(
            name: themeCloudRouteName,
            path: themeCloudRoutePath,
            builder: (context, state) => const ThemeCloudScreen(),
          ),
          GoRoute(
            name: themeDetailRouteName,
            path: themeDetailRoutePath,
            builder: (context, state) {
              final themeId = state.pathParameters['themeId']!;

              return ThemeDetailScreen(themeId: themeId);
            },
          ),
          GoRoute(
            name: journalEntryCreateRouteName,
            path: journalEntryCreateRoutePath,
            builder: (context, state) => const JournalEntryEditorScreen(),
          ),
          GoRoute(
            name: journalEntryDetailRouteName,
            path: journalEntryDetailRoutePath,
            builder: (context, state) {
              final entryId = state.pathParameters['entryId']!;

              return JournalEntryDetailScreen(entryId: entryId);
            },
          ),
          GoRoute(
            name: journalEntryEditRouteName,
            path: journalEntryEditRoutePath,
            builder: (context, state) {
              final entryId = state.pathParameters['entryId']!;

              return JournalEntryEditorScreen(entryId: entryId);
            },
          ),
          GoRoute(
            name: settingsRouteName,
            path: settingsRoutePath,
            builder: (context, state) => const ThemeSettingsScreen(),
          ),
        ],
      ),
    ],
  );
});

class LumenNavigationScaffold extends StatelessWidget {
  const LumenNavigationScaffold({
    required this.location,
    required this.child,
    super.key,
  });

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          final routeName = switch (index) {
            0 => journalHomeRouteName,
            1 => themeCloudRouteName,
            2 => voiceRecordingRouteName,
            3 => settingsRouteName,
            _ => journalHomeRouteName,
          };
          final routePath = switch (index) {
            0 => journalHomeRoutePath,
            1 => themeCloudRoutePath,
            2 => voiceRecordingRoutePath,
            3 => settingsRoutePath,
            _ => journalHomeRoutePath,
          };

          if (location == routePath) {
            return;
          }

          context.goNamed(routeName);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.book_outlined),
            selectedIcon: Icon(Icons.book),
            label: 'Journal',
          ),
          NavigationDestination(
            icon: Icon(Icons.bubble_chart_outlined),
            selectedIcon: Icon(Icons.bubble_chart),
            label: 'Themes',
          ),
          NavigationDestination(
            icon: Icon(Icons.mic_none_outlined),
            selectedIcon: Icon(Icons.mic),
            label: 'Voice',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  int get _selectedIndex {
    if (location == voiceRecordingRoutePath) {
      return 2;
    }

    if (location == settingsRoutePath) {
      return 3;
    }

    if (location == themeCloudRoutePath) {
      return 1;
    }

    return 0;
  }
}
