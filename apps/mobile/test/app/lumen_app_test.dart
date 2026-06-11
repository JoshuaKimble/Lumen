import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumen/src/app/lumen_app.dart';
import 'package:lumen/src/app/supabase_config.dart';
import 'package:lumen/src/features/auth/data/auth_service_provider.dart';
import 'package:lumen/src/features/auth/domain/auth_service.dart';
import 'package:lumen/src/features/auth/domain/auth_session.dart';
import 'package:lumen/src/features/journal/data/journal_ai_service_provider.dart';
import 'package:lumen/src/features/journal/data/in_memory_journal_repository.dart';
import 'package:lumen/src/features/journal/data/journal_repository_provider.dart';
import 'package:lumen/src/features/journal/domain/ai_results.dart';
import 'package:lumen/src/features/journal/domain/entry_source.dart';
import 'package:lumen/src/features/journal/domain/journal_ai_service.dart';
import 'package:lumen/src/features/journal/domain/journal_entry.dart';
import 'package:lumen/src/features/journal/domain/journal_theme.dart';
import 'package:lumen/src/features/journal/domain/related_resource.dart';
import 'package:lumen/src/features/journal/domain/rewrite_personalization.dart';
import 'package:lumen/src/features/journal/domain/voice_recorder.dart';
import 'package:lumen/src/features/journal/domain/voice_recording.dart';
import 'package:lumen/src/features/journal/domain/voice_recording_attempt.dart';
import 'package:lumen/src/features/journal/domain/voice_recording_history_store.dart';
import 'package:lumen/src/features/journal/domain/voice_transcription_exception.dart';
import 'package:lumen/src/features/journal/domain/voice_transcription_service.dart';
import 'package:lumen/src/features/journal/data/voice_recorder_provider.dart';
import 'package:lumen/src/features/journal/data/voice_transcription_service_provider.dart';
import 'package:lumen/src/features/journal/presentation/voice_recording_history_controller.dart';
import 'package:lumen/src/features/profiles/data/profile_service_provider.dart';
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
  testWidgets('renders the journal home screen', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          journalRepositoryProvider.overrideWithValue(
            InMemoryJournalRepository(),
          ),
          voiceRecordingHistoryStoreProvider.overrideWithValue(
            _InMemoryVoiceRecordingHistoryStore(),
          ),
        ],
        child: const LumenApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Lumen'), findsOneWidget);
    expect(find.text('Welcome to Lumen'), findsOneWidget);
    expect(find.text('A quiet place for daily reflection.'), findsOneWidget);
    expect(find.byTooltip('Record voice entry'), findsOneWidget);
    expect(find.byTooltip('New text entry'), findsOneWidget);
    expect(find.text('Journal'), findsOneWidget);
    expect(find.text('Voice'), findsOneWidget);
  });

  testWidgets('routes verified users with incomplete profile to onboarding', (
    tester,
  ) async {
    await _pumpAuthenticatedApp(
      tester,
      profileService: _FakeProfileService(
        profile: _sampleProfile(onboardingCompleted: false),
      ),
    );

    expect(find.text('Finish your profile'), findsOneWidget);
    expect(find.text('Continue to app'), findsOneWidget);
  });

  testWidgets('completing onboarding redirects into the app', (tester) async {
    tester.view.physicalSize = const Size(1440, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final profileService = _FakeProfileService(
      profile: _sampleProfile(onboardingCompleted: false),
    );
    final themeRepository = _FakeThemePreferenceRepository();
    final scriptureRepository = _FakeScriptureAppPreferenceRepository();

    await _pumpAuthenticatedApp(
      tester,
      profileService: profileService,
      themeRepository: themeRepository,
      scriptureRepository: scriptureRepository,
    );

    await tester.enterText(find.byType(TextFormField).first, 'Jordan');
    await tester.tap(find.text('Continue to app').last);
    await tester.pumpAndSettle();

    expect(find.text('Welcome to Lumen'), findsOneWidget);
    expect(profileService.profile.onboardingCompleted, isTrue);
    expect(profileService.profile.displayName, 'Jordan');
    expect(themeRepository.storedPreference, ThemePreference.system);
    expect(scriptureRepository.storedPreference, ScriptureAppPreference.none);
  });

  testWidgets('applies saved dark theme override on startup', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          journalRepositoryProvider.overrideWithValue(
            InMemoryJournalRepository(),
          ),
          themePreferenceRepositoryProvider.overrideWithValue(
            _FakeThemePreferenceRepository(
              initialPreference: ThemePreference.dark,
            ),
          ),
        ],
        child: const LumenApp(),
      ),
    );
    await tester.pumpAndSettle();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);
  });

  testWidgets('uses system theme mode when saved preference is system', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          journalRepositoryProvider.overrideWithValue(
            InMemoryJournalRepository(),
          ),
          themePreferenceRepositoryProvider.overrideWithValue(
            _FakeThemePreferenceRepository(
              initialPreference: ThemePreference.system,
            ),
          ),
        ],
        child: const LumenApp(),
      ),
    );
    await tester.pumpAndSettle();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.system);
  });

  testWidgets('navigates between top-level pages', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          journalRepositoryProvider.overrideWithValue(
            InMemoryJournalRepository(),
          ),
        ],
        child: const LumenApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Voice'));
    await tester.pumpAndSettle();

    expect(find.text('Voice entry'), findsOneWidget);
    expect(find.text('Capture a voice entry'), findsOneWidget);

    await tester.tap(find.text('Themes'));
    await tester.pumpAndSettle();

    expect(find.text('Themes'), findsWidgets);
    expect(find.text('Recurring themes'), findsOneWidget);

    await tester.tap(find.text('Journal'));
    await tester.pumpAndSettle();

    expect(find.text('Lumen'), findsOneWidget);
    expect(find.text('Welcome to Lumen'), findsOneWidget);
  });

  testWidgets('shows recurring themes by prominence', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          journalRepositoryProvider.overrideWithValue(
            InMemoryJournalRepository(seedEntries: _themeCloudEntries),
          ),
        ],
        child: const LumenApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Themes'));
    await tester.pumpAndSettle();

    expect(find.text('Recurring themes'), findsOneWidget);
    expect(find.text('Work'), findsOneWidget);
    expect(find.text('Stress'), findsOneWidget);
    expect(find.text('Family'), findsOneWidget);
    expect(find.text('3 entries'), findsOneWidget);
    expect(find.text('2 entries'), findsOneWidget);
    expect(find.text('1 entry'), findsOneWidget);

    await tester.tap(find.text('Work'));
    await tester.pumpAndSettle();

    expect(find.text('3 related journal entries'), findsOneWidget);
    expect(find.text('Insights'), findsOneWidget);
    expect(find.text('Related entries'), findsOneWidget);
    expect(find.text('theme-entry-1'), findsOneWidget);
    expect(find.text('theme-entry-2'), findsOneWidget);

    await tester.drag(find.byType(Scrollable).last, const Offset(0, -360));
    await tester.pumpAndSettle();

    expect(find.text('theme-entry-3'), findsOneWidget);

    await tester.tap(find.text('theme-entry-3'));
    await tester.pumpAndSettle();

    expect(find.text('Journal entry'), findsOneWidget);
    expect(find.text('Theme source text.'), findsOneWidget);
  });

  testWidgets('shows navigation on entry detail pages', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          journalRepositoryProvider.overrideWithValue(
            InMemoryJournalRepository(seedEntries: [_sampleEntry]),
          ),
        ],
        child: const LumenApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('A difficult but honest morning'));
    await tester.pumpAndSettle();

    expect(find.text('Journal entry'), findsOneWidget);
    expect(find.text('Journal'), findsOneWidget);
    expect(find.text('Voice'), findsOneWidget);

    await tester.tap(find.text('Journal'));
    await tester.pumpAndSettle();

    expect(find.text('Lumen'), findsOneWidget);
    expect(find.text('A difficult but honest morning'), findsOneWidget);
  });

  testWidgets('renders entry list content', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          journalRepositoryProvider.overrideWithValue(
            InMemoryJournalRepository(seedEntries: [_sampleEntry]),
          ),
        ],
        child: const LumenApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('May 7, 2026'), findsOneWidget);
    expect(find.text('A difficult but honest morning'), findsOneWidget);
    expect(find.text('Family'), findsOneWidget);
    expect(
      find.text('A morning reflection about family stress.'),
      findsOneWidget,
    );
  });

  testWidgets('opens entry detail and separates original from rewrite', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          journalRepositoryProvider.overrideWithValue(
            InMemoryJournalRepository(seedEntries: [_sampleEntry]),
          ),
        ],
        child: const LumenApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('A difficult but honest morning'));
    await tester.pumpAndSettle();

    expect(find.text('Journal entry'), findsOneWidget);
    expect(find.text('Your entry stays yours'), findsOneWidget);
    expect(
      find.text(
        'The original is preserved. AI rewrites are suggestions to help with clarity, not judgments, diagnoses, or replacements for your words.',
      ),
      findsOneWidget,
    );
    expect(find.text('Original entry'), findsOneWidget);
    expect(find.text('Preserved exactly as you saved it.'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('AI rewrite'), 120);
    expect(find.text('AI rewrite'), findsOneWidget);
    expect(
      find.text('A clarity suggestion, not a replacement.'),
      findsOneWidget,
    );
    expect(
      find.text('I was irritated and rushed this morning.'),
      findsOneWidget,
    );
    expect(
      find.text('I noticed I was tense before breakfast.'),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.text('Morning reflection prompt'),
      120,
    );
    expect(find.text('Morning reflection prompt'), findsOneWidget);
    expect(find.text('Regenerate AI'), findsNothing);
  });

  testWidgets('renders a calm empty state', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          journalRepositoryProvider.overrideWithValue(
            InMemoryJournalRepository(seedEntries: const []),
          ),
        ],
        child: const LumenApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No journal entries yet'), findsOneWidget);
    expect(
      find.text('Your reflections will appear here after you save them.'),
      findsOneWidget,
    );
  });

  testWidgets('creates a typed journal entry', (tester) async {
    final repository = InMemoryJournalRepository(seedEntries: const []);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [journalRepositoryProvider.overrideWithValue(repository)],
        child: const LumenApp(),
      ),
    );
    await tester.pumpAndSettle();

    const originalText = '  These are my exact typed words.  ';

    await tester.tap(find.byTooltip('New text entry'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Typed entry');
    await tester.enterText(find.byType(TextFormField).at(1), originalText);
    await tester.tap(find.text('Save entry'));
    await tester.pumpAndSettle();

    final entries = await repository.listEntries();

    expect(entries, hasLength(1));
    expect(entries.single.title, 'Typed entry');
    expect(entries.single.originalText, originalText);
    expect(
      entries.single.rewrittenText,
      '[Flutter mock: typed create] I am noticing this more clearly: These are my exact typed words.',
    );
    expect(entries.single.themes.single.displayName, 'Reflection');
    expect(find.text('Typed entry'), findsOneWidget);
    expect(find.text(originalText), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text(
        '[Flutter mock: typed create] I am noticing this more clearly: These are my exact typed words.',
      ),
      120,
    );
    expect(
      find.text(
        '[Flutter mock: typed create] I am noticing this more clearly: These are my exact typed words.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('saves a new entry when initial rewrite generation fails', (
    tester,
  ) async {
    final repository = InMemoryJournalRepository(seedEntries: const []);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          journalRepositoryProvider.overrideWithValue(repository),
          journalAiServiceProvider.overrideWithValue(const _FailingAiService()),
        ],
        child: const LumenApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('New text entry'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Fallback entry');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'Original still saves.',
    );
    await tester.tap(find.text('Save entry'));
    await tester.pumpAndSettle();

    final entries = await repository.listEntries();

    expect(entries, hasLength(1));
    expect(entries.single.title, 'Fallback entry');
    expect(entries.single.originalText, 'Original still saves.');
    expect(entries.single.rewrittenText, isEmpty);
    expect(entries.single.themes, isEmpty);
    expect(find.text('No rewrite yet.'), findsOneWidget);
  });

  testWidgets('edits a typed journal entry', (tester) async {
    final repository = InMemoryJournalRepository(seedEntries: [_sampleEntry]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [journalRepositoryProvider.overrideWithValue(repository)],
        child: const LumenApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('A difficult but honest morning'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Edit entry'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Updated title');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'Updated original text.',
    );
    await tester.tap(find.text('Save entry'));
    await tester.pumpAndSettle();

    final entry = await repository.getEntry('entry-1');

    expect(entry?.title, 'Updated title');
    expect(entry?.originalText, 'Updated original text.');
    expect(
      entry?.rewrittenText,
      '[Flutter mock: typed edit save] I am noticing this more clearly: Updated original text.',
    );
    expect(find.text('Updated title'), findsOneWidget);
    expect(find.text('Updated original text.'), findsWidgets);
  });

  testWidgets('regenerates rewrite and themes when edited text changes', (
    tester,
  ) async {
    final repository = InMemoryJournalRepository(seedEntries: [_sampleEntry]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          journalRepositoryProvider.overrideWithValue(repository),
          journalAiServiceProvider.overrideWithValue(
            _ImmediateAiService(
              rewrittenText: 'Updated generated rewrite.',
              theme: const JournalTheme(
                id: 'stress',
                name: 'stress',
                displayName: 'Stress',
              ),
            ),
          ),
        ],
        child: const LumenApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('A difficult but honest morning'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Edit entry'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(1), 'Changed text.');
    await tester.tap(find.text('Save entry'));
    await tester.pumpAndSettle();

    final entry = await repository.getEntry('entry-1');

    expect(entry?.originalText, 'Changed text.');
    expect(
      entry?.rewrittenText,
      '[Test AI: typed edit save] Updated generated rewrite.',
    );
    expect(entry?.themes.single.displayName, 'Stress');
    await tester.scrollUntilVisible(
      find.text('[Test AI: typed edit save] Updated generated rewrite.'),
      120,
    );
    expect(
      find.text('[Test AI: typed edit save] Updated generated rewrite.'),
      findsOneWidget,
    );
    expect(find.text('Stress'), findsOneWidget);
  });

  testWidgets('deletes a journal entry', (tester) async {
    final repository = InMemoryJournalRepository(seedEntries: [_sampleEntry]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [journalRepositoryProvider.overrideWithValue(repository)],
        child: const LumenApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('A difficult but honest morning'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Delete entry'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'This removes the original entry, AI rewrite, themes, and resources from this device. You own your entries and can delete them at any time.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(await repository.listEntries(), isEmpty);
    expect(find.text('No journal entries yet'), findsOneWidget);
  });

  testWidgets('shows regenerate ai only for admin accounts', (tester) async {
    await _pumpAuthenticatedApp(
      tester,
      profileService: _FakeProfileService(
        profile: _sampleProfile(onboardingCompleted: true),
      ),
      repository: InMemoryJournalRepository(seedEntries: [_sampleEntry]),
      session: const AuthSession(
        userId: 'user-1',
        email: 'joshuakimble@gmail.com',
        emailVerified: true,
      ),
    );

    await tester.tap(find.text('A difficult but honest morning'));
    await tester.pumpAndSettle();

    expect(find.text('Regenerate AI'), findsOneWidget);
  });

  testWidgets('generates mock rewrite and themes for an entry', (tester) async {
    final repository = InMemoryJournalRepository(
      seedEntries: [_unprocessedEntry],
    );
    final aiService = _ControlledAiService();

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
                email: 'joshuakimble@gmail.com',
                emailVerified: true,
              ),
            ),
          ),
          profileServiceProvider.overrideWithValue(
            _FakeProfileService(
              profile: _sampleProfile(onboardingCompleted: true),
            ),
          ),
          journalRepositoryProvider.overrideWithValue(repository),
          journalAiServiceProvider.overrideWithValue(aiService),
          themePreferenceRepositoryProvider.overrideWithValue(
            _FakeThemePreferenceRepository(),
          ),
          scriptureAppPreferenceRepositoryProvider.overrideWithValue(
            _FakeScriptureAppPreferenceRepository(),
          ),
        ],
        child: const LumenApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('A raw work note'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Regenerate AI'));
    await tester.pump();

    expect(find.text('Refreshing AI'), findsOneWidget);

    aiService.completeRewrite();
    await tester.pumpAndSettle();

    final entry = await repository.getEntry('entry-2');

    expect(
      entry?.rewrittenText,
      '[Test AI: regenerate] A clearer mock rewrite.',
    );
    expect(entry?.themes.single.displayName, 'Work');
    await tester.scrollUntilVisible(
      find.text('[Test AI: regenerate] A clearer mock rewrite.'),
      120,
    );
    expect(
      find.text('[Test AI: regenerate] A clearer mock rewrite.'),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(find.text('Work'), -120);
    expect(find.text('Work'), findsOneWidget);
  });

  testWidgets('shows an error when mock rewrite generation fails', (
    tester,
  ) async {
    final repository = InMemoryJournalRepository(
      seedEntries: [_unprocessedEntry],
    );

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
                email: 'joshuakimble@gmail.com',
                emailVerified: true,
              ),
            ),
          ),
          profileServiceProvider.overrideWithValue(
            _FakeProfileService(
              profile: _sampleProfile(onboardingCompleted: true),
            ),
          ),
          journalRepositoryProvider.overrideWithValue(repository),
          journalAiServiceProvider.overrideWithValue(const _FailingAiService()),
          themePreferenceRepositoryProvider.overrideWithValue(
            _FakeThemePreferenceRepository(),
          ),
          scriptureAppPreferenceRepositoryProvider.overrideWithValue(
            _FakeScriptureAppPreferenceRepository(),
          ),
        ],
        child: const LumenApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('A raw work note'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Regenerate AI'));
    await tester.pumpAndSettle();

    final entry = await repository.getEntry('entry-2');

    expect(entry?.rewrittenText, isEmpty);
    expect(
      find.text('Unable to refresh AI for this entry right now.'),
      findsOneWidget,
    );
  });

  testWidgets('starts, stops, and transcribes a voice recording', (
    tester,
  ) async {
    final recorder = _FakeVoiceRecorder();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          journalRepositoryProvider.overrideWithValue(
            InMemoryJournalRepository(seedEntries: const []),
          ),
          voiceRecorderProvider.overrideWithValue(recorder),
          voiceRecordingHistoryStoreProvider.overrideWithValue(
            _InMemoryVoiceRecordingHistoryStore(),
          ),
          voiceTranscriptionServiceProvider.overrideWithValue(
            const _FakeVoiceTranscriptionService(
              transcript: 'This is the reviewed transcript.',
            ),
          ),
        ],
        child: const LumenApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Record voice entry'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start recording'));
    await tester.pumpAndSettle();

    expect(recorder.didStart, isTrue);
    expect(find.text('Recording'), findsOneWidget);

    await tester.tap(find.text('Stop recording'));
    await tester.pumpAndSettle();

    expect(recorder.didStop, isTrue);
    expect(find.text('Review transcript'), findsOneWidget);
    expect(find.text('This is the reviewed transcript.'), findsOneWidget);
    await tester.drag(find.byType(Scrollable).last, const Offset(0, -320));
    await tester.pumpAndSettle();
    expect(find.text('Temporary audio saved'), findsOneWidget);
    expect(find.text('memory://recording.m4a'), findsOneWidget);
  });

  testWidgets('saves reviewed voice transcript as a journal entry', (
    tester,
  ) async {
    final repository = InMemoryJournalRepository(seedEntries: const []);
    final recorder = _FakeVoiceRecorder();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          journalRepositoryProvider.overrideWithValue(repository),
          voiceRecorderProvider.overrideWithValue(recorder),
          voiceRecordingHistoryStoreProvider.overrideWithValue(
            _InMemoryVoiceRecordingHistoryStore(),
          ),
          voiceTranscriptionServiceProvider.overrideWithValue(
            const _FakeVoiceTranscriptionService(
              transcript: 'Rough voice transcript.',
            ),
          ),
        ],
        child: const LumenApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Record voice entry'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start recording'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Stop recording'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField),
      'Edited voice transcript.',
    );
    await tester.drag(find.byType(Scrollable).last, const Offset(0, -240));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save voice entry'));
    await tester.pumpAndSettle();

    final entries = await repository.listEntries();

    expect(entries, hasLength(1));
    expect(entries.single.source, EntrySource.voice);
    expect(entries.single.originalText, 'Edited voice transcript.');
    expect(
      entries.single.rewrittenText,
      '[Flutter mock: voice save] I am noticing this more clearly: Edited voice transcript.',
    );
    expect(entries.single.themes.single.displayName, 'Reflection');
    expect(find.text('Edited voice transcript.'), findsWidgets);
    await tester.scrollUntilVisible(
      find.text(
        '[Flutter mock: voice save] I am noticing this more clearly: Edited voice transcript.',
      ),
      120,
    );
    expect(
      find.text(
        '[Flutter mock: voice save] I am noticing this more clearly: Edited voice transcript.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('handles denied microphone permission', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          journalRepositoryProvider.overrideWithValue(
            InMemoryJournalRepository(seedEntries: const []),
          ),
          voiceRecordingHistoryStoreProvider.overrideWithValue(
            _InMemoryVoiceRecordingHistoryStore(),
          ),
          voiceRecorderProvider.overrideWithValue(
            _FakeVoiceRecorder(hasPermissionValue: false),
          ),
        ],
        child: const LumenApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Record voice entry'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start recording'));
    await tester.pumpAndSettle();

    expect(find.text('Microphone access is needed'), findsOneWidget);
    expect(
      find.text(
        'Allow microphone access in your browser or device settings to record journal entries.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('surfaces no-speech failures and sorts failed recordings first', (
    tester,
  ) async {
    final olderTranscribedAttempt = VoiceRecordingAttempt(
      id: 'voice-old',
      recording: VoiceRecording(
        uri: 'memory://old-recording.m4a',
        startedAt: DateTime.utc(2026, 6, 1, 11),
        stoppedAt: DateTime.utc(2026, 6, 1, 11, 1),
      ),
      status: VoiceRecordingAttemptStatus.transcribed,
      createdAt: DateTime.utc(2026, 6, 1, 11, 1),
      updatedAt: DateTime.utc(2026, 6, 1, 11, 5),
      transcript: 'Earlier transcript.',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          journalRepositoryProvider.overrideWithValue(
            InMemoryJournalRepository(seedEntries: const []),
          ),
          voiceRecorderProvider.overrideWithValue(_FakeVoiceRecorder()),
          voiceRecordingHistoryStoreProvider.overrideWithValue(
            _InMemoryVoiceRecordingHistoryStore(
              initialAttempts: [olderTranscribedAttempt],
            ),
          ),
          voiceTranscriptionServiceProvider.overrideWithValue(
            const _FakeVoiceTranscriptionService(
              error: NoSpeechDetectedException(),
            ),
          ),
        ],
        child: const LumenApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Record voice entry'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start recording'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Stop recording'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'No speech was detected in the recording. Try again closer to the microphone.',
      ),
      findsWidgets,
    );
    expect(find.text('Recent recordings'), findsOneWidget);
    expect(find.text('Transcription failed'), findsOneWidget);
    expect(find.text('Transcript ready'), findsOneWidget);

    final failedPosition = tester.getTopLeft(find.text('Transcription failed'));
    final readyPosition = tester.getTopLeft(find.text('Transcript ready'));
    expect(failedPosition.dy, lessThan(readyPosition.dy));
  });
}

