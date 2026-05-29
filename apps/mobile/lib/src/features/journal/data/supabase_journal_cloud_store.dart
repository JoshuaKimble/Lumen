import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/entry_source.dart';
import '../domain/journal_cloud_entry_page.dart';
import '../domain/journal_cloud_store.dart';
import '../domain/journal_entry.dart';
import '../domain/journal_theme.dart';
import '../domain/related_resource.dart';
import 'supabase_journal_cloud_adapter.dart';

typedef CurrentJournalCloudUserId = String? Function();

class SupabaseJournalCloudStore implements JournalCloudStore {
  SupabaseJournalCloudStore({
    SupabaseJournalCloudAdapter? adapter,
    SupabaseClient? client,
    CurrentJournalCloudUserId? currentUserId,
  }) : assert(
         adapter != null || client != null,
         'Provide either a Supabase client or a cloud adapter.',
       ),
       _adapter = adapter ?? SupabaseClientJournalCloudAdapter(client!),
       _currentUserId = currentUserId ?? (() => client!.auth.currentUser?.id);

  final SupabaseJournalCloudAdapter _adapter;
  final CurrentJournalCloudUserId _currentUserId;

  @override
  Future<void> deleteEntry({
    required String userId,
    required String entryId,
  }) async {
    _assertOwnUserId(userId);
    await _adapter.deleteEntry(userId: userId, entryId: entryId);
  }

  @override
  Future<JournalEntry?> getEntry({
    required String userId,
    required String entryId,
  }) async {
    _assertOwnUserId(userId);
    final rows = await _selectEntries(userId: userId, entryId: entryId);
    if (rows.isEmpty) {
      return null;
    }
    return _entryFromRow(rows.single);
  }

  @override
  Future<List<JournalEntry>> listEntries({required String userId}) async {
    _assertOwnUserId(userId);
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
    _assertOwnUserId(userId);
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
    _assertOwnUserId(userId);
    await _adapter.upsertEntry(
      userId: userId,
      row: {
        'user_id': userId,
        'id': entry.id,
        'title': entry.title,
        'summary': entry.summary,
        'source': entry.source.name,
        'original_text': entry.originalText,
        'rewritten_text': entry.rewrittenText,
        'last_regenerated_at': entry.lastRegeneratedAt
            ?.toUtc()
            .toIso8601String(),
        'created_at': entry.createdAt.toUtc().toIso8601String(),
        'updated_at': entry.updatedAt.toUtc().toIso8601String(),
        'client_updated_at': entry.updatedAt.toUtc().toIso8601String(),
        'version': 1,
        'sync_state': 'synced',
      },
    );

    await _replaceThemes(userId: userId, entry: entry);
    await _replaceResources(userId: userId, entry: entry);
  }

  Future<List<Map<String, dynamic>>> _selectEntries({
    required String userId,
    String? entryId,
    int? limit,
    DateTime? beforeCreatedAt,
  }) async {
    return _adapter.selectEntries(
      userId: userId,
      entryId: entryId,
      limit: limit,
      beforeCreatedAt: beforeCreatedAt,
    );
  }

  Future<void> _replaceThemes({
    required String userId,
    required JournalEntry entry,
  }) async {
    await _adapter.replaceThemes(
      userId: userId,
      entryId: entry.id,
      rows: [
        for (final theme in entry.themes)
          {
            'user_id': userId,
            'entry_id': entry.id,
            'theme_id': theme.id,
            'name': theme.name,
            'display_name': theme.displayName,
            'weight': theme.weight,
          },
      ],
    );
  }

  Future<void> _replaceResources({
    required String userId,
    required JournalEntry entry,
  }) async {
    await _adapter.replaceResources(
      userId: userId,
      entryId: entry.id,
      rows: [
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
      ],
    );
  }

  void _assertOwnUserId(String userId) {
    final authenticatedUserId = _currentUserId();
    if (authenticatedUserId == null) {
      throw StateError(
        'Supabase journal cloud access requires an authenticated user session.',
      );
    }
    if (authenticatedUserId != userId) {
      throw StateError(
        'Supabase journal cloud access only supports the authenticated user.',
      );
    }
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
