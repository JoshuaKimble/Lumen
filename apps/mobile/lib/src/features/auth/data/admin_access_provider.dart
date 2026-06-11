import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_session_controller.dart';

const _adminEmails = {'joshuakimble@gmail.com'};

final isCurrentUserAdminProvider = Provider<bool>((ref) {
  final email = ref.watch(
    authSessionControllerProvider.select((value) => value.asData?.value?.email),
  );
  if (email == null) {
    return false;
  }

  return _adminEmails.contains(email.trim().toLowerCase());
});
