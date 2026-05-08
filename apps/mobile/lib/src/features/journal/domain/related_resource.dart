import 'package:flutter/foundation.dart';

@immutable
class RelatedResource {
  const RelatedResource({
    required this.id,
    required this.title,
    required this.type,
    this.url,
    this.entryId,
    this.themeId,
  });

  final String id;
  final String title;
  final String type;
  final Uri? url;
  final String? entryId;
  final String? themeId;
}
