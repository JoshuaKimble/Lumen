import '../domain/entry_source.dart';
import '../domain/journal_entry.dart';
import '../domain/journal_theme.dart';
import '../domain/related_resource.dart';
import '../domain/study_guide.dart';

class JournalEntryJsonMapper {
  const JournalEntryJsonMapper();

  Map<String, Object?> toJson(JournalEntry entry) {
    return {
      'id': entry.id,
      'createdAt': entry.createdAt.toIso8601String(),
      'updatedAt': entry.updatedAt.toIso8601String(),
      'source': entry.source.name,
      'originalText': entry.originalText,
      'rewrittenText': entry.rewrittenText,
      'themes': entry.themes.map(_themeToJson).toList(growable: false),
      'resources': entry.resources.map(_resourceToJson).toList(growable: false),
      'studyGuide': entry.studyGuide == null
          ? null
          : _studyGuideToJson(entry.studyGuide!),
      'title': entry.title,
      'summary': entry.summary,
      'lastRegeneratedAt': entry.lastRegeneratedAt?.toIso8601String(),
    };
  }

  JournalEntry fromJson(Map<String, Object?> json) {
    final studyGuideJson = _optionalObjectValue(json, 'studyGuide');

    return JournalEntry(
      id: _stringValue(json, 'id'),
      createdAt: DateTime.parse(_stringValue(json, 'createdAt')),
      updatedAt: DateTime.parse(_stringValue(json, 'updatedAt')),
      source: EntrySource.values.byName(_stringValue(json, 'source')),
      originalText: _stringValue(json, 'originalText'),
      rewrittenText: _stringValue(json, 'rewrittenText'),
      themes: _objectList(
        json,
        'themes',
      ).map(_themeFromJson).toList(growable: false),
      resources: _objectList(
        json,
        'resources',
      ).map(_resourceFromJson).toList(growable: false),
      studyGuide: studyGuideJson == null
          ? null
          : _studyGuideFromJson(studyGuideJson),
      title: _optionalStringValue(json, 'title'),
      summary: _optionalStringValue(json, 'summary'),
      lastRegeneratedAt: _optionalDateTimeValue(json, 'lastRegeneratedAt'),
    );
  }

  Map<String, Object?> _themeToJson(JournalTheme theme) {
    return {
      'id': theme.id,
      'name': theme.name,
      'displayName': theme.displayName,
      'weight': theme.weight,
    };
  }

  JournalTheme _themeFromJson(Map<String, Object?> json) {
    return JournalTheme(
      id: _stringValue(json, 'id'),
      name: _stringValue(json, 'name'),
      displayName: _stringValue(json, 'displayName'),
      weight: _optionalDoubleValue(json, 'weight'),
    );
  }

  Map<String, Object?> _resourceToJson(RelatedResource resource) {
    return {
      'id': resource.id,
      'title': resource.title,
      'type': resource.type,
      'url': resource.url?.toString(),
      'entryId': resource.entryId,
      'themeId': resource.themeId,
      'sourceType': resource.sourceType,
      'matchReason': resource.matchReason,
      'confidence': resource.confidence,
      'description': resource.description,
    };
  }

  RelatedResource _resourceFromJson(Map<String, Object?> json) {
    final url = _optionalStringValue(json, 'url');

    return RelatedResource(
      id: _stringValue(json, 'id'),
      title: _stringValue(json, 'title'),
      type: _stringValue(json, 'type'),
      url: url == null ? null : Uri.parse(url),
      entryId: _optionalStringValue(json, 'entryId'),
      themeId: _optionalStringValue(json, 'themeId'),
      sourceType: _optionalStringValue(json, 'sourceType') ?? 'curated',
      matchReason:
          _optionalStringValue(json, 'matchReason') ??
          'Related to your reflection.',
      confidence: _optionalDoubleValue(json, 'confidence') ?? 0.75,
      description: _optionalStringValue(json, 'description'),
    );
  }

  Map<String, Object?> _studyGuideToJson(StudyGuide studyGuide) {
    return {
      'id': studyGuide.id,
      'entryId': studyGuide.entryId,
      'providerKey': studyGuide.providerKey,
      'generatedAt': studyGuide.generatedAt.toIso8601String(),
      'overview': studyGuide.overview,
      'previewText': studyGuide.previewText,
      'items': studyGuide.items
          .map(_studyGuideItemToJson)
          .toList(growable: false),
      'reflectionPrompt': _studyGuidePromptToJson(studyGuide.reflectionPrompt),
    };
  }

