import 'dart:io';
import 'dart:typed_data';

import '../domain/voice_recording.dart';
import '../domain/voice_recording_audio.dart';
import 'voice_recording_audio_reader.dart';

VoiceRecordingAudioReader createVoiceRecordingAudioReader() {
  return const IoVoiceRecordingAudioReader();
}

class IoVoiceRecordingAudioReader implements VoiceRecordingAudioReader {
  const IoVoiceRecordingAudioReader();

  @override
  Future<VoiceRecordingAudio> read(VoiceRecording recording) async {
    final bytes = await File(_filePath(recording.uri)).readAsBytes();

    return VoiceRecordingAudio(
      bytes: Uint8List.fromList(bytes),
      mimeType: _mimeTypeFor(recording.uri),
    );
  }

  String _filePath(String uri) {
    final parsedUri = Uri.tryParse(uri);

    if (parsedUri != null && parsedUri.scheme == 'file') {
      return parsedUri.toFilePath();
    }

    return uri;
  }

  String _mimeTypeFor(String uri) {
    final lowerUri = uri.toLowerCase();

    if (lowerUri.endsWith('.mp3')) {
      return 'audio/mpeg';
    }

    if (lowerUri.endsWith('.wav')) {
      return 'audio/wav';
    }

    if (lowerUri.endsWith('.webm')) {
      return 'audio/webm';
    }

    return 'audio/mp4';
  }
}
