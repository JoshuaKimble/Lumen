import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lumen/src/api/generated/lumen_api_client.dart';
import 'package:lumen/src/features/journal/data/api_resource_suggestion_service.dart';
import 'package:lumen/src/features/journal/data/mock_resource_suggestion_service.dart';
import 'package:lumen/src/features/journal/domain/resource_suggestion_service.dart';
import 'package:lumen/src/features/settings/domain/scripture_app_preference.dart';

void main() {
  group('MockResourceSuggestionService', () {
    const service = MockResourceSuggestionService();

    test('routes scripture suggestions to Gospel Library', () async {
      final suggestions = await service.suggest(
        text: 'I want to pray and read scripture tonight.',
        preference: ScriptureAppPreference.gospelLibrary,
      );

      expect(suggestions, isNotEmpty);
      expect(suggestions.first.url?.host, 'www.churchofjesuschrist.org');
    });

    test('routes scripture suggestions to Bible Gateway', () async {
      final suggestions = await service.suggest(
        text: 'I want to pray and read scripture tonight.',
        preference: ScriptureAppPreference.bibleGateway,
      );

      expect(suggestions, isNotEmpty);
      expect(suggestions.first.url?.host, 'www.biblegateway.com');
    });
  });

  group('ApiResourceSuggestionService', () {
    test(
      'routes returned scripture suggestions using selected preference',
      () async {
        final service = ApiResourceSuggestionService(
          client: LumenApiClient(
            baseUri: Uri.parse('http://localhost:3000'),
            httpClient: MockClient((request) async {
              expect(request.method, 'POST');
              expect(request.url.path, '/v1/resources/suggest');

              return http.Response(
                '{"suggestions":[{"id":"faith-scripture-psalm-46-10","type":"scripture","title":"Psalm 46:10","description":"Be still.","scriptureReference":"Psalm 46:10","sourceType":"curated","matchReason":"faith match","confidence":0.82,"themeId":"faith"}]}',
                200,
              );
            }),
          ),
        );

        final suggestions = await service.suggest(
          text: 'I want to pray and read scripture tonight.',
          preference: ScriptureAppPreference.youVersion,
        );

        expect(suggestions, hasLength(1));
        expect(suggestions.single.url?.host, 'www.bible.com');
        expect(suggestions.single.url?.path, '/search/bible');
        expect(suggestions.single.scriptureReference, 'Psalm 46:10');
      },
    );

    test('keeps non-scripture suggestions unchanged', () async {
      final service = ApiResourceSuggestionService(
        client: LumenApiClient(
          baseUri: Uri.parse('http://localhost:3000'),
          httpClient: MockClient((request) async {
            return http.Response(
              '{"suggestions":[{"id":"stress-prompt","type":"reflection_prompt","title":"Pause and breathe","description":"Reset.","sourceType":"curated","matchReason":"stress match","confidence":0.75}]}',
              200,
            );
          }),
        ),
      );

      final suggestions = await service.suggest(
        text: 'I feel overwhelmed.',
        preference: ScriptureAppPreference.catholic,
      );

      expect(suggestions, hasLength(1));
      expect(suggestions.single.url, isNull);
    });

    test(
      'submits authenticated resource feedback through the API client',
      () async {
        final service = ApiResourceSuggestionService(
          client: LumenApiClient(
            baseUri: Uri.parse('http://localhost:3000'),
            accessTokenProvider: () async => 'session-token-1',
            httpClient: MockClient((request) async {
              expect(request.method, 'POST');
              expect(request.url.path, '/v1/resources/feedback');
              expect(
                request.headers['authorization'],
                'Bearer session-token-1',
              );
              expect(
                request.body,
                '{"resourceId":"resource-1","action":"dismiss","entryId":"entry-1","themeId":"stress"}',
              );

              return http.Response('{"status":"accepted"}', 202);
            }),
          ),
        );

        await service.submitFeedback(
          resourceId: 'resource-1',
          action: ResourceFeedbackAction.dismiss,
          entryId: 'entry-1',
          themeId: 'stress',
        );
      },
    );
  });
}
