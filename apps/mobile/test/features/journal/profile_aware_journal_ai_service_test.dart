import 'package:flutter_test/flutter_test.dart';
import 'package:lumen/src/features/journal/data/profile_aware_journal_ai_service.dart';
import 'package:lumen/src/features/journal/domain/ai_results.dart';
import 'package:lumen/src/features/journal/domain/journal_ai_service.dart';
import 'package:lumen/src/features/journal/domain/rewrite_personalization.dart';
import 'package:lumen/src/features/journal/domain/journal_theme.dart';
import 'package:lumen/src/features/journal/domain/study_guide.dart';
import 'package:lumen/src/features/profiles/domain/rewrite_tone_preference.dart';

void main() {
  test(
    'applies default personalization when caller does not provide one',
    () async {
      final delegate = _RecordingJournalAiService();
      final service = ProfileAwareJournalAiService(
        delegate: delegate,
        defaultPersonalization: const RewritePersonalization(
          rewriteTone: RewriteTonePreference.reflective,
          preserveVoice: false,
        ),
      );

      await service.rewriteEntry(originalText: 'raw note');

      expect(
        delegate.lastPersonalization,
        const RewritePersonalization(
          rewriteTone: RewriteTonePreference.reflective,
          preserveVoice: false,
        ),
      );
    },
  );

  test('preserves explicit personalization overrides', () async {
    final delegate = _RecordingJournalAiService();
    final service = ProfileAwareJournalAiService(
      delegate: delegate,
      defaultPersonalization: RewritePersonalization.defaults,
    );

    await service.rewriteEntry(
      originalText: 'raw note',
      personalization: const RewritePersonalization(
        rewriteTone: RewriteTonePreference.gentle,
        preserveVoice: true,
      ),
    );

    expect(
      delegate.lastPersonalization,
      const RewritePersonalization(
        rewriteTone: RewriteTonePreference.gentle,
        preserveVoice: true,
      ),
    );
  });
}

class _RecordingJournalAiService implements JournalAiService {
  RewritePersonalization? lastPersonalization;

  @override
  Future<ThemeDetectionResult> detectThemes({required String text}) async {
    return const ThemeDetectionResult(themes: []);
  }

  @override
  Future<EntrySummaryResult> summarizeEntry({
    required String originalText,
  }) async {
    return const EntrySummaryResult(summary: 'summary');
  }

  @override
  Future<StudyGuide> generateStudyGuide({
    required String entryId,
    required String originalText,
    required List<JournalTheme> themes,
    required String providerKey,
  }) async {
    return StudyGuide(
      id: 'guide-$entryId',
      entryId: entryId,
      providerKey: providerKey,
      generatedAt: DateTime.utc(2026, 1, 1),
      overview: 'overview',
      previewText: 'preview',
      items: const [],
      reflectionPrompt: const StudyGuidePrompt(text: 'prompt'),
    );
  }

  @override
  Future<RewriteResult> rewriteEntry({
    required String originalText,
    JournalRewriteSource source = JournalRewriteSource.unspecified,
    RewritePersonalization? personalization,
  }) async {
    lastPersonalization = personalization;
    return const RewriteResult(rewrittenText: 'rewritten');
  }
}
