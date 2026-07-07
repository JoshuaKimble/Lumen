import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/study_guide.dart';

final studyGuideLinkResolverProvider = Provider<StudyGuideLinkResolver>((ref) {
  return const DefaultStudyGuideLinkResolver();
});

@immutable
class ResolvedStudyGuideLink {
  const ResolvedStudyGuideLink({
    required this.uri,
    required this.precision,
    required this.providerKey,
    required this.contentType,
  });

  final Uri uri;
  final StudyGuideDestinationPrecision precision;
  final String providerKey;
  final String contentType;
}

abstract interface class StudyGuideLinkResolver {
  ResolvedStudyGuideLink? resolve(StudyGuideDestination destination);
}

abstract interface class StudyGuideProviderLinkAdapter {
  ResolvedStudyGuideLink? resolve(StudyGuideDestination destination);
}

class DefaultStudyGuideLinkResolver implements StudyGuideLinkResolver {
  const DefaultStudyGuideLinkResolver({
    StudyGuideProviderLinkAdapter? gospelLibraryAdapter,
  }) : _gospelLibraryAdapter =
           gospelLibraryAdapter ?? const GospelLibraryStudyGuideLinkAdapter();

  final StudyGuideProviderLinkAdapter _gospelLibraryAdapter;

  @override
  ResolvedStudyGuideLink? resolve(StudyGuideDestination destination) {
    return switch (destination.providerKey) {
      'gospel_library' => _gospelLibraryAdapter.resolve(destination),
      _ => _fallbackResolvedLink(destination),
    };
  }

  ResolvedStudyGuideLink? _fallbackResolvedLink(
    StudyGuideDestination destination,
  ) {
    final url = destination.url;
    if (url == null) {
      return null;
    }

    return ResolvedStudyGuideLink(
      uri: url,
      precision: StudyGuideDestinationPrecision.webFallback,
      providerKey: destination.providerKey,
      contentType: destination.contentType,
    );
  }
}

class GospelLibraryStudyGuideLinkAdapter
    implements StudyGuideProviderLinkAdapter {
  const GospelLibraryStudyGuideLinkAdapter();

  @override
  ResolvedStudyGuideLink? resolve(StudyGuideDestination destination) {
    return switch (destination.contentType) {
      'scripture' => _resolveScripture(destination),
      'conference_talk' => _resolveConferenceTalk(destination),
      _ => _resolveFallback(destination),
    };
  }

  ResolvedStudyGuideLink? _resolveScripture(StudyGuideDestination destination) {
    final url = destination.url;
    if (url == null) {
      return null;
    }

    return ResolvedStudyGuideLink(
      uri: url,
      precision: switch (destination.precision) {
        StudyGuideDestinationPrecision.verseRange =>
          StudyGuideDestinationPrecision.chapter,
        StudyGuideDestinationPrecision.chapter =>
          StudyGuideDestinationPrecision.chapter,
        _ => StudyGuideDestinationPrecision.chapter,
      },
      providerKey: destination.providerKey,
      contentType: destination.contentType,
    );
  }

  ResolvedStudyGuideLink? _resolveConferenceTalk(
    StudyGuideDestination destination,
  ) {
    final url = destination.url;
    if (url == null) {
      return null;
    }

    return ResolvedStudyGuideLink(
      uri: url,
      precision: StudyGuideDestinationPrecision.document,
      providerKey: destination.providerKey,
      contentType: destination.contentType,
    );
  }

  ResolvedStudyGuideLink? _resolveFallback(StudyGuideDestination destination) {
    final url = destination.url;
    if (url == null) {
      return null;
    }

    return ResolvedStudyGuideLink(
      uri: url,
      precision: StudyGuideDestinationPrecision.webFallback,
      providerKey: destination.providerKey,
      contentType: destination.contentType,
    );
  }
}
