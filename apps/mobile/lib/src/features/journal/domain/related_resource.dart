import 'package:flutter/foundation.dart';

@immutable
class RelatedResource {
  const RelatedResource({
    required this.id,
    required this.title,
    required this.type,
    this.sourceType = 'curated',
    this.matchReason = 'Related to your reflection.',
    this.confidence = 0.75,
    this.url,
    this.scriptureReference,
    this.entryId,
    this.themeId,
    this.description,
  });

  final String id;
  final String title;
  final String type;
  final String sourceType;
  final String matchReason;
  final double confidence;
  final Uri? url;
  final String? scriptureReference;
  final String? entryId;
  final String? themeId;
  final String? description;
}
