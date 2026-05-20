enum ProfileFailureCode { missingEmail, hydrationFailed }

class ProfileFailure implements Exception {
  const ProfileFailure({required this.code, required this.message});

  final ProfileFailureCode code;
  final String message;

  @override
  String toString() => 'ProfileFailure(code: $code, message: $message)';
}
