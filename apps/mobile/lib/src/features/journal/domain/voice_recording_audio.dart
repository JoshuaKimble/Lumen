import 'package:flutter/foundation.dart';

@immutable
class VoiceRecordingAudio {
  const VoiceRecordingAudio({required this.bytes, required this.mimeType});

  final Uint8List bytes;
  final String mimeType;
}
