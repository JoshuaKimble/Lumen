import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/theme_summary.dart';
import 'journal_entries_provider.dart';

final themeSummariesProvider = FutureProvider<List<ThemeSummary>>((ref) async {
  final entries = await ref.watch(journalEntriesProvider.future);

  return summarizeThemes(entries);
});
