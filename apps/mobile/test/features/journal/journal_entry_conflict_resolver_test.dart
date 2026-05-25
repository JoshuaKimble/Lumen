import 'package:flutter_test/flutter_test.dart';
import 'package:lumen/src/features/journal/domain/entry_source.dart';
import 'package:lumen/src/features/journal/domain/journal_entry.dart';
import 'package:lumen/src/features/journal/domain/journal_entry_conflict_resolution.dart';
import 'package:lumen/src/features/journal/domain/journal_entry_conflict_resolver.dart';
import 'package:lumen/src/features/journal/domain/journal_entry_sync_snapshot.dart';
import 'package:lumen/src/features/journal/domain/journal_theme.dart';

void main() {
  const resolver = JournalEntryConflictResolver();

  test('prefers the newer rewrite when original text matches', () {
    final local = _snapshot(
      rewrittenText: 'Local rewrite',
      title: 'Local title',
      clientUpdatedAt: DateTime.utc(2026, 5, 25, 20, 0),
      version: 2,
    );
    final cloud = _snapshot(
      rewrittenText: 'Cloud rewrite',
      title: 'Cloud title',
      clientUpdatedAt: DateTime.utc(2026, 5, 25, 21, 0),
      version: 3,
    );

    final result = resolver.resolve(local: local, cloud: cloud);

    expect(result.outcome, JournalEntryMergeOutcome.cloudApplied);
    expect(result.requiresRewriteRegeneration, isFalse);
    expect(result.entry.rewrittenText, 'Cloud rewrite');
    expect(result.entry.title, 'Cloud title');
    expect(result.preservedOriginalText, isNull);
    expect(result.preservedRewrittenText, 'Local rewrite');
  });

  test(
    'marks rewrite stale when original text diverges but AI state matches',
    () {
      final local = _snapshot(
        originalText: 'Local original',
        rewrittenText: 'Shared rewrite',
        clientUpdatedAt: DateTime.utc(2026, 5, 25, 22, 0),
        version: 5,
      );
      final cloud = _snapshot(
        originalText: 'Cloud original',
        rewrittenText: 'Shared rewrite',
        clientUpdatedAt: DateTime.utc(2026, 5, 25, 21, 0),
        version: 4,
      );

      final result = resolver.resolve(local: local, cloud: cloud);

      expect(result.outcome, JournalEntryMergeOutcome.rewriteStale);
      expect(result.requiresRewriteRegeneration, isTrue);
      expect(result.entry.originalText, 'Local original');
      expect(result.entry.rewrittenText, isEmpty);
      expect(result.entry.themes, isEmpty);
      expect(result.entry.resources, isEmpty);
      expect(result.preservedOriginalText, 'Cloud original');
      expect(result.preservedRewrittenText, 'Shared rewrite');
    },
  );

  test(
    'escalates to manual conflict when original and rewrite both diverge',
    () {
      final local = _snapshot(
        originalText: 'Local original',
        rewrittenText: 'Local rewrite',
        themes: const [
          JournalTheme(id: 'faith', name: 'faith', displayName: 'Faith'),
        ],
        clientUpdatedAt: DateTime.utc(2026, 5, 25, 22, 0),
        version: 7,
      );
      final cloud = _snapshot(
        originalText: 'Cloud original',
        rewrittenText: 'Cloud rewrite',
        clientUpdatedAt: DateTime.utc(2026, 5, 25, 21, 0),
        version: 6,
      );

      final result = resolver.resolve(local: local, cloud: cloud);

      expect(result.outcome, JournalEntryMergeOutcome.manualConflict);
      expect(result.requiresManualReview, isTrue);
      expect(result.requiresRewriteRegeneration, isTrue);
      expect(result.entry.originalText, 'Local original');
      expect(result.entry.rewrittenText, isEmpty);
      expect(result.preservedOriginalText, 'Cloud original');
      expect(result.preservedRewrittenText, 'Cloud rewrite');
    },
  );

  test(
    'breaks equal timestamps by version, then prefers local deterministically',
    () {
      final sharedTime = DateTime.utc(2026, 5, 25, 22, 0);
      final local = _snapshot(
        rewrittenText: 'Local rewrite',
        clientUpdatedAt: sharedTime,
        version: 3,
      );
      final cloud = _snapshot(
        rewrittenText: 'Cloud rewrite',
        clientUpdatedAt: sharedTime,
        version: 3,
      );

      final result = resolver.resolve(local: local, cloud: cloud);

      expect(result.outcome, JournalEntryMergeOutcome.localApplied);
      expect(result.entry.rewrittenText, 'Local rewrite');
    },
  );
}

JournalEntrySyncSnapshot _snapshot({
  String originalText = 'Original text',
  String rewrittenText = 'Rewritten text',
  String? title = 'A title',
  List<JournalTheme> themes = const [],
  required DateTime clientUpdatedAt,
  required int version,
}) {
  final updatedAt = DateTime.utc(2026, 5, 25, 19, 0);

  return JournalEntrySyncSnapshot(
    entry: JournalEntry(
      id: 'entry-1',
      createdAt: DateTime.utc(2026, 5, 20, 19, 0),
      updatedAt: updatedAt,
      source: EntrySource.text,
      originalText: originalText,
      rewrittenText: rewrittenText,
      themes: themes,
      resources: const [],
      title: title,
      summary: 'Summary',
      lastRegeneratedAt: DateTime.utc(2026, 5, 24, 19, 0),
    ),
    clientUpdatedAt: clientUpdatedAt,
    version: version,
  );
}
