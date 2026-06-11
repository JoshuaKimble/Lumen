import 'package:flutter/foundation.dart';

import 'journal_theme.dart';

@immutable
class TranscriptionResult {
  const TranscriptionResult({required this.transcript});

  final String transcript;
}

@immutable
class RewriteResult {
  const RewriteResult({required this.rewrittenText, this.title, this.summary});

  final String rewrittenText;
  final String? title;
  final String? summary;
}

@immutable
class EntrySummaryResult {
  const EntrySummaryResult({this.title, this.summary});

  final String? title;
  final String? summary;
}

@immutable
class ThemeDetectionResult {
  const ThemeDetectionResult({required this.themes});

  final List<JournalTheme> themes;
}
