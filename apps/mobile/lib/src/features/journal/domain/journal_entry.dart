import 'package:flutter/foundation.dart';

@immutable
class JournalEntry {
  const JournalEntry({
    required this.id,
    required this.title,
    required this.body,
  });

  final String id;
  final String title;
  final String body;
}
