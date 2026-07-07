import 'package:flutter_test/flutter_test.dart';
import 'package:lumen/src/features/journal/data/mock_journal_ai_service.dart';
import 'package:lumen/src/features/journal/domain/journal_ai_service.dart';
import 'package:lumen/src/features/journal/domain/journal_theme.dart';

void main() {
  test('generates deterministic summary output', () async {
    const service = MockJournalAiService();

    final summary = await service.summarizeEntry(
      originalText: ' Work felt rushed today. ',
    );

    expect(summary.title, 'Work felt rushed today');
    expect(summary.summary, 'Work felt rushed today.');
  });

  test('generates deterministic rewrite output', () async {
    const service = MockJournalAiService();

    final rewrite = await service.rewriteEntry(
      originalText: ' Work felt rushed today. ',
      source: JournalRewriteSource.typedCreate,
    );

    expect(
      rewrite.rewrittenText,
      '[Flutter mock: typed create] I am noticing this more clearly: Work felt rushed today.',
    );
    expect(rewrite.title, 'Work felt rushed today');
    expect(rewrite.summary, 'Work felt rushed today.');
  });

  test('labels mock rewrite output by source flow', () async {
    const service = MockJournalAiService();

    final edit = await service.rewriteEntry(
      originalText: 'Edited thought.',
      source: JournalRewriteSource.typedEditSave,
    );
    final regenerate = await service.rewriteEntry(
      originalText: 'Regenerated thought.',
      source: JournalRewriteSource.regenerate,
    );
    final voice = await service.rewriteEntry(
      originalText: 'Voice thought.',
      source: JournalRewriteSource.voiceSave,
    );

    expect(edit.rewrittenText, startsWith('[Flutter mock: typed edit save]'));
    expect(regenerate.rewrittenText, startsWith('[Flutter mock: regenerate]'));
    expect(voice.rewrittenText, startsWith('[Flutter mock: voice save]'));
  });

  test('detects themes from journal text', () async {
    const service = MockJournalAiService();

    final result = await service.detectThemes(
      text: 'I felt rushed after a family meeting at work.',
    );

    expect(
      result.themes.map((theme) => theme.displayName),
      containsAll(['Family', 'Work', 'Stress']),
    );
  });

  test('falls back to reflection theme', () async {
    const service = MockJournalAiService();

    final result = await service.detectThemes(text: 'A quiet ordinary day.');

    expect(result.themes.single.displayName, 'Reflection');
  });

  test('generates a deterministic study guide', () async {
    const service = MockJournalAiService();

    final guide = await service.generateStudyGuide(
      entryId: 'entry-1',
      originalText: 'I feel stressed about work and want help staying steady.',
      themes: const [
        JournalTheme(id: 'work', name: 'work', displayName: 'Work'),
        JournalTheme(id: 'faith', name: 'faith', displayName: 'Faith'),
      ],
      providerKey: 'gospel_library',
    );

    expect(guide.entryId, 'entry-1');
    expect(guide.items, isNotEmpty);
    expect(guide.reflectionPrompt.text, contains('work'));
  });
}
