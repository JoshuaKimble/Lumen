import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../data/journal_ai_service_provider.dart';
import '../data/journal_repository_provider.dart';
import '../domain/entry_source.dart';
import '../domain/journal_ai_service.dart';
import '../domain/journal_entry.dart';
import 'journal_entries_provider.dart';
import 'journal_entry_provider.dart';

class JournalEntryEditorScreen extends ConsumerWidget {
  const JournalEntryEditorScreen({this.entryId, super.key});

  final String? entryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = entryId;

    if (id == null) {
      return const _JournalEntryEditorScaffold(entry: null);
    }

    final entry = ref.watch(journalEntryProvider(id));

    return entry.when(
      data: (item) {
        if (item == null) {
          return const Scaffold(
            body: SafeArea(
              child: Center(
                child: Text('This journal entry could not be found.'),
              ),
            ),
          );
        }

        return _JournalEntryEditorScaffold(entry: item);
      },
      error: (error, stackTrace) => const Scaffold(
        body: SafeArea(
          child: Center(child: Text('Unable to load this journal entry.')),
        ),
      ),
      loading: () => const Scaffold(
        body: SafeArea(child: Center(child: CircularProgressIndicator())),
      ),
    );
  }
}

class _JournalEntryEditorScaffold extends ConsumerStatefulWidget {
  const _JournalEntryEditorScaffold({required this.entry});

  final JournalEntry? entry;

  @override
  ConsumerState<_JournalEntryEditorScaffold> createState() =>
      _JournalEntryEditorScaffoldState();
}

class _JournalEntryEditorScaffoldState
    extends ConsumerState<_JournalEntryEditorScaffold> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _originalTextController;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.entry?.title ?? '');
    _originalTextController = TextEditingController(
      text: widget.entry?.originalText ?? '',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _originalTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.entry != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit entry' : 'New text entry')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              TextFormField(
                controller: _titleController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'Optional',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _originalTextController,
                autofocus: !isEditing,
                minLines: 8,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  alignLabelWithHint: true,
                  labelText: 'Original entry',
                  hintText: 'Write what you want to remember.',
                  helperText:
                      'This is saved as your original entry. AI rewrites never replace it.',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Write an entry before saving.';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _isSaving ? null : _saveEntry,
                icon: const Icon(Icons.check_outlined),
                label: Text(_isSaving ? 'Saving' : 'Save entry'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _isSaving ? null : () => context.pop(),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveEntry() async {
    final formState = _formKey.currentState;

    if (formState == null || !formState.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final repository = ref.read(journalRepositoryProvider);
    final aiService = ref.read(journalAiServiceProvider);
    final now = DateTime.now().toUtc();
    final originalText = _originalTextController.text;
    final title = _titleController.text.trim();
    final existingEntry = widget.entry;
    var entry = existingEntry == null
        ? _newTypedEntry(
            now: now,
            originalText: originalText,
            title: title.isEmpty ? null : title,
          )
        : _updatedEntry(
            existingEntry: existingEntry,
            now: now,
            originalText: originalText,
            title: title.isEmpty ? null : title,
          );

    if (_shouldGenerateAfterSave(existingEntry, originalText)) {
      try {
        final rewrite = await aiService.rewriteEntry(
          originalText: originalText,
          source: existingEntry == null
              ? JournalRewriteSource.typedCreate
              : JournalRewriteSource.typedEditSave,
        );
        final themeDetection = await aiService.detectThemes(text: originalText);
        entry = entry.applyAiResults(
          rewrite: rewrite,
          themeDetection: themeDetection,
          updatedAt: now,
          preserveTitle: title.isNotEmpty,
        );
      } catch (_) {
        entry = entry.withoutAiResults(updatedAt: now);
      }
    }

    await repository.saveEntry(entry);
    ref.invalidate(journalEntriesProvider);
    ref.invalidate(journalEntryProvider(entry.id));

    if (mounted) {
      context.goNamed(
        journalEntryDetailRouteName,
        pathParameters: {'entryId': entry.id},
      );
    }
  }

  bool _shouldGenerateAfterSave(
    JournalEntry? existingEntry,
    String originalText,
  ) {
    return existingEntry == null || existingEntry.originalText != originalText;
  }

  JournalEntry _newTypedEntry({
    required DateTime now,
    required String originalText,
    required String? title,
  }) {
    return JournalEntry(
      id: 'entry-${now.microsecondsSinceEpoch}',
      createdAt: now,
      updatedAt: now,
      source: EntrySource.text,
      originalText: originalText,
      rewrittenText: '',
      themes: const [],
      resources: const [],
      title: title,
    );
  }

  JournalEntry _updatedEntry({
    required JournalEntry existingEntry,
    required DateTime now,
    required String originalText,
    required String? title,
  }) {
    return JournalEntry(
      id: existingEntry.id,
      createdAt: existingEntry.createdAt,
      updatedAt: now,
      source: existingEntry.source,
      originalText: originalText,
      rewrittenText: existingEntry.rewrittenText,
      themes: existingEntry.themes,
      resources: existingEntry.resources,
      title: title,
      summary: existingEntry.summary,
      lastRegeneratedAt: existingEntry.lastRegeneratedAt,
    );
  }
}
