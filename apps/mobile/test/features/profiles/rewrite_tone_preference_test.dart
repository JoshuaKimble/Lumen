import 'package:flutter_test/flutter_test.dart';
import 'package:lumen/src/features/profiles/domain/rewrite_tone_preference.dart';

void main() {
  test('serializes rewrite tone preferences for storage', () {
    expect(RewriteTonePreference.balanced.storageValue, 'balanced');
    expect(RewriteTonePreference.gentle.storageValue, 'gentle');
    expect(RewriteTonePreference.encouraging.storageValue, 'encouraging');
    expect(RewriteTonePreference.reflective.storageValue, 'reflective');
  });

  test('deserializes stored rewrite tone values', () {
    expect(
      RewriteTonePreference.fromStorageValue('balanced'),
      RewriteTonePreference.balanced,
    );
    expect(
      RewriteTonePreference.fromStorageValue('gentle'),
      RewriteTonePreference.gentle,
    );
    expect(
      RewriteTonePreference.fromStorageValue('encouraging'),
      RewriteTonePreference.encouraging,
    );
    expect(
      RewriteTonePreference.fromStorageValue('reflective'),
      RewriteTonePreference.reflective,
    );
  });

  test('falls back to balanced for unknown rewrite tone values', () {
    expect(
      RewriteTonePreference.fromStorageValue(null),
      RewriteTonePreference.balanced,
    );
    expect(
      RewriteTonePreference.fromStorageValue('unknown'),
      RewriteTonePreference.balanced,
    );
  });
}