final _sampleEntry = JournalEntry(
  id: 'entry-1',
  createdAt: DateTime.utc(2026, 5, 7, 15, 30),
  updatedAt: DateTime.utc(2026, 5, 7, 15, 45),
  source: EntrySource.voice,
  originalText: 'I was irritated and rushed this morning.',
  rewrittenText: 'I noticed I was tense before breakfast.',
  themes: const [
    JournalTheme(id: 'family', name: 'family', displayName: 'Family'),
  ],
  resources: [
    RelatedResource(
      id: 'resource-1',
      title: 'Morning reflection prompt',
      type: 'prompt',
    ),
  ],
  title: 'A difficult but honest morning',
  summary: 'A morning reflection about family stress.',
);

final _unprocessedEntry = JournalEntry(
  id: 'entry-2',
  createdAt: DateTime.utc(2026, 5, 8, 16),
  updatedAt: DateTime.utc(2026, 5, 8, 16),
  source: EntrySource.text,
  originalText: 'I had a rushed work meeting.',
  rewrittenText: '',
  themes: const [],
  resources: const [],
  title: 'A raw work note',
);

final _themeCloudEntries = [
  _themeEntry(
    id: 'theme-entry-1',
    themes: const [
      JournalTheme(id: 'work', name: 'work', displayName: 'Work'),
      JournalTheme(id: 'stress', name: 'stress', displayName: 'Stress'),
      JournalTheme(id: 'family', name: 'family', displayName: 'Family'),
    ],
  ),
  _themeEntry(
    id: 'theme-entry-2',
    themes: const [
      JournalTheme(id: 'work', name: 'work', displayName: 'Work'),
      JournalTheme(id: 'stress', name: 'stress', displayName: 'Stress'),
    ],
  ),
  _themeEntry(
    id: 'theme-entry-3',
    themes: const [JournalTheme(id: 'work', name: 'work', displayName: 'Work')],
  ),
];

