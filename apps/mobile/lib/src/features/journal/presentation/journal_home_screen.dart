import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../domain/journal_entry.dart';
import 'journal_formatters.dart';
import 'journal_entries_provider.dart';
import 'journal_theme_chips.dart';

class JournalHomeScreen extends ConsumerWidget {
  const JournalHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(journalEntriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Lumen')),
      body: SafeArea(
        child: entries.when(
          data: (items) {
            if (items.isEmpty) {
              return const _EmptyJournalState();
            }

            return _JournalEntryList(entries: items);
          },
          error: (error, stackTrace) =>
              const Center(child: Text('Unable to load journal entries.')),
          loading: () => const Center(child: CircularProgressIndicator()),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'New entry',
        onPressed: () => context.goNamed(journalEntryCreateRouteName),
        child: const Icon(Icons.edit_outlined),
      ),
    );
  }
}

class _JournalEntryList extends StatelessWidget {
  const _JournalEntryList({required this.entries});

  final List<JournalEntry> entries;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: entries.length,
      separatorBuilder: (context, index) => const Divider(height: 32),
      itemBuilder: (context, index) {
        final entry = entries[index];

        return _JournalEntryListItem(entry: entry);
      },
    );
  }
}

class _JournalEntryListItem extends StatelessWidget {
  const _JournalEntryListItem({required this.entry});

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
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              formatJournalDate(entry.createdAt),
              style: textTheme.labelLarge?.copyWith(color: colorScheme.primary),
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
    );
  }
}

class _EmptyJournalState extends StatelessWidget {
  const _EmptyJournalState();

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
              Icons.edit_note_outlined,
              size: 48,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'No journal entries yet',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Your reflections will appear here after you save them.',
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
