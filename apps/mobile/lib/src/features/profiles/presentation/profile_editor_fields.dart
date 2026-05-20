import 'package:flutter/material.dart';

import '../../settings/domain/scripture_app_preference.dart';
import '../../settings/domain/theme_preference.dart';
import '../domain/rewrite_tone_preference.dart';

class ProfileEditorFields extends StatelessWidget {
  const ProfileEditorFields({
    required this.displayNameController,
    required this.rewriteTone,
    required this.preserveVoice,
    required this.preferredScriptureApp,
    required this.themePreference,
    required this.isSubmitting,
    required this.onRewriteToneChanged,
    required this.onPreserveVoiceChanged,
    required this.onPreferredScriptureAppChanged,
    required this.onThemePreferenceChanged,
    super.key,
  });

  final TextEditingController displayNameController;
  final RewriteTonePreference rewriteTone;
  final bool preserveVoice;
  final ScriptureAppPreference preferredScriptureApp;
  final ThemePreference themePreference;
  final bool isSubmitting;
  final ValueChanged<RewriteTonePreference> onRewriteToneChanged;
  final ValueChanged<bool> onPreserveVoiceChanged;
  final ValueChanged<ScriptureAppPreference> onPreferredScriptureAppChanged;
  final ValueChanged<ThemePreference> onThemePreferenceChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: displayNameController,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Display name',
            hintText: 'How should Lumen address you?',
          ),
          validator: (value) {
            final trimmedValue = value?.trim() ?? '';
            if (trimmedValue.isEmpty) {
              return 'Display name is required.';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        DropdownButtonFormField<RewriteTonePreference>(
          initialValue: rewriteTone,
          decoration: const InputDecoration(labelText: 'Rewrite tone'),
          items: RewriteTonePreference.values
              .map(
                (preference) => DropdownMenuItem(
                  value: preference,
                  child: Text(preference.label),
                ),
              )
              .toList(growable: false),
          onChanged: isSubmitting
              ? null
              : (value) {
                  if (value == null) {
                    return;
                  }
                  onRewriteToneChanged(value);
                },
        ),
        const SizedBox(height: 8),
        Text(
          rewriteTone.helperText,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: const Text('Preserve your original voice'),
          subtitle: const Text(
            'Keep rewrites close to your wording, pace, and personality.',
          ),
          value: preserveVoice,
          onChanged: isSubmitting ? null : onPreserveVoiceChanged,
        ),
        const SizedBox(height: 20),
        DropdownButtonFormField<ScriptureAppPreference>(
          initialValue: preferredScriptureApp,
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
          onChanged: isSubmitting
              ? null
              : (value) {
                  if (value == null) {
                    return;
                  }
                  onPreferredScriptureAppChanged(value);
                },
        ),
        const SizedBox(height: 8),
        Text(
          preferredScriptureApp.helperText,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
        Text('Theme', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        SegmentedButton<ThemePreference>(
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
          selected: {themePreference},
          onSelectionChanged: isSubmitting
              ? null
              : (selection) {
                  onThemePreferenceChanged(selection.first);
                },
        ),
      ],
    );
  }
}
