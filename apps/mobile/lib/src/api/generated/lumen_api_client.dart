// Generated from packages/api_contracts/openapi/openapi.json.
// Regenerate with: npm --prefix packages/api_contracts run generate:flutter
// Do not edit by hand.

import 'dart:convert';

import 'package:http/http.dart' as http;

class LumenApiClient {
  const LumenApiClient({required this.baseUri, required this.httpClient});

  final Uri baseUri;
  final http.Client httpClient;

  Future<RewriteEntryResponse> rewriteEntry(RewriteEntryRequest request) async {
    final response = await _postJson('/v1/entries/rewrite', request.toJson());

    return RewriteEntryResponse.fromJson(response);
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

  Future<Map<String, Object?>> _postJson(
    String path,
    Map<String, Object?> body,
  ) async {
    final response = await httpClient.post(
      baseUri.resolve(path),
      headers: const {'content-type': 'application/json'},
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
}

class RewriteEntryRequest {
  const RewriteEntryRequest({required this.originalText});

  final String originalText;

  Map<String, Object?> toJson() {
    return {'originalText': originalText};
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
