import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/journal_entry.dart';
import '../domain/journal_local_store.dart';
import 'journal_entry_json_mapper.dart';

class SharedPreferencesJournalRepository implements JournalLocalStore {
  const SharedPreferencesJournalRepository({
    required SharedPreferencesAsync preferences,
    JournalEntryJsonMapper mapper = const JournalEntryJsonMapper(),
  }) : _preferences = preferences,
       _mapper = mapper;

  static const entriesKey = 'journal.entries.v1';

  final SharedPreferencesAsync _preferences;
  final JournalEntryJsonMapper _mapper;

  @override
  Future<void> deleteEntry(String id) async {
    final entries = await listEntries();
    final updatedEntries = entries
        .where((entry) => entry.id != id)
        .toList(growable: false);

    await _saveEntries(updatedEntries);
  }

  @override
  Future<JournalEntry?> getEntry(String id) async {
    final entries = await listEntries();

    for (final entry in entries) {
      if (entry.id == id) {
        return entry;
      }
    }

    return null;
  }

  @override
  Future<List<JournalEntry>> listEntries() async {
    final rawEntries = await _preferences.getStringList(entriesKey);

    if (rawEntries == null) {
      return const [];
    }

    final entries = rawEntries.map(_decodeEntry).toList(growable: false)
      ..sort(_compareNewestFirst);

    return entries;
  }

  @override
  Future<List<JournalEntry>> listEntriesByTheme(String themeId) async {
    final entries = await listEntries();

    return entries
        .where((entry) => entry.themes.any((theme) => theme.id == themeId))
        .toList(growable: false);
  }

  @override
  Future<void> saveEntry(JournalEntry entry) async {
    final entries = await listEntries();
    final updatedEntries = <JournalEntry>[
      for (final existingEntry in entries)
        if (existingEntry.id != entry.id) existingEntry,
      entry,
    ]..sort(_compareNewestFirst);

    await _saveEntries(updatedEntries);
  }

  JournalEntry _decodeEntry(String rawEntry) {
    final decoded = jsonDecode(rawEntry);

    if (decoded is! Map<String, Object?>) {
      throw const FormatException('Expected journal entry JSON object.');
    }

    return _mapper.fromJson(decoded);
  }

  Future<void> _saveEntries(List<JournalEntry> entries) async {
    final rawEntries = entries
        .map((entry) => jsonEncode(_mapper.toJson(entry)))
        .toList(growable: false);

    await _preferences.setStringList(entriesKey, rawEntries);
  }

  int _compareNewestFirst(JournalEntry left, JournalEntry right) {
    return right.createdAt.compareTo(left.createdAt);
  }
}
