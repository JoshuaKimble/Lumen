import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:lumen/src/api/generated/lumen_api_client.dart';

import '../domain/voice_transcription_service.dart';
import 'api_voice_transcription_service.dart';
import 'mock_voice_transcription_service.dart';
import 'voice_recording_audio_reader.dart';

const _useApiAi = bool.fromEnvironment('LUMEN_USE_API_AI');
const _apiBaseUrl = String.fromEnvironment(
  'LUMEN_API_BASE_URL',
  defaultValue: 'http://localhost:3000',
);

final voiceTranscriptionServiceProvider = Provider<VoiceTranscriptionService>((
  ref,
) {
  if (_useApiAi) {
    return ApiVoiceTranscriptionService(
      client: LumenApiClient(
        baseUri: Uri.parse(_apiBaseUrl),
        httpClient: http.Client(),
      ),
      audioReader: createVoiceRecordingAudioReader(),
    );
  }

  return const MockVoiceTranscriptionService();
});
