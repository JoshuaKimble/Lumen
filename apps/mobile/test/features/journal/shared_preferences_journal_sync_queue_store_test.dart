import 'package:flutter_test/flutter_test.dart';
import 'package:lumen/src/features/journal/data/shared_preferences_journal_sync_queue_store.dart';
import 'package:lumen/src/features/journal/domain/entry_source.dart';
import 'package:lumen/src/features/journal/domain/journal_entry.dart';
import 'package:lumen/src/features/journal/domain/journal_sync_operation.dart';
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

  test('round trips queued operations', () async {
    final store = SharedPreferencesJournalSyncQueueStore(
      preferences: SharedPreferencesAsync(),
    );
    final operation = JournalSyncOperation(
      queueKey: 'user-1:entry-1',
      userId: 'user-1',
      entryId: 'entry-1',
      type: JournalSyncOperationType.upsert,
      entry: JournalEntry(
        id: 'entry-1',
        createdAt: DateTime.utc(2026, 5, 25, 21, 55),
        updatedAt: DateTime.utc(2026, 5, 25, 21, 55),
        source: EntrySource.text,
        originalText: 'Original text',
        rewrittenText: 'Rewritten text',
        themes: const [],
        resources: const [],
        title: 'Title',
      ),
      enqueuedAt: DateTime.utc(2026, 5, 25, 22, 0),
      nextAttemptAt: DateTime.utc(2026, 5, 25, 22, 5),
      attemptCount: 2,
      lastErrorMessage: 'Timed out',
    );

    await store.saveOperations([operation]);

    final loadedOperations = await store.loadOperations();
    expect(loadedOperations, hasLength(1));
    expect(loadedOperations.single.queueKey, operation.queueKey);
    expect(loadedOperations.single.entry?.title, 'Title');
    expect(loadedOperations.single.attemptCount, 2);
    expect(loadedOperations.single.lastErrorMessage, 'Timed out');
  });
}
