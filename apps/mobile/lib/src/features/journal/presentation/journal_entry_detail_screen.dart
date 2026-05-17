import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../data/journal_ai_service_provider.dart';
import '../data/journal_repository_provider.dart';
import '../data/resource_suggestion_service_provider.dart';
import '../../settings/data/scripture_app_preference_provider.dart';
import '../../settings/domain/scripture_app_preference.dart';
import '../domain/journal_entry.dart';
import '../domain/journal_ai_service.dart';
import '../domain/related_resource.dart';
import '../domain/resource_suggestion_service.dart';
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
          'This removes the original entry, AI rewrite, themes, and resources from this device. You own your entries and can delete them at any time.',
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
        if (entry.summary case final summary?) ...[
          const SizedBox(height: 16),
          Text(summary, style: textTheme.bodyLarge),
        ],
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
        const SizedBox(height: 16),
        _EntryTextSection(
          title: 'AI rewrite',
          subtitle: 'A clarity suggestion, not a replacement.',
          text: entry.rewrittenText,
          icon: Icons.auto_awesome_outlined,
          emptyText: 'No rewrite yet.',
          emphasized: true,
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: _isGenerating ? null : _generateRewrite,
            icon: _isGenerating
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome_outlined),
            label: Text(
              _isGenerating ? 'Generating rewrite' : 'Regenerate AI rewrite',
            ),
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
        const SizedBox(height: 16),
        _ResourcesSection(
          resources: entry.resources,
          suggestions: suggestions,
          entryId: entry.id,
        ),
      ],
    );
  }

  Future<void> _generateRewrite() async {
    setState(() {
      _isGenerating = true;
      _generationError = null;
    });

    try {
      final aiService = ref.read(journalAiServiceProvider);
      final repository = ref.read(journalRepositoryProvider);
      final entry = widget.entry;
      final rewrite = await aiService.rewriteEntry(
        originalText: entry.originalText,
        source: JournalRewriteSource.regenerate,
      );
      final themeDetection = await aiService.detectThemes(
        text: entry.originalText,
      );
      final updatedEntry = entry.applyAiResults(
        rewrite: rewrite,
        themeDetection: themeDetection,
        updatedAt: DateTime.now().toUtc(),
      );

      await repository.saveEntry(updatedEntry);
      ref.invalidate(journalEntriesProvider);
      ref.invalidate(journalEntryProvider(entry.id));
    } catch (_) {
      if (mounted) {
        setState(() {
          _generationError = 'Unable to generate a rewrite right now.';
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
    this.emptyText,
    this.emphasized = false,
  });

  final String title;
  final String subtitle;
  final String text;
  final IconData icon;
  final String? emptyText;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final backgroundColor = emphasized
        ? colorScheme.primaryContainer
        : colorScheme.surfaceContainerHighest;
    final foregroundColor = emphasized
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurfaceVariant;

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
            Text(
              text.isEmpty ? emptyText ?? '' : text,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
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
                    'The original is preserved. AI rewrites are suggestions to help with clarity, not judgments, diagnoses, or replacements for your words.',
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

class _ResourcesSection extends StatelessWidget {
  const _ResourcesSection({
    required this.resources,
    required this.suggestions,
    required this.entryId,
  });

  final List<RelatedResource> resources;
  final AsyncValue<List<RelatedResource>> suggestions;
  final String entryId;

  @override
  Widget build(BuildContext context) {
    final combined = <RelatedResource>[
      ...resources,
      ...switch (suggestions) {
        AsyncData(value: final value) => value,
        _ => const <RelatedResource>[],
      },
    ];

    if (combined.isEmpty) {
      return const _EmptyResourcesSection();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Resources', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (suggestions.isLoading && resources.isEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text('Loading related resources...'),
          ),
        for (final resource in _dedupeById(combined))
          _ResourceCard(resource: resource, entryId: entryId),
      ],
    );
  }

  List<RelatedResource> _dedupeById(List<RelatedResource> value) {
    final seen = <String>{};
    final unique = <RelatedResource>[];

    for (final resource in value) {
      if (seen.add(resource.id)) {
        unique.add(resource);
      }
    }

    return unique;
  }
}

class _EmptyResourcesSection extends StatelessWidget {
  const _EmptyResourcesSection();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Text('No related resources yet.'),
      ),
    );
  }
}

class _ResourceCard extends ConsumerWidget {
  const _ResourceCard({required this.resource, required this.entryId});

  final RelatedResource resource;
  final String entryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final feedbackMap = ref.watch(resourceFeedbackControllerProvider);
    final feedback = feedbackMap.asData?.value[resource.id];
    final scripturePreference = ref.watch(
      scriptureAppPreferenceControllerProvider,
    );
    final selectedPreference =
        scripturePreference.asData?.value ?? ScriptureAppPreference.none;
    final resolvedUrl = ref
        .watch(scriptureResourceLinkResolverProvider)
        .resolve(resource, preference: selectedPreference);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _iconFor(resource.type),
                  size: 18,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    resource.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (feedback == ResourceFeedbackAction.save)
                  Icon(Icons.bookmark, size: 18, color: colorScheme.primary),
              ],
            ),
            if (resource.description case final description?) ...[
              const SizedBox(height: 6),
              Text(description, style: Theme.of(context).textTheme.bodyMedium),
            ],
            const SizedBox(height: 6),
            Text(
              '${resource.type} • ${resource.sourceType} • ${(resource.confidence * 100).round()}% match',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              resource.matchReason,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                OutlinedButton.icon(
                  onPressed: resolvedUrl == null
                      ? null
                      : () => _openResource(context, ref, resolvedUrl),
                  icon: const Icon(Icons.open_in_new_outlined),
                  label: const Text('Open'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _submitFeedback(
                    ref,
                    resourceId: resource.id,
                    action: ResourceFeedbackAction.save,
                    entryId: entryId,
                    themeId: resource.themeId,
                  ),
                  icon: const Icon(Icons.bookmark_border),
                  label: const Text('Save'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _submitFeedback(
                    ref,
                    resourceId: resource.id,
                    action: ResourceFeedbackAction.dismiss,
                    entryId: entryId,
                    themeId: resource.themeId,
                  ),
                  icon: const Icon(Icons.visibility_off_outlined),
                  label: const Text('Dismiss'),
                ),
                TextButton.icon(
                  onPressed: () => _submitFeedback(
                    ref,
                    resourceId: resource.id,
                    action: ResourceFeedbackAction.notHelpful,
                    entryId: entryId,
                    themeId: resource.themeId,
                  ),
                  icon: Icon(
                    Icons.thumb_down_alt_outlined,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  label: Text(
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

  Future<void> _submitFeedback(
    WidgetRef ref, {
    required String resourceId,
    required ResourceFeedbackAction action,
    required String entryId,
    String? themeId,
  }) async {
    await ref
        .read(resourceFeedbackControllerProvider.notifier)
        .saveFeedback(resourceId: resourceId, action: action);
    await ref
        .read(resourceSuggestionServiceProvider)
        .submitFeedback(
          resourceId: resourceId,
          action: action,
          entryId: entryId,
          themeId: themeId,
        );
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

  IconData _iconFor(String type) {
    return switch (type) {
      'scripture' => Icons.menu_book_outlined,
      'reflection_prompt' => Icons.quiz_outlined,
      'talk_or_article' => Icons.article_outlined,
      'video_or_audio' => Icons.play_circle_outline,
      'quote' => Icons.format_quote_outlined,
      'exercise' => Icons.self_improvement_outlined,
      'internal_entry_link' => Icons.link_outlined,
      _ => Icons.link_outlined,
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
