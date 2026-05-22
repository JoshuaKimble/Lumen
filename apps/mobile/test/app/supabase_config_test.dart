import 'package:flutter_test/flutter_test.dart';
import 'package:lumen/src/app/supabase_config.dart';

void main() {
  test('supabase config defaults to disabled when flag is not set', () {
    final config = loadSupabaseClientConfig();

    expect(config.enabled, isFalse);
    expect(config.url, isEmpty);
    expect(config.publishableKey, isEmpty);
  });
}
