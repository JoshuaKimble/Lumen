enum AuthFailureCode {
  invalidCredentials,
  emailAlreadyRegistered,
  emailNotVerified,
  rateLimited,
  weakPassword,
  expiredOrInvalidLink,
  networkUnavailable,
  unknown,
}

class AuthFailure implements Exception {
  const AuthFailure({required this.code, required this.message});

  final AuthFailureCode code;
  final String message;

  @override
  String toString() => 'AuthFailure(code: $code, message: $message)';
}
