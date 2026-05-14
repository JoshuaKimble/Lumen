import '../domain/voice_recording.dart';
import '../domain/voice_recording_audio.dart';
import 'voice_recording_audio_reader.dart';

VoiceRecordingAudioReader createVoiceRecordingAudioReader() {
  return const _UnsupportedVoiceRecordingAudioReader();
}

class _UnsupportedVoiceRecordingAudioReader
    implements VoiceRecordingAudioReader {
  const _UnsupportedVoiceRecordingAudioReader();

  @override
  Future<VoiceRecordingAudio> read(VoiceRecording recording) {
    throw UnsupportedError('Voice recording audio is unavailable.');
  }
}
