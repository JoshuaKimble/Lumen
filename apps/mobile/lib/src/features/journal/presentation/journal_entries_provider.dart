import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/journal_repository_provider.dart';
import '../domain/journal_entry.dart';

final journalEntriesProvider = FutureProvider<List<JournalEntry>>((ref) {
  return ref.watch(journalRepositoryProvider).listEntries();
});
