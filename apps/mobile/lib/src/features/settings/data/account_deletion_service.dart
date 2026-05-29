import 'package:lumen/src/api/generated/lumen_api_client.dart';

import '../domain/account_deletion_failure.dart';

abstract class AccountDeletionService {
  Future<void> deleteCurrentAccount();
}

class ApiAccountDeletionService implements AccountDeletionService {
  const ApiAccountDeletionService({required LumenApiClient apiClient})
    : _apiClient = apiClient;

  final LumenApiClient _apiClient;

  @override
  Future<void> deleteCurrentAccount() async {
    try {
      await _apiClient.deleteAccount(
        const DeleteAccountRequest(confirmation: 'DELETE'),
      );
    } on LumenApiException catch (error) {
      throw AccountDeletionFailure(
        error.error.message ?? 'Account deletion failed.',
      );
    } catch (_) {
      throw const AccountDeletionFailure(
        'Account deletion failed. Please try again.',
      );
    }
  }
}
