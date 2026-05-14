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

  @override
  Future<bool> hasPermission() {
    return _recorder.hasPermission();
  }

  @override
  Future<void> start({required DateTime startedAt}) async {
    _startedAt = startedAt;

    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: await _recordingPath(startedAt),
    );
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
    final fileName = 'lumen-${startedAt.microsecondsSinceEpoch}.m4a';

    if (kIsWeb) {
      return fileName;
    }

    final directory = await getTemporaryDirectory();

    return '${directory.path}/$fileName';
  }
}
