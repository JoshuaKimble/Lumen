import 'package:flutter_test/flutter_test.dart';
import 'package:lumen/src/features/journal/domain/ai_results.dart';
import 'package:lumen/src/features/journal/domain/entry_source.dart';
import 'package:lumen/src/features/journal/domain/journal_entry.dart';

void main() {
  test('keeps original and rewritten text on the same entry', () {
    final createdAt = DateTime.utc(2026, 5, 7);
    final regeneratedAt = DateTime.utc(2026, 5, 8);
    final entry = JournalEntry(
      id: 'entry-1',
      createdAt: createdAt,
      updatedAt: createdAt,
      source: EntrySource.voice,
      originalText: 'raw transcript with my exact words',
      rewrittenText: '',
      themes: const [],
      resources: const [],
    );

    final rewritten = entry.applyRewrite(
      rewrite: const RewriteResult(
        rewrittenText: 'A clearer version of my exact words.',
      ),
      updatedAt: regeneratedAt,
    );

    expect(rewritten.id, entry.id);
    expect(rewritten.originalText, entry.originalText);
    expect(rewritten.rewrittenText, 'A clearer version of my exact words.');
    expect(rewritten.lastRegeneratedAt, regeneratedAt);
  });

  test('uses rewritten text for preview when available', () {
    final entry = JournalEntry(
      id: 'entry-1',
      createdAt: DateTime.utc(2026, 5, 7),
      updatedAt: DateTime.utc(2026, 5, 7),
      source: EntrySource.text,
      originalText: 'original text',
      rewrittenText: 'rewritten text',
      themes: const [],
      resources: const [],
    );

    expect(entry.previewText, 'rewritten text');
  });
}
