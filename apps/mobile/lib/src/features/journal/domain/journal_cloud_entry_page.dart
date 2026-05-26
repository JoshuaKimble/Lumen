import 'package:flutter/foundation.dart';

import 'journal_entry.dart';

@immutable
class JournalCloudEntryPage {
  const JournalCloudEntryPage({
    required this.entries,
    required this.hasMore,
    this.nextBeforeCreatedAt,
  });

  final List<JournalEntry> entries;
  final bool hasMore;
  final DateTime? nextBeforeCreatedAt;
}
