import 'package:flutter/material.dart';

ThemeData buildLumenTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF3E6C5B),
    brightness: Brightness.light,
  );

  return ThemeData(
    colorScheme: colorScheme,
    useMaterial3: true,
    appBarTheme: AppBarTheme(
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      centerTitle: false,
    ),
  );
}
