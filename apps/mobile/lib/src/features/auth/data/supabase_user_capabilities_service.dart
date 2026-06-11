import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/auth_session.dart';
import '../domain/user_capabilities.dart';
import '../domain/user_capabilities_service.dart';

typedef UserCapabilitiesRowReader =
    Future<Map<String, Object?>?> Function(String userId);

class SupabaseUserCapabilitiesService implements UserCapabilitiesService {
  SupabaseUserCapabilitiesService({
    SupabaseClient? client,
    UserCapabilitiesRowReader? readRow,
  }) : _client = client,
       _readRow = readRow {
    if (_client == null && _readRow == null) {
      throw ArgumentError(
        'SupabaseUserCapabilitiesService requires a Supabase client or row reader.',
      );
    }
  }

  final SupabaseClient? _client;
  final UserCapabilitiesRowReader? _readRow;

  @override
  Future<UserCapabilities> getForSession(AuthSession session) async {
    final row =
        _readRow != null
            ? await _readRow.call(session.userId)
            : await _client!
                .from('user_capabilities')
                .select('is_admin')
                .eq('user_id', session.userId)
                .maybeSingle();

    final capabilityRow =
        row == null ? null : Map<String, Object?>.from(row as Map);

    if (capabilityRow == null) {
      return UserCapabilities.none;
    }

    return UserCapabilities(isAdmin: capabilityRow['is_admin'] == true);
  }
}
