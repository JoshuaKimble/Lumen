import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../settings/data/scripture_app_preference_provider.dart';
import '../../settings/domain/scripture_app_preference.dart';
import '../data/resource_suggestion_service_provider.dart';
import '../domain/journal_entry.dart';
import '../domain/related_resource.dart';
import 'journal_entry_provider.dart';
import 'journal_formatters.dart';
import 'resource_suggestions_provider.dart';
import 'study_guide_progress_provider.dart';

class JournalStudyGuideScreen extends ConsumerWidget {
  const JournalStudyGuideScreen({required this.entryId, super.key});

  final String entryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entry = ref.watch(journalEntryProvider(entryId));

    return Scaffold(
      appBar: AppBar(title: const Text('Study guide')),
      body: SafeArea(
        child: entry.when(
          data: (item) {
            if (item == null) {
              return const Center(
                child: Text('This journal entry could not be found.'),
              );
            }

            return _StudyGuideBody(entry: item);
          },
          error: (error, stackTrace) =>
              const Center(child: Text('Unable to load this study guide.')),
          loading: () => const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }
}

class _StudyGuideBody extends ConsumerWidget {
  const _StudyGuideBody({required this.entry});

  final JournalEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ResourceSuggestionQuery(
      text: entry.originalText,
      themeIds: entry.themes.map((theme) => theme.id).toList(growable: false),
    );
    final suggestions = ref.watch(resourceSuggestionsProvider(query));
    final guide = _EntryStudyGuide.fromEntry(entry, switch (suggestions) {
      AsyncData(value: final value) => value,
      _ => null,
    });
    final progress = ref.watch(studyGuideProgressProvider(entry.id));

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Study guide', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          'Built from your reflection on ${formatJournalDateTime(entry.createdAt)}.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        _GuideOverviewCard(
          summary:
              entry.summary ??
              'These resources connect to the themes in your reflection and offer a few places to continue your gospel study.',
          progressLabel: _progressLabel(
            completedCount: _completedCount(
              guide.items,
              progress.asData?.value ?? const <String, bool>{},
            ),
            totalCount: guide.items.length,
          ),
        ),
        const SizedBox(height: 20),
        if (suggestions.isLoading && guide.items.isEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (guide.items.isEmpty)
          const _EmptyStudyGuideCard()
        else
          ...guide.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _StudyGuideItemCard(
                guideId: entry.id,
                item: item,
                isCompleted: progress.asData?.value[item.id] ?? false,
              ),
            ),
          ),
        const SizedBox(height: 8),
        _ReflectionPromptCard(prompt: guide.reflectionPrompt),
      ],
    );
  }

  int _completedCount(List<_GuideItem> items, Map<String, bool> progress) {
    return items.where((item) => progress[item.id] == true).length;
  }

  String _progressLabel({
    required int completedCount,
    required int totalCount,
  }) {
    if (totalCount == 0) {
      return 'Study guide ready';
    }

    return '$completedCount of $totalCount completed';
  }
}

class _GuideOverviewCard extends StatelessWidget {
  const _GuideOverviewCard({
    required this.summary,
    required this.progressLabel,
  });

