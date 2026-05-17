import 'package:shared_preferences/shared_preferences.dart';

import '../domain/theme_preference.dart';
import '../domain/theme_preference_repository.dart';

class SharedPreferencesThemePreferenceRepository
    implements ThemePreferenceRepository {
  const SharedPreferencesThemePreferenceRepository({
    required SharedPreferencesAsync preferences,
  }) : _preferences = preferences;

  static const preferenceKey = 'settings.theme_preference.v1';

  final SharedPreferencesAsync _preferences;

  @override
  Future<ThemePreference> load() async {
    final value = await _preferences.getString(preferenceKey);
    return ThemePreference.fromStorageValue(value);
  }

  @override
  Future<void> save(ThemePreference preference) {
    return _preferences.setString(preferenceKey, preference.storageValue);
  }
}
