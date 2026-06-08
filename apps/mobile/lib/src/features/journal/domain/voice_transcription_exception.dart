sealed class VoiceTranscriptionException implements Exception {
  const VoiceTranscriptionException();
}

class NoSpeechDetectedException extends VoiceTranscriptionException {
  const NoSpeechDetectedException();
}
