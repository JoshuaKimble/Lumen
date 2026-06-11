import 'package:flutter_test/flutter_test.dart';
import 'package:lumen/src/features/auth/data/supabase_user_capabilities_service.dart';
import 'package:lumen/src/features/auth/domain/auth_session.dart';
import 'package:lumen/src/features/auth/domain/user_capabilities.dart';

void main() {
  group('SupabaseUserCapabilitiesService', () {
    test('requires a client or row reader', () {
      expect(() => SupabaseUserCapabilitiesService(), throwsArgumentError);
    });

    test('returns none when no capability row exists', () async {
      final service = SupabaseUserCapabilitiesService(
        readRow: (_) async => null,
      );

      final capabilities = await service.getForSession(_sampleSession());

      expect(capabilities, UserCapabilities.none);
    });

    test('returns admin capability from row', () async {
      final service = SupabaseUserCapabilitiesService(
        readRow: (_) async => {'is_admin': true},
      );

      final capabilities = await service.getForSession(_sampleSession());

      expect(capabilities, const UserCapabilities(isAdmin: true));
    });
  });
}

AuthSession _sampleSession() {
  return const AuthSession(
    userId: 'user-1',
    email: 'user@example.com',
    emailVerified: true,
  );
}
