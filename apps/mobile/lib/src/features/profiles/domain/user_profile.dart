import 'package:flutter/foundation.dart';

import '../../settings/domain/scripture_app_preference.dart';
import '../../settings/domain/theme_preference.dart';
import 'rewrite_tone_preference.dart';

@immutable
class UserProfile {
  const UserProfile({
    required this.id,
    required this.email,
    required this.rewriteTone,
    required this.preserveVoice,
    required this.preferredScriptureApp,
    required this.themePreference,
    required this.onboardingCompleted,
    required this.createdAt,
    required this.updatedAt,
    this.displayName,
  });

  final String id;
  final String email;
  final String? displayName;
  final RewriteTonePreference rewriteTone;
  final bool preserveVoice;
  final ScriptureAppPreference preferredScriptureApp;
  final ThemePreference themePreference;
  final bool onboardingCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile copyWith({
    String? id,
    String? email,
    ValueGetter<String?>? displayName,
    RewriteTonePreference? rewriteTone,
    bool? preserveVoice,
    ScriptureAppPreference? preferredScriptureApp,
    ThemePreference? themePreference,
    bool? onboardingCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName == null ? this.displayName : displayName(),
      rewriteTone: rewriteTone ?? this.rewriteTone,
      preserveVoice: preserveVoice ?? this.preserveVoice,
      preferredScriptureApp:
          preferredScriptureApp ?? this.preferredScriptureApp,
      themePreference: themePreference ?? this.themePreference,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is UserProfile &&
        other.id == id &&
        other.email == email &&
        other.displayName == displayName &&
        other.rewriteTone == rewriteTone &&
        other.preserveVoice == preserveVoice &&
        other.preferredScriptureApp == preferredScriptureApp &&
        other.themePreference == themePreference &&
        other.onboardingCompleted == onboardingCompleted &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode => Object.hash(
    id,
    email,
    displayName,
    rewriteTone,
    preserveVoice,
    preferredScriptureApp,
    themePreference,
    onboardingCompleted,
    createdAt,
    updatedAt,
  );
}
