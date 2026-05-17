import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/theme_preference.dart';
import '../domain/theme_preference_repository.dart';
import 'shared_preferences_theme_preference_repository.dart';

final themePreferenceRepositoryProvider = Provider<ThemePreferenceRepository>((
  ref,
) {
  return SharedPreferencesThemePreferenceRepository(
    preferences: SharedPreferencesAsync(),
  );
});

final themePreferenceControllerProvider =
    AsyncNotifierProvider<ThemePreferenceController, ThemePreference>(
      ThemePreferenceController.new,
    );

class ThemePreferenceController extends AsyncNotifier<ThemePreference> {
  @override
  Future<ThemePreference> build() {
    return ref.watch(themePreferenceRepositoryProvider).load();
  }

  Future<void> setPreference(ThemePreference preference) async {
    final previousValue = state.asData?.value ?? ThemePreference.system;
    state = AsyncData(preference);

    try {
      await ref.watch(themePreferenceRepositoryProvider).save(preference);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      state = AsyncData(previousValue);
    }
  }
}
