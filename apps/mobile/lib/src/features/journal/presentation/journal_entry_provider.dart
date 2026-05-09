import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/journal_repository_provider.dart';
import '../domain/journal_entry.dart';

final journalEntryProvider = FutureProvider.family<JournalEntry?, String>((
  ref,
  entryId,
) {
  return ref.watch(journalRepositoryProvider).getEntry(entryId);
});
