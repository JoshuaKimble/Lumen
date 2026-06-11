import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'current_user_capabilities_controller.dart';

final isCurrentUserAdminProvider = Provider<bool>((ref) {
  return ref.watch(
    currentUserCapabilitiesControllerProvider.select(
      (value) => value.asData?.value.isAdmin ?? false,
    ),
  );
});
