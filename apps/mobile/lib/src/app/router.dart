import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/journal/presentation/journal_entry_detail_screen.dart';
import '../features/journal/presentation/journal_entry_editor_screen.dart';
import '../features/journal/presentation/journal_home_screen.dart';
import '../features/journal/presentation/theme_cloud_screen.dart';
import '../features/journal/presentation/theme_detail_screen.dart';
import '../features/journal/presentation/voice_recording_screen.dart';
import '../features/settings/presentation/theme_settings_screen.dart';

const journalHomeRouteName = 'journal-home';
const journalHomeRoutePath = '/';
const journalEntryCreateRouteName = 'journal-entry-create';
const journalEntryCreateRoutePath = '/entries/new';
const journalEntryDetailRouteName = 'journal-entry-detail';
const journalEntryDetailRoutePath = '/entries/:entryId';
const journalEntryEditRouteName = 'journal-entry-edit';
const journalEntryEditRoutePath = '/entries/:entryId/edit';
const themeCloudRouteName = 'theme-cloud';
const themeCloudRoutePath = '/themes';
const themeDetailRouteName = 'theme-detail';
const themeDetailRoutePath = '/themes/:themeId';
const voiceRecordingRouteName = 'voice-recording';
const voiceRecordingRoutePath = '/voice/new';
const settingsRouteName = 'settings';
const settingsRoutePath = '/settings';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: journalHomeRoutePath,
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          return LumenNavigationScaffold(
            location: state.uri.path,
            child: child,
          );
        },
        routes: [
          GoRoute(
            name: journalHomeRouteName,
            path: journalHomeRoutePath,
            builder: (context, state) => const JournalHomeScreen(),
          ),
          GoRoute(
            name: voiceRecordingRouteName,
            path: voiceRecordingRoutePath,
            builder: (context, state) => const VoiceRecordingScreen(),
          ),
          GoRoute(
            name: themeCloudRouteName,
            path: themeCloudRoutePath,
            builder: (context, state) => const ThemeCloudScreen(),
          ),
          GoRoute(
            name: themeDetailRouteName,
            path: themeDetailRoutePath,
            builder: (context, state) {
              final themeId = state.pathParameters['themeId']!;

              return ThemeDetailScreen(themeId: themeId);
            },
          ),
          GoRoute(
            name: journalEntryCreateRouteName,
            path: journalEntryCreateRoutePath,
            builder: (context, state) => const JournalEntryEditorScreen(),
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
          GoRoute(
            name: settingsRouteName,
            path: settingsRoutePath,
            builder: (context, state) => const ThemeSettingsScreen(),
          ),
        ],
      ),
    ],
  );
});

class LumenNavigationScaffold extends StatelessWidget {
  const LumenNavigationScaffold({
    required this.location,
    required this.child,
    super.key,
  });

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          final routeName = switch (index) {
            0 => journalHomeRouteName,
            1 => themeCloudRouteName,
            2 => voiceRecordingRouteName,
            3 => settingsRouteName,
            _ => journalHomeRouteName,
          };
          final routePath = switch (index) {
            0 => journalHomeRoutePath,
            1 => themeCloudRoutePath,
            2 => voiceRecordingRoutePath,
            3 => settingsRoutePath,
            _ => journalHomeRoutePath,
          };

          if (location == routePath) {
            return;
          }

          context.goNamed(routeName);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.book_outlined),
            selectedIcon: Icon(Icons.book),
            label: 'Journal',
          ),
          NavigationDestination(
            icon: Icon(Icons.bubble_chart_outlined),
            selectedIcon: Icon(Icons.bubble_chart),
            label: 'Themes',
          ),
          NavigationDestination(
            icon: Icon(Icons.mic_none_outlined),
            selectedIcon: Icon(Icons.mic),
            label: 'Voice',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  int get _selectedIndex {
    if (location == voiceRecordingRoutePath) {
      return 2;
    }

    if (location == settingsRoutePath) {
      return 3;
    }

    if (location == themeCloudRoutePath) {
      return 1;
    }

    return 0;
  }
}
