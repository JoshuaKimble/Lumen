import fs from 'node:fs';
import path from 'node:path';
import process from 'node:process';

const repoRoot = path.resolve('../..');
const contractPath = path.resolve('openapi/openapi.json');
const outputPath = path.join(
  repoRoot,
  'apps/mobile/lib/src/api/generated/lumen_api_client.dart',
);
const contract = JSON.parse(fs.readFileSync(contractPath, 'utf8'));

assertOperation('/v1/entries/rewrite', 'post', 'rewriteEntry');
assertOperation('/v1/entries/themes/detect', 'post', 'detectEntryThemes');
assertOperation('/v1/transcriptions', 'post', 'createTranscription');
assertOperation('/v1/resources/suggest', 'post', 'suggestResources');
assertOperation('/v1/resources/feedback', 'post', 'submitResourceFeedback');

const output = `// Generated from packages/api_contracts/openapi/openapi.json.
// Regenerate with: npm --prefix packages/api_contracts run generate:flutter
// Do not edit by hand.

import 'dart:convert';

import 'package:http/http.dart' as http;

typedef LumenApiAccessTokenProvider = Future<String?> Function();

class LumenApiClient {
  const LumenApiClient({
    required this.baseUri,
    required this.httpClient,
    this.accessTokenProvider,
  });

  final Uri baseUri;
  final http.Client httpClient;
  final LumenApiAccessTokenProvider? accessTokenProvider;

  Future<RewriteEntryResponse> rewriteEntry(RewriteEntryRequest request) async {
    final response = await _postJson('/v1/entries/rewrite', request.toJson());

    return RewriteEntryResponse.fromJson(response);
  }

  Future<CreateTranscriptionResponse> createTranscription(
    CreateTranscriptionRequest request,
  ) async {
    final response = await _postJson('/v1/transcriptions', request.toJson());

    return CreateTranscriptionResponse.fromJson(response);
  }

  Future<DetectThemesResponse> detectEntryThemes(
    DetectThemesRequest request,
  ) async {
    final response = await _postJson(
      '/v1/entries/themes/detect',
      request.toJson(),
    );

    return DetectThemesResponse.fromJson(response);
  }

  Future<SuggestResourcesResponse> suggestResources(
    SuggestResourcesRequest request,
  ) async {
    final response = await _postJson('/v1/resources/suggest', request.toJson());

    return SuggestResourcesResponse.fromJson(response);
  }

  Future<ResourceFeedbackResponse> submitResourceFeedback(
    ResourceFeedbackRequest request,
  ) async {
    final response = await _postJson(
      '/v1/resources/feedback',
      request.toJson(),
      requiresAuth: true,
    );

    return ResourceFeedbackResponse.fromJson(response);
  }

  Future<Map<String, Object?>> _postJson(
    String path,
    Map<String, Object?> body,
    {bool requiresAuth = false}
  ) async {
    final response = await httpClient.post(
      baseUri.resolve(path),
      headers: await _jsonHeaders(requiresAuth: requiresAuth),
      body: jsonEncode(body),
    );
    final decodedBody = jsonDecode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final error = decodedBody is Map<String, Object?>
          ? ApiError.fromJson(decodedBody)
          : const ApiError(error: 'api_error');

      throw LumenApiException(response.statusCode, error);
    }

    if (decodedBody is Map<String, Object?>) {
      return decodedBody;
    }

    throw const FormatException('Expected JSON object response.');
  }

  Future<Map<String, String>> _jsonHeaders({required bool requiresAuth}) async {
    final headers = <String, String>{'content-type': 'application/json'};

    if (!requiresAuth) {
      return headers;
    }

    final token = await accessTokenProvider?.call();
    if (token == null || token.trim().isEmpty) {
      throw StateError(
        'Authenticated API request requires an access token.',
      );
    }

    headers['authorization'] = 'Bearer \${token.trim()}';
    return headers;
  }
}

class RewriteEntryRequest {
  const RewriteEntryRequest({
    required this.originalText,
    this.personalization,
  });

  final String originalText;
  final ApiRewritePersonalization? personalization;

  Map<String, Object?> toJson() {
    return {
      'originalText': originalText,
      if (personalization != null) 'personalization': personalization!.toJson(),
    };
  }
}

class ApiRewritePersonalization {
  const ApiRewritePersonalization({
    required this.rewriteTone,
    required this.preserveVoice,
  });

  factory ApiRewritePersonalization.fromJson(Map<String, Object?> json) {
    return ApiRewritePersonalization(
      rewriteTone: _requiredString(json, 'rewriteTone'),
      preserveVoice: _requiredBool(json, 'preserveVoice'),
    );
  }

  final String rewriteTone;
  final bool preserveVoice;

  Map<String, Object?> toJson() {
    return {
      'rewriteTone': rewriteTone,
      'preserveVoice': preserveVoice,
    };
  }
}

class RewriteEntryResponse {
  const RewriteEntryResponse({
    required this.rewrittenText,
    this.title,
    this.summary,
  });

  factory RewriteEntryResponse.fromJson(Map<String, Object?> json) {
    return RewriteEntryResponse(
      rewrittenText: _requiredString(json, 'rewrittenText'),
      title: _optionalString(json, 'title'),
      summary: _optionalString(json, 'summary'),
    );
  }

  final String rewrittenText;
  final String? title;
  final String? summary;
}

class CreateTranscriptionRequest {
  const CreateTranscriptionRequest({
    required this.audioBase64,
    required this.mimeType,
  });

  final String audioBase64;
  final String mimeType;

  Map<String, Object?> toJson() {
    return {
      'audioBase64': audioBase64,
      'mimeType': mimeType,
    };
  }
}

class CreateTranscriptionResponse {
  const CreateTranscriptionResponse({required this.transcript});

  factory CreateTranscriptionResponse.fromJson(Map<String, Object?> json) {
    return CreateTranscriptionResponse(
      transcript: _requiredString(json, 'transcript'),
    );
  }

  final String transcript;
}

class DetectThemesRequest {
  const DetectThemesRequest({required this.text});

  final String text;

  Map<String, Object?> toJson() {
    return {'text': text};
  }
}

class DetectThemesResponse {
  const DetectThemesResponse({required this.themes});

  factory DetectThemesResponse.fromJson(Map<String, Object?> json) {
    final themes = json['themes'];

    if (themes is! List<Object?>) {
      throw const FormatException('Expected themes array.');
    }

    return DetectThemesResponse(
      themes: themes
          .whereType<Map<String, Object?>>()
          .map(ApiJournalTheme.fromJson)
          .toList(growable: false),
    );
  }

  final List<ApiJournalTheme> themes;
}

class ApiJournalTheme {
  const ApiJournalTheme({
    required this.id,
    required this.name,
    required this.displayName,
    this.weight,
  });

  factory ApiJournalTheme.fromJson(Map<String, Object?> json) {
    return ApiJournalTheme(
      id: _requiredString(json, 'id'),
      name: _requiredString(json, 'name'),
      displayName: _requiredString(json, 'displayName'),
      weight: _optionalNumber(json, 'weight'),
    );
  }

  final String id;
  final String name;
  final String displayName;
  final double? weight;
}

class SuggestResourcesRequest {
  const SuggestResourcesRequest({
    required this.text,
    this.themeIds,
  });

  final String text;
  final List<String>? themeIds;

  Map<String, Object?> toJson() {
    return {
      'text': text,
      if (themeIds != null) 'themeIds': themeIds,
    };
  }
}

class SuggestResourcesResponse {
  const SuggestResourcesResponse({required this.suggestions});

  factory SuggestResourcesResponse.fromJson(Map<String, Object?> json) {
    final suggestions = json['suggestions'];

    if (suggestions is! List<Object?>) {
      throw const FormatException('Expected suggestions array.');
    }

    return SuggestResourcesResponse(
      suggestions: suggestions
          .whereType<Map<String, Object?>>()
          .map(ApiRelatedResourceSuggestion.fromJson)
          .toList(growable: false),
    );
  }

  final List<ApiRelatedResourceSuggestion> suggestions;
}

class ApiRelatedResourceSuggestion {
  const ApiRelatedResourceSuggestion({
    required this.id,
    required this.type,
    required this.title,
    required this.sourceType,
    required this.matchReason,
    required this.confidence,
    this.description,
    this.url,
    this.entryId,
    this.themeId,
  });

  factory ApiRelatedResourceSuggestion.fromJson(Map<String, Object?> json) {
    return ApiRelatedResourceSuggestion(
      id: _requiredString(json, 'id'),
      type: _requiredString(json, 'type'),
      title: _requiredString(json, 'title'),
      sourceType: _requiredString(json, 'sourceType'),
      matchReason: _requiredString(json, 'matchReason'),
      confidence: _requiredNumber(json, 'confidence'),
      description: _optionalString(json, 'description'),
      url: _optionalString(json, 'url'),
      entryId: _optionalString(json, 'entryId'),
      themeId: _optionalString(json, 'themeId'),
    );
  }

  final String id;
  final String type;
  final String title;
  final String sourceType;
  final String matchReason;
  final double confidence;
  final String? description;
  final String? url;
  final String? entryId;
  final String? themeId;
}

class ResourceFeedbackRequest {
  const ResourceFeedbackRequest({
    required this.resourceId,
    required this.action,
    this.entryId,
    this.themeId,
    this.note,
  });

  final String resourceId;
  final String action;
  final String? entryId;
  final String? themeId;
  final String? note;

  Map<String, Object?> toJson() {
    return {
      'resourceId': resourceId,
      'action': action,
      if (entryId != null) 'entryId': entryId,
      if (themeId != null) 'themeId': themeId,
      if (note != null) 'note': note,
    };
  }
}

class ResourceFeedbackResponse {
  const ResourceFeedbackResponse({required this.status});

  factory ResourceFeedbackResponse.fromJson(Map<String, Object?> json) {
    return ResourceFeedbackResponse(status: _requiredString(json, 'status'));
  }

  final String status;
}

class ApiError {
  const ApiError({required this.error, this.message});

  factory ApiError.fromJson(Map<String, Object?> json) {
    return ApiError(
      error: _requiredString(json, 'error'),
      message: _optionalString(json, 'message'),
    );
  }

  final String error;
  final String? message;
}

class LumenApiException implements Exception {
  const LumenApiException(this.statusCode, this.error);

  final int statusCode;
  final ApiError error;

  @override
  String toString() {
    final message = error.message;

    if (message == null) {
      return 'LumenApiException($statusCode, \${error.error})';
    }

    return 'LumenApiException($statusCode, \${error.error}: $message)';
  }
}

String _requiredString(Map<String, Object?> json, String key) {
  final value = json[key];

  if (value is String) {
    return value;
  }

  throw FormatException('Expected string "$key".');
}

bool _requiredBool(Map<String, Object?> json, String key) {
  final value = json[key];

  if (value is bool) {
    return value;
  }

  throw FormatException('Expected required bool "\$key".');
}

String? _optionalString(Map<String, Object?> json, String key) {
  final value = json[key];

  if (value == null) {
    return null;
  }

  if (value is String) {
    return value;
  }

  throw FormatException('Expected optional string "$key".');
}

double? _optionalNumber(Map<String, Object?> json, String key) {
  final value = json[key];

  if (value == null) {
    return null;
  }

  if (value is num) {
    return value.toDouble();
  }

  throw FormatException('Expected optional number "$key".');
}

double _requiredNumber(Map<String, Object?> json, String key) {
  final value = json[key];

  if (value is num) {
    return value.toDouble();
  }

  throw FormatException('Expected number "$key".');
}
`;

if (process.argv.includes('--check')) {
  const existing = fs.readFileSync(outputPath, 'utf8');

  if (existing !== output) {
    console.error('Generated Flutter API client is out of date.');
    process.exit(1);
  }

  console.log('Generated Flutter API client is up to date.');
} else {
  fs.mkdirSync(path.dirname(outputPath), { recursive: true });
  fs.writeFileSync(outputPath, output);
  console.log(`Wrote ${path.relative(repoRoot, outputPath)}`);
}

function assertOperation(route, method, operationId) {
  const operation = contract.paths?.[route]?.[method];

  if (operation?.operationId !== operationId) {
    throw new Error(`Expected ${method.toUpperCase()} ${route} ${operationId}`);
  }
}
