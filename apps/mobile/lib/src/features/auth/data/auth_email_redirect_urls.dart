class AuthEmailRedirectUrls {
  const AuthEmailRedirectUrls({this.emailConfirmation, this.passwordReset});

  factory AuthEmailRedirectUrls.forCurrentOrigin(Uri currentUri) {
    if (!_isHttpOrigin(currentUri)) {
      return const AuthEmailRedirectUrls();
    }

    final origin = Uri(
      scheme: currentUri.scheme,
      host: currentUri.host,
      port: currentUri.hasPort ? currentUri.port : null,
    );

    return AuthEmailRedirectUrls(
      emailConfirmation: origin.resolve('/auth/login').toString(),
      passwordReset: origin.resolve('/auth/reset-password').toString(),
    );
  }

  final String? emailConfirmation;
  final String? passwordReset;

  static bool _isHttpOrigin(Uri uri) {
    return uri.scheme == 'http' || uri.scheme == 'https';
  }
}
