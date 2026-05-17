import '../../settings/domain/scripture_app_preference.dart';
import '../domain/related_resource.dart';

class ScriptureResourceLinkResolver {
  const ScriptureResourceLinkResolver();

  Uri? resolve(
    RelatedResource resource, {
    required ScriptureAppPreference preference,
  }) {
    final existingUrl = resource.url;
    final normalizedType = resource.type.toLowerCase();
    final reference = (resource.scriptureReference ?? resource.title).trim();

    if (reference.isEmpty) {
      return existingUrl;
    }

    if (normalizedType != 'scripture' &&
        normalizedType != 'talk_or_article' &&
        normalizedType != 'quote') {
      return existingUrl;
    }

    return switch (preference) {
      ScriptureAppPreference.none => existingUrl,
      ScriptureAppPreference.gospelLibrary => _gospelLibraryUrl(
        reference: reference,
        fallback: existingUrl,
      ),
      ScriptureAppPreference.youVersion => _youVersionUrl(
        reference: reference,
        fallback: existingUrl,
      ),
      ScriptureAppPreference.bibleGateway => _bibleGatewayUrl(
        reference: reference,
        fallback: existingUrl,
      ),
      ScriptureAppPreference.catholic => _catholicFallbackUrl(
        reference: reference,
        fallback: existingUrl,
      ),
    };
  }

  Uri _gospelLibraryUrl({required String reference, Uri? fallback}) {
    return Uri.https('www.churchofjesuschrist.org', '/search', {
      'lang': 'eng',
      'query': reference,
      'facet': 'scriptures',
    });
  }

  Uri _youVersionUrl({required String reference, Uri? fallback}) {
    return Uri.https('www.bible.com', '/search/bible', {'query': reference});
  }

  Uri _bibleGatewayUrl({required String reference, Uri? fallback}) {
    return Uri.https('www.biblegateway.com', '/passage/', {
      'search': reference,
    });
  }

  Uri _catholicFallbackUrl({required String reference, Uri? fallback}) {
    return Uri.https('bible.usccb.org', '/search', {
      'search_api_fulltext': reference,
    });
  }
}
