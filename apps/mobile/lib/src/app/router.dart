import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/journal/presentation/journal_entry_detail_screen.dart';
import '../features/journal/presentation/journal_entry_editor_screen.dart';
import '../features/journal/presentation/journal_home_screen.dart';
import '../features/journal/presentation/voice_recording_screen.dart';

const journalHomeRouteName = 'journal-home';
const journalHomeRoutePath = '/';
const journalEntryCreateRouteName = 'journal-entry-create';
const journalEntryCreateRoutePath = '/entries/new';
const journalEntryDetailRouteName = 'journal-entry-detail';
const journalEntryDetailRoutePath = '/entries/:entryId';
const journalEntryEditRouteName = 'journal-entry-edit';
const journalEntryEditRoutePath = '/entries/:entryId/edit';
const voiceRecordingRouteName = 'voice-recording';
const voiceRecordingRoutePath = '/voice/new';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: journalHomeRoutePath,
    routes: [
      GoRoute(
        name: journalHomeRouteName,
        path: journalHomeRoutePath,
        builder: (context, state) => const JournalHomeScreen(),
      ),
      GoRoute(
        name: journalEntryCreateRouteName,
        path: journalEntryCreateRoutePath,
        builder: (context, state) => const JournalEntryEditorScreen(),
      ),
      GoRoute(
        name: voiceRecordingRouteName,
        path: voiceRecordingRoutePath,
        builder: (context, state) => const VoiceRecordingScreen(),
      ),
      GoRoute(
        name: journalEntryDetailRouteName,
        path: journalEntryDetailRoutePath,
        builder: (context, state) {
          final entryId = state.pathParameters['entryId']!;

          return JournalEntryDetailScreen(entryId: entryId);
        },
      ),
      GoRoute(
        name: journalEntryEditRouteName,
        path: journalEntryEditRoutePath,
        builder: (context, state) {
          final entryId = state.pathParameters['entryId']!;

          return JournalEntryEditorScreen(entryId: entryId);
        },
      ),
    ],
  );
});
