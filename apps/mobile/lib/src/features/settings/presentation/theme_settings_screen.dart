import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../auth/data/auth_session_controller.dart';
import '../../profiles/data/current_user_profile_controller.dart';
import '../data/account_deletion_service_provider.dart';
import '../data/scripture_app_preference_provider.dart';
import '../data/theme_preference_provider.dart';
import '../domain/account_deletion_failure.dart';
import '../domain/scripture_app_preference.dart';
import '../domain/theme_preference.dart';

class ThemeSettingsScreen extends ConsumerWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authSession = ref.watch(authSessionControllerProvider).asData?.value;
    final currentProfile = ref
        .watch(currentUserProfileControllerProvider)
        .asData
        ?.value;
    final hasSignedInProfile = authSession != null && currentProfile != null;
    final themePreference = ref.watch(themePreferenceControllerProvider);
    final selectedPreference =
        themePreference.asData?.value ?? ThemePreference.system;
    final scripturePreference = ref.watch(
      scriptureAppPreferenceControllerProvider,
    );
    final selectedScripturePreference =
        scripturePreference.asData?.value ?? ScriptureAppPreference.none;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          if (hasSignedInProfile) ...[
            Text('Profile', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Manage the profile and signed-in preferences that follow your account.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.account_circle_outlined),
                title: Text(currentProfile.displayName ?? 'Complete profile'),
                subtitle: Text(currentProfile.email),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.pushNamed(profileSettingsRouteName),
              ),
            ),
            const SizedBox(height: 28),
          ],
          if (!hasSignedInProfile) ...[
            Text('Theme', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Choose how Lumen appears across your devices.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: SegmentedButton<ThemePreference>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment<ThemePreference>(
                      value: ThemePreference.system,
                      label: Text('System'),
                      icon: Icon(Icons.phone_android_outlined),
                    ),
                    ButtonSegment<ThemePreference>(
                      value: ThemePreference.light,
                      label: Text('Light'),
                      icon: Icon(Icons.light_mode_outlined),
                    ),
                    ButtonSegment<ThemePreference>(
                      value: ThemePreference.dark,
                      label: Text('Dark'),
                      icon: Icon(Icons.dark_mode_outlined),
                    ),
                  ],
                  selected: {selectedPreference},
                  onSelectionChanged: (selection) {
                    final preference = selection.first;
                    ref
                        .read(themePreferenceControllerProvider.notifier)
                        .setPreference(preference);
                  },
                ),
              ),
            ),
            if (themePreference.hasError) ...[
              const SizedBox(height: 12),
              Text(
                'Unable to save theme setting.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: 28),
          ],
          if (!hasSignedInProfile) ...[
            Text(
              'Study resource links',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Choose where scripture-oriented suggestions should open.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: DropdownButtonFormField<ScriptureAppPreference>(
                  initialValue: selectedScripturePreference,
                  decoration: const InputDecoration(
                    labelText: 'Preferred scripture app',
                  ),
                  items: ScriptureAppPreference.values
                      .map(
                        (preference) => DropdownMenuItem(
                          value: preference,
                          child: Text(preference.label),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    ref
                        .read(scriptureAppPreferenceControllerProvider.notifier)
                        .setPreference(value);
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              selectedScripturePreference.helperText,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            if (scripturePreference.hasError) ...[
              const SizedBox(height: 12),
              Text(
                'Unable to save scripture app setting.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: 28),
          ],
          Text('Account', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: Icon(hasSignedInProfile ? Icons.tune : Icons.login),
              title: Text(
                hasSignedInProfile
                    ? 'Signed-in profile active'
                    : 'Sign in or create account',
              ),
              subtitle: Text(
                hasSignedInProfile
                    ? 'Edit profile settings above to update synced preferences.'
                    : 'Authentication setup for cloud sync',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => hasSignedInProfile
                  ? context.pushNamed(profileSettingsRouteName)
                  : context.goNamed(loginRouteName),
            ),
          ),
          if (hasSignedInProfile) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                try {
                  await ref
                      .read(authSessionControllerProvider.notifier)
                      .requestPasswordResetForCurrentUser();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Password reset instructions sent to your email.',
                        ),
                      ),
                    );
                  }
                } catch (_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Unable to send password reset email right now.',
                        ),
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.lock_reset_outlined),
              label: const Text('Send password reset email'),
            ),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: () {
                ref.read(authSessionControllerProvider.notifier).logout();
              },
              icon: const Icon(Icons.logout),
              label: const Text('Sign out'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete account?'),
                    content: const Text(
                      'This permanently deletes your profile, journal data, and account. This action cannot be undone.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Delete account'),
                      ),
                    ],
                  ),
                );

                if (confirmed != true) {
                  return;
                }

                try {
                  await ref
                      .read(accountDeletionServiceProvider)
                      .deleteCurrentAccount();
                  await ref
                      .read(authSessionControllerProvider.notifier)
                      .logout();
                  if (context.mounted) {
                    context.goNamed(loginRouteName);
                  }
                } on AccountDeletionFailure catch (error) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(error.message)));
                  }
                }
              },
              icon: const Icon(Icons.delete_forever_outlined),
              label: const Text('Delete account'),
            ),
          ],
        ],
      ),
    );
  }
}
