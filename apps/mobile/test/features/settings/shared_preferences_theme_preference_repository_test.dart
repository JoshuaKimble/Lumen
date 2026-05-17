import 'package:flutter_test/flutter_test.dart';
import 'package:lumen/src/features/settings/data/shared_preferences_theme_preference_repository.dart';
import 'package:lumen/src/features/settings/domain/theme_preference.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  tearDown(() {
    SharedPreferencesAsyncPlatform.instance = null;
  });

  test('defaults to system when no preference is stored', () async {
    final repository = _repository();

    expect(await repository.load(), ThemePreference.system);
  });

  test('persists and reloads each theme preference', () async {
    final repository = _repository();

    await repository.save(ThemePreference.light);
    expect(await repository.load(), ThemePreference.light);

    await repository.save(ThemePreference.dark);
    expect(await repository.load(), ThemePreference.dark);

    await repository.save(ThemePreference.system);
    expect(await repository.load(), ThemePreference.system);
  });

  test('falls back to system for invalid stored values', () async {
    final preferences = SharedPreferencesAsync();
    await preferences.setString(
      SharedPreferencesThemePreferenceRepository.preferenceKey,
      'invalid',
    );
    final repository = SharedPreferencesThemePreferenceRepository(
      preferences: preferences,
    );

    expect(await repository.load(), ThemePreference.system);
  });
}

SharedPreferencesThemePreferenceRepository _repository() {
  return SharedPreferencesThemePreferenceRepository(
    preferences: SharedPreferencesAsync(),
  );
}
