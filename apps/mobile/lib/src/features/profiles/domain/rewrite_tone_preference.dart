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
}
