import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_session_controller.dart';
import '../../auth/presentation/auth_error_notice.dart';
import '../../auth/presentation/auth_form_scaffold.dart';
import '../../settings/data/scripture_app_preference_provider.dart';
import '../../settings/data/theme_preference_provider.dart';
import '../../settings/domain/scripture_app_preference.dart';
import '../../settings/domain/theme_preference.dart';
import '../data/current_user_profile_controller.dart';
import '../domain/profile_failure.dart';
import '../domain/rewrite_tone_preference.dart';
import '../domain/user_profile.dart';

class ProfileOnboardingScreen extends ConsumerStatefulWidget {
  const ProfileOnboardingScreen({super.key});

  @override
  ConsumerState<ProfileOnboardingScreen> createState() =>
      _ProfileOnboardingScreenState();
}

class _ProfileOnboardingScreenState
    extends ConsumerState<ProfileOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  var _didSeedForm = false;
  var _isSubmitting = false;
  String? _errorText;
  RewriteTonePreference _rewriteTone = RewriteTonePreference.balanced;
  var _preserveVoice = true;
  var _preferredScriptureApp = ScriptureAppPreference.none;
  var _themePreference = ThemePreference.system;

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(currentUserProfileControllerProvider);
    final profile = profileState.asData?.value;

    if (profile == null) {
      if (profileState.isLoading) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }

      return AuthFormScaffold(
        title: 'Finish your profile',
        subtitle: 'We need your profile before we can continue into the app.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthErrorNotice(
              message:
                  'Unable to load your profile right now. Retry, or sign out and back in if the problem continues.',
              onRetry: _retryHydration,
            ),
          ],
        ),
      );
    }

    if (!_didSeedForm) {
      _seedForm(profile);
    }

    return AuthFormScaffold(
      title: 'Finish your profile',
      subtitle:
          'Complete your profile so Lumen can keep your onboarding state and preferences in sync across signed-in sessions.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Step 1 of 1',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _displayNameController,
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
              initialValue: _rewriteTone,
              decoration: const InputDecoration(labelText: 'Rewrite tone'),
              items: RewriteTonePreference.values
                  .map(
                    (preference) => DropdownMenuItem(
                      value: preference,
                      child: Text(preference.label),
                    ),
                  )
                  .toList(growable: false),
              onChanged: _isSubmitting
                  ? null
                  : (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() {
                        _rewriteTone = value;
                      });
                    },
            ),
            const SizedBox(height: 8),
            Text(
              _rewriteTone.helperText,
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
              value: _preserveVoice,
              onChanged: _isSubmitting
                  ? null
                  : (value) {
                      setState(() {
                        _preserveVoice = value;
                      });
                    },
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<ScriptureAppPreference>(
              initialValue: _preferredScriptureApp,
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
              onChanged: _isSubmitting
                  ? null
                  : (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() {
                        _preferredScriptureApp = value;
                      });
                    },
            ),
            const SizedBox(height: 8),
            Text(
              _preferredScriptureApp.helperText,
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
              selected: {_themePreference},
              onSelectionChanged: _isSubmitting
                  ? null
                  : (selection) {
                      setState(() {
                        _themePreference = selection.first;
                      });
                    },
            ),
            if (_errorText != null)
              AuthErrorNotice(message: _errorText!, onRetry: _submit),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _isSubmitting ? null : _submit,
              icon: _isSubmitting
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.arrow_forward),
              label: const Text('Continue to app'),
            ),
          ],
        ),
      ),
    );
  }

  void _seedForm(UserProfile profile) {
    _displayNameController.text = profile.displayName ?? '';
    _rewriteTone = profile.rewriteTone;
    _preserveVoice = profile.preserveVoice;
    _preferredScriptureApp = profile.preferredScriptureApp;
    _themePreference = profile.themePreference;
    _didSeedForm = true;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final currentProfile = ref.read(currentUserProfileControllerProvider).value;
    if (currentProfile == null) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    final updatedProfile = currentProfile.copyWith(
      displayName: () => _displayNameController.text.trim(),
      rewriteTone: _rewriteTone,
      preserveVoice: _preserveVoice,
      preferredScriptureApp: _preferredScriptureApp,
      themePreference: _themePreference,
      onboardingCompleted: true,
    );

    try {
      await ref
          .read(currentUserProfileControllerProvider.notifier)
          .saveProfile(updatedProfile);
      await ref
          .read(themePreferenceControllerProvider.notifier)
          .setPreference(_themePreference);
      await ref
          .read(scriptureAppPreferenceControllerProvider.notifier)
          .setPreference(_preferredScriptureApp);
    } on ProfileFailure catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorText = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorText = 'Unable to complete profile setup right now.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _retryHydration() async {
    final session = ref.read(authSessionControllerProvider).value;
    if (session == null) {
      return;
    }

    try {
      await ref
          .read(currentUserProfileControllerProvider.notifier)
          .hydrateForSession(session);
    } catch (_) {}
  }
}
