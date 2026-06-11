import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumen/src/app/supabase_config.dart';
import 'package:lumen/src/features/auth/data/current_user_capabilities_controller.dart';
import 'package:lumen/src/features/auth/data/user_capabilities_service_provider.dart';
import 'package:lumen/src/features/auth/domain/auth_session.dart';
import 'package:lumen/src/features/auth/domain/user_capabilities.dart';
import 'package:lumen/src/features/auth/domain/user_capabilities_service.dart';

void main() {
  group('CurrentUserCapabilitiesController', () {
    test('hydrates capabilities for signed-in session', () async {
      final container = ProviderContainer(
        overrides: [
          supabaseClientConfigProvider.overrideWithValue(
            const SupabaseClientConfig(
              enabled: true,
              url: 'https://example.supabase.co',
              publishableKey: 'sb_publishable_example',
            ),
          ),
          userCapabilitiesServiceProvider.overrideWithValue(
            const _FakeUserCapabilitiesService(
              capabilities: UserCapabilities(isAdmin: true),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(currentUserCapabilitiesControllerProvider.future);
      final returned = await container
          .read(currentUserCapabilitiesControllerProvider.notifier)
          .hydrateForSession(_sampleSession());

      expect(returned, const UserCapabilities(isAdmin: true));
      expect(
        container.read(currentUserCapabilitiesControllerProvider).value,
        const UserCapabilities(isAdmin: true),
      );
    });

    test('clears capabilities when session is removed', () async {
      final container = ProviderContainer(
        overrides: [
          supabaseClientConfigProvider.overrideWithValue(
            const SupabaseClientConfig(
              enabled: true,
              url: 'https://example.supabase.co',
              publishableKey: 'sb_publishable_example',
            ),
          ),
          userCapabilitiesServiceProvider.overrideWithValue(
            const _FakeUserCapabilitiesService(
              capabilities: UserCapabilities(isAdmin: true),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(currentUserCapabilitiesControllerProvider.future);
      await container
          .read(currentUserCapabilitiesControllerProvider.notifier)
          .hydrateForSession(_sampleSession());
      await container
          .read(currentUserCapabilitiesControllerProvider.notifier)
          .hydrateForSession(null);

      expect(
        container.read(currentUserCapabilitiesControllerProvider).value,
        UserCapabilities.none,
      );
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

class _FakeUserCapabilitiesService implements UserCapabilitiesService {
  const _FakeUserCapabilitiesService({required this.capabilities});

  final UserCapabilities capabilities;

  @override
  Future<UserCapabilities> getForSession(AuthSession session) async {
    return capabilities;
  }
}
