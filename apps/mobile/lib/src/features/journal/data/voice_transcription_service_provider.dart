import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/voice_transcription_service.dart';
import 'api_voice_transcription_service.dart';
import 'lumen_api_client_provider.dart';
import 'mock_voice_transcription_service.dart';
import 'voice_recording_audio_reader.dart';

const _useApiAi = bool.fromEnvironment('LUMEN_USE_API_AI');

final voiceTranscriptionServiceProvider = Provider<VoiceTranscriptionService>((
  ref,
) {
  if (_useApiAi) {
    return ApiVoiceTranscriptionService(
      client: ref.watch(lumenApiClientProvider),
      audioReader: createVoiceRecordingAudioReader(),
    );
  }

  return const MockVoiceTranscriptionService();
});
