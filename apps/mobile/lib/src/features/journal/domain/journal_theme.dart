import 'package:flutter/foundation.dart';

@immutable
class JournalTheme {
  const JournalTheme({
    required this.id,
    required this.name,
    required this.displayName,
    this.weight,
  });

  final String id;
  final String name;
  final String displayName;
  final double? weight;
}