  final String summary;
  final String progressLabel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'A few places to begin',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              summary,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              progressLabel,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyStudyGuideCard extends StatelessWidget {
  const _EmptyStudyGuideCard();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'A study guide is not available for this entry yet.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}

class _StudyGuideItemCard extends ConsumerWidget {
  const _StudyGuideItemCard({
    required this.guideId,
    required this.item,
    required this.isCompleted,
  });

  final String guideId;
  final _GuideItem item;
  final bool isCompleted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final scripturePreference = ref.watch(
      scriptureAppPreferenceControllerProvider,
    );
    final selectedPreference =
        scripturePreference.asData?.value ?? ScriptureAppPreference.none;
    final resolvedUrl = ref
        .watch(scriptureResourceLinkResolverProvider)
        .resolve(item.resource, preference: selectedPreference);

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: isCompleted ? 0.72 : 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          border: Border.all(
            color: isCompleted
                ? colorScheme.primary.withValues(alpha: 0.4)
                : colorScheme.outlineVariant,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: isCompleted,
                    onChanged: (value) => _toggleItem(
                      ref,
                      itemId: item.id,
                      isCompleted: value ?? false,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.label,
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                decoration: isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (item.secondaryLine case final secondaryLine?) ...[
                const SizedBox(height: 8),
                Text(
                  secondaryLine,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                item.contextLine,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (item.focusLine case final focusLine?) ...[
                const SizedBox(height: 8),
                Text(
                  focusLine,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (item.quote case final quote?) ...[
                const SizedBox(height: 10),
                Text(
                  '"$quote"',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              if (resolvedUrl != null)
                FilledButton.icon(
                  onPressed: () => _openResource(context, ref, resolvedUrl),
                  icon: const Icon(Icons.open_in_new_outlined),
                  label: Text(_openLabel(selectedPreference)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _openLabel(ScriptureAppPreference preference) {
    return switch (preference) {
      ScriptureAppPreference.gospelLibrary => 'Open in Gospel Library',
      ScriptureAppPreference.youVersion => 'Open in YouVersion',
      ScriptureAppPreference.bibleGateway => 'Open in Bible Gateway',
      ScriptureAppPreference.catholic => 'Open in Catholic study',
      ScriptureAppPreference.none => 'Open resource',
    };
  }

  Future<void> _openResource(
    BuildContext context,
    WidgetRef ref,
    Uri url,
  ) async {
    final didOpen = await ref.read(resourceLinkOpenerProvider).open(url);
    if (!context.mounted || didOpen) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Unable to open this resource on this device.'),
      ),
    );
  }

  Future<void> _toggleItem(
    WidgetRef ref, {
    required String itemId,
    required bool isCompleted,
  }) async {
    await ref
        .read(studyGuideProgressRepositoryProvider)
        .save(guideId: guideId, itemId: itemId, isCompleted: isCompleted);
    ref.invalidate(studyGuideProgressProvider(guideId));
  }
}

class _ReflectionPromptCard extends StatelessWidget {
  const _ReflectionPromptCard({required this.prompt});

  final String prompt;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reflect on this',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              prompt,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onPrimaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EntryStudyGuide {
  const _EntryStudyGuide({required this.items, required this.reflectionPrompt});

  final List<_GuideItem> items;
  final String reflectionPrompt;

  factory _EntryStudyGuide.fromEntry(
    JournalEntry entry,
    List<RelatedResource>? suggestions,
  ) {
    final combined = <RelatedResource>[...entry.resources, ...?suggestions];
    final seen = <String>{};
    final unique = combined.where((resource) => seen.add(resource.id)).toList();
    final promptResource = unique.cast<RelatedResource?>().firstWhere(
      (resource) => resource?.type == 'reflection_prompt',
      orElse: () => null,
    );

    final guideItems = unique
        .where((resource) => resource.type != 'reflection_prompt')
        .map(_GuideItem.fromResource)
        .whereType<_GuideItem>()
        .toList(growable: false);

    return _EntryStudyGuide(
      items: guideItems,
      reflectionPrompt:
          promptResource?.description ??
          promptResource?.title ??
          _defaultPrompt(entry),
    );
  }

  static String _defaultPrompt(JournalEntry entry) {
    if (entry.themes.isNotEmpty) {
      final themeNames = entry.themes
          .take(2)
          .map((theme) => theme.displayName.toLowerCase())
          .join(' and ');
      return 'As you study, what do you notice about $themeNames in your life right now?';
    }

    return 'As you study these resources, what feels most worth carrying into the rest of your day?';
  }
}

class _GuideItem {
  const _GuideItem({
    required this.id,
    required this.label,
    required this.title,
    required this.contextLine,
    required this.resource,
    this.secondaryLine,
    this.focusLine,
    this.quote,
  });

  final String id;
  final String label;
  final String title;
  final String contextLine;
  final String? secondaryLine;
  final String? focusLine;
  final String? quote;
  final RelatedResource resource;

  static _GuideItem? fromResource(RelatedResource resource) {
    final normalizedType = resource.type.toLowerCase();

    return switch (normalizedType) {
      'scripture' => _GuideItem(
        id: resource.id,
        label: 'Scripture',
        title: resource.title,
        contextLine: resource.matchReason,
        focusLine: resource.scriptureReference == null
            ? null
            : 'Focus on ${resource.scriptureReference}.',
        quote: resource.description,
        resource: resource,
      ),
      'talk_or_article' => _GuideItem(
        id: resource.id,
        label: 'Conference talk',
        title: resource.title,
        contextLine: resource.matchReason,
        secondaryLine: resource.description,
        resource: resource,
      ),
      _ => _GuideItem(
        id: resource.id,
        label: 'Study resource',
        title: resource.title,
        contextLine: resource.matchReason,
        secondaryLine: resource.description,
        resource: resource,
      ),
    };
  }
}
