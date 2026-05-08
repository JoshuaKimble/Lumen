import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/journal_repository.dart';
import 'in_memory_journal_repository.dart';

final journalRepositoryProvider = Provider<JournalRepository>((ref) {
  return const InMemoryJournalRepository();
});
