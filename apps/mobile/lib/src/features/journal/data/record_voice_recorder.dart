import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../domain/voice_recorder.dart';
import '../domain/voice_recording.dart';

class RecordVoiceRecorder implements VoiceRecorder {
  RecordVoiceRecorder({AudioRecorder? recorder})
    : _recorder = recorder ?? AudioRecorder();

  final AudioRecorder _recorder;
  DateTime? _startedAt;

  @visibleForTesting
  static RecordConfig configForPlatform({required bool isWeb}) {
    if (isWeb) {
      return webConfigs.first;
    }

    return const RecordConfig(encoder: AudioEncoder.aacLc);
  }

  @visibleForTesting
  static const webConfigs = <RecordConfig>[
    RecordConfig(encoder: AudioEncoder.wav, numChannels: 1),
    RecordConfig(encoder: AudioEncoder.pcm16bits, numChannels: 1),
  ];

  @visibleForTesting
  static String fileNameForPlatform(DateTime startedAt, {required bool isWeb}) {
    final extension = isWeb ? 'wav' : 'm4a';

    return 'lumen-${startedAt.microsecondsSinceEpoch}.$extension';
  }

  @override
  Future<bool> hasPermission() {
    return _recorder.hasPermission();
  }

  @override
  Future<void> start({required DateTime startedAt}) async {
    _startedAt = startedAt;

    final path = await _recordingPath(startedAt);

    if (!kIsWeb) {
      await _recorder.start(configForPlatform(isWeb: false), path: path);
      return;
    }

    Object? lastError;
    StackTrace? lastStackTrace;

    for (final config in webConfigs) {
      try {
        await _recorder.start(config, path: path);
        return;
      } catch (error, stackTrace) {
        lastError = error;
        lastStackTrace = stackTrace;
        debugPrint(
          'Voice recorder web start failed for ${config.encoder.name}: $error',
        );
      }
    }

    if (lastError != null && lastStackTrace != null) {
      Error.throwWithStackTrace(lastError, lastStackTrace);
    }
  }

  @override
  Future<VoiceRecording?> stop({required DateTime stoppedAt}) async {
    final uri = await _recorder.stop();
    final startedAt = _startedAt;
    _startedAt = null;

    if (uri == null || startedAt == null) {
      return null;
    }

    return VoiceRecording(uri: uri, startedAt: startedAt, stoppedAt: stoppedAt);
  }

  @override
  Future<void> dispose() {
    return _recorder.dispose();
  }

  Future<String> _recordingPath(DateTime startedAt) async {
    if (kIsWeb) {
      return '';
    }

    final directory = await getTemporaryDirectory();

    return '${directory.path}/${fileNameForPlatform(startedAt, isWeb: false)}';
  }
}
