import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lumen/src/api/generated/lumen_api_client.dart';
import 'package:lumen/src/features/journal/data/api_journal_ai_service.dart';
import 'package:lumen/src/features/journal/data/api_voice_transcription_service.dart';
import 'package:lumen/src/features/journal/data/voice_recording_audio_reader.dart';
import 'package:lumen/src/features/journal/domain/rewrite_personalization.dart';
import 'package:lumen/src/features/journal/domain/voice_recording.dart';
import 'package:lumen/src/features/journal/domain/voice_recording_audio.dart';
import 'package:lumen/src/features/journal/domain/voice_transcription_exception.dart';
import 'package:lumen/src/features/profiles/domain/rewrite_tone_preference.dart';

void main() {
  test('calls typed rewrite endpoint', () async {
    final client = LumenApiClient(
      baseUri: Uri.parse('http://localhost:3000'),
      httpClient: MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/v1/entries/rewrite');
        expect(
          request.body,
          '{"originalText":"raw note","personalization":{"rewriteTone":"gentle","preserveVoice":false}}',
        );

        return http.Response(
          '{"rewrittenText":"clear note","title":"Generated","summary":"Short"}',
          200,
        );
      }),
    );

    final response = await client.rewriteEntry(
      const RewriteEntryRequest(
        originalText: 'raw note',
        personalization: ApiRewritePersonalization(
          rewriteTone: 'gentle',
          preserveVoice: false,
        ),
      ),
    );

    expect(response.rewrittenText, 'clear note');
    expect(response.title, 'Generated');
    expect(response.summary, 'Short');
  });

  test('calls typed theme endpoint', () async {
    final client = LumenApiClient(
      baseUri: Uri.parse('http://localhost:3000'),
      httpClient: MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/v1/entries/themes/detect');
        expect(request.body, '{"text":"work note"}');

        return http.Response(
          '{"themes":[{"id":"work","name":"work","displayName":"Work","weight":1}]}',
          200,
        );
      }),
    );

    final response = await client.detectEntryThemes(
      const DetectThemesRequest(text: 'work note'),
    );

    expect(response.themes.single.id, 'work');
    expect(response.themes.single.displayName, 'Work');
    expect(response.themes.single.weight, 1);
  });

  test('calls typed transcription endpoint', () async {
    final client = LumenApiClient(
      baseUri: Uri.parse('http://localhost:3000'),
      httpClient: MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/v1/transcriptions');
        expect(
          request.body,
          '{"audioBase64":"cmVjb3JkZWQgYXVkaW8=","mimeType":"audio/mp4"}',
        );

        return http.Response('{"transcript":"transcribed note"}', 200);
      }),
    );

    final response = await client.createTranscription(
      const CreateTranscriptionRequest(
        audioBase64: 'cmVjb3JkZWQgYXVkaW8=',
        mimeType: 'audio/mp4',
      ),
    );

    expect(response.transcript, 'transcribed note');
  });

  test('throws typed exception for API errors', () async {
    final client = LumenApiClient(
      baseUri: Uri.parse('http://localhost:3000'),
      httpClient: MockClient((request) async {
        return http.Response(
          '{"error":"bad_request","message":"Expected text."}',
          400,
        );
      }),
    );

    await expectLater(
      client.rewriteEntry(const RewriteEntryRequest(originalText: '')),
      throwsA(
        isA<LumenApiException>()
            .having((error) => error.statusCode, 'statusCode', 400)
            .having((error) => error.error.error, 'error', 'bad_request'),
      ),
    );
  });

  test('calls typed resource feedback endpoint', () async {
    final client = LumenApiClient(
      baseUri: Uri.parse('http://localhost:3000'),
      accessTokenProvider: () async => 'access-token-1',
      httpClient: MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/v1/resources/feedback');
        expect(request.headers['authorization'], 'Bearer access-token-1');
        expect(
          request.body,
          '{"resourceId":"resource-1","action":"save","entryId":"entry-1","themeId":"hope"}',
        );

        return http.Response('{"status":"accepted"}', 202);
      }),
    );

    final response = await client.submitResourceFeedback(
      const ResourceFeedbackRequest(
        resourceId: 'resource-1',
        action: 'save',
        entryId: 'entry-1',
        themeId: 'hope',
      ),
    );

    expect(response.status, 'accepted');
  });

  test(
    'throws clear error when protected request has no access token',
    () async {
      final client = LumenApiClient(
        baseUri: Uri.parse('http://localhost:3000'),
        accessTokenProvider: () async => null,
        httpClient: MockClient((request) async {
          throw StateError('request should not be sent');
        }),
      );

      await expectLater(
        client.submitResourceFeedback(
          const ResourceFeedbackRequest(
            resourceId: 'resource-1',
            action: 'save',
          ),
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'Authenticated API request requires an access token.',
          ),
        ),
      );
    },
  );

  test('adapts API client responses to journal AI service results', () async {
    final service = ApiJournalAiService(
      client: LumenApiClient(
        baseUri: Uri.parse('http://localhost:3000'),
        httpClient: MockClient((request) async {
          if (request.url.path.endsWith('/rewrite')) {
            return http.Response(
              '{"rewrittenText":"clear note","title":"Generated","summary":"Short"}',
              200,
            );
          }

          return http.Response(
            '{"themes":[{"id":"work","name":"work","displayName":"Work"}]}',
            200,
          );
        }),
      ),
    );

    final rewrite = await service.rewriteEntry(
      originalText: 'raw note',
      personalization: const RewritePersonalization(
        rewriteTone: RewriteTonePreference.reflective,
        preserveVoice: false,
      ),
    );
    final themes = await service.detectThemes(text: 'work note');

    expect(rewrite.rewrittenText, 'clear note');
    expect(rewrite.title, 'Generated');
    expect(themes.themes.single.displayName, 'Work');
  });

  test('defaults rewrite personalization when none is provided', () async {
    final service = ApiJournalAiService(
      client: LumenApiClient(
        baseUri: Uri.parse('http://localhost:3000'),
        httpClient: MockClient((request) async {
          expect(
            request.body,
            '{"originalText":"raw note","personalization":{"rewriteTone":"balanced","preserveVoice":true}}',
          );

          return http.Response('{"rewrittenText":"clear note"}', 200);
        }),
      ),
    );

    final rewrite = await service.rewriteEntry(originalText: 'raw note');

    expect(rewrite.rewrittenText, 'clear note');
  });

  test('adapts recorded audio to transcription API request', () async {
    final service = ApiVoiceTranscriptionService(
      audioReader: const _FakeAudioReader(),
      client: LumenApiClient(
        baseUri: Uri.parse('http://localhost:3000'),
        httpClient: MockClient((request) async {
          expect(request.method, 'POST');
          expect(request.url.path, '/v1/transcriptions');
          expect(
            request.body,
            '{"audioBase64":"AQIDBA==","mimeType":"audio/mp4"}',
          );

          return http.Response('{"transcript":"transcribed audio"}', 200);
        }),
      ),
    );

    final transcript = await service.transcribe(
      VoiceRecording(
        uri: 'memory://recording.m4a',
        startedAt: DateTime.utc(2026, 5, 14, 12),
        stoppedAt: DateTime.utc(2026, 5, 14, 12, 1),
      ),
    );

    expect(transcript, 'transcribed audio');
  });

  test('treats empty transcription text as no speech detected', () async {
    final service = ApiVoiceTranscriptionService(
      audioReader: const _FakeAudioReader(),
      client: LumenApiClient(
        baseUri: Uri.parse('http://localhost:3000'),
        httpClient: MockClient((request) async {
          return http.Response('{"transcript":""}', 200);
        }),
      ),
    );

    await expectLater(
      service.transcribe(
        VoiceRecording(
          uri: 'memory://recording.m4a',
          startedAt: DateTime.utc(2026, 5, 14, 12),
          stoppedAt: DateTime.utc(2026, 5, 14, 12, 1),
        ),
      ),
      throwsA(isA<NoSpeechDetectedException>()),
    );
  });
}

class _FakeAudioReader implements VoiceRecordingAudioReader {
  const _FakeAudioReader();

  @override
  Future<VoiceRecordingAudio> read(VoiceRecording recording) async {
    return VoiceRecordingAudio(
      bytes: Uint8List.fromList([1, 2, 3, 4]),
      mimeType: 'audio/mp4',
    );
  }
}
