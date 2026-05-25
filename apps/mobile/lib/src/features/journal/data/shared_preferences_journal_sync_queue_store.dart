import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/journal_sync_operation.dart';
import 'journal_entry_json_mapper.dart';
import 'journal_sync_queue_store.dart';

class SharedPreferencesJournalSyncQueueStore implements JournalSyncQueueStore {
  const SharedPreferencesJournalSyncQueueStore({
    required SharedPreferencesAsync preferences,
    JournalEntryJsonMapper entryMapper = const JournalEntryJsonMapper(),
  }) : _preferences = preferences,
       _entryMapper = entryMapper;

  static const queueKey = 'journal.sync.queue.v1';

  final SharedPreferencesAsync _preferences;
  final JournalEntryJsonMapper _entryMapper;

  @override
  Future<List<JournalSyncOperation>> loadOperations() async {
    final rawOperations = await _preferences.getStringList(queueKey);
    if (rawOperations == null) {
      return const [];
    }

    return rawOperations.map(_decodeOperation).toList(growable: false);
  }

  @override
  Future<void> saveOperations(List<JournalSyncOperation> operations) async {
    final rawOperations = operations
        .map((operation) => jsonEncode(_encodeOperation(operation)))
        .toList(growable: false);
    await _preferences.setStringList(queueKey, rawOperations);
  }

  Map<String, Object?> _encodeOperation(JournalSyncOperation operation) {
    return {
      'queueKey': operation.queueKey,
      'userId': operation.userId,
      'entryId': operation.entryId,
      'type': operation.type.name,
      'entry': operation.entry == null
          ? null
          : _entryMapper.toJson(operation.entry!),
      'enqueuedAt': operation.enqueuedAt.toIso8601String(),
      'nextAttemptAt': operation.nextAttemptAt.toIso8601String(),
      'attemptCount': operation.attemptCount,
      'lastErrorMessage': operation.lastErrorMessage,
    };
  }

  JournalSyncOperation _decodeOperation(String rawOperation) {
    final decoded = jsonDecode(rawOperation);
    if (decoded is! Map<String, Object?>) {
      throw const FormatException(
        'Expected journal sync operation JSON object.',
      );
    }

    final rawEntry = decoded['entry'];
    return JournalSyncOperation(
      queueKey: _stringValue(decoded, 'queueKey'),
      userId: _stringValue(decoded, 'userId'),
      entryId: _stringValue(decoded, 'entryId'),
      type: JournalSyncOperationType.values.byName(
        _stringValue(decoded, 'type'),
      ),
      entry: rawEntry is Map<String, Object?>
          ? _entryMapper.fromJson(rawEntry)
          : null,
      enqueuedAt: DateTime.parse(_stringValue(decoded, 'enqueuedAt')).toUtc(),
      nextAttemptAt: DateTime.parse(
        _stringValue(decoded, 'nextAttemptAt'),
      ).toUtc(),
      attemptCount: _intValue(decoded, 'attemptCount'),
      lastErrorMessage: _optionalStringValue(decoded, 'lastErrorMessage'),
    );
  }

  String _stringValue(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is String) {
      return value;
    }
    throw FormatException('Expected string value for "$key".');
  }

  String? _optionalStringValue(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value == null) {
      return null;
    }
    if (value is String) {
      return value;
    }
    throw FormatException('Expected optional string value for "$key".');
  }

  int _intValue(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is int) {
      return value;
    }
    throw FormatException('Expected integer value for "$key".');
  }
}
