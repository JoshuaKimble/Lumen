import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/theme_preference_provider.dart';
import '../domain/theme_preference.dart';

class ThemeSettingsScreen extends ConsumerWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themePreference = ref.watch(themePreferenceControllerProvider);
    final selectedPreference =
        themePreference.asData?.value ?? ThemePreference.system;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
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
        ],
      ),
    );
  }
}
