import 'package:flutter_test/flutter_test.dart';
import 'package:lumen/src/features/journal/domain/ai_results.dart';
import 'package:lumen/src/features/journal/data/journal_entry_json_mapper.dart';
import 'package:lumen/src/features/journal/domain/entry_source.dart';
import 'package:lumen/src/features/journal/domain/journal_entry.dart';
import 'package:lumen/src/features/journal/domain/journal_entry_conflict_resolution.dart';
import 'package:lumen/src/features/journal/domain/journal_entry_conflict_resolver.dart';
import 'package:lumen/src/features/journal/domain/journal_entry_sync_snapshot.dart';
import 'package:lumen/src/features/journal/domain/journal_theme.dart';
import 'package:lumen/src/features/journal/domain/study_guide.dart';

void main() {
  test('preserves study guide across entry-derived AI updates', () {
    final studyGuide = _studyGuide();
    final entry = _entry(studyGuide: studyGuide);

    final updated = entry.applyGeneratedInsights(
      summaryResult: const EntrySummaryResult(summary: 'summary'),
      themeDetection: const ThemeDetectionResult(themes: []),
      updatedAt: DateTime.utc(2026, 6, 11, 18),
    );

    expect(updated.studyGuide, studyGuide);
  });

  test('round trips study guide through journal entry JSON mapping', () {
    final mapper = JournalEntryJsonMapper();
    final entry = _entry(studyGuide: _studyGuide());

    final encoded = mapper.toJson(entry);
    final decoded = mapper.fromJson(encoded);

    expect(decoded.studyGuide, entry.studyGuide);
    expect(decoded.studyGuide?.items, hasLength(2));
    expect(decoded.studyGuide?.reflectionPrompt.text, 'Reflect on this');
  });

  test(
    'retains study guide when conflict resolution clears derived AI state',
    () {
      final resolver = JournalEntryConflictResolver();
      final local = _snapshot(
        studyGuide: _studyGuide(
          id: 'study-guide-local',
          previewText: 'Local preview',
        ),
        clientUpdatedAt: DateTime.utc(2026, 6, 11, 20),
        version: 2,
      );
      final cloud = _snapshot(
        studyGuide: _studyGuide(
          id: 'study-guide-cloud',
          previewText: 'Cloud preview',
        ),
        originalText: 'Cloud original',
        clientUpdatedAt: DateTime.utc(2026, 6, 11, 19),
        version: 1,
      );

      final result = resolver.resolve(local: local, cloud: cloud);

      expect(result.outcome, JournalEntryMergeOutcome.manualConflict);
      expect(result.entry.studyGuide, local.entry.studyGuide);
      expect(result.entry.studyGuide?.previewText, 'Local preview');
      expect(result.requiresRewriteRegeneration, isTrue);
    },
  );
}

StudyGuide _studyGuide({
  String id = 'study-guide-1',
  String previewText = 'Psalm 46:10 and one more resource.',
}) {
  return StudyGuide(
    id: id,
    entryId: 'entry-1',
    providerKey: 'gospel_library',
    generatedAt: DateTime.utc(2026, 6, 11, 12),
    overview: 'A short guide for steady study.',
    previewText: previewText,
    items: [
      StudyGuideItem(
        id: 'item-1',
        kind: 'scripture',
        title: 'Psalm 46:10',
        contextLine: 'This passage calls for stillness and trust.',
        position: 0,
        destination: StudyGuideDestination(
          providerKey: 'gospel_library',
          contentType: 'scripture',
          reference: 'Psalm 46:10',
          precision: StudyGuideDestinationPrecision.chapter,
          url: Uri.parse(
            'https://www.churchofjesuschrist.org/study/scriptures',
          ),
        ),
        focusText: 'Focus on verse 10.',
      ),
      StudyGuideItem(
        id: 'item-2',
        kind: 'conference_talk',
        title: 'Endure Well',
        contextLine: 'A steady discipleship reminder.',
        position: 1,
        destination: StudyGuideDestination(
          providerKey: 'gospel_library',
          contentType: 'conference_talk',
          reference: '2024-10/51uchtdorf',
          precision: StudyGuideDestinationPrecision.document,
          url: Uri.parse(
            'https://www.churchofjesuschrist.org/study/general-conference/2024/10/51uchtdorf?lang=eng',
          ),
        ),
        quote: 'The Lord knows how to rescue the faithful.',
        author: 'Dieter F. Uchtdorf',
        publishedContext: 'October 2024 general conference',
      ),
    ],
    reflectionPrompt: const StudyGuidePrompt(text: 'Reflect on this'),
  );
}

JournalEntry _entry({StudyGuide? studyGuide}) {
  return JournalEntry(
    id: 'entry-1',
    createdAt: DateTime.utc(2026, 6, 11, 12),
    updatedAt: DateTime.utc(2026, 6, 11, 12),
    source: EntrySource.text,
    originalText: 'I need steady faith this week.',
    rewrittenText: 'I need steady faith this week.',
    themes: const [
      JournalTheme(id: 'faith', name: 'faith', displayName: 'Faith'),
    ],
    resources: const [],
    studyGuide: studyGuide,
    title: 'Faith and trust',
    summary: 'summary',
  );
}

JournalEntrySyncSnapshot _snapshot({
  required DateTime clientUpdatedAt,
  required int version,
  StudyGuide? studyGuide,
  String originalText = 'Original text',
}) {
  return JournalEntrySyncSnapshot(
    entry: JournalEntry(
      id: 'entry-1',
      createdAt: DateTime.utc(2026, 6, 11, 12),
      updatedAt: DateTime.utc(2026, 6, 11, 12),
      source: EntrySource.text,
      originalText: originalText,
      rewrittenText: 'Rewrite',
      themes: const [],
      resources: const [],
      studyGuide: studyGuide,
      title: 'Title',
      summary: 'Summary',
      lastRegeneratedAt: DateTime.utc(2026, 6, 11, 13),
    ),
    clientUpdatedAt: clientUpdatedAt,
    version: version,
  );
}
