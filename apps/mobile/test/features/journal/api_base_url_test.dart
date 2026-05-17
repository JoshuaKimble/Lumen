import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumen/src/features/journal/data/api_base_url.dart';

void main() {
  test('uses localhost for web', () {
    final url = defaultApiBaseUrlForPlatform(
      platform: TargetPlatform.android,
      isWeb: true,
    );

    expect(url, 'http://127.0.0.1:3000');
  });

  test('uses emulator host loopback for android', () {
    final url = defaultApiBaseUrlForPlatform(
      platform: TargetPlatform.android,
      isWeb: false,
    );

    expect(url, 'http://10.0.2.2:3000');
  });

  test('uses localhost for ios and other native platforms', () {
    final ios = defaultApiBaseUrlForPlatform(
      platform: TargetPlatform.iOS,
      isWeb: false,
    );
    final macos = defaultApiBaseUrlForPlatform(
      platform: TargetPlatform.macOS,
      isWeb: false,
    );

    expect(ios, 'http://127.0.0.1:3000');
    expect(macos, 'http://127.0.0.1:3000');
  });
}
