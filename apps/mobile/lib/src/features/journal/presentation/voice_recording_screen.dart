import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../api/generated/lumen_api_client.dart';
import '../../../app/router.dart';
import '../data/journal_ai_service_provider.dart';
import '../data/journal_repository_provider.dart';
import '../data/voice_transcription_service_provider.dart';
import '../domain/entry_source.dart';
import '../domain/journal_entry.dart';
import '../data/voice_recorder_provider.dart';
import '../domain/voice_recording.dart';
import '../domain/voice_recording_attempt.dart';
import '../domain/voice_transcription_exception.dart';
import 'voice_recording_history_controller.dart';
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
  String? _activeAttemptId;
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
    final historyValue = ref.watch(voiceRecordingHistoryControllerProvider);

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
              const SizedBox(height: 24),
              _TranscriptionHistorySection(
                historyValue: historyValue,
                onRetry: _retryAttempt,
                onUseTranscript: _useAttemptTranscript,
              ),
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
      _activeAttemptId = null;
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
    } catch (error, stackTrace) {
      debugPrint('Unable to start recording: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (mounted) {
        setState(() {
          _status = VoiceRecordingStatus.error;
          _errorMessage = kDebugMode
              ? 'Unable to start recording. $error'
              : 'Unable to start recording.';
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
        _activeAttemptId = null;
        _status = VoiceRecordingStatus.transcribing;
      });

      final attempt = await ref
          .read(voiceRecordingHistoryControllerProvider.notifier)
          .createAttempt(recording);

      if (!mounted) {
        return;
      }

      setState(() {
        _activeAttemptId = attempt.id;
      });

      await _transcribeRecording(attempt);
    } catch (error, stackTrace) {
      debugPrint('Unable to stop recording: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (mounted) {
        setState(() {
          _status = VoiceRecordingStatus.error;
          _errorMessage = kDebugMode
              ? 'Unable to stop recording. $error'
              : 'Unable to stop recording.';
        });
      }
    }
  }

  Future<void> _transcribeRecording(VoiceRecordingAttempt attempt) async {
    try {
      final transcript = await ref
          .read(voiceTranscriptionServiceProvider)
          .transcribe(attempt.recording);

      await ref
          .read(voiceRecordingHistoryControllerProvider.notifier)
          .markTranscribed(attempt.id, transcript);

      if (mounted) {
        setState(() {
          _transcriptController.text = transcript;
          _recording = attempt.recording;
          _activeAttemptId = attempt.id;
          _status = VoiceRecordingStatus.reviewingTranscript;
        });
      }
    } catch (error, stackTrace) {
      debugPrint('Unable to transcribe recording: $error');
      debugPrintStack(stackTrace: stackTrace);
      final message = _transcriptionFailureMessage(error);

      await ref
          .read(voiceRecordingHistoryControllerProvider.notifier)
          .markFailed(attempt.id, message);

      if (mounted) {
        setState(() {
          _status = VoiceRecordingStatus.error;
          _recording = attempt.recording;
          _activeAttemptId = attempt.id;
          _errorMessage = message;
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
      final summary = await aiService.summarizeEntry(originalText: originalText);
      final themeDetection = await aiService.detectThemes(text: originalText);
      entry = entry.applyGeneratedInsights(
        summaryResult: summary,
        themeDetection: themeDetection,
        updatedAt: now,
        preserveRewrite: false,
      );
    } catch (_) {
      entry = entry.withoutAiResults(updatedAt: now);
    }

    await repository.saveEntry(entry);
    if (_activeAttemptId case final attemptId?) {
      await ref
          .read(voiceRecordingHistoryControllerProvider.notifier)
          .markSaved(attemptId);
    }
    ref.invalidate(journalEntriesProvider);
    ref.invalidate(journalEntryProvider(entry.id));

    if (mounted) {
      context.goNamed(
        journalEntryDetailRouteName,
        pathParameters: {'entryId': entry.id},
      );
    }
  }

  Future<void> _retryAttempt(VoiceRecordingAttempt attempt) async {
    setState(() {
      _status = VoiceRecordingStatus.transcribing;
      _recording = attempt.recording;
      _activeAttemptId = attempt.id;
      _errorMessage = null;
      _transcriptController.clear();
    });

    await ref
        .read(voiceRecordingHistoryControllerProvider.notifier)
        .markTranscribing(attempt.id);
    await _transcribeRecording(attempt);
  }

  void _useAttemptTranscript(VoiceRecordingAttempt attempt) {
    if (!attempt.hasTranscript) {
      return;
    }

    setState(() {
      _status = VoiceRecordingStatus.reviewingTranscript;
      _recording = attempt.recording;
      _activeAttemptId = attempt.id;
      _errorMessage = null;
      _transcriptController.text = attempt.transcript!;
    });
  }

  String _transcriptionFailureMessage(Object error) {
    if (error is NoSpeechDetectedException) {
      return 'No speech was detected in the recording. Try again closer to the microphone.';
    }

    if (error is LumenApiException) {
      if (error.error.error == 'provider_timeout') {
        return 'The AI transcription request timed out. Please try again.';
      }

      if (error.error.message case final message?) {
        return message;
      }

      return 'Unable to transcribe the recording right now.';
    }

    if (kDebugMode) {
      return 'Unable to transcribe the recording. $error';
    }

    return 'Unable to transcribe the recording.';
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

class _TranscriptionHistorySection extends StatelessWidget {
  const _TranscriptionHistorySection({
    required this.historyValue,
    required this.onRetry,
    required this.onUseTranscript,
  });

  final AsyncValue<List<VoiceRecordingAttempt>> historyValue;
  final Future<void> Function(VoiceRecordingAttempt attempt) onRetry;
  final void Function(VoiceRecordingAttempt attempt) onUseTranscript;

  @override
  Widget build(BuildContext context) {
    return historyValue.when(
      data: (value) {
        if (value.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent recordings',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            for (final attempt in value)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _VoiceRecordingAttemptTile(
                  attempt: attempt,
                  onRetry: () => onRetry(attempt),
                  onUseTranscript: attempt.hasTranscript
                      ? () => onUseTranscript(attempt)
                      : null,
                ),
              ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

class _VoiceRecordingAttemptTile extends StatelessWidget {
  const _VoiceRecordingAttemptTile({
    required this.attempt,
    required this.onRetry,
    required this.onUseTranscript,
  });

  final VoiceRecordingAttempt attempt;
  final Future<void> Function() onRetry;
  final VoidCallback? onUseTranscript;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final duration = attempt.recording.stoppedAt.difference(
      attempt.recording.startedAt,
    );

    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      collapsedShape: RoundedRectangleBorder(
        side: BorderSide(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      title: Row(
        children: [
          Expanded(child: Text(_statusLabel(attempt.status))),
          const SizedBox(width: 12),
          _StatusChip(status: attempt.status),
        ],
      ),
      subtitle: Text(
        '${_formatTimestamp(attempt.recording.stoppedAt)} • ${duration.inSeconds}s',
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                attempt.recording.uri,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              if (attempt.errorMessage case final message?) ...[
                const SizedBox(height: 12),
                Text(
                  message,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: colorScheme.error),
                ),
              ],
              if (attempt.transcript case final transcript?) ...[
                const SizedBox(height: 12),
                Text(transcript, style: Theme.of(context).textTheme.bodyMedium),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (attempt.status == VoiceRecordingAttemptStatus.failed)
                    OutlinedButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh_outlined),
                      label: const Text('Retry transcription'),
                    ),
                  if (onUseTranscript case final callback?)
                    TextButton.icon(
                      onPressed: callback,
                      icon: const Icon(Icons.edit_note_outlined),
                      label: const Text('Use transcript'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _statusLabel(VoiceRecordingAttemptStatus status) {
    return switch (status) {
      VoiceRecordingAttemptStatus.transcribing => 'Transcribing',
      VoiceRecordingAttemptStatus.transcribed => 'Transcript ready',
      VoiceRecordingAttemptStatus.failed => 'Transcription failed',
      VoiceRecordingAttemptStatus.saved => 'Saved as journal entry',
    };
  }

  String _formatTimestamp(DateTime value) {
    final localValue = value.toLocal();
    final hour = localValue.hour % 12 == 0 ? 12 : localValue.hour % 12;
    final minute = localValue.minute.toString().padLeft(2, '0');
    final suffix = localValue.hour >= 12 ? 'PM' : 'AM';
    return '${localValue.month}/${localValue.day}/${localValue.year} $hour:$minute $suffix';
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final VoiceRecordingAttemptStatus status;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final (label, backgroundColor, foregroundColor) = switch (status) {
      VoiceRecordingAttemptStatus.failed => (
        'Failed',
        colorScheme.errorContainer,
        colorScheme.onErrorContainer,
      ),
      VoiceRecordingAttemptStatus.transcribing => (
        'Pending',
        colorScheme.secondaryContainer,
        colorScheme.onSecondaryContainer,
      ),
      VoiceRecordingAttemptStatus.transcribed => (
        'Ready',
        colorScheme.primaryContainer,
        colorScheme.onPrimaryContainer,
      ),
      VoiceRecordingAttemptStatus.saved => (
        'Saved',
        colorScheme.tertiaryContainer,
        colorScheme.onTertiaryContainer,
      ),
    };

    return Chip(
      label: Text(label),
      backgroundColor: backgroundColor,
      labelStyle: Theme.of(
        context,
      ).textTheme.labelMedium?.copyWith(color: foregroundColor),
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
    );
  }
}
