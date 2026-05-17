import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../data/resource_suggestion_service_provider.dart';
import '../domain/journal_entry.dart';
import '../domain/related_resource.dart';
import '../domain/resource_suggestion_service.dart';
import '../domain/theme_summary.dart';
import 'journal_formatters.dart';
import 'journal_theme_chips.dart';
import 'resource_suggestions_provider.dart';
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

    return Consumer(
      builder: (context, ref, child) {
        final suggestions = ref.watch(
          resourceSuggestionsProvider(
            ResourceSuggestionQuery(
              text: entries.map((entry) => entry.originalText).join('\n'),
              themeIds: [summary?.id ?? displayName.toLowerCase()],
            ),
          ),
        );

        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: entries.length + 3,
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
                            'Related resources and reflection prompts appear below related entries.',
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

            if (index <= entries.length + 1) {
              return _ThemeEntryListItem(entry: entries[index - 2]);
            }

            return _ThemeSuggestionsSection(
              suggestions: suggestions,
              themeId: summary?.id,
            );
          },
        );
      },
    );
  }
}

class _ThemeSuggestionsSection extends StatelessWidget {
  const _ThemeSuggestionsSection({required this.suggestions, this.themeId});

  final AsyncValue<List<RelatedResource>> suggestions;
  final String? themeId;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Related resources', style: textTheme.titleMedium),
        const SizedBox(height: 8),
        if (suggestions.isLoading)
          Text(
            'Loading related resources...',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        if (suggestions case AsyncData(value: final items))
          ...items
              .take(3)
              .map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _ThemeResourceCard(resource: item, themeId: themeId),
                ),
              ),
        if (suggestions case AsyncData(value: final items) when items.isEmpty)
          Text(
            'No related resources yet for this theme.',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}

class _ThemeResourceCard extends ConsumerWidget {
  const _ThemeResourceCard({required this.resource, this.themeId});

  final RelatedResource resource;
  final String? themeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(resource.title, style: Theme.of(context).textTheme.titleSmall),
            if (resource.description case final description?) ...[
              const SizedBox(height: 4),
              Text(description, style: Theme.of(context).textTheme.bodySmall),
            ],
            const SizedBox(height: 4),
            Text(
              '${resource.type} • ${(resource.confidence * 100).round()}% match',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: [
                TextButton(
                  onPressed: () => _submit(
                    ref,
                    resourceId: resource.id,
                    action: ResourceFeedbackAction.save,
                  ),
                  child: const Text('Save'),
                ),
                TextButton(
                  onPressed: () => _submit(
                    ref,
                    resourceId: resource.id,
                    action: ResourceFeedbackAction.dismiss,
                  ),
                  child: const Text('Dismiss'),
                ),
                TextButton(
                  onPressed: () => _submit(
                    ref,
                    resourceId: resource.id,
                    action: ResourceFeedbackAction.notHelpful,
                  ),
                  child: Text(
                    'Not helpful',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit(
    WidgetRef ref, {
    required String resourceId,
    required ResourceFeedbackAction action,
  }) async {
    await ref
        .read(resourceFeedbackControllerProvider.notifier)
        .saveFeedback(resourceId: resourceId, action: action);
    await ref
        .read(resourceSuggestionServiceProvider)
        .submitFeedback(
          resourceId: resourceId,
          action: action,
          themeId: themeId,
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
