import 'voice_recording_attempt.dart';

abstract interface class VoiceRecordingHistoryStore {
  Future<List<VoiceRecordingAttempt>> listAttempts();

  Future<void> saveAttempts(List<VoiceRecordingAttempt> attempts);
}
