import 'package:flutter_test/flutter_test.dart';
import 'package:lumen/src/features/journal/data/record_voice_recorder.dart';
import 'package:record/record.dart';

void main() {
  group('RecordVoiceRecorder platform settings', () {
    test('uses wav on web', () {
      final config = RecordVoiceRecorder.configForPlatform(isWeb: true);

      expect(config.encoder, AudioEncoder.wav);
      expect(config.numChannels, 1);
    });

    test('uses aac on native platforms', () {
      final config = RecordVoiceRecorder.configForPlatform(isWeb: false);

      expect(config.encoder, AudioEncoder.aacLc);
    });

    test('tries wav and pcm16bits fallbacks on web', () {
      expect(RecordVoiceRecorder.webConfigs.map((config) => config.encoder), [
        AudioEncoder.wav,
        AudioEncoder.pcm16bits,
      ]);
      expect(
        RecordVoiceRecorder.webConfigs.every(
          (config) => config.numChannels == 1,
        ),
        isTrue,
      );
    });

    test('builds native file names with m4a extension', () {
      final fileName = RecordVoiceRecorder.fileNameForPlatform(
        DateTime.parse('2026-05-24T05:38:43Z'),
        isWeb: false,
      );

      expect(fileName, 'lumen-1779601123000000.m4a');
    });

    test('builds web file names with wav extension', () {
      final fileName = RecordVoiceRecorder.fileNameForPlatform(
        DateTime.parse('2026-05-24T05:38:43Z'),
        isWeb: true,
      );

      expect(fileName, 'lumen-1779601123000000.wav');
    });
  });
}