  StudyGuide _studyGuideFromJson(Map<String, Object?> json) {
    return StudyGuide(
      id: _stringValue(json, 'id'),
      entryId: _stringValue(json, 'entryId'),
      providerKey: _stringValue(json, 'providerKey'),
      generatedAt: DateTime.parse(_stringValue(json, 'generatedAt')),
      overview: _stringValue(json, 'overview'),
      previewText: _stringValue(json, 'previewText'),
      items: _objectList(
        json,
        'items',
      ).map(_studyGuideItemFromJson).toList(growable: false),
      reflectionPrompt: _studyGuidePromptFromJson(
        _objectValue(json, 'reflectionPrompt'),
      ),
    );
  }

  Map<String, Object?> _studyGuideItemToJson(StudyGuideItem item) {
    return {
      'id': item.id,
      'kind': item.kind,
      'title': item.title,
      'contextLine': item.contextLine,
      'position': item.position,
      'destination': _studyGuideDestinationToJson(item.destination),
      'focusText': item.focusText,
      'quote': item.quote,
      'author': item.author,
      'publishedContext': item.publishedContext,
    };
  }

  StudyGuideItem _studyGuideItemFromJson(Map<String, Object?> json) {
    return StudyGuideItem(
      id: _stringValue(json, 'id'),
      kind: _stringValue(json, 'kind'),
      title: _stringValue(json, 'title'),
      contextLine: _stringValue(json, 'contextLine'),
      position: _intValue(json, 'position'),
      destination: _studyGuideDestinationFromJson(
        _objectValue(json, 'destination'),
      ),
      focusText: _optionalStringValue(json, 'focusText'),
      quote: _optionalStringValue(json, 'quote'),
      author: _optionalStringValue(json, 'author'),
      publishedContext: _optionalStringValue(json, 'publishedContext'),
    );
  }

  Map<String, Object?> _studyGuidePromptToJson(StudyGuidePrompt prompt) {
    return {'text': prompt.text};
  }

  StudyGuidePrompt _studyGuidePromptFromJson(Map<String, Object?> json) {
    return StudyGuidePrompt(text: _stringValue(json, 'text'));
  }

  Map<String, Object?> _studyGuideDestinationToJson(
    StudyGuideDestination destination,
  ) {
    return {
      'providerKey': destination.providerKey,
      'contentType': destination.contentType,
      'reference': destination.reference,
      'url': destination.url?.toString(),
      'precision': destination.precision.name,
    };
  }

  StudyGuideDestination _studyGuideDestinationFromJson(
    Map<String, Object?> json,
  ) {
    final url = _optionalStringValue(json, 'url');

    return StudyGuideDestination(
      providerKey: _stringValue(json, 'providerKey'),
      contentType: _stringValue(json, 'contentType'),
      reference: _stringValue(json, 'reference'),
      url: url == null ? null : Uri.parse(url),
      precision: StudyGuideDestinationPrecision.values.byName(
        _stringValue(json, 'precision'),
      ),
    );
  }

  List<Map<String, Object?>> _objectList(
    Map<String, Object?> json,
    String key,
  ) {
    final value = json[key];

    if (value is! List<Object?>) {
      return const [];
    }

    return value.whereType<Map<String, Object?>>().toList(growable: false);
  }

  Map<String, Object?> _objectValue(Map<String, Object?> json, String key) {
    final value = json[key];

    if (value is Map<String, Object?>) {
      return value;
    }

    throw FormatException('Expected object value for "$key".');
  }

  Map<String, Object?>? _optionalObjectValue(
    Map<String, Object?> json,
    String key,
  ) {
    final value = json[key];

    if (value == null) {
      return null;
    }

    if (value is Map<String, Object?>) {
      return value;
    }

    throw FormatException('Expected optional object value for "$key".');
  }

  String _stringValue(Map<String, Object?> json, String key) {
    final value = json[key];

    if (value is String) {
      return value;
    }

    throw FormatException('Expected string value for "$key".');
  }

  String? _optionalStringValue(Map<String, Object?> json, String key) {
    final value = json[key];

    if (value == null) {
      return null;
    }

    if (value is String) {
      return value;
    }

    throw FormatException('Expected optional string value for "$key".');
  }

  double? _optionalDoubleValue(Map<String, Object?> json, String key) {
    final value = json[key];

    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    throw FormatException('Expected optional number value for "$key".');
  }

  int _intValue(Map<String, Object?> json, String key) {
    final value = json[key];

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    throw FormatException('Expected integer value for "$key".');
  }

  DateTime? _optionalDateTimeValue(Map<String, Object?> json, String key) {
    final value = _optionalStringValue(json, key);

    if (value == null) {
      return null;
    }

    return DateTime.parse(value);
  }
}
