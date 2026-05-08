import 'package:flutter_test/flutter_test.dart';
import 'package:lumen/src/features/journal/data/in_memory_journal_repository.dart';

void main() {
  test('returns the starter journal entry', () async {
    const repository = InMemoryJournalRepository();

    final entries = await repository.listEntries();

    expect(entries, hasLength(1));
    expect(entries.single.id, 'welcome');
    expect(entries.single.title, 'Welcome to Lumen');
  });
}
