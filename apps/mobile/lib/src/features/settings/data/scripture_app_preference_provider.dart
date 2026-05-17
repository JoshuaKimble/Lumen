import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/scripture_app_preference.dart';
import '../domain/scripture_app_preference_repository.dart';
import 'shared_preferences_scripture_app_preference_repository.dart';

final scriptureAppPreferenceRepositoryProvider =
    Provider<ScriptureAppPreferenceRepository>((ref) {
      return SharedPreferencesScriptureAppPreferenceRepository(
        preferences: SharedPreferencesAsync(),
      );
    });

final scriptureAppPreferenceControllerProvider =
    AsyncNotifierProvider<
      ScriptureAppPreferenceController,
      ScriptureAppPreference
    >(ScriptureAppPreferenceController.new);

class ScriptureAppPreferenceController
    extends AsyncNotifier<ScriptureAppPreference> {
  @override
  Future<ScriptureAppPreference> build() {
    return ref.watch(scriptureAppPreferenceRepositoryProvider).load();
  }

  Future<void> setPreference(ScriptureAppPreference preference) async {
    final previousValue = state.asData?.value ?? ScriptureAppPreference.none;
    state = AsyncData(preference);

    try {
      await ref
          .watch(scriptureAppPreferenceRepositoryProvider)
          .save(preference);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      state = AsyncData(previousValue);
    }
  }
}
