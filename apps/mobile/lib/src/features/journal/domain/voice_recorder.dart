import 'voice_recording.dart';

abstract interface class VoiceRecorder {
  Future<bool> hasPermission();

  Future<void> start({required DateTime startedAt});

  Future<VoiceRecording?> stop({required DateTime stoppedAt});

  Future<void> dispose();
}
