import '../domain/voice_recording.dart';
import '../domain/voice_transcription_service.dart';

class MockVoiceTranscriptionService implements VoiceTranscriptionService {
  const MockVoiceTranscriptionService();

  @override
  Future<String> transcribe(VoiceRecording recording) async {
    return 'Mock transcript from recorded audio.';
  }
}
