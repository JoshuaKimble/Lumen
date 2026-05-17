import 'theme_preference.dart';

abstract class ThemePreferenceRepository {
  Future<ThemePreference> load();

  Future<void> save(ThemePreference preference);
}
