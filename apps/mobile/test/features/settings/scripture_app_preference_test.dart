import 'package:flutter_test/flutter_test.dart';
import 'package:lumen/src/features/settings/domain/scripture_app_preference.dart';

void main() {
  test('serializes scripture app preference for storage', () {
    expect(ScriptureAppPreference.none.storageValue, 'none');
    expect(ScriptureAppPreference.gospelLibrary.storageValue, 'gospel_library');
    expect(ScriptureAppPreference.youVersion.storageValue, 'you_version');
    expect(ScriptureAppPreference.bibleGateway.storageValue, 'bible_gateway');
    expect(ScriptureAppPreference.catholic.storageValue, 'catholic');
  });

  test('deserializes stored scripture app preference values', () {
    expect(
      ScriptureAppPreferenceX.fromStorageValue('gospel_library'),
      ScriptureAppPreference.gospelLibrary,
    );
    expect(
      ScriptureAppPreferenceX.fromStorageValue('you_version'),
      ScriptureAppPreference.youVersion,
    );
    expect(
      ScriptureAppPreferenceX.fromStorageValue('bible_gateway'),
      ScriptureAppPreference.bibleGateway,
    );
    expect(
      ScriptureAppPreferenceX.fromStorageValue('catholic'),
      ScriptureAppPreference.catholic,
    );
  });

  test('falls back to none for unknown preference values', () {
    expect(
      ScriptureAppPreferenceX.fromStorageValue(null),
      ScriptureAppPreference.none,
    );
    expect(
      ScriptureAppPreferenceX.fromStorageValue('unknown'),
      ScriptureAppPreference.none,
    );
  });
}
