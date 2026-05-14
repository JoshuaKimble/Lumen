import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../domain/voice_recording.dart';
import '../domain/voice_recording_audio.dart';
import 'voice_recording_audio_reader.dart';

VoiceRecordingAudioReader createVoiceRecordingAudioReader() {
  return WebVoiceRecordingAudioReader(httpClient: http.Client());
}

class WebVoiceRecordingAudioReader implements VoiceRecordingAudioReader {
  const WebVoiceRecordingAudioReader({required this.httpClient});

  final http.Client httpClient;

  @override
  Future<VoiceRecordingAudio> read(VoiceRecording recording) async {
    final response = await httpClient.get(Uri.parse(recording.uri));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('Unable to read recorded audio.');
    }

    return VoiceRecordingAudio(
      bytes: Uint8List.fromList(response.bodyBytes),
      mimeType: response.headers['content-type'] ?? 'audio/webm',
    );
  }
}
