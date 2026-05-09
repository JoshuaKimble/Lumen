import 'package:flutter_test/flutter_test.dart';
import 'package:lumen/src/features/journal/data/mock_journal_ai_service.dart';

void main() {
  test('generates deterministic rewrite output', () async {
    const service = MockJournalAiService();

    final rewrite = await service.rewriteEntry(
      originalText: ' Work felt rushed today. ',
    );

    expect(
      rewrite.rewrittenText,
      'I am noticing this more clearly: Work felt rushed today.',
    );
    expect(rewrite.title, 'Work felt rushed today');
    expect(rewrite.summary, 'Work felt rushed today.');
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
}
