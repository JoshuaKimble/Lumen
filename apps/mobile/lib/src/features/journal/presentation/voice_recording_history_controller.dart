import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/shared_preferences_voice_recording_history_store.dart';
import '../domain/voice_recording.dart';
import '../domain/voice_recording_attempt.dart';
import '../domain/voice_recording_history_store.dart';

final voiceRecordingHistoryStoreProvider = Provider<VoiceRecordingHistoryStore>(
  (ref) {
    return SharedPreferencesVoiceRecordingHistoryStore(
      preferences: SharedPreferencesAsync(),
    );
  },
);

final voiceRecordingHistoryControllerProvider =
    AsyncNotifierProvider<
      VoiceRecordingHistoryController,
      List<VoiceRecordingAttempt>
    >(VoiceRecordingHistoryController.new);

class VoiceRecordingHistoryController
    extends AsyncNotifier<List<VoiceRecordingAttempt>> {
  late final VoiceRecordingHistoryStore _store;

  @override
  Future<List<VoiceRecordingAttempt>> build() async {
    _store = ref.watch(voiceRecordingHistoryStoreProvider);
    final attempts = await _store.listAttempts();
    return _sortAttempts(attempts);
  }

  Future<VoiceRecordingAttempt> createAttempt(VoiceRecording recording) async {
    final attempts = await future;
    final now = DateTime.now().toUtc();
    final attempt = VoiceRecordingAttempt(
      id: 'voice-${now.microsecondsSinceEpoch}',
      recording: recording,
      status: VoiceRecordingAttemptStatus.transcribing,
      createdAt: now,
      updatedAt: now,
    );
    await _saveAttempts([attempt, ...attempts]);
    return attempt;
  }

  Future<void> markTranscribing(String attemptId) async {
    await _updateAttempt(
      attemptId,
      (attempt, now) => attempt.copyWith(
        status: VoiceRecordingAttemptStatus.transcribing,
        updatedAt: now,
        clearTranscript: true,
        clearErrorMessage: true,
      ),
    );
  }

  Future<void> markTranscribed(String attemptId, String transcript) async {
    await _updateAttempt(
      attemptId,
      (attempt, now) => attempt.copyWith(
        status: VoiceRecordingAttemptStatus.transcribed,
        updatedAt: now,
        transcript: transcript,
        clearErrorMessage: true,
      ),
    );
  }

  Future<void> markFailed(String attemptId, String errorMessage) async {
    await _updateAttempt(
      attemptId,
      (attempt, now) => attempt.copyWith(
        status: VoiceRecordingAttemptStatus.failed,
        updatedAt: now,
        errorMessage: errorMessage,
      ),
    );
  }

  Future<void> markSaved(String attemptId) async {
    await _updateAttempt(
      attemptId,
      (attempt, now) => attempt.copyWith(
        status: VoiceRecordingAttemptStatus.saved,
        updatedAt: now,
        clearErrorMessage: true,
      ),
    );
  }

  Future<void> _updateAttempt(
    String attemptId,
    VoiceRecordingAttempt Function(VoiceRecordingAttempt attempt, DateTime now)
    update,
  ) async {
    final attempts = await future;
    final now = DateTime.now().toUtc();
    final updated = [
      for (final attempt in attempts)
        if (attempt.id == attemptId) update(attempt, now) else attempt,
    ];
    await _saveAttempts(updated);
  }

  Future<void> _saveAttempts(List<VoiceRecordingAttempt> attempts) async {
    final sorted = _sortAttempts(attempts);
    state = AsyncData(sorted);
    await _store.saveAttempts(sorted);
  }

  List<VoiceRecordingAttempt> _sortAttempts(
    List<VoiceRecordingAttempt> attempts,
  ) {
    final sorted = [...attempts];
    sorted.sort((left, right) {
      final priority = _statusPriority(
        left.status,
      ).compareTo(_statusPriority(right.status));
      if (priority != 0) {
        return priority;
      }

      return right.updatedAt.compareTo(left.updatedAt);
    });
    return sorted;
  }

  int _statusPriority(VoiceRecordingAttemptStatus status) {
    return switch (status) {
      VoiceRecordingAttemptStatus.failed => 0,
      VoiceRecordingAttemptStatus.transcribing => 1,
      VoiceRecordingAttemptStatus.transcribed => 2,
      VoiceRecordingAttemptStatus.saved => 3,
    };
  }
}
