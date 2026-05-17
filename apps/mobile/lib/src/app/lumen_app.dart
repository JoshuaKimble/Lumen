import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/settings/data/theme_preference_provider.dart';
import 'router.dart';
import 'theme.dart';

class LumenApp extends ConsumerWidget {
  const LumenApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
