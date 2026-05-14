import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/voice_recorder_provider.dart';
import '../domain/voice_recording.dart';

class VoiceRecordingScreen extends ConsumerStatefulWidget {
  const VoiceRecordingScreen({super.key});

  @override
  ConsumerState<VoiceRecordingScreen> createState() =>
      _VoiceRecordingScreenState();
}

class _VoiceRecordingScreenState extends ConsumerState<VoiceRecordingScreen> {
  VoiceRecordingStatus _status = VoiceRecordingStatus.idle;
  VoiceRecording? _recording;
  String? _errorMessage;

  bool get _isStarting => _status == VoiceRecordingStatus.starting;

  bool get _isRecording => _status == VoiceRecordingStatus.recording;

  bool get _isStopping => _status == VoiceRecordingStatus.stopping;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Voice entry')),
      body: SafeArea(
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
            if (_isRecording || _isStopping)
              FilledButton.icon(
                onPressed: _isStopping ? null : _stopRecording,
                icon: const Icon(Icons.stop_outlined),
                label: Text(_isStopping ? 'Stopping' : 'Stop recording'),
              )
            else
              FilledButton.icon(
                onPressed: _isStarting ? null : _startRecording,
                icon: const Icon(Icons.mic_outlined),
                label: Text(_isStarting ? 'Starting' : 'Start recording'),
              ),
            if (_recording case final recording?) ...[
              const SizedBox(height: 24),
              _CapturedRecording(recording: recording),
            ],
          ],
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
      VoiceRecordingStatus.permissionDenied => 'Microphone access is needed',
      VoiceRecordingStatus.captured => 'Recording captured',
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
      VoiceRecordingStatus.permissionDenied =>
        'Allow microphone access in your browser or device settings to record journal entries.',
      VoiceRecordingStatus.captured =>
        'Next, this audio will be sent through the transcription flow.',
      VoiceRecordingStatus.error =>
        'The recording could not be completed. Try again in a moment.',
    };
  }

  Future<void> _startRecording() async {
    setState(() {
      _status = VoiceRecordingStatus.starting;
      _errorMessage = null;
      _recording = null;
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

      if (mounted) {
        setState(() {
          _recording = recording;
          _status = recording == null
              ? VoiceRecordingStatus.error
              : VoiceRecordingStatus.captured;
          _errorMessage = recording == null
              ? 'Unable to save the recording.'
              : null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _status = VoiceRecordingStatus.error;
          _errorMessage = 'Unable to stop recording.';
        });
      }
    }
  }
}

enum VoiceRecordingStatus {
  idle,
  starting,
  recording,
  stopping,
  permissionDenied,
  captured,
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
