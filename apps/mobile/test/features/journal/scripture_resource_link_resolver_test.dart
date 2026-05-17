import 'package:flutter_test/flutter_test.dart';
import 'package:lumen/src/features/journal/data/scripture_resource_link_resolver.dart';
import 'package:lumen/src/features/journal/domain/related_resource.dart';
import 'package:lumen/src/features/settings/domain/scripture_app_preference.dart';

void main() {
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
}
