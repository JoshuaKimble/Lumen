enum ScriptureAppPreference {
  none,
  gospelLibrary,
  youVersion,
  bibleGateway,
  catholic,
}

extension ScriptureAppPreferenceX on ScriptureAppPreference {
  String get storageValue => switch (this) {
    ScriptureAppPreference.none => 'none',
    ScriptureAppPreference.gospelLibrary => 'gospel_library',
    ScriptureAppPreference.youVersion => 'you_version',
    ScriptureAppPreference.bibleGateway => 'bible_gateway',
    ScriptureAppPreference.catholic => 'catholic',
  };

  String get label => switch (this) {
    ScriptureAppPreference.none => 'No preference',
    ScriptureAppPreference.gospelLibrary => 'Gospel Library (LDS)',
    ScriptureAppPreference.youVersion => 'YouVersion Bible',
    ScriptureAppPreference.bibleGateway => 'Bible Gateway',
    ScriptureAppPreference.catholic => 'Catholic study',
  };

  String get helperText => switch (this) {
    ScriptureAppPreference.none => 'Use resource links exactly as provided.',
    ScriptureAppPreference.gospelLibrary =>
      'Prefer Church of Jesus Christ study links when available.',
    ScriptureAppPreference.youVersion =>
      'Prefer Protestant-friendly YouVersion routing.',
    ScriptureAppPreference.bibleGateway =>
      'Prefer Bible Gateway routing for references and passages.',
    ScriptureAppPreference.catholic =>
      'Prefer Catholic-friendly resources (USCCB/Vatican fallbacks).',
  };

  static ScriptureAppPreference fromStorageValue(String? value) {
    return switch (value) {
      'none' => ScriptureAppPreference.none,
      'gospel_library' => ScriptureAppPreference.gospelLibrary,
      'you_version' => ScriptureAppPreference.youVersion,
      'bible_gateway' => ScriptureAppPreference.bibleGateway,
      'catholic' => ScriptureAppPreference.catholic,
      _ => ScriptureAppPreference.none,
    };
  }
}
