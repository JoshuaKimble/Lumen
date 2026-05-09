import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/journal/presentation/journal_entry_detail_screen.dart';
import '../features/journal/presentation/journal_home_screen.dart';

const journalHomeRouteName = 'journal-home';
const journalHomeRoutePath = '/';
const journalEntryDetailRouteName = 'journal-entry-detail';
const journalEntryDetailRoutePath = '/entries/:entryId';

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
        name: journalEntryDetailRouteName,
        path: journalEntryDetailRoutePath,
        builder: (context, state) {
          final entryId = state.pathParameters['entryId']!;

          return JournalEntryDetailScreen(entryId: entryId);
        },
      ),
    ],
  );
});
