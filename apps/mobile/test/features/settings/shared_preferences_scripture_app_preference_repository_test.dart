import 'package:flutter_test/flutter_test.dart';
import 'package:lumen/src/features/settings/data/shared_preferences_scripture_app_preference_repository.dart';
import 'package:lumen/src/features/settings/domain/scripture_app_preference.dart';
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

  test('defaults to none when no preference is stored', () async {
    final repository = _repository();

    expect(await repository.load(), ScriptureAppPreference.none);
  });

  test('persists and reloads each scripture app preference', () async {
    final repository = _repository();

    await repository.save(ScriptureAppPreference.gospelLibrary);
    expect(await repository.load(), ScriptureAppPreference.gospelLibrary);

    await repository.save(ScriptureAppPreference.youVersion);
    expect(await repository.load(), ScriptureAppPreference.youVersion);

    await repository.save(ScriptureAppPreference.bibleGateway);
    expect(await repository.load(), ScriptureAppPreference.bibleGateway);

    await repository.save(ScriptureAppPreference.catholic);
    expect(await repository.load(), ScriptureAppPreference.catholic);
  });

  test('falls back to none for invalid stored values', () async {
    final preferences = SharedPreferencesAsync();
    await preferences.setString(
      SharedPreferencesScriptureAppPreferenceRepository.preferenceKey,
      'invalid',
    );
    final repository = SharedPreferencesScriptureAppPreferenceRepository(
      preferences: preferences,
    );

    expect(await repository.load(), ScriptureAppPreference.none);
  });
}

SharedPreferencesScriptureAppPreferenceRepository _repository() {
  return SharedPreferencesScriptureAppPreferenceRepository(
    preferences: SharedPreferencesAsync(),
  );
}
