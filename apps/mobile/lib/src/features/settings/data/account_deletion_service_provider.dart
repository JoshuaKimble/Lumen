import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lumen/src/features/journal/data/lumen_api_client_provider.dart';

import 'account_deletion_service.dart';

final accountDeletionServiceProvider = Provider<AccountDeletionService>((ref) {
  return ApiAccountDeletionService(
    apiClient: ref.watch(lumenApiClientProvider),
  );
});
