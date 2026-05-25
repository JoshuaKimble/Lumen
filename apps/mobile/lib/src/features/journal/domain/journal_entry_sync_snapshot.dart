import 'package:flutter/foundation.dart';

import 'journal_entry.dart';

@immutable
class JournalEntrySyncSnapshot {
  const JournalEntrySyncSnapshot({
    required this.entry,
    required this.clientUpdatedAt,
    required this.version,
  });

  final JournalEntry entry;
  final DateTime clientUpdatedAt;
  final int version;
}