JournalEntry _themeEntry({
  required String id,
  required List<JournalTheme> themes,
}) {
  final createdAt = DateTime.utc(2026, 5, 9, 16);

  return JournalEntry(
    id: id,
    createdAt: createdAt,
    updatedAt: createdAt,
    source: EntrySource.text,
    originalText: 'Theme source text.',
    rewrittenText: 'Theme rewritten text.',
    themes: themes,
    resources: const [],
    title: id,
  );
}

class _ControlledAiService implements JournalAiService {
  final _rewrite = Completer<RewriteResult>();
  JournalRewriteSource _source = JournalRewriteSource.unspecified;

  void completeRewrite() {
    _rewrite.complete(
      RewriteResult(
        rewrittenText:
            '[Test AI: ${_source.testLabel}] A clearer mock rewrite.',
        title: 'Generated title',
        summary: 'Generated summary',
      ),
    );
  }

  @override
  Future<ThemeDetectionResult> detectThemes({required String text}) async {
    return const ThemeDetectionResult(
      themes: [JournalTheme(id: 'work', name: 'work', displayName: 'Work')],
    );
  }

  @override
  Future<RewriteResult> rewriteEntry({
    required String originalText,
    JournalRewriteSource source = JournalRewriteSource.unspecified,
    RewritePersonalization? personalization,
  }) async {
    _source = source;
    return _rewrite.future;
  }
}

