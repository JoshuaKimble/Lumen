import 'package:flutter/foundation.dart';

@immutable
class VoiceRecording {
  const VoiceRecording({
    required this.uri,
    required this.startedAt,
    required this.stoppedAt,
  });

  final String uri;
  final DateTime startedAt;
  final DateTime stoppedAt;
}
