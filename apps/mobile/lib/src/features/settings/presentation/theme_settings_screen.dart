import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/scripture_app_preference_provider.dart';
import '../data/theme_preference_provider.dart';
import '../domain/scripture_app_preference.dart';
import '../domain/theme_preference.dart';

class ThemeSettingsScreen extends ConsumerWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        ],
      ),
    );
  }
}
