import 'package:flutter_test/flutter_test.dart';
import 'package:lumen/src/features/journal/data/shared_preferences_journal_repository.dart';
import 'package:lumen/src/features/journal/domain/entry_source.dart';
import 'package:lumen/src/features/journal/domain/journal_entry.dart';
import 'package:lumen/src/features/journal/domain/journal_theme.dart';
import 'package:lumen/src/features/journal/domain/study_guide.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  tearDown(() {
    SharedPreferencesAsyncPlatform.instance = null;
  });

  test('creates, reads, updates, and deletes entries', () async {
    final repository = _repository();
    final originalEntry = _entry(
      id: 'entry-1',
      originalText: 'Original text',
      rewrittenText: 'Rewritten text',
      title: 'Original title',
    );
    final updatedEntry = _entry(
      id: 'entry-1',
      originalText: 'Original text',
      rewrittenText: 'Updated rewrite',
      title: 'Updated title',
    );

    await repository.saveEntry(originalEntry);
    expect((await repository.getEntry('entry-1'))?.title, 'Original title');

    await repository.saveEntry(updatedEntry);
    expect((await repository.getEntry('entry-1'))?.title, 'Updated title');
    expect(await repository.listEntries(), hasLength(1));

    await repository.deleteEntry('entry-1');
    expect(await repository.getEntry('entry-1'), isNull);
    expect(await repository.listEntries(), isEmpty);
  });

  test('lists entries by newest created date first', () async {
    final repository = _repository();

    await repository.saveEntry(
      _entry(id: 'older', createdAt: DateTime.utc(2026, 5, 6)),
    );
    await repository.saveEntry(
      _entry(id: 'newer', createdAt: DateTime.utc(2026, 5, 7)),
    );

    final entries = await repository.listEntries();

    expect(entries.map((entry) => entry.id), ['newer', 'older']);
  });

  test('lists entries by theme', () async {
    final repository = _repository();

    await repository.saveEntry(
      _entry(
        id: 'family-entry',
        themes: const [
          JournalTheme(id: 'family', name: 'family', displayName: 'Family'),
        ],
      ),
    );
    await repository.saveEntry(
      _entry(
        id: 'work-entry',
        themes: const [
          JournalTheme(id: 'work', name: 'work', displayName: 'Work'),
        ],
      ),
    );

    final entries = await repository.listEntriesByTheme('family');

    expect(entries.map((entry) => entry.id), ['family-entry']);
  });

  test('persists entries across repository instances', () async {
    final firstRepository = _repository();

    await firstRepository.saveEntry(_entry(id: 'entry-1'));

    final secondRepository = _repository();

    expect((await secondRepository.getEntry('entry-1'))?.id, 'entry-1');
  });

  test('persists study guides alongside journal entries', () async {
    final repository = _repository();
    final studyGuide = _studyGuide();
    final entry = _entry(id: 'entry-1', studyGuide: studyGuide);

    await repository.saveEntry(entry);

    final loaded = await repository.getEntry('entry-1');

    expect(loaded?.studyGuide, studyGuide);
    expect(loaded?.studyGuide?.items, hasLength(1));
    expect(loaded?.studyGuide?.reflectionPrompt.text, 'Reflect on this');
  });
}

SharedPreferencesJournalRepository _repository() {
  return SharedPreferencesJournalRepository(
    preferences: SharedPreferencesAsync(),
  );
}

JournalEntry _entry({
  required String id,
  DateTime? createdAt,
  String originalText = 'Original text',
  String rewrittenText = 'Rewritten text',
  String? title,
  List<JournalTheme> themes = const [],
  StudyGuide? studyGuide,
}) {
  final timestamp = createdAt ?? DateTime.utc(2026, 5, 7);

  return JournalEntry(
    id: id,
    createdAt: timestamp,
    updatedAt: timestamp,
    source: EntrySource.text,
    originalText: originalText,
    rewrittenText: rewrittenText,
    themes: themes,
    resources: const [],
    studyGuide: studyGuide,
    title: title,
  );
}

StudyGuide _studyGuide() {
  return StudyGuide(
    id: 'study-guide-1',
    entryId: 'entry-1',
    providerKey: 'gospel_library',
    generatedAt: DateTime.utc(2026, 5, 7, 12),
    overview: 'A short guide for steady study.',
    previewText: 'Psalm 46:10 and one more resource.',
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
    ],
    reflectionPrompt: const StudyGuidePrompt(text: 'Reflect on this'),
  );
}
