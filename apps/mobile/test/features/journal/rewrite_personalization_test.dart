import 'package:flutter_test/flutter_test.dart';
import 'package:lumen/src/features/journal/domain/rewrite_personalization.dart';
import 'package:lumen/src/features/profiles/domain/rewrite_tone_preference.dart';

void main() {
  test('defines explicit rewrite personalization defaults', () {
    expect(
      RewritePersonalization.defaults,
      const RewritePersonalization(
        rewriteTone: RewriteTonePreference.balanced,
        preserveVoice: true,
      ),
    );
  });

  test('serializes rewrite personalization for the API contract', () {
    const personalization = RewritePersonalization(
      rewriteTone: RewriteTonePreference.encouraging,
      preserveVoice: false,
    );

    expect(personalization.toApiJson(), {
      'rewriteTone': 'encouraging',
      'preserveVoice': false,
    });
  });
}
