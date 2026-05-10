import 'package:flutter/foundation.dart';

import 'ai_results.dart';
import 'entry_source.dart';
import 'journal_theme.dart';
import 'related_resource.dart';

@immutable
class JournalEntry {
  const JournalEntry({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.source,
    required this.originalText,
    required this.rewrittenText,
    required this.themes,
    required this.resources,
    this.title,
    this.summary,
    this.lastRegeneratedAt,
  });

  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final EntrySource source;
  final String originalText;
  final String rewrittenText;
  final List<JournalTheme> themes;
  final List<RelatedResource> resources;
  final String? title;
  final String? summary;
  final DateTime? lastRegeneratedAt;

  String get displayTitle => title ?? 'Untitled entry';

  String get previewText {
    if (rewrittenText.isNotEmpty) {
      return rewrittenText;
    }

    return originalText;
  }

  JournalEntry applyRewrite({
    required RewriteResult rewrite,
    required DateTime updatedAt,
  }) {
    return JournalEntry(
      id: id,
      createdAt: createdAt,
      updatedAt: updatedAt,
      source: source,
      originalText: originalText,
      rewrittenText: rewrite.rewrittenText,
      themes: themes,
      resources: resources,
      title: rewrite.title ?? title,
      summary: rewrite.summary ?? summary,
      lastRegeneratedAt: updatedAt,
    );
  }

  JournalEntry applyAiResults({
    required RewriteResult rewrite,
    required ThemeDetectionResult themeDetection,
    required DateTime updatedAt,
    bool preserveTitle = false,
  }) {
    return JournalEntry(
      id: id,
      createdAt: createdAt,
      updatedAt: updatedAt,
      source: source,
      originalText: originalText,
      rewrittenText: rewrite.rewrittenText,
      themes: themeDetection.themes,
      resources: resources,
      title: preserveTitle ? title : rewrite.title ?? title,
      summary: rewrite.summary ?? summary,
      lastRegeneratedAt: updatedAt,
    );
  }

  JournalEntry withoutAiResults({required DateTime updatedAt}) {
    return JournalEntry(
      id: id,
      createdAt: createdAt,
      updatedAt: updatedAt,
      source: source,
      originalText: originalText,
      rewrittenText: '',
      themes: const [],
      resources: resources,
      title: title,
      summary: null,
    );
  }
}
