import 'package:flutter/foundation.dart';

@immutable
class StudyGuide {
  const StudyGuide({
    required this.id,
    required this.entryId,
    required this.providerKey,
    required this.generatedAt,
    required this.overview,
    required this.previewText,
    required this.items,
    required this.reflectionPrompt,
  });

  final String id;
  final String entryId;
  final String providerKey;
  final DateTime generatedAt;
  final String overview;
  final String previewText;
  final List<StudyGuideItem> items;
  final StudyGuidePrompt reflectionPrompt;

  StudyGuide copyWith({
    String? id,
    String? entryId,
    String? providerKey,
    DateTime? generatedAt,
    String? overview,
    String? previewText,
    List<StudyGuideItem>? items,
    StudyGuidePrompt? reflectionPrompt,
  }) {
    return StudyGuide(
      id: id ?? this.id,
      entryId: entryId ?? this.entryId,
      providerKey: providerKey ?? this.providerKey,
      generatedAt: generatedAt ?? this.generatedAt,
      overview: overview ?? this.overview,
      previewText: previewText ?? this.previewText,
      items: items ?? this.items,
      reflectionPrompt: reflectionPrompt ?? this.reflectionPrompt,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is StudyGuide &&
        other.id == id &&
        other.entryId == entryId &&
        other.providerKey == providerKey &&
        other.generatedAt == generatedAt &&
        other.overview == overview &&
        other.previewText == previewText &&
        _sameItems(other.items, items) &&
        other.reflectionPrompt == reflectionPrompt;
  }

  @override
  int get hashCode => Object.hash(
    id,
    entryId,
    providerKey,
    generatedAt,
    overview,
    previewText,
    Object.hashAll(items),
    reflectionPrompt,
  );

  bool _sameItems(List<StudyGuideItem> left, List<StudyGuideItem> right) {
    if (left.length != right.length) {
      return false;
    }

    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) {
        return false;
      }
    }

    return true;
  }
}

@immutable
class StudyGuideItem {
  const StudyGuideItem({
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

  final String id;
  final String kind;
  final String title;
  final String contextLine;
  final int position;
  final StudyGuideDestination destination;
  final String? focusText;
  final String? quote;
  final String? author;
  final String? publishedContext;

  StudyGuideItem copyWith({
    String? id,
    String? kind,
    String? title,
    String? contextLine,
    int? position,
    StudyGuideDestination? destination,
    String? focusText,
    String? quote,
    String? author,
    String? publishedContext,
  }) {
    return StudyGuideItem(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      title: title ?? this.title,
      contextLine: contextLine ?? this.contextLine,
      position: position ?? this.position,
      destination: destination ?? this.destination,
      focusText: focusText ?? this.focusText,
      quote: quote ?? this.quote,
      author: author ?? this.author,
      publishedContext: publishedContext ?? this.publishedContext,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is StudyGuideItem &&
        other.id == id &&
        other.kind == kind &&
        other.title == title &&
        other.contextLine == contextLine &&
        other.position == position &&
        other.destination == destination &&
        other.focusText == focusText &&
        other.quote == quote &&
        other.author == author &&
        other.publishedContext == publishedContext;
  }

  @override
  int get hashCode => Object.hash(
    id,
    kind,
    title,
    contextLine,
    position,
    destination,
    focusText,
    quote,
    author,
    publishedContext,
  );
}

@immutable
class StudyGuidePrompt {
  const StudyGuidePrompt({required this.text});

  final String text;

  StudyGuidePrompt copyWith({String? text}) {
    return StudyGuidePrompt(text: text ?? this.text);
  }

  @override
  bool operator ==(Object other) {
    return other is StudyGuidePrompt && other.text == text;
  }

  @override
  int get hashCode => text.hashCode;
}

@immutable
class StudyGuideDestination {
  const StudyGuideDestination({
    required this.providerKey,
    required this.contentType,
    required this.reference,
    required this.precision,
    this.url,
  });

  final String providerKey;
  final String contentType;
  final String reference;
  final Uri? url;
  final StudyGuideDestinationPrecision precision;

  StudyGuideDestination copyWith({
    String? providerKey,
    String? contentType,
    String? reference,
    Uri? url,
    StudyGuideDestinationPrecision? precision,
  }) {
    return StudyGuideDestination(
      providerKey: providerKey ?? this.providerKey,
      contentType: contentType ?? this.contentType,
      reference: reference ?? this.reference,
      url: url ?? this.url,
      precision: precision ?? this.precision,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is StudyGuideDestination &&
        other.providerKey == providerKey &&
        other.contentType == contentType &&
        other.reference == reference &&
        other.url == url &&
        other.precision == precision;
  }

  @override
  int get hashCode =>
      Object.hash(providerKey, contentType, reference, url, precision);
}

enum StudyGuideDestinationPrecision {
  verseRange,
  chapter,
  document,
  webFallback,
}
