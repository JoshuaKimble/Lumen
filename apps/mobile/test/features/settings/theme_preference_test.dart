import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumen/src/features/settings/domain/theme_preference.dart';

void main() {
  test('serializes preferences for storage', () {
    expect(ThemePreference.system.storageValue, 'system');
    expect(ThemePreference.light.storageValue, 'light');
    expect(ThemePreference.dark.storageValue, 'dark');
  });

  test('deserializes valid storage values', () {
    expect(ThemePreference.fromStorageValue('system'), ThemePreference.system);
    expect(ThemePreference.fromStorageValue('light'), ThemePreference.light);
    expect(ThemePreference.fromStorageValue('dark'), ThemePreference.dark);
  });

  test('falls back to system for invalid storage values', () {
    expect(ThemePreference.fromStorageValue(null), ThemePreference.system);
    expect(ThemePreference.fromStorageValue('unknown'), ThemePreference.system);
  });

  test('maps to ThemeMode values', () {
    expect(ThemePreference.system.themeMode, ThemeMode.system);
    expect(ThemePreference.light.themeMode, ThemeMode.light);
    expect(ThemePreference.dark.themeMode, ThemeMode.dark);
  });
}
