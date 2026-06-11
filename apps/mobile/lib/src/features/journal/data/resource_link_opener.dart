import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

abstract class ResourceLinkOpener {
  Future<bool> open(Uri url);
}

class UrlLauncherResourceLinkOpener implements ResourceLinkOpener {
  const UrlLauncherResourceLinkOpener();

  @override
  Future<bool> open(Uri url) async {
    return launchUrl(
      url,
      mode: LaunchMode.platformDefault,
      webOnlyWindowName: kIsWeb ? '_blank' : null,
    );
  }
}
