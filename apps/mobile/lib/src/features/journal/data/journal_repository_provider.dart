import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/journal_repository.dart';
import 'hybrid_journal_repository.dart';
import 'shared_preferences_journal_repository.dart';

final journalRepositoryProvider = Provider<JournalRepository>((ref) {
  return HybridJournalRepository(
    localStore: SharedPreferencesJournalRepository(
      preferences: SharedPreferencesAsync(),
    ),
  );
});
