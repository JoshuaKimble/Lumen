import 'journal_entry.dart';
import 'journal_entry_conflict_resolution.dart';
import 'journal_entry_sync_snapshot.dart';
import 'journal_theme.dart';
import 'related_resource.dart';

class JournalEntryConflictResolver {
  const JournalEntryConflictResolver();

  JournalEntryConflictResolution resolve({
    required JournalEntrySyncSnapshot local,
    required JournalEntrySyncSnapshot cloud,
  }) {
    final winningSnapshot = _pickWinningSnapshot(local: local, cloud: cloud);
    final losingSnapshot = identical(winningSnapshot, local) ? cloud : local;
    final winningOutcome = identical(winningSnapshot, local)
        ? JournalEntryMergeOutcome.localApplied
        : JournalEntryMergeOutcome.cloudApplied;

    final originalConflict =
        local.entry.originalText != cloud.entry.originalText ||
        local.entry.source != cloud.entry.source;
    final rewriteConflict = _hasRewriteConflict(local.entry, cloud.entry);

    if (!originalConflict && !rewriteConflict) {
      return JournalEntryConflictResolution(
        entry: winningSnapshot.entry,
        clientUpdatedAt: winningSnapshot.clientUpdatedAt,
        version: winningSnapshot.version,
        outcome: winningOutcome,
        requiresRewriteRegeneration: false,
      );
    }

    if (!originalConflict && rewriteConflict) {
      return JournalEntryConflictResolution(
        entry: winningSnapshot.entry,
        clientUpdatedAt: winningSnapshot.clientUpdatedAt,
        version: winningSnapshot.version,
        outcome: winningOutcome,
        requiresRewriteRegeneration: false,
        preservedRewrittenText: _preservedRewrittenText(losingSnapshot.entry),
      );
    }

    final sanitizedEntry = _clearDerivedAiState(
      winningSnapshot.entry,
      updatedAt:
          winningSnapshot.entry.updatedAt.isAfter(
            losingSnapshot.entry.updatedAt,
          )
          ? winningSnapshot.entry.updatedAt
          : losingSnapshot.entry.updatedAt,
    );

    return JournalEntryConflictResolution(
      entry: sanitizedEntry,
      clientUpdatedAt: winningSnapshot.clientUpdatedAt,
      version: winningSnapshot.version,
      outcome: rewriteConflict
          ? JournalEntryMergeOutcome.manualConflict
          : JournalEntryMergeOutcome.rewriteStale,
      requiresRewriteRegeneration: true,
      preservedOriginalText: losingSnapshot.entry.originalText,
      preservedRewrittenText: _preservedRewrittenText(losingSnapshot.entry),
    );
  }

  JournalEntrySyncSnapshot _pickWinningSnapshot({
    required JournalEntrySyncSnapshot local,
    required JournalEntrySyncSnapshot cloud,
  }) {
    final updatedAtComparison = local.clientUpdatedAt.compareTo(
      cloud.clientUpdatedAt,
    );
    if (updatedAtComparison > 0) {
      return local;
    }
    if (updatedAtComparison < 0) {
      return cloud;
    }

    final versionComparison = local.version.compareTo(cloud.version);
    if (versionComparison > 0) {
      return local;
    }
    if (versionComparison < 0) {
      return cloud;
    }

    return local;
  }

  bool _hasRewriteConflict(JournalEntry left, JournalEntry right) {
    return left.rewrittenText != right.rewrittenText ||
        left.title != right.title ||
        left.summary != right.summary ||
        left.lastRegeneratedAt != right.lastRegeneratedAt ||
        !_sameThemes(left.themes, right.themes) ||
        !_sameResources(left.resources, right.resources);
  }

  JournalEntry _clearDerivedAiState(
    JournalEntry entry, {
    required DateTime updatedAt,
  }) {
    return JournalEntry(
      id: entry.id,
      createdAt: entry.createdAt,
      updatedAt: updatedAt,
      source: entry.source,
      originalText: entry.originalText,
      rewrittenText: '',
      themes: const [],
      resources: const [],
      title: null,
      summary: null,
      lastRegeneratedAt: null,
    );
  }

  String? _preservedRewrittenText(JournalEntry entry) {
    if (entry.rewrittenText.isEmpty) {
      return null;
    }

    return entry.rewrittenText;
  }

  bool _sameThemes(List<JournalTheme> left, List<JournalTheme> right) {
    if (left.length != right.length) {
      return false;
    }

    for (var index = 0; index < left.length; index++) {
      final leftTheme = left[index];
      final rightTheme = right[index];
      if (leftTheme.id != rightTheme.id ||
          leftTheme.name != rightTheme.name ||
          leftTheme.displayName != rightTheme.displayName ||
          leftTheme.weight != rightTheme.weight) {
        return false;
      }
    }

    return true;
  }

  bool _sameResources(List<RelatedResource> left, List<RelatedResource> right) {
    if (left.length != right.length) {
      return false;
    }

    for (var index = 0; index < left.length; index++) {
      final leftResource = left[index];
      final rightResource = right[index];
      if (leftResource.id != rightResource.id ||
          leftResource.title != rightResource.title ||
          leftResource.type != rightResource.type ||
          leftResource.sourceType != rightResource.sourceType ||
          leftResource.matchReason != rightResource.matchReason ||
          leftResource.confidence != rightResource.confidence ||
          leftResource.url != rightResource.url ||
          leftResource.scriptureReference != rightResource.scriptureReference ||
          leftResource.entryId != rightResource.entryId ||
          leftResource.themeId != rightResource.themeId ||
          leftResource.description != rightResource.description) {
        return false;
      }
    }

    return true;
  }
}
