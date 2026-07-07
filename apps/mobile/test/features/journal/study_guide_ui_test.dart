import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lumen/src/app/lumen_app.dart';
import 'package:lumen/src/features/journal/data/in_memory_journal_repository.dart';
import 'package:lumen/src/features/journal/data/journal_repository_provider.dart';
import 'package:lumen/src/features/journal/data/resource_link_opener.dart';
import 'package:lumen/src/features/journal/data/resource_suggestion_service_provider.dart';
import 'package:lumen/src/features/journal/domain/entry_source.dart';
import 'package:lumen/src/features/journal/domain/journal_entry.dart';
import 'package:lumen/src/features/journal/domain/journal_theme.dart';
import 'package:lumen/src/features/journal/domain/study_guide.dart';
import 'package:lumen/src/features/settings/data/scripture_app_preference_provider.dart';
import 'package:lumen/src/features/settings/domain/scripture_app_preference.dart';
import 'package:lumen/src/features/settings/domain/scripture_app_preference_repository.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  tearDown(() {
    SharedPreferencesAsyncPlatform.instance = null;
  });

  testWidgets(
    'entry detail shows study guide preview CTA and opens dedicated study guide page',
    (tester) async {
      await _pumpStudyGuideApp(tester);

      await tester.tap(find.text('Faith in a difficult week'));
      await tester.pumpAndSettle();

      expect(find.text('Study guide'), findsOneWidget);
      expect(
        find.text('A gospel study guide built from this reflection.'),
        findsOneWidget,
      );
      expect(find.text('Psalm 46:10 and one more resource'), findsOneWidget);

      await tester.tap(find.text('Open study guide'));
      await tester.pumpAndSettle();

      expect(
        find.text('A gospel study guide built from this reflection.'),
        findsOneWidget,
      );
      expect(find.text('Psalm 46:10'), findsOneWidget);
      expect(find.text('Reflect on this'), findsOneWidget);
    },
  );

  testWidgets(
    'manual completion persists and completed resources remain openable',
    (tester) async {
      final opener = _FakeResourceLinkOpener();

      await _pumpStudyGuideApp(tester, opener: opener);

      await tester.tap(find.text('Faith in a difficult week'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open study guide'));
      await tester.pumpAndSettle();

      expect(find.text('0 of 1 completed'), findsOneWidget);
      expect(
        tester.widget<Checkbox>(find.byType(Checkbox).first).value,
        isFalse,
      );

      await tester.tap(find.byType(Checkbox).first);
      await tester.pumpAndSettle();

      expect(find.text('1 of 1 completed'), findsOneWidget);
      expect(
        tester.widget<Checkbox>(find.byType(Checkbox).first).value,
        isTrue,
      );

      await tester.tap(find.text('Journal'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Faith in a difficult week'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open study guide'));
      await tester.pumpAndSettle();

      expect(find.text('1 of 1 completed'), findsOneWidget);
      expect(
        tester.widget<Checkbox>(find.byType(Checkbox).first).value,
        isTrue,
      );

      await tester.tap(find.text('Open in Gospel Library'));
      await tester.pumpAndSettle();

      expect(opener.openedUrls, hasLength(1));
      expect(opener.openedUrls.single.host, 'www.churchofjesuschrist.org');
      expect(find.text('1 of 1 completed'), findsOneWidget);
    },
  );

  testWidgets(
    'opening a study guide resource does not mark it complete automatically',
    (tester) async {
      final opener = _FakeResourceLinkOpener();

      await _pumpStudyGuideApp(tester, opener: opener);

      await tester.tap(find.text('Faith in a difficult week'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open study guide'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open in Gospel Library'));
      await tester.pumpAndSettle();

      expect(opener.openedUrls, hasLength(1));
      expect(find.text('0 of 1 completed'), findsOneWidget);
      expect(
        tester.widget<Checkbox>(find.byType(Checkbox).first).value,
        isFalse,
      );
    },
  );
}

Future<void> _pumpStudyGuideApp(
  WidgetTester tester, {
  ResourceLinkOpener? opener,
}) async {
  tester.view.physicalSize = const Size(1200, 2200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final repository = InMemoryJournalRepository(seedEntries: [_sampleEntry]);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        journalRepositoryProvider.overrideWithValue(repository),
        scriptureAppPreferenceRepositoryProvider.overrideWithValue(
          _InMemoryScriptureAppPreferenceRepository(
            initial: ScriptureAppPreference.gospelLibrary,
          ),
        ),
        if (opener != null)
          resourceLinkOpenerProvider.overrideWithValue(opener),
      ],
      child: const LumenApp(),
    ),
  );
  await tester.pumpAndSettle();
}

final _sampleEntry = JournalEntry(
  id: 'entry-study-guide',
  createdAt: DateTime.utc(2026, 6, 11, 14),
  updatedAt: DateTime.utc(2026, 6, 11, 14),
  source: EntrySource.text,
  originalText:
      'I have felt stretched this week and want to turn more to scripture and faith.',
  rewrittenText: '',
  themes: const [
    JournalTheme(id: 'faith', name: 'faith', displayName: 'Faith'),
    JournalTheme(id: 'stress', name: 'stress', displayName: 'Stress'),
  ],
  resources: const [],
  studyGuide: _studyGuide(),
  title: 'Faith in a difficult week',
  summary: 'A reflection on faith, stress, and turning back to scripture.',
);

StudyGuide _studyGuide() {
  return StudyGuide(
    id: 'study-guide-entry-study-guide',
    entryId: 'entry-study-guide',
    providerKey: 'gospel_library',
    generatedAt: DateTime.utc(2026, 6, 11, 14, 30),
    overview: 'A gospel study guide built from this reflection.',
    previewText: 'Psalm 46:10 and one more resource',
    items: [
      StudyGuideItem(
        id: 'faith-scripture-psalm-46-10',
        kind: 'scripture',
        title: 'Psalm 46:10',
        contextLine: 'A quiet anchor when you need steadiness.',
        position: 0,
        destination: StudyGuideDestination(
          providerKey: 'gospel_library',
          contentType: 'scripture',
          reference: 'Psalm 46:10',
          url: Uri.parse(
            'https://www.churchofjesuschrist.org/study/scriptures/ot/ps/46?lang=eng',
          ),
          precision: StudyGuideDestinationPrecision.chapter,
        ),
        focusText: 'Focus on the reminder to be still and trust God.',
      ),
    ],
    reflectionPrompt: const StudyGuidePrompt(
      text:
          'As you study these resources, what feels most worth carrying into the rest of your day?',
    ),
  );
}

class _InMemoryScriptureAppPreferenceRepository
    implements ScriptureAppPreferenceRepository {
  _InMemoryScriptureAppPreferenceRepository({required this.initial});

  final ScriptureAppPreference initial;
  late ScriptureAppPreference _value = initial;

  @override
  Future<ScriptureAppPreference> load() async {
    return _value;
  }

  @override
  Future<void> save(ScriptureAppPreference preference) async {
    _value = preference;
  }
}

class _FakeResourceLinkOpener implements ResourceLinkOpener {
  final List<Uri> openedUrls = [];

  @override
  Future<bool> open(Uri url) async {
    openedUrls.add(url);
    return true;
  }
}
