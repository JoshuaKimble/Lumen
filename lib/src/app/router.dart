import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/journal/presentation/journal_home_screen.dart';

const journalHomeRouteName = 'journal-home';
const journalHomeRoutePath = '/';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: journalHomeRoutePath,
    routes: [
      GoRoute(
        name: journalHomeRouteName,
        path: journalHomeRoutePath,
        builder: (context, state) => const JournalHomeScreen(),
      ),
    ],
  );
});
