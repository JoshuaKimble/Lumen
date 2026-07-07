// Generated from packages/api_contracts/openapi/openapi.json.
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

  Future<SummarizeEntryResponse> summarizeEntry(
    SummarizeEntryRequest request,
  ) async {
    final response = await _postJson('/v1/entries/summarize', request.toJson());

    return SummarizeEntryResponse.fromJson(response);
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

  Future<GenerateStudyGuideResponse> generateStudyGuide(
    GenerateStudyGuideRequest request,
  ) async {
    final response = await _postJson(
      '/v1/study-guides/generate',
      request.toJson(),
    );

    return GenerateStudyGuideResponse.fromJson(response);
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

  Future<DeleteAccountResponse> deleteAccount(DeleteAccountRequest request) async {
    final response = await _postJson(
      '/v1/account/delete',
      request.toJson(),
      requiresAuth: true,
    );

    return DeleteAccountResponse.fromJson(response);
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

    headers['authorization'] = 'Bearer ${token.trim()}';
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

class SummarizeEntryRequest {
  const SummarizeEntryRequest({required this.originalText});

  final String originalText;

  Map<String, Object?> toJson() {
    return {'originalText': originalText};
  }
}

class SummarizeEntryResponse {
  const SummarizeEntryResponse({this.title, this.summary});

  factory SummarizeEntryResponse.fromJson(Map<String, Object?> json) {
    return SummarizeEntryResponse(
      title: _optionalString(json, 'title'),
      summary: _optionalString(json, 'summary'),
    );
  }

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

class GenerateStudyGuideRequest {
  const GenerateStudyGuideRequest({
    required this.entryId,
    required this.originalText,
    required this.providerKey,
    this.themeIds,
  });

  final String entryId;
  final String originalText;
  final String providerKey;
  final List<String>? themeIds;

  Map<String, Object?> toJson() {
    return {
      'entryId': entryId,
      'originalText': originalText,
      'providerKey': providerKey,
      if (themeIds != null) 'themeIds': themeIds,
    };
  }
}

class GenerateStudyGuideResponse {
  const GenerateStudyGuideResponse({
    required this.guideId,
    required this.entryId,
    required this.providerKey,
    required this.generatedAt,
    required this.overview,
    required this.previewText,
    required this.items,
    required this.reflectionPrompt,
  });

  factory GenerateStudyGuideResponse.fromJson(Map<String, Object?> json) {
    final items = json['items'];
    final reflectionPrompt = json['reflectionPrompt'];

    if (items is! List<Object?>) {
      throw const FormatException('Expected study guide items array.');
    }

    if (reflectionPrompt is! Map<String, Object?>) {
      throw const FormatException('Expected reflection prompt object.');
    }

    return GenerateStudyGuideResponse(
      guideId: _requiredString(json, 'guideId'),
      entryId: _requiredString(json, 'entryId'),
      providerKey: _requiredString(json, 'providerKey'),
      generatedAt: DateTime.parse(_requiredString(json, 'generatedAt')),
      overview: _requiredString(json, 'overview'),
      previewText: _requiredString(json, 'previewText'),
      items: items
          .whereType<Map<String, Object?>>()
          .map(GenerateStudyGuideItem.fromJson)
          .toList(growable: false),
      reflectionPrompt: GenerateStudyGuidePrompt.fromJson(reflectionPrompt),
    );
  }

  final String guideId;
  final String entryId;
  final String providerKey;
  final DateTime generatedAt;
  final String overview;
  final String previewText;
  final List<GenerateStudyGuideItem> items;
  final GenerateStudyGuidePrompt reflectionPrompt;
}

class GenerateStudyGuideItem {
  const GenerateStudyGuideItem({
    required this.id,
    required this.kind,
    required this.title,
    required this.contextLine,
    required this.position,
    required this.destination,
    this.focusText,
    this.quote,
    this.author,
    this.publishedContext,
  });

  factory GenerateStudyGuideItem.fromJson(Map<String, Object?> json) {
    final destination = json['destination'];

    if (destination is! Map<String, Object?>) {
      throw const FormatException('Expected study guide destination object.');
    }

    return GenerateStudyGuideItem(
      id: _requiredString(json, 'id'),
      kind: _requiredString(json, 'kind'),
      title: _requiredString(json, 'title'),
      contextLine: _requiredString(json, 'contextLine'),
      position: _requiredInt(json, 'position'),
      destination: GenerateStudyGuideDestination.fromJson(destination),
      focusText: _optionalString(json, 'focusText'),
      quote: _optionalString(json, 'quote'),
      author: _optionalString(json, 'author'),
      publishedContext: _optionalString(json, 'publishedContext'),
    );
  }

  final String id;
  final String kind;
  final String title;
  final String contextLine;
  final int position;
  final GenerateStudyGuideDestination destination;
  final String? focusText;
  final String? quote;
  final String? author;
  final String? publishedContext;
}

class GenerateStudyGuideDestination {
  const GenerateStudyGuideDestination({
    required this.providerKey,
    required this.contentType,
    required this.reference,
    required this.precision,
    this.url,
  });

  factory GenerateStudyGuideDestination.fromJson(Map<String, Object?> json) {
    return GenerateStudyGuideDestination(
      providerKey: _requiredString(json, 'providerKey'),
      contentType: _requiredString(json, 'contentType'),
      reference: _requiredString(json, 'reference'),
      precision: _requiredString(json, 'precision'),
      url: _optionalString(json, 'url'),
    );
  }

  final String providerKey;
  final String contentType;
  final String reference;
  final String precision;
  final String? url;
}

class GenerateStudyGuidePrompt {
  const GenerateStudyGuidePrompt({required this.text});

  factory GenerateStudyGuidePrompt.fromJson(Map<String, Object?> json) {
    return GenerateStudyGuidePrompt(text: _requiredString(json, 'text'));
  }

  final String text;
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
    this.scriptureReference,
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
      scriptureReference: _optionalString(json, 'scriptureReference'),
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
  final String? scriptureReference;
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

class DeleteAccountRequest {
  const DeleteAccountRequest({required this.confirmation});

  final String confirmation;

  Map<String, Object?> toJson() {
    return {'confirmation': confirmation};
  }
}

class DeleteAccountResponse {
  const DeleteAccountResponse({required this.status});

  factory DeleteAccountResponse.fromJson(Map<String, Object?> json) {
    return DeleteAccountResponse(status: _requiredString(json, 'status'));
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
      return 'LumenApiException($statusCode, ${error.error})';
    }

    return 'LumenApiException($statusCode, ${error.error}: $message)';
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

  throw FormatException('Expected required bool "$key".');
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

int _requiredInt(Map<String, Object?> json, String key) {
  final value = json[key];

  if (value is int) {
    return value;
  }

  throw FormatException('Expected int "$key".');
}
