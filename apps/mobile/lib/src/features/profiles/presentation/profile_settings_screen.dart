import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/presentation/auth_error_notice.dart';
import '../../settings/data/scripture_app_preference_provider.dart';
import '../../settings/data/theme_preference_provider.dart';
import '../../settings/domain/scripture_app_preference.dart';
import '../../settings/domain/theme_preference.dart';
import '../data/current_user_profile_controller.dart';
import '../domain/profile_failure.dart';
import '../domain/rewrite_tone_preference.dart';
import '../domain/user_profile.dart';
import 'profile_editor_fields.dart';

class ProfileSettingsScreen extends ConsumerStatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  ConsumerState<ProfileSettingsScreen> createState() =>
      _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends ConsumerState<ProfileSettingsScreen> {
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
      return Scaffold(
        appBar: AppBar(title: const Text('Profile settings')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (!_didSeedForm) {
      _seedForm(profile);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile settings'),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : () => context.pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                Text(
                  'Update how Lumen addresses you and how your signed-in preferences behave across sessions.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ProfileEditorFields(
                            displayNameController: _displayNameController,
                            rewriteTone: _rewriteTone,
                            preserveVoice: _preserveVoice,
                            preferredScriptureApp: _preferredScriptureApp,
                            themePreference: _themePreference,
                            isSubmitting: _isSubmitting,
                            onRewriteToneChanged: (value) {
                              setState(() {
                                _rewriteTone = value;
                              });
                            },
                            onPreserveVoiceChanged: (value) {
                              setState(() {
                                _preserveVoice = value;
                              });
                            },
                            onPreferredScriptureAppChanged: (value) {
                              setState(() {
                                _preferredScriptureApp = value;
                              });
                            },
                            onThemePreferenceChanged: (value) {
                              setState(() {
                                _themePreference = value;
                              });
                            },
                          ),
                          if (_errorText != null) ...[
                            const SizedBox(height: 16),
                            AuthErrorNotice(
                              message: _errorText!,
                              onRetry: _saveChanges,
                            ),
                          ],
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _isSubmitting
                                      ? null
                                      : () => context.pop(),
                                  child: const Text('Cancel'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: _isSubmitting
                                      ? null
                                      : _saveChanges,
                                  icon: _isSubmitting
                                      ? const SizedBox.square(
                                          dimension: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.save_outlined),
                                  label: const Text('Save changes'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
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

  Future<void> _saveChanges() async {
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
      if (!mounted) {
        return;
      }
      context.pop();
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
        _errorText = 'Unable to save profile settings right now.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}
