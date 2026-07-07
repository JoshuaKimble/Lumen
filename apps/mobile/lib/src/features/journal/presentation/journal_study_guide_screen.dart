import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/journal_entry.dart';
import '../domain/study_guide.dart';
import '../data/resource_suggestion_service_provider.dart';
import 'journal_entry_provider.dart';
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
    final guide = entry.studyGuide;
    final progress = ref.watch(studyGuideProgressProvider(entry.id));

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Study guide', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          guide == null
              ? 'A gospel study guide will appear here after the entry is processed.'
              : guide.overview,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        if (guide != null && guide.items.isNotEmpty)
          Text(
            _progressLabel(
              completedCount: guide.items
                  .where((item) => progress.asData?.value[item.id] == true)
                  .length,
              totalCount: guide.items.length,
            ),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        const SizedBox(height: 16),
        if (guide == null || guide.items.isEmpty)
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
        _ReflectionPromptCard(
          prompt: guide?.reflectionPrompt.text ?? _defaultPrompt(entry),
        ),
      ],
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
  final StudyGuideItem item;
  final bool isCompleted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final resolvedUrl = item.destination.url;

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
                          _kindLabel(item.kind),
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
              if (item.publishedContext case final publishedContext?) ...[
                const SizedBox(height: 8),
                Text(
                  publishedContext,
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
              if (item.focusText case final focusLine?) ...[
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
                  label: Text(_openLabel(item.destination.providerKey)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _openLabel(String providerKey) {
    return switch (providerKey) {
      'gospel_library' => 'Open in Gospel Library',
      'you_version' => 'Open in YouVersion',
      'bible_gateway' => 'Open in Bible Gateway',
      'catholic' => 'Open in Catholic study',
      _ => 'Open resource',
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

String _kindLabel(String kind) {
  return switch (kind) {
    'scripture' => 'Scripture',
    'conference_talk' => 'Conference talk',
    _ => 'Study resource',
  };
}

String _defaultPrompt(JournalEntry entry) {
  if (entry.themes.isNotEmpty) {
    final themeNames = entry.themes
        .take(2)
        .map((theme) => theme.displayName.toLowerCase())
        .join(' and ');
    return 'As you study, what do you notice about $themeNames in your life right now?';
  }

  return 'As you study these resources, what feels most worth carrying into the rest of your day?';
}

String _progressLabel({required int completedCount, required int totalCount}) {
  if (totalCount == 0) {
    return 'Study guide ready';
  }

  return '$completedCount of $totalCount completed';
}
