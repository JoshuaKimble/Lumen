import '../domain/voice_recording.dart';
import '../domain/voice_recording_audio.dart';
import 'voice_recording_audio_reader_stub.dart'
    if (dart.library.io) 'voice_recording_audio_reader_io.dart'
    if (dart.library.js_interop) 'voice_recording_audio_reader_web.dart'
    as platform;

abstract interface class VoiceRecordingAudioReader {
  Future<VoiceRecordingAudio> read(VoiceRecording recording);
}

VoiceRecordingAudioReader createVoiceRecordingAudioReader() {
  return platform.createVoiceRecordingAudioReader();
}
