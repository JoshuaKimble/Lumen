import 'voice_recording.dart';

abstract interface class VoiceTranscriptionService {
  Future<String> transcribe(VoiceRecording recording);
}