class _ImmediateAiService implements JournalAiService {
  const _ImmediateAiService({required this.rewrittenText, required this.theme});

  final String rewrittenText;
  final JournalTheme theme;

  @override
  Future<ThemeDetectionResult> detectThemes({required String text}) async {
    return ThemeDetectionResult(themes: [theme]);
  }

  @override
  Future<RewriteResult> rewriteEntry({
    required String originalText,
    JournalRewriteSource source = JournalRewriteSource.unspecified,
    RewritePersonalization? personalization,
  }) async {
    return RewriteResult(
      rewrittenText: '[Test AI: ${source.testLabel}] $rewrittenText',
      title: 'Updated generated title',
      summary: 'Updated generated summary',
    );
  }
}

extension on JournalRewriteSource {
  String get testLabel {
    return switch (this) {
      JournalRewriteSource.typedCreate => 'typed create',
      JournalRewriteSource.typedEditSave => 'typed edit save',
      JournalRewriteSource.regenerate => 'regenerate',
      JournalRewriteSource.voiceSave => 'voice save',
      JournalRewriteSource.unspecified => 'unspecified flow',
    };
  }
}

class _FailingAiService implements JournalAiService {
  const _FailingAiService();

  @override
  Future<ThemeDetectionResult> detectThemes({required String text}) async {
    return const ThemeDetectionResult(themes: []);
  }

