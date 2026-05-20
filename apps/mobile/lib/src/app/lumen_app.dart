import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/profiles/data/current_user_profile_controller.dart';
import '../features/settings/data/scripture_app_preference_provider.dart';
import '../features/settings/data/theme_preference_provider.dart';
import 'router.dart';
import 'theme.dart';

class LumenApp extends ConsumerWidget {
  const LumenApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(currentUserProfileControllerProvider, (_, next) {
      final profile = next.asData?.value;
      if (profile == null) {
        return;
      }

      final currentTheme = ref
          .read(themePreferenceControllerProvider)
          .asData
          ?.value;
      if (currentTheme != profile.themePreference) {
        unawaited(
          ref
              .read(themePreferenceControllerProvider.notifier)
              .setPreference(profile.themePreference),
        );
      }

      final currentScripturePreference = ref
          .read(scriptureAppPreferenceControllerProvider)
          .asData
          ?.value;
      if (currentScripturePreference != profile.preferredScriptureApp) {
        unawaited(
          ref
              .read(scriptureAppPreferenceControllerProvider.notifier)
              .setPreference(profile.preferredScriptureApp),
        );
      }
    });

    final router = ref.watch(appRouterProvider);
    final themePreferenceState = ref.watch(themePreferenceControllerProvider);
    final themeMode =
        themePreferenceState.asData?.value.themeMode ?? ThemeMode.system;

    return MaterialApp.router(
      title: 'Lumen',
      theme: buildLumenLightTheme(),
      darkTheme: buildLumenDarkTheme(),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
