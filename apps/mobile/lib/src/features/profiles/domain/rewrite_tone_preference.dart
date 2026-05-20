enum RewriteTonePreference {
  balanced,
  gentle,
  encouraging,
  reflective;

  String get storageValue {
    return switch (this) {
      RewriteTonePreference.balanced => 'balanced',
      RewriteTonePreference.gentle => 'gentle',
      RewriteTonePreference.encouraging => 'encouraging',
      RewriteTonePreference.reflective => 'reflective',
    };
  }

  static RewriteTonePreference fromStorageValue(String? value) {
    return switch (value) {
      'gentle' => RewriteTonePreference.gentle,
      'encouraging' => RewriteTonePreference.encouraging,
      'reflective' => RewriteTonePreference.reflective,
      _ => RewriteTonePreference.balanced,
    };
  }

  String get label {
    return switch (this) {
      RewriteTonePreference.balanced => 'Balanced',
      RewriteTonePreference.gentle => 'Gentle',
      RewriteTonePreference.encouraging => 'Encouraging',
      RewriteTonePreference.reflective => 'Reflective',
    };
  }

  String get helperText {
    return switch (this) {
      RewriteTonePreference.balanced =>
        'Keep rewrites clear and natural without pushing too soft or too polished.',
      RewriteTonePreference.gentle =>
        'Prefer softer wording when entries feel heavy, tender, or raw.',
      RewriteTonePreference.encouraging =>
        'Lean toward hopeful, steady language without changing your meaning.',
      RewriteTonePreference.reflective =>
        'Favor a slower, thoughtful tone that helps with later reflection.',
    };
  }
}
