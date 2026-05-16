import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/journal_repository_provider.dart';
import '../domain/journal_entry.dart';

final themeEntriesProvider = FutureProvider.family<List<JournalEntry>, String>((
  ref,
  themeId,
) {
  return ref.watch(journalRepositoryProvider).listEntriesByTheme(themeId);
});
