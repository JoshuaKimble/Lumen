import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/entry_source.dart';
import '../domain/journal_cloud_entry_page.dart';
import '../domain/journal_cloud_store.dart';
import '../domain/journal_entry.dart';
import '../domain/journal_theme.dart';
import '../domain/related_resource.dart';

class SupabaseJournalCloudStore implements JournalCloudStore {
  const SupabaseJournalCloudStore({required SupabaseClient client})
    : _client = client;

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
  Future<JournalEntry?> getEntry({
    required String userId,
    required String entryId,
  }) async {
    final rows = await _selectEntries(userId: userId, entryId: entryId);
    if (rows.isEmpty) {
      return null;
    }
    return _entryFromRow(rows.single);
  }

  @override
  Future<List<JournalEntry>> listEntries({required String userId}) async {
    final rows = await _selectEntries(userId: userId);
    final entries = rows.map(_entryFromRow).toList(growable: false)
      ..sort((left, right) => right.createdAt.compareTo(left.createdAt));
    return entries;
  }

  @override
  Future<JournalCloudEntryPage> listEntriesPage({
    required String userId,
    required int limit,
    DateTime? beforeCreatedAt,
  }) async {
    final rows = await _selectEntries(
      userId: userId,
      limit: limit,
      beforeCreatedAt: beforeCreatedAt,
    );
    final entries = rows.map(_entryFromRow).toList(growable: false)
      ..sort((left, right) => right.createdAt.compareTo(left.createdAt));
    return JournalCloudEntryPage(
      entries: entries,
      hasMore: entries.length == limit,
      nextBeforeCreatedAt: entries.isEmpty ? null : entries.last.createdAt,
    );
  }

  @override
  Future<void> saveEntry({
    required String userId,
    required JournalEntry entry,
  }) async {
    await _client.from('journal_entries').upsert({
      'user_id': userId,
      'id': entry.id,
      'title': entry.title,
      'summary': entry.summary,
      'source': entry.source.name,
      'original_text': entry.originalText,
      'rewritten_text': entry.rewrittenText,
      'last_regenerated_at': entry.lastRegeneratedAt?.toUtc().toIso8601String(),
      'created_at': entry.createdAt.toUtc().toIso8601String(),
      'updated_at': entry.updatedAt.toUtc().toIso8601String(),
      'client_updated_at': entry.updatedAt.toUtc().toIso8601String(),
      'version': 1,
      'sync_state': 'synced',
    });

    await _replaceThemes(userId: userId, entry: entry);
    await _replaceResources(userId: userId, entry: entry);
  }

  Future<List<Map<String, dynamic>>> _selectEntries({
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

  Future<void> _replaceThemes({
    required String userId,
    required JournalEntry entry,
  }) async {
    await _client
        .from('journal_themes')
        .delete()
        .eq('user_id', userId)
        .eq('entry_id', entry.id);

    if (entry.themes.isEmpty) {
      return;
    }

    await _client.from('journal_themes').upsert([
      for (final theme in entry.themes)
        {
          'user_id': userId,
          'entry_id': entry.id,
          'theme_id': theme.id,
          'name': theme.name,
          'display_name': theme.displayName,
          'weight': theme.weight,
        },
    ]);
  }

  Future<void> _replaceResources({
    required String userId,
    required JournalEntry entry,
  }) async {
    await _client
        .from('related_resources')
        .delete()
        .eq('user_id', userId)
        .eq('entry_id', entry.id);

    if (entry.resources.isEmpty) {
      return;
    }

    await _client.from('related_resources').upsert([
      for (final resource in entry.resources)
        {
          'user_id': userId,
          'resource_id': resource.id,
          'entry_id': resource.entryId ?? entry.id,
          'theme_id': resource.themeId,
          'title': resource.title,
          'type': resource.type,
          'source_type': resource.sourceType,
          'match_reason': resource.matchReason,
          'confidence': resource.confidence,
          'url': resource.url?.toString(),
          'scripture_reference': resource.scriptureReference,
          'description': resource.description,
        },
    ]);
  }

  JournalEntry _entryFromRow(Map<String, dynamic> row) {
    final themeRows = (row['journal_themes'] as List<Object?>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
    final resourceRows =
        (row['related_resources'] as List<Object?>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .toList(growable: false);
    return JournalEntry(
      id: row['id'] as String,
      createdAt: DateTime.parse(row['created_at'] as String).toUtc(),
      updatedAt: DateTime.parse(row['client_updated_at'] as String).toUtc(),
      source: EntrySource.values.byName(row['source'] as String),
      originalText: row['original_text'] as String,
      rewrittenText: row['rewritten_text'] as String? ?? '',
      themes: themeRows.map(_themeFromRow).toList(growable: false),
      resources: resourceRows.map(_resourceFromRow).toList(growable: false),
      title: row['title'] as String?,
      summary: row['summary'] as String?,
      lastRegeneratedAt: row['last_regenerated_at'] == null
          ? null
          : DateTime.parse(row['last_regenerated_at'] as String).toUtc(),
    );
  }

  JournalTheme _themeFromRow(Map<String, dynamic> row) {
    return JournalTheme(
      id: row['theme_id'] as String,
      name: row['name'] as String,
      displayName: row['display_name'] as String,
      weight: (row['weight'] as num?)?.toDouble(),
    );
  }

  RelatedResource _resourceFromRow(Map<String, dynamic> row) {
    final url = row['url'] as String?;
    return RelatedResource(
      id: row['resource_id'] as String,
      title: row['title'] as String,
      type: row['type'] as String,
      url: url == null ? null : Uri.parse(url),
      entryId: row['entry_id'] as String?,
      themeId: row['theme_id'] as String?,
      sourceType: row['source_type'] as String? ?? 'curated',
      matchReason:
          row['match_reason'] as String? ?? 'Related to your reflection.',
      confidence: (row['confidence'] as num?)?.toDouble() ?? 0.75,
      description: row['description'] as String?,
      scriptureReference: row['scripture_reference'] as String?,
    );
  }
}
