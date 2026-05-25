import 'package:flutter_test/flutter_test.dart';
import 'package:lumen/src/features/journal/data/hybrid_journal_repository.dart';
import 'package:lumen/src/features/journal/data/in_memory_journal_repository.dart';
import 'package:lumen/src/features/journal/domain/entry_source.dart';
import 'package:lumen/src/features/journal/domain/journal_entry.dart';

void main() {
  test('delegates CRUD operations to the local store', () async {
    final repository = HybridJournalRepository(
      localStore: InMemoryJournalRepository(seedEntries: const []),
    );
    final timestamp = DateTime.utc(2026, 5, 25, 20, 55);
    final entry = JournalEntry(
      id: 'entry-1',
      createdAt: timestamp,
      updatedAt: timestamp,
      source: EntrySource.text,
      originalText: 'Original text',
      rewrittenText: 'Rewritten text',
      themes: const [],
      resources: const [],
      title: 'A title',
    );

    await repository.saveEntry(entry);

    expect((await repository.getEntry('entry-1'))?.title, 'A title');
    expect((await repository.listEntries()).map((item) => item.id), [
      'entry-1',
    ]);
    expect(repository.hasCloudStore, isFalse);

    await repository.deleteEntry('entry-1');

    expect(await repository.getEntry('entry-1'), isNull);
  });
}
