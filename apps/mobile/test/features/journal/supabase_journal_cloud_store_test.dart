import 'package:flutter_test/flutter_test.dart';
import 'package:lumen/src/features/journal/data/supabase_journal_cloud_adapter.dart';
import 'package:lumen/src/features/journal/data/supabase_journal_cloud_store.dart';
import 'package:lumen/src/features/journal/domain/entry_source.dart';
import 'package:lumen/src/features/journal/domain/journal_entry.dart';
import 'package:lumen/src/features/journal/domain/journal_theme.dart';
import 'package:lumen/src/features/journal/domain/related_resource.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('reads entries for the authenticated user', () async {
    final adapter = _FakeSupabaseJournalCloudAdapter(
      selectEntriesResult: [
        {
          'id': 'entry-1',
          'created_at': '2026-05-25T20:00:00Z',
          'client_updated_at': '2026-05-25T20:30:00Z',
          'source': 'text',
          'original_text': 'Original',
          'rewritten_text': 'Rewrite',
          'title': 'Title',
          'summary': 'Summary',
          'last_regenerated_at': null,
          'journal_themes': const [],
          'related_resources': const [],
        },
      ],
    );
    final store = SupabaseJournalCloudStore(
      adapter: adapter,
      currentUserId: () => 'user-1',
    );

    final entries = await store.listEntries(userId: 'user-1');

    expect(entries.single.id, 'entry-1');
    expect(entries.single.originalText, 'Original');
  });

  test('rejects reads for another user id', () async {
    final store = SupabaseJournalCloudStore(
      adapter: _FakeSupabaseJournalCloudAdapter(),
      currentUserId: () => 'user-1',
    );

    await expectLater(
      store.listEntries(userId: 'user-2'),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('authenticated user'),
        ),
      ),
    );
  });

  test('rejects writes without an authenticated user', () async {
    final store = SupabaseJournalCloudStore(
      adapter: _FakeSupabaseJournalCloudAdapter(),
      currentUserId: () => null,
    );

    await expectLater(
      store.saveEntry(userId: 'user-1', entry: _sampleEntry()),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          contains('authenticated user session'),
        ),
      ),
    );
  });
}

class _FakeSupabaseJournalCloudAdapter implements SupabaseJournalCloudAdapter {
  _FakeSupabaseJournalCloudAdapter({this.selectEntriesResult = const []});

  final List<JournalEntryRow> selectEntriesResult;

  @override
  Future<void> deleteEntry({
    required String userId,
    required String entryId,
  }) async {}

  @override
  Future<void> replaceResources({
    required String userId,
    required String entryId,
    required List<Map<String, Object?>> rows,
  }) async {}

  @override
  Future<void> replaceThemes({
    required String userId,
    required String entryId,
    required List<Map<String, Object?>> rows,
  }) async {}

  @override
  Future<List<JournalEntryRow>> selectEntries({
    required String userId,
    String? entryId,
    int? limit,
    DateTime? beforeCreatedAt,
  }) async {
    return selectEntriesResult;
  }

  @override
  Future<void> upsertEntry({
    required String userId,
    required Map<String, Object?> row,
  }) async {}
}

JournalEntry _sampleEntry() {
  return JournalEntry(
    id: 'entry-1',
    createdAt: DateTime.utc(2026, 5, 25, 20, 0),
    updatedAt: DateTime.utc(2026, 5, 25, 20, 30),
    source: EntrySource.text,
    originalText: 'Original',
    rewrittenText: 'Rewrite',
    themes: const [JournalTheme(id: 'hope', name: 'hope', displayName: 'Hope')],
    resources: const [
      RelatedResource(
        id: 'resource-1',
        title: 'Prompt',
        type: 'reflection_prompt',
      ),
    ],
    title: 'Title',
    summary: 'Summary',
  );
}
