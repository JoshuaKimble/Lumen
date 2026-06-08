import 'package:flutter/foundation.dart';

import 'voice_recording.dart';

enum VoiceRecordingAttemptStatus { transcribing, transcribed, failed, saved }

@immutable
class VoiceRecordingAttempt {
  const VoiceRecordingAttempt({
    required this.id,
    required this.recording,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.transcript,
    this.errorMessage,
  });

  final String id;
  final VoiceRecording recording;
  final VoiceRecordingAttemptStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? transcript;
  final String? errorMessage;

  bool get hasTranscript => transcript != null && transcript!.trim().isNotEmpty;

  VoiceRecordingAttempt copyWith({
    VoiceRecordingAttemptStatus? status,
    DateTime? updatedAt,
    String? transcript,
    bool clearTranscript = false,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return VoiceRecordingAttempt(
      id: id,
      recording: recording,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      transcript: clearTranscript ? null : (transcript ?? this.transcript),
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
    );
  }
}
