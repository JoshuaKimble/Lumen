import 'scripture_app_preference.dart';

abstract class ScriptureAppPreferenceRepository {
  Future<ScriptureAppPreference> load();

  Future<void> save(ScriptureAppPreference preference);
}
