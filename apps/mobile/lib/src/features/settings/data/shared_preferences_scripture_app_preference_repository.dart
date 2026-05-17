import 'package:shared_preferences/shared_preferences.dart';

import '../domain/scripture_app_preference.dart';
import '../domain/scripture_app_preference_repository.dart';

class SharedPreferencesScriptureAppPreferenceRepository
    implements ScriptureAppPreferenceRepository {
  SharedPreferencesScriptureAppPreferenceRepository({
    required this.preferences,
  });

  static const preferenceKey = 'lumen.settings.scripture_app_preference';

  final SharedPreferencesAsync preferences;

  @override
  Future<ScriptureAppPreference> load() async {
    final value = await preferences.getString(preferenceKey);
    return ScriptureAppPreferenceX.fromStorageValue(value);
  }

  @override
  Future<void> save(ScriptureAppPreference preference) {
    return preferences.setString(preferenceKey, preference.storageValue);
  }
}
