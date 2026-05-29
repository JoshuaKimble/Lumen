class AccountDeletionFailure implements Exception {
  const AccountDeletionFailure(this.message);

  final String message;
}
