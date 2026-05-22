import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumen/src/app/lumen_app.dart';
import 'package:lumen/src/app/supabase_config.dart';
import 'package:lumen/src/features/auth/data/auth_service_provider.dart';
import 'package:lumen/src/features/auth/domain/auth_service.dart';
import 'package:lumen/src/features/auth/domain/auth_session.dart';
import 'package:lumen/src/features/journal/data/in_memory_journal_repository.dart';
import 'package:lumen/src/features/journal/data/journal_repository_provider.dart';
import 'package:lumen/src/features/profiles/data/profile_service_provider.dart';
import 'package:lumen/src/features/profiles/domain/profile_failure.dart';
import 'package:lumen/src/features/profiles/domain/profile_service.dart';
import 'package:lumen/src/features/profiles/domain/rewrite_tone_preference.dart';
import 'package:lumen/src/features/profiles/domain/user_profile.dart';
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

  testWidgets('opens profile settings from settings and saves changes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final themeRepository = _FakeThemePreferenceRepository();
    final scriptureRepository = _FakeScriptureAppPreferenceRepository();
    final profileService = _FakeProfileService(profile: _sampleProfile());
    await _pumpSignedInApp(
      tester,
      themeRepository: themeRepository,
      scriptureRepository: scriptureRepository,
      profileService: profileService,
    );

    await tester.tap(find.text('Settings').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Jordan').last);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'Avery');
    await tester.tap(
      find.byType(DropdownButtonFormField<RewriteTonePreference>),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reflective').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dark'));
    await tester.tap(
      find.byType(DropdownButtonFormField<ScriptureAppPreference>),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Catholic study').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    expect(profileService.profile.displayName, 'Avery');
    expect(
      profileService.profile.rewriteTone,
      RewriteTonePreference.reflective,
    );
    expect(profileService.profile.preserveVoice, isFalse);
    expect(profileService.profile.themePreference, ThemePreference.dark);
    expect(
      profileService.profile.preferredScriptureApp,
      ScriptureAppPreference.catholic,
    );
    expect(themeRepository.storedPreference, ThemePreference.dark);
    expect(
      scriptureRepository.storedPreference,
      ScriptureAppPreference.catholic,
    );
  });

  testWidgets('profile settings rehydrate persisted AI personalization', (
    tester,
  ) async {
    final profileService = _FakeProfileService(
      profile: _sampleProfile(
        rewriteTone: RewriteTonePreference.reflective,
        preserveVoice: false,
      ),
    );
    await _pumpSignedInApp(tester, profileService: profileService);

    await tester.tap(find.text('Settings').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Jordan').last);
    await tester.pumpAndSettle();

    expect(find.text('AI personalization'), findsOneWidget);
    expect(
      find.text(
        'Favor a slower, thoughtful tone that helps with later reflection.',
      ),
      findsOneWidget,
    );

    final preserveVoiceTile = tester.widget<SwitchListTile>(
      find.byType(SwitchListTile),
    );
    expect(preserveVoiceTile.value, isFalse);
  });

  testWidgets('profile settings cancel leaves profile unchanged', (
    tester,
  ) async {
    final profileService = _FakeProfileService(profile: _sampleProfile());
    await _pumpSignedInApp(tester, profileService: profileService);

    await tester.tap(find.text('Settings').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Jordan').last);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'Changed');
    await tester.tap(find.text('Cancel').last);
    await tester.pumpAndSettle();

    expect(profileService.profile.displayName, 'Jordan');
  });

  testWidgets('profile settings surfaces save errors', (tester) async {
    tester.view.physicalSize = const Size(1440, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final profileService = _FakeProfileService(
      profile: _sampleProfile(),
      saveError: const ProfileFailure(
        code: ProfileFailureCode.hydrationFailed,
        message: 'Unable to save profile settings right now.',
      ),
    );
    await _pumpSignedInApp(tester, profileService: profileService);

    await tester.tap(find.text('Settings').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Jordan').last);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'Avery');
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    expect(
      find.text('Unable to save profile settings right now.'),
      findsOneWidget,
    );
    expect(find.text('Profile settings'), findsOneWidget);
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

Future<void> _pumpSignedInApp(
  WidgetTester tester, {
  ThemePreferenceRepository? themeRepository,
  ScriptureAppPreferenceRepository? scriptureRepository,
  required _FakeProfileService profileService,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        supabaseClientConfigProvider.overrideWithValue(
          const SupabaseClientConfig(
            enabled: true,
            url: 'https://example.supabase.co',
            publishableKey: 'sb_publishable_example',
          ),
        ),
        authServiceProvider.overrideWithValue(
          _FakeAuthService(
            currentSession: const AuthSession(
              userId: 'user-1',
              email: 'user@example.com',
              emailVerified: true,
            ),
          ),
        ),
        profileServiceProvider.overrideWithValue(profileService),
        journalRepositoryProvider.overrideWithValue(
          InMemoryJournalRepository(),
        ),
        themePreferenceRepositoryProvider.overrideWithValue(
          themeRepository ?? _FakeThemePreferenceRepository(),
        ),
        scriptureAppPreferenceRepositoryProvider.overrideWithValue(
          scriptureRepository ?? _FakeScriptureAppPreferenceRepository(),
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

class _FakeAuthService implements AuthService {
  _FakeAuthService({required this.currentSession});

  final AuthSession? currentSession;

  @override
  Future<AuthSession?> getCurrentSession() async => currentSession;

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    return currentSession ??
        AuthSession(userId: 'user-1', email: email, emailVerified: true);
  }

  @override
  Future<void> logout() async {}

  @override
  Future<AuthSession> register({
    required String email,
    required String password,
  }) async {
    return currentSession ??
        AuthSession(userId: 'user-1', email: email, emailVerified: true);
  }

  @override
  Future<void> requestPasswordReset({required String email}) async {}

  @override
  Future<void> resendVerificationEmail({required String email}) async {}

  @override
  Future<void> updatePassword({required String newPassword}) async {}
}

class _FakeProfileService implements ProfileService {
  _FakeProfileService({required this.profile, this.saveError});

  UserProfile profile;
  final Object? saveError;

  @override
  Future<UserProfile> getOrCreateProfile(AuthSession session) async {
    return profile;
  }

  @override
  Future<UserProfile> saveProfile(UserProfile nextProfile) async {
    final error = saveError;
    if (error != null) {
      throw error;
    }

    profile = nextProfile;
    return profile;
  }
}

UserProfile _sampleProfile({
  RewriteTonePreference rewriteTone = RewriteTonePreference.balanced,
  bool preserveVoice = true,
}) {
  return UserProfile(
    id: 'user-1',
    email: 'user@example.com',
    displayName: 'Jordan',
    rewriteTone: rewriteTone,
    preserveVoice: preserveVoice,
    preferredScriptureApp: ScriptureAppPreference.none,
    themePreference: ThemePreference.system,
    onboardingCompleted: true,
    createdAt: DateTime.parse('2026-05-19T09:00:00Z'),
    updatedAt: DateTime.parse('2026-05-19T10:00:00Z'),
  );
}
