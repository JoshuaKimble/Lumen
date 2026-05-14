import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/voice_recorder.dart';
import 'record_voice_recorder.dart';

final voiceRecorderProvider = Provider.autoDispose<VoiceRecorder>((ref) {
  final recorder = RecordVoiceRecorder();

  ref.onDispose(() {
    recorder.dispose();
  });

  return recorder;
});
