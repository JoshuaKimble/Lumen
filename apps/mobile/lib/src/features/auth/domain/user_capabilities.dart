import 'package:flutter/foundation.dart';

@immutable
class UserCapabilities {
  const UserCapabilities({required this.isAdmin});

  static const none = UserCapabilities(isAdmin: false);

  final bool isAdmin;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is UserCapabilities && other.isAdmin == isAdmin;
  }

  @override
  int get hashCode => isAdmin.hashCode;
}
