import 'package:url_launcher/url_launcher.dart';

abstract class ResourceLinkOpener {
  Future<bool> open(Uri url);
}

class UrlLauncherResourceLinkOpener implements ResourceLinkOpener {
  const UrlLauncherResourceLinkOpener();

  @override
  Future<bool> open(Uri url) async {
    if (!await canLaunchUrl(url)) {
      return false;
    }

    return launchUrl(url, mode: LaunchMode.externalApplication);
  }
}
