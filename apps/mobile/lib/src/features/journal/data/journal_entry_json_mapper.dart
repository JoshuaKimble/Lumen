import '../domain/entry_source.dart';
import '../domain/journal_entry.dart';
import '../domain/journal_theme.dart';
import '../domain/related_resource.dart';

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
      'title': entry.title,
      'summary': entry.summary,
      'lastRegeneratedAt': entry.lastRegeneratedAt?.toIso8601String(),
    };
  }

  JournalEntry fromJson(Map<String, Object?> json) {
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

  DateTime? _optionalDateTimeValue(Map<String, Object?> json, String key) {
    final value = _optionalStringValue(json, key);

    if (value == null) {
      return null;
    }

    return DateTime.parse(value);
  }
}
