import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumen/src/app/lumen_app.dart';
import 'package:lumen/src/features/journal/data/in_memory_journal_repository.dart';
import 'package:lumen/src/features/journal/data/journal_repository_provider.dart';
import 'package:lumen/src/features/settings/data/scripture_app_preference_provider.dart';
import 'package:lumen/src/features/settings/data/theme_preference_provider.dart';
import 'package:lumen/src/features/settings/domain/scripture_app_preference.dart';
import 'package:lumen/src/features/settings/domain/scripture_app_preference_repository.dart';
import 'package:lumen/src/features/settings/domain/theme_preference.dart';
import 'package:lumen/src/features/settings/domain/theme_preference_repository.dart';

void main() {
  testWidgets('selects light theme preference', (tester) async {
    final repository = _FakeThemePreferenceRepository();
    await _pumpApp(tester, repository: repository);

    await tester.tap(find.text('Settings').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Light'));
    await tester.pumpAndSettle();

    expect(repository.storedPreference, ThemePreference.light);
    expect(_materialApp(tester).themeMode, ThemeMode.light);
  });

  testWidgets('selects dark theme preference', (tester) async {
    final repository = _FakeThemePreferenceRepository();
    await _pumpApp(tester, repository: repository);

    await tester.tap(find.text('Settings').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();

    expect(repository.storedPreference, ThemePreference.dark);
    expect(_materialApp(tester).themeMode, ThemeMode.dark);
  });

  testWidgets('selects system theme preference', (tester) async {
    final repository = _FakeThemePreferenceRepository(
      initialPreference: ThemePreference.dark,
    );
    await _pumpApp(tester, repository: repository);

    await tester.tap(find.text('Settings').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('System'));
    await tester.pumpAndSettle();

    expect(repository.storedPreference, ThemePreference.system);
    expect(_materialApp(tester).themeMode, ThemeMode.system);
  });

  testWidgets('selects scripture app preference', (tester) async {
    final themeRepository = _FakeThemePreferenceRepository();
    final scriptureRepository = _FakeScriptureAppPreferenceRepository();
    await _pumpApp(
      tester,
      repository: themeRepository,
      scriptureRepository: scriptureRepository,
    );

    await tester.tap(find.text('Settings').last);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byType(DropdownButtonFormField<ScriptureAppPreference>),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gospel Library (LDS)').last);
    await tester.pumpAndSettle();

    expect(
      scriptureRepository.storedPreference,
      ScriptureAppPreference.gospelLibrary,
    );
  });
}

Future<void> _pumpApp(
  WidgetTester tester, {
  required ThemePreferenceRepository repository,
  ScriptureAppPreferenceRepository? scriptureRepository,
}) async {
  final resolvedScriptureRepository =
      scriptureRepository ?? _FakeScriptureAppPreferenceRepository();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        journalRepositoryProvider.overrideWithValue(
          InMemoryJournalRepository(),
        ),
        themePreferenceRepositoryProvider.overrideWithValue(repository),
        scriptureAppPreferenceRepositoryProvider.overrideWithValue(
          resolvedScriptureRepository,
        ),
      ],
      child: const LumenApp(),
    ),
  );
  await tester.pumpAndSettle();
}

MaterialApp _materialApp(WidgetTester tester) {
  return tester.widget<MaterialApp>(find.byType(MaterialApp));
}

class _FakeThemePreferenceRepository implements ThemePreferenceRepository {
  _FakeThemePreferenceRepository({
    this.initialPreference = ThemePreference.system,
  }) : storedPreference = initialPreference;

  final ThemePreference initialPreference;
  ThemePreference storedPreference;

  @override
  Future<ThemePreference> load() async {
    return storedPreference;
  }

  @override
  Future<void> save(ThemePreference preference) async {
    storedPreference = preference;
  }
}

class _FakeScriptureAppPreferenceRepository
    implements ScriptureAppPreferenceRepository {
  _FakeScriptureAppPreferenceRepository({
    this.initialPreference = ScriptureAppPreference.none,
  }) : storedPreference = initialPreference;

  final ScriptureAppPreference initialPreference;
  ScriptureAppPreference storedPreference;

  @override
  Future<ScriptureAppPreference> load() async {
    return storedPreference;
  }

  @override
  Future<void> save(ScriptureAppPreference preference) async {
    storedPreference = preference;
  }
}
