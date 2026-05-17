import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../data/journal_ai_service_provider.dart';
import '../data/journal_repository_provider.dart';
import '../data/voice_transcription_service_provider.dart';
import '../domain/entry_source.dart';
import '../domain/journal_ai_service.dart';
import '../domain/journal_entry.dart';
import '../data/voice_recorder_provider.dart';
import '../domain/voice_recording.dart';
import 'journal_entries_provider.dart';
import 'journal_entry_provider.dart';

class VoiceRecordingScreen extends ConsumerStatefulWidget {
  const VoiceRecordingScreen({super.key});

  @override
  ConsumerState<VoiceRecordingScreen> createState() =>
      _VoiceRecordingScreenState();
}

class _VoiceRecordingScreenState extends ConsumerState<VoiceRecordingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _transcriptController = TextEditingController();

  VoiceRecordingStatus _status = VoiceRecordingStatus.idle;
  VoiceRecording? _recording;
  String? _errorMessage;

  bool get _isStarting => _status == VoiceRecordingStatus.starting;

  bool get _isRecording => _status == VoiceRecordingStatus.recording;

  bool get _isStopping => _status == VoiceRecordingStatus.stopping;

  bool get _isTranscribing => _status == VoiceRecordingStatus.transcribing;

  bool get _isReviewing => _status == VoiceRecordingStatus.reviewingTranscript;

  bool get _isSaving => _status == VoiceRecordingStatus.savingEntry;

  @override
  void dispose() {
    _transcriptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Voice entry')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Icon(
                _isRecording ? Icons.mic : Icons.mic_none_outlined,
                size: 56,
                color: _isRecording ? colorScheme.error : colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                _headline,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _supportingText,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              if (_errorMessage case final message?) ...[
                const SizedBox(height: 16),
                Text(
                  message,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: colorScheme.error),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 24),
              if (_isReviewing || _isSaving) ...[
                TextFormField(
                  controller: _transcriptController,
                  minLines: 8,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    alignLabelWithHint: true,
                    labelText: 'Transcript',
                    hintText: 'Review and edit the transcript before saving.',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Review the transcript before saving.';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _isSaving ? null : _saveVoiceEntry,
                  icon: _isSaving
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_outlined),
                  label: Text(_isSaving ? 'Saving' : 'Save voice entry'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _isSaving ? null : _startRecording,
                  child: const Text('Record again'),
                ),
              ] else if (_isRecording || _isStopping) ...[
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.error,
                    foregroundColor: colorScheme.onError,
                  ),
                  onPressed: _isStopping ? null : _stopRecording,
                  icon: const Icon(Icons.stop_outlined),
                  label: Text(_isStopping ? 'Stopping' : 'Stop recording'),
                ),
              ] else if (_isTranscribing) ...[
                const Center(child: CircularProgressIndicator()),
              ] else ...[
                FilledButton.icon(
                  onPressed: _isStarting ? null : _startRecording,
                  icon: const Icon(Icons.mic_outlined),
                  label: Text(_isStarting ? 'Starting' : 'Start recording'),
                ),
              ],
              if (_recording case final recording?) ...[
                const SizedBox(height: 24),
                _CapturedRecording(recording: recording),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String get _headline {
    return switch (_status) {
      VoiceRecordingStatus.idle => 'Capture a voice entry',
      VoiceRecordingStatus.starting => 'Preparing microphone',
      VoiceRecordingStatus.recording => 'Recording',
      VoiceRecordingStatus.stopping => 'Saving temporary audio',
      VoiceRecordingStatus.transcribing => 'Transcribing recording',
      VoiceRecordingStatus.reviewingTranscript => 'Review transcript',
      VoiceRecordingStatus.savingEntry => 'Saving voice entry',
      VoiceRecordingStatus.permissionDenied => 'Microphone access is needed',
      VoiceRecordingStatus.error => 'Recording unavailable',
    };
  }

  String get _supportingText {
    return switch (_status) {
      VoiceRecordingStatus.idle =>
        'Start recording when you are ready. The audio is kept temporarily until transcription is available.',
      VoiceRecordingStatus.starting => 'The app is checking microphone access.',
      VoiceRecordingStatus.recording => 'Tap stop when you are finished.',
      VoiceRecordingStatus.stopping => 'The recording is being stored locally.',
      VoiceRecordingStatus.transcribing =>
        'The app is preparing text from your recording.',
      VoiceRecordingStatus.reviewingTranscript =>
        'Make any corrections before saving this as your original entry.',
      VoiceRecordingStatus.savingEntry =>
        'The app is saving your original transcript and preparing AI results.',
      VoiceRecordingStatus.permissionDenied =>
        'Allow microphone access in your browser or device settings to record journal entries.',
      VoiceRecordingStatus.error =>
        'The recording could not be completed. Try again in a moment.',
    };
  }

  Future<void> _startRecording() async {
    setState(() {
      _status = VoiceRecordingStatus.starting;
      _errorMessage = null;
      _recording = null;
      _transcriptController.clear();
    });

    final recorder = ref.read(voiceRecorderProvider);
    final hasPermission = await recorder.hasPermission();

    if (!mounted) {
      return;
    }

    if (!hasPermission) {
      setState(() {
        _status = VoiceRecordingStatus.permissionDenied;
      });
      return;
    }

    try {
      await recorder.start(startedAt: DateTime.now().toUtc());

      if (mounted) {
        setState(() {
          _status = VoiceRecordingStatus.recording;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _status = VoiceRecordingStatus.error;
          _errorMessage = 'Unable to start recording.';
        });
      }
    }
  }

  Future<void> _stopRecording() async {
    setState(() {
      _status = VoiceRecordingStatus.stopping;
      _errorMessage = null;
    });

    try {
      final recording = await ref
          .read(voiceRecorderProvider)
          .stop(stoppedAt: DateTime.now().toUtc());

      if (!mounted) {
        return;
      }

      if (recording == null) {
        setState(() {
          _status = VoiceRecordingStatus.error;
          _errorMessage = 'Unable to save the recording.';
        });
        return;
      }

      setState(() {
        _recording = recording;
        _status = VoiceRecordingStatus.transcribing;
      });

      await _transcribeRecording(recording);
    } catch (_) {
      if (mounted) {
        setState(() {
          _status = VoiceRecordingStatus.error;
          _errorMessage = 'Unable to stop recording.';
        });
      }
    }
  }

  Future<void> _transcribeRecording(VoiceRecording recording) async {
    try {
      final transcript = await ref
          .read(voiceTranscriptionServiceProvider)
          .transcribe(recording);

      if (mounted) {
        setState(() {
          _transcriptController.text = transcript;
          _status = VoiceRecordingStatus.reviewingTranscript;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _status = VoiceRecordingStatus.error;
          _errorMessage = 'Unable to transcribe the recording.';
        });
      }
    }
  }

  Future<void> _saveVoiceEntry() async {
    final formState = _formKey.currentState;

    if (formState == null || !formState.validate()) {
      return;
    }

    setState(() {
      _status = VoiceRecordingStatus.savingEntry;
      _errorMessage = null;
    });

    final repository = ref.read(journalRepositoryProvider);
    final aiService = ref.read(journalAiServiceProvider);
    final now = DateTime.now().toUtc();
    final originalText = _transcriptController.text;
    var entry = JournalEntry(
      id: 'entry-${now.microsecondsSinceEpoch}',
      createdAt: now,
      updatedAt: now,
      source: EntrySource.voice,
      originalText: originalText,
      rewrittenText: '',
      themes: const [],
      resources: const [],
    );

    try {
      final rewrite = await aiService.rewriteEntry(
        originalText: originalText,
        source: JournalRewriteSource.voiceSave,
      );
      final themeDetection = await aiService.detectThemes(text: originalText);
      entry = entry.applyAiResults(
        rewrite: rewrite,
        themeDetection: themeDetection,
        updatedAt: now,
      );
    } catch (_) {
      entry = entry.withoutAiResults(updatedAt: now);
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
}

enum VoiceRecordingStatus {
  idle,
  starting,
  recording,
  stopping,
  transcribing,
  reviewingTranscript,
  savingEntry,
  permissionDenied,
  error,
}

class _CapturedRecording extends StatelessWidget {
  const _CapturedRecording({required this.recording});

  final VoiceRecording recording;

  @override
  Widget build(BuildContext context) {
    final duration = recording.stoppedAt.difference(recording.startedAt);

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Temporary audio saved',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text('Duration: ${duration.inSeconds}s'),
            const SizedBox(height: 4),
            Text(recording.uri, maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}
