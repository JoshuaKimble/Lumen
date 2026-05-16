import type {
  AiGatewayProvider,
  RewriteRequest,
  RewriteResult,
  ThemeDetectionRequest,
  ThemeDetectionResult,
  TranscriptionRequest,
  TranscriptionResult,
} from './aiGatewayProvider.js';

export class MockAiGatewayProvider implements AiGatewayProvider {
  async transcribe(
    request: TranscriptionRequest,
  ): Promise<TranscriptionResult> {
    if (request.audio.byteLength === 0) {
      return { transcript: '' };
    }

    return { transcript: 'Mock transcript from recorded audio.' };
  }

  async rewrite(request: RewriteRequest): Promise<RewriteResult> {
    const originalText = request.originalText.trim();

    return {
      rewrittenText: `[API mock: rewrite endpoint] Mock rewrite: ${originalText}`,
      title: titleFor(originalText),
      summary: summaryFor(originalText),
    };
  }

  async detectThemes(
    request: ThemeDetectionRequest,
  ): Promise<ThemeDetectionResult> {
    const text = request.text.toLowerCase();
    const themes = themeCandidates
      .filter((candidate) =>
        candidate.keywords.some((keyword) => text.includes(keyword)),
      )
      .map((candidate) => candidate.theme);

    return {
      themes: themes.length > 0 ? themes : [reflectionTheme],
    };
  }
}

function titleFor(text: string): string {
  const firstSentence = text.split(/[.!?]/)[0]?.trim() ?? '';
  const words = firstSentence.split(/\s+/).filter(Boolean).slice(0, 6);

  return words.length === 0 ? 'Untitled entry' : words.join(' ');
}

function summaryFor(text: string): string {
  const words = text.split(/\s+/).filter(Boolean).slice(0, 14);

  return words.length === 0 ? 'A short reflection.' : words.join(' ');
}

const reflectionTheme = {
  id: 'reflection',
  name: 'reflection',
  displayName: 'Reflection',
};

const themeCandidates = [
  {
    theme: { id: 'work', name: 'work', displayName: 'Work' },
    keywords: ['work', 'job', 'meeting', 'project', 'deadline', 'career'],
  },
  {
    theme: { id: 'family', name: 'family', displayName: 'Family' },
    keywords: ['family', 'parent', 'child', 'kid', 'spouse', 'wife', 'husband'],
  },
  {
    theme: { id: 'gratitude', name: 'gratitude', displayName: 'Gratitude' },
    keywords: ['gratitude', 'grateful', 'thankful', 'appreciate'],
  },
  {
    theme: { id: 'stress', name: 'stress', displayName: 'Stress' },
    keywords: ['stress', 'tense', 'overwhelmed', 'rushed', 'anxious'],
  },
] as const;
