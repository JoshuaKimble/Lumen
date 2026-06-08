import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/voice_recording.dart';
import '../domain/voice_recording_attempt.dart';
import '../domain/voice_recording_history_store.dart';

class SharedPreferencesVoiceRecordingHistoryStore
    implements VoiceRecordingHistoryStore {
  const SharedPreferencesVoiceRecordingHistoryStore({
    required SharedPreferencesAsync preferences,
  }) : _preferences = preferences;

  static const attemptsKey = 'journal.voice.recordings.v1';

  final SharedPreferencesAsync _preferences;

  @override
  Future<List<VoiceRecordingAttempt>> listAttempts() async {
    final rawAttempts = await _preferences.getStringList(attemptsKey);
    if (rawAttempts == null) {
      return const [];
    }

    return rawAttempts.map(_decodeAttempt).toList(growable: false);
  }

  @override
  Future<void> saveAttempts(List<VoiceRecordingAttempt> attempts) async {
    final rawAttempts = attempts
        .map((attempt) => jsonEncode(_encodeAttempt(attempt)))
        .toList(growable: false);
    await _preferences.setStringList(attemptsKey, rawAttempts);
  }

  Map<String, Object?> _encodeAttempt(VoiceRecordingAttempt attempt) {
    return {
      'id': attempt.id,
      'recording': {
        'uri': attempt.recording.uri,
        'startedAt': attempt.recording.startedAt.toIso8601String(),
        'stoppedAt': attempt.recording.stoppedAt.toIso8601String(),
      },
      'status': attempt.status.name,
      'createdAt': attempt.createdAt.toIso8601String(),
      'updatedAt': attempt.updatedAt.toIso8601String(),
      'transcript': attempt.transcript,
      'errorMessage': attempt.errorMessage,
    };
  }

  VoiceRecordingAttempt _decodeAttempt(String rawAttempt) {
    final decoded = jsonDecode(rawAttempt);
    if (decoded is! Map<String, Object?>) {
      throw const FormatException('Expected voice recording attempt JSON.');
    }

    final rawRecording = decoded['recording'];
    if (rawRecording is! Map<String, Object?>) {
      throw const FormatException('Expected nested voice recording JSON.');
    }

    return VoiceRecordingAttempt(
      id: _stringValue(decoded, 'id'),
      recording: VoiceRecording(
        uri: _stringValue(rawRecording, 'uri'),
        startedAt: DateTime.parse(
          _stringValue(rawRecording, 'startedAt'),
        ).toUtc(),
        stoppedAt: DateTime.parse(
          _stringValue(rawRecording, 'stoppedAt'),
        ).toUtc(),
      ),
      status: VoiceRecordingAttemptStatus.values.byName(
        _stringValue(decoded, 'status'),
      ),
      createdAt: DateTime.parse(_stringValue(decoded, 'createdAt')).toUtc(),
      updatedAt: DateTime.parse(_stringValue(decoded, 'updatedAt')).toUtc(),
      transcript: _optionalStringValue(decoded, 'transcript'),
      errorMessage: _optionalStringValue(decoded, 'errorMessage'),
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
}
