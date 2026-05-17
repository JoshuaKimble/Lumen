import 'package:flutter/foundation.dart';

const _configuredApiBaseUrl = String.fromEnvironment('LUMEN_API_BASE_URL');

String resolveApiBaseUrl() {
  if (_configuredApiBaseUrl.trim().isNotEmpty) {
    return _configuredApiBaseUrl.trim();
  }

  return defaultApiBaseUrlForPlatform(
    platform: defaultTargetPlatform,
    isWeb: kIsWeb,
  );
}

String defaultApiBaseUrlForPlatform({
  required TargetPlatform platform,
  required bool isWeb,
}) {
  if (isWeb) {
    return 'http://127.0.0.1:3000';
  }

  if (platform == TargetPlatform.android) {
    return 'http://10.0.2.2:3000';
  }

  return 'http://127.0.0.1:3000';
}
