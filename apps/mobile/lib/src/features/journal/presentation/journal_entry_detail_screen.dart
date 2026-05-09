import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../data/journal_ai_service_provider.dart';
import '../data/journal_repository_provider.dart';
import '../domain/journal_entry.dart';
import '../domain/related_resource.dart';
import 'journal_entries_provider.dart';
import 'journal_entry_provider.dart';
import 'journal_formatters.dart';
import 'journal_theme_chips.dart';

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
              icon: const Icon(Icons.delete_outline),
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
        content: const Text('This removes the journal entry from this device.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
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
        _EntryTextSection(
          title: 'Original',
          text: entry.originalText,
          icon: Icons.mic_none_outlined,
        ),
        const SizedBox(height: 16),
        _EntryTextSection(
          title: 'AI rewrite',
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
              _isGenerating ? 'Generating rewrite' : 'Regenerate rewrite',
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
        _ResourcesSection(resources: entry.resources),
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
    required this.text,
    required this.icon,
    this.emptyText,
    this.emphasized = false,
  });

  final String title;
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
              text.isEmpty ? emptyText ?? '' : text,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}

class _ResourcesSection extends StatelessWidget {
  const _ResourcesSection({required this.resources});

  final List<RelatedResource> resources;

  @override
  Widget build(BuildContext context) {
    if (resources.isEmpty) {
      return const _EmptyResourcesSection();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Resources', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        for (final resource in resources)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.link_outlined),
            title: Text(resource.title),
            subtitle: Text(resource.type),
          ),
      ],
    );
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

class _MissingEntryState extends StatelessWidget {
  const _MissingEntryState();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('This journal entry could not be found.'));
  }
}
