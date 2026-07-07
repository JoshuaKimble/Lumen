import 'package:flutter_test/flutter_test.dart';
import 'package:lumen/src/features/journal/data/scripture_resource_link_resolver.dart';
import 'package:lumen/src/features/journal/data/study_guide_link_resolver.dart';
import 'package:lumen/src/features/journal/domain/related_resource.dart';
import 'package:lumen/src/features/journal/domain/study_guide.dart';
import 'package:lumen/src/features/settings/domain/scripture_app_preference.dart';

void main() {
  group('ScriptureResourceLinkResolver', () {
    const resolver = ScriptureResourceLinkResolver();
    final resource = RelatedResource(
      id: 'faith-scripture-psalm-46-10',
      title: 'Psalm 46:10',
      scriptureReference: 'Psalm 46:10',
      type: 'scripture',
      sourceType: 'curated',
      matchReason: 'faith match',
      confidence: 0.8,
      url: Uri.parse('https://example.com/fallback'),
    );

    test('uses Gospel Library search URL for gospel library preference', () {
      final url = resolver.resolve(
        resource,
        preference: ScriptureAppPreference.gospelLibrary,
      );

      expect(url?.host, 'www.churchofjesuschrist.org');
      expect(url?.path, '/search');
    });

    test('uses YouVersion search URL for YouVersion preference', () {
      final url = resolver.resolve(
        resource,
        preference: ScriptureAppPreference.youVersion,
      );

      expect(url?.host, 'www.bible.com');
      expect(url?.path, '/search/bible');
    });

    test('uses Bible Gateway passage URL for bible gateway preference', () {
      final url = resolver.resolve(
        resource,
        preference: ScriptureAppPreference.bibleGateway,
      );

      expect(url?.host, 'www.biblegateway.com');
      expect(url?.path, '/passage/');
    });

    test('uses catholic-friendly fallback URL for catholic preference', () {
      final url = resolver.resolve(
        resource,
        preference: ScriptureAppPreference.catholic,
      );

      expect(url?.host, 'bible.usccb.org');
      expect(url?.path, '/search');
    });

    test('returns resource URL when preference is none', () {
      final url = resolver.resolve(
        resource,
        preference: ScriptureAppPreference.none,
      );
      expect(url, resource.url);
    });
  });

  group('DefaultStudyGuideLinkResolver', () {
    const resolver = DefaultStudyGuideLinkResolver();

    test('resolves scripture destinations to canonical chapter URLs', () {
      final link = resolver.resolve(
        StudyGuideDestination(
          providerKey: 'gospel_library',
          contentType: 'scripture',
          reference: 'Psalm 46:10',
          url: Uri.parse(
            'https://www.churchofjesuschrist.org/study/scriptures/ot/ps/46?lang=eng',
          ),
          precision: StudyGuideDestinationPrecision.chapter,
        ),
      );

      expect(link, isNotNull);
      expect(link?.uri.host, 'www.churchofjesuschrist.org');
      expect(link?.precision, StudyGuideDestinationPrecision.chapter);
    });

    test('degrades verse-range scripture destinations to chapter precision', () {
      final link = resolver.resolve(
        StudyGuideDestination(
          providerKey: 'gospel_library',
          contentType: 'scripture',
          reference: '3 Nephi 1:6-12',
          url: Uri.parse(
            'https://www.churchofjesuschrist.org/study/scriptures/bofm/3-ne/1?lang=eng',
          ),
          precision: StudyGuideDestinationPrecision.verseRange,
        ),
      );

      expect(link, isNotNull);
      expect(link?.precision, StudyGuideDestinationPrecision.chapter);
    });

    test('resolves conference talks to document precision', () {
      final link = resolver.resolve(
        StudyGuideDestination(
          providerKey: 'gospel_library',
          contentType: 'conference_talk',
          reference: 'Nourish the Roots, and the Branches Will Grow',
          url: Uri.parse(
            'https://www.churchofjesuschrist.org/study/general-conference/2024/10/51uchtdorf?lang=eng',
          ),
          precision: StudyGuideDestinationPrecision.document,
        ),
      );

      expect(link, isNotNull);
      expect(link?.precision, StudyGuideDestinationPrecision.document);
      expect(link?.uri.path, '/study/general-conference/2024/10/51uchtdorf');
    });

    test('returns null for unsupported gospel library content without URL', () {
      final link = resolver.resolve(
        const StudyGuideDestination(
          providerKey: 'gospel_library',
          contentType: 'unsupported',
          reference: 'unknown',
          precision: StudyGuideDestinationPrecision.webFallback,
        ),
      );

      expect(link, isNull);
    });
  });
}
