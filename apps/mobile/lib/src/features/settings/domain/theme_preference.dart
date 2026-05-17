import 'package:flutter/material.dart';

enum ThemePreference {
  system,
  light,
  dark;

  String get storageValue {
    return switch (this) {
      ThemePreference.system => 'system',
      ThemePreference.light => 'light',
      ThemePreference.dark => 'dark',
    };
  }

  ThemeMode get themeMode {
    return switch (this) {
      ThemePreference.system => ThemeMode.system,
      ThemePreference.light => ThemeMode.light,
      ThemePreference.dark => ThemeMode.dark,
    };
  }

  static ThemePreference fromStorageValue(String? value) {
    return switch (value) {
      'light' => ThemePreference.light,
      'dark' => ThemePreference.dark,
      _ => ThemePreference.system,
    };
  }
}
