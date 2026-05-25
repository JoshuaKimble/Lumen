import 'package:flutter/foundation.dart';

import 'journal_entry.dart';

enum JournalEntryMergeOutcome {
  localApplied,
  cloudApplied,
  rewriteStale,
  manualConflict,
}

@immutable
class JournalEntryConflictResolution {
  const JournalEntryConflictResolution({
    required this.entry,
    required this.clientUpdatedAt,
    required this.version,
    required this.outcome,
    required this.requiresRewriteRegeneration,
    this.preservedOriginalText,
    this.preservedRewrittenText,
  });

  final JournalEntry entry;
  final DateTime clientUpdatedAt;
  final int version;
  final JournalEntryMergeOutcome outcome;
  final bool requiresRewriteRegeneration;
  final String? preservedOriginalText;
  final String? preservedRewrittenText;

  bool get requiresManualReview =>
      outcome == JournalEntryMergeOutcome.manualConflict;
}
