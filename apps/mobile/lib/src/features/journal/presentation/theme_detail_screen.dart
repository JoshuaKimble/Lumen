import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../domain/journal_entry.dart';
import '../domain/theme_summary.dart';
import 'journal_formatters.dart';
import 'journal_theme_chips.dart';
import 'theme_entries_provider.dart';
import 'theme_summaries_provider.dart';

class ThemeDetailScreen extends ConsumerWidget {
  const ThemeDetailScreen({required this.themeId, super.key});

  final String themeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(themeEntriesProvider(themeId));
    final summaries = ref.watch(themeSummariesProvider);
    final summary = switch (summaries) {
      AsyncData(value: final items) => _summaryFor(items),
      _ => null,
    };
    final displayName = summary?.displayName ?? _fallbackDisplayName(themeId);

    return Scaffold(
      appBar: AppBar(title: Text(displayName)),
      body: SafeArea(
        child: entries.when(
          data: (items) {
            if (items.isEmpty) {
              return _EmptyThemeDetailState(displayName: displayName);
            }

            return _ThemeDetailContent(
              displayName: displayName,
              summary: summary,
              entries: items,
            );
          },
          error: (error, stackTrace) =>
              const Center(child: Text('Unable to load theme entries.')),
          loading: () => const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }

  ThemeSummary? _summaryFor(List<ThemeSummary> summaries) {
    for (final summary in summaries) {
      if (summary.id == themeId) {
        return summary;
      }
    }

    return null;
  }

  String _fallbackDisplayName(String value) {
    if (value.isEmpty) {
      return 'Theme';
    }

    return '${value[0].toUpperCase()}${value.substring(1)}';
  }
}

class _ThemeDetailContent extends StatelessWidget {
  const _ThemeDetailContent({
    required this.displayName,
    required this.summary,
    required this.entries,
  });

  final String displayName;
  final ThemeSummary? summary;
  final List<JournalEntry> entries;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final entryCount = summary?.entryCount ?? entries.length;

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: entries.length + 2,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(displayName, style: textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                entryCount == 1
                    ? '1 related journal entry'
                    : '$entryCount related journal entries',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  border: Border.all(color: colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Insights', style: textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text(
                        'AI summaries and related resources for this theme will appear here as the product develops.',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }

        if (index == 1) {
          return Text('Related entries', style: textTheme.titleMedium);
        }

        return _ThemeEntryListItem(entry: entries[index - 2]);
      },
    );
  }
}

class _ThemeEntryListItem extends StatelessWidget {
  const _ThemeEntryListItem({required this.entry});

  final JournalEntry entry;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => context.goNamed(
        journalEntryDetailRouteName,
        pathParameters: {'entryId': entry.id},
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                formatJournalDate(entry.createdAt),
                style: textTheme.labelLarge?.copyWith(
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 6),
              Text(entry.displayTitle, style: textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                entry.summary ?? entry.previewText,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              JournalThemeChips(themes: entry.themes),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyThemeDetailState extends StatelessWidget {
  const _EmptyThemeDetailState({required this.displayName});

  final String displayName;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bubble_chart_outlined,
              size: 48,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'No entries for $displayName',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Entries will appear here after this theme is detected.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
