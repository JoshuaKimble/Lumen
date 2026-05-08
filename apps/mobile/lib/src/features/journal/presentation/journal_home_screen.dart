import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'journal_entries_provider.dart';

class JournalHomeScreen extends ConsumerWidget {
  const JournalHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(journalEntriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Lumen')),
      body: SafeArea(
        child: entries.when(
          data: (items) => ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (context, index) => const Divider(height: 24),
            itemBuilder: (context, index) {
              final entry = items[index];

              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(entry.displayTitle),
                subtitle: Text(entry.previewText),
              );
            },
          ),
          error: (error, stackTrace) =>
              const Center(child: Text('Unable to load journal entries.')),
          loading: () => const Center(child: CircularProgressIndicator()),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'New entry',
        onPressed: () {},
        child: const Icon(Icons.edit_outlined),
      ),
    );
  }
}
