import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../auth/data/admin_access_provider.dart';
import '../data/journal_ai_service_provider.dart';
import '../data/journal_repository_provider.dart';
import '../domain/journal_entry.dart';
import '../domain/related_resource.dart';
import 'journal_entries_provider.dart';
import 'journal_entry_provider.dart';
import 'journal_formatters.dart';
import 'journal_theme_chips.dart';
import 'resource_suggestions_provider.dart';

class JournalEntryDetailScreen extends ConsumerWidget {
  const JournalEntryDetailScreen({required this.entryId, super.key});

  final String entryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entry = ref.watch(journalEntryProvider(entryId));
    final loadedEntry = switch (entry) {
      AsyncData(value: final value) => value,
      _ => null,
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Journal entry'),
        actions: [
          if (loadedEntry != null) ...[
            IconButton(
              tooltip: 'Edit entry',
              onPressed: () => context.goNamed(
                journalEntryEditRouteName,
                pathParameters: {'entryId': entryId},
              ),
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              tooltip: 'Delete entry',
              onPressed: () => _confirmDelete(context, ref),
              icon: Icon(
                Icons.delete_outline,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ],
      ),
      body: SafeArea(
        child: entry.when(
          data: (item) {
            if (item == null) {
              return const _MissingEntryState();
            }

            return _JournalEntryDetail(entry: item);
          },
          error: (error, stackTrace) =>
              const Center(child: Text('Unable to load this journal entry.')),
          loading: () => const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete entry?'),
        content: const Text(
          'This removes the original entry, AI summary, themes, and resources from this device. You own your entries and can delete them at any time.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) {
      return;
    }

    await ref.read(journalRepositoryProvider).deleteEntry(entryId);
    ref.invalidate(journalEntriesProvider);
    ref.invalidate(journalEntryProvider(entryId));

    if (context.mounted) {
      context.goNamed(journalHomeRouteName);
    }
  }
}

class _JournalEntryDetail extends ConsumerStatefulWidget {
  const _JournalEntryDetail({required this.entry});

  final JournalEntry entry;

  @override
  ConsumerState<_JournalEntryDetail> createState() =>
      _JournalEntryDetailState();
}

class _JournalEntryDetailState extends ConsumerState<_JournalEntryDetail> {
  bool _isGenerating = false;
  String? _generationError;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final entry = widget.entry;
    final isAiAdmin = ref.watch(isCurrentUserAdminProvider);
    final suggestions = ref.watch(
      resourceSuggestionsProvider(
        ResourceSuggestionQuery(
          text: entry.originalText,
          themeIds: entry.themes
              .map((theme) => theme.id)
              .toList(growable: false),
        ),
      ),
    );

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(entry.displayTitle, style: textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          formatJournalDateTime(entry.createdAt),
          style: textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        if (isAiAdmin) ...[
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: _isGenerating ? null : _regenerateAi,
              icon: _isGenerating
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome_outlined),
              label: Text(_isGenerating ? 'Refreshing AI' : 'Regenerate AI'),
            ),
          ),
          if (_generationError case final message?) ...[
            const SizedBox(height: 8),
            Text(
              message,
              style: textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ],
        if (entry.summary case final summary?) ...[
          const SizedBox(height: 16),
          Text(summary, style: textTheme.bodyLarge),
        ],
        const SizedBox(height: 20),
        _StudyGuidePreviewCard(
          entryId: entry.id,
          resources: entry.resources,
          suggestions: suggestions,
        ),
        const SizedBox(height: 20),
        JournalThemeChips(themes: entry.themes),
        const SizedBox(height: 24),
        const _TrustNotice(),
        const SizedBox(height: 24),
        _EntryTextSection(
          title: 'Original entry',
          subtitle: 'Preserved exactly as you saved it.',
          text: entry.originalText,
          icon: Icons.mic_none_outlined,
        ),
      ],
    );
  }

  Future<void> _regenerateAi() async {
    setState(() {
      _isGenerating = true;
      _generationError = null;
    });

    try {
      final aiService = ref.read(journalAiServiceProvider);
      final repository = ref.read(journalRepositoryProvider);
      final entry = widget.entry;
      final summary = await aiService.summarizeEntry(
        originalText: entry.originalText,
      );
      final themeDetection = await aiService.detectThemes(
        text: entry.originalText,
      );
      final updatedEntry = entry.applyGeneratedInsights(
        summaryResult: summary,
        themeDetection: themeDetection,
        updatedAt: DateTime.now().toUtc(),
      );
      final oldResourceQuery = ResourceSuggestionQuery(
        text: entry.originalText,
        themeIds: entry.themes.map((theme) => theme.id).toList(growable: false),
      );
      final newResourceQuery = ResourceSuggestionQuery(
        text: updatedEntry.originalText,
        themeIds: updatedEntry.themes
            .map((theme) => theme.id)
            .toList(growable: false),
      );

      await repository.saveEntry(updatedEntry);
      ref.invalidate(journalEntriesProvider);
      ref.invalidate(journalEntryProvider(entry.id));
      ref.invalidate(resourceSuggestionsProvider(oldResourceQuery));
      ref.invalidate(resourceSuggestionsProvider(newResourceQuery));
    } catch (_) {
      if (mounted) {
        setState(() {
          _generationError = 'Unable to refresh AI for this entry right now.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }
}

class _EntryTextSection extends StatelessWidget {
  const _EntryTextSection({
    required this.title,
    required this.subtitle,
    required this.text,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final backgroundColor = colorScheme.surfaceContainerHighest;
    final foregroundColor = colorScheme.onSurfaceVariant;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: foregroundColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: foregroundColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Text(text, style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}

class _TrustNotice extends StatelessWidget {
  const _TrustNotice();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.lock_outline, color: colorScheme.primary, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Your entry stays yours', style: textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text(
                    'The original is preserved. AI can summarize and tag patterns in your writing, but it does not replace your words.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StudyGuidePreviewCard extends StatelessWidget {
  const _StudyGuidePreviewCard({
    required this.entryId,
    required this.resources,
    required this.suggestions,
  });

  final String entryId;
  final List<RelatedResource> resources;
  final AsyncValue<List<RelatedResource>> suggestions;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final guidePreview = _EntryStudyGuidePreview.fromResources(
      resources: resources,
      suggestions: switch (suggestions) {
        AsyncData(value: final value) => value,
        _ => const <RelatedResource>[],
      },
    );

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
              'Study guide',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              guidePreview.subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            if (guidePreview.previewLine case final previewLine?) ...[
              const SizedBox(height: 8),
              Text(
                previewLine,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 12),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.onPrimaryContainer,
                foregroundColor: colorScheme.primaryContainer,
              ),
              onPressed: guidePreview.isAvailable
                  ? () => context.goNamed(
                      journalStudyGuideRouteName,
                      pathParameters: {'entryId': entryId},
                    )
                  : null,
              icon: const Icon(Icons.auto_stories_outlined),
              label: const Text('Open study guide'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EntryStudyGuidePreview {
  const _EntryStudyGuidePreview({
    required this.isAvailable,
    required this.subtitle,
    this.previewLine,
  });

  final bool isAvailable;
  final String subtitle;
  final String? previewLine;

  factory _EntryStudyGuidePreview.fromResources({
    required List<RelatedResource> resources,
    required List<RelatedResource> suggestions,
  }) {
    final combined = <RelatedResource>[...resources, ...suggestions];
    final seen = <String>{};
    final unique = combined.where((resource) => seen.add(resource.id)).toList();
    final guideItems = unique
        .where((resource) => resource.type != 'reflection_prompt')
        .toList(growable: false);

    if (guideItems.isEmpty) {
      return const _EntryStudyGuidePreview(
        isAvailable: false,
        subtitle: 'A study guide is not available for this entry yet.',
      );
    }

    final strongest = guideItems.first;
    final itemCount = guideItems.length;

    return _EntryStudyGuidePreview(
      isAvailable: true,
      subtitle: 'A gospel study guide built from this reflection.',
      previewLine: switch (itemCount) {
        1 => 'Includes ${_resourcePreviewLabel(strongest)}.',
        2 =>
          'Includes ${_resourcePreviewLabel(strongest)} and one more resource.',
        _ =>
          'Includes ${_resourcePreviewLabel(strongest)} and ${itemCount - 1} more resources.',
      },
    );
  }

  static String _resourcePreviewLabel(RelatedResource resource) {
    return switch (resource.type) {
      'scripture' => resource.scriptureReference ?? resource.title,
      'talk_or_article' => resource.title,
      _ => resource.title,
    };
  }
}

class _MissingEntryState extends StatelessWidget {
  const _MissingEntryState();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('This journal entry could not be found.'));
  }
}
