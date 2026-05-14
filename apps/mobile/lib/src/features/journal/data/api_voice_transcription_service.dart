import 'dart:convert';

import 'package:lumen/src/api/generated/lumen_api_client.dart';

import '../domain/voice_recording.dart';
import '../domain/voice_transcription_service.dart';
import 'voice_recording_audio_reader.dart';

class ApiVoiceTranscriptionService implements VoiceTranscriptionService {
  const ApiVoiceTranscriptionService({
    required this.client,
    required this.audioReader,
  });

  final LumenApiClient client;
  final VoiceRecordingAudioReader audioReader;

  @override
  Future<String> transcribe(VoiceRecording recording) async {
    final audio = await audioReader.read(recording);
    final response = await client.createTranscription(
      CreateTranscriptionRequest(
        audioBase64: base64Encode(audio.bytes),
        mimeType: audio.mimeType,
      ),
    );

    return response.transcript;
  }
}
