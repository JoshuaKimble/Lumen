import 'package:supabase_flutter/supabase_flutter.dart';

typedef JournalEntryRow = Map<String, dynamic>;

abstract interface class SupabaseJournalCloudAdapter {
  Future<void> deleteEntry({required String userId, required String entryId});

  Future<List<JournalEntryRow>> selectEntries({
    required String userId,
    String? entryId,
    int? limit,
    DateTime? beforeCreatedAt,
  });

  Future<void> upsertEntry({
    required String userId,
    required Map<String, Object?> row,
  });

  Future<void> replaceThemes({
    required String userId,
    required String entryId,
    required List<Map<String, Object?>> rows,
  });

  Future<void> replaceResources({
    required String userId,
    required String entryId,
    required List<Map<String, Object?>> rows,
  });
}

class SupabaseClientJournalCloudAdapter implements SupabaseJournalCloudAdapter {
  const SupabaseClientJournalCloudAdapter(this._client);

  final SupabaseClient _client;

  @override
  Future<void> deleteEntry({
    required String userId,
    required String entryId,
  }) async {
    await _client
        .from('journal_entries')
        .delete()
        .eq('user_id', userId)
        .eq('id', entryId);
  }

  @override
  Future<List<JournalEntryRow>> selectEntries({
    required String userId,
    String? entryId,
    int? limit,
    DateTime? beforeCreatedAt,
  }) async {
    var query = _client
        .from('journal_entries')
        .select('''
          *,
          journal_themes (
            theme_id,
            name,
            display_name,
            weight
          ),
          study_guide,
          related_resources (
            resource_id,
            entry_id,
            theme_id,
            title,
            type,
            source_type,
            match_reason,
            confidence,
            url,
            scripture_reference,
            description
          )
        ''')
        .eq('user_id', userId);
    if (beforeCreatedAt != null) {
      query = query.lt('created_at', beforeCreatedAt.toUtc().toIso8601String());
    }
    if (entryId != null) {
      query = query.eq('id', entryId);
    }
    final orderedQuery = query.order('created_at', ascending: false);
    if (limit != null) {
      orderedQuery.limit(limit);
    }
    final response = await orderedQuery;
    return (response as List<Object?>).whereType<Map<String, dynamic>>().toList(
      growable: false,
    );
  }

  @override
  Future<void> upsertEntry({
    required String userId,
    required Map<String, Object?> row,
  }) async {
    await _client.from('journal_entries').upsert(row);
  }

  @override
  Future<void> replaceThemes({
    required String userId,
    required String entryId,
    required List<Map<String, Object?>> rows,
  }) async {
    await _client
        .from('journal_themes')
        .delete()
        .eq('user_id', userId)
        .eq('entry_id', entryId);

    if (rows.isEmpty) {
      return;
    }

    await _client.from('journal_themes').upsert(rows);
  }

  @override
  Future<void> replaceResources({
    required String userId,
    required String entryId,
    required List<Map<String, Object?>> rows,
  }) async {
    await _client
        .from('related_resources')
        .delete()
        .eq('user_id', userId)
        .eq('entry_id', entryId);

    if (rows.isEmpty) {
      return;
    }

    await _client.from('related_resources').upsert(rows);
  }
}