  @override
  Future<RewriteResult> rewriteEntry({
    required String originalText,
    JournalRewriteSource source = JournalRewriteSource.unspecified,
    RewritePersonalization? personalization,
  }) async {
    throw StateError('AI unavailable');
  }
}

class _FakeVoiceTranscriptionService implements VoiceTranscriptionService {
  const _FakeVoiceTranscriptionService({this.transcript = '', this.error});

  final String transcript;
  final Object? error;

  @override
  Future<String> transcribe(VoiceRecording recording) async {
    if (error != null) {
      throw error!;
    }

    return transcript;
  }
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
  _FakeProfileService({required this.profile});

  UserProfile profile;

  @override
  Future<UserProfile> getOrCreateProfile(AuthSession session) async {
    return profile;
  }

  @override
  Future<UserProfile> saveProfile(UserProfile nextProfile) async {
    profile = nextProfile;
    return profile;
  }
}

Future<void> _pumpAuthenticatedApp(
  WidgetTester tester, {
  required _FakeProfileService profileService,
  InMemoryJournalRepository? repository,
  AuthSession? session,
  ThemePreferenceRepository? themeRepository,
  ScriptureAppPreferenceRepository? scriptureRepository,
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
            currentSession:
                session ??
                const AuthSession(
                  userId: 'user-1',
                  email: 'user@example.com',
                  emailVerified: true,
                ),
          ),
        ),
        profileServiceProvider.overrideWithValue(profileService),
        journalRepositoryProvider.overrideWithValue(
          repository ?? InMemoryJournalRepository(),
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

UserProfile _sampleProfile({required bool onboardingCompleted}) {
  return UserProfile(
    id: 'user-1',
    email: 'user@example.com',
    displayName: null,
    rewriteTone: RewriteTonePreference.balanced,
    preserveVoice: true,
    preferredScriptureApp: ScriptureAppPreference.none,
    themePreference: ThemePreference.system,
    onboardingCompleted: onboardingCompleted,
    createdAt: DateTime.parse('2026-05-19T09:00:00Z'),
    updatedAt: DateTime.parse('2026-05-19T10:00:00Z'),
  );
}

class _FakeVoiceRecorder implements VoiceRecorder {
  _FakeVoiceRecorder({this.hasPermissionValue = true});

  final bool hasPermissionValue;
  bool didStart = false;
  bool didStop = false;
  DateTime? _startedAt;

  @override
  Future<void> dispose() async {}

  @override
  Future<bool> hasPermission() async {
    return hasPermissionValue;
  }

  @override
  Future<void> start({required DateTime startedAt}) async {
    didStart = true;
    _startedAt = startedAt;
  }

  @override
  Future<VoiceRecording?> stop({required DateTime stoppedAt}) async {
    didStop = true;

    return VoiceRecording(
      uri: 'memory://recording.m4a',
      startedAt: _startedAt ?? stoppedAt,
      stoppedAt: stoppedAt,
    );
  }
}

class _InMemoryVoiceRecordingHistoryStore
    implements VoiceRecordingHistoryStore {
  _InMemoryVoiceRecordingHistoryStore({
    List<VoiceRecordingAttempt> initialAttempts = const [],
  }) : _attempts = [...initialAttempts];

  List<VoiceRecordingAttempt> _attempts;

  @override
  Future<List<VoiceRecordingAttempt>> listAttempts() async {
    return [..._attempts];
  }

  @override
  Future<void> saveAttempts(List<VoiceRecordingAttempt> attempts) async {
    _attempts = [...attempts];
  }
}
