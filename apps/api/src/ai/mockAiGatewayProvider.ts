import type {
  AiGatewayProvider,
  ResourceSuggestionRequest,
  ResourceSuggestionResult,
  RewriteRequest,
  RewriteResult,
  SummaryRequest,
  SummaryResult,
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

  async summarize(request: SummaryRequest): Promise<SummaryResult> {
    const originalText = request.originalText.trim();

    return {
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

  async suggestResources(
    request: ResourceSuggestionRequest,
  ): Promise<ResourceSuggestionResult> {
    const text = request.text.toLowerCase();
    const requestedThemes = new Set(
      (request.themeIds ?? []).map((themeId) => themeId.toLowerCase().trim()),
    );
    const matchedThemes = new Set<string>();

    for (const candidate of themeCandidates) {
      const matchesByText = candidate.keywords.some((keyword) =>
        text.includes(keyword),
      );
      const matchesByTheme = requestedThemes.has(candidate.theme.id);

      if (matchesByText || matchesByTheme) {
        matchedThemes.add(candidate.theme.id);
      }
    }

    if (matchedThemes.size === 0) {
      matchedThemes.add(reflectionTheme.id);
    }

    const suggestions = [...matchedThemes]
      .flatMap((themeId) => resourceSuggestionsByTheme[themeId] ?? [])
      .filter((suggestion) => suggestion.confidence >= minimumConfidence)
      .sort((left, right) => right.confidence - left.confidence)
      .slice(0, maxSuggestions);

    return { suggestions };
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

const minimumConfidence = 0.65;
const maxSuggestions = 5;

const resourceSuggestionsByTheme: Record<
  string,
  readonly ResourceSuggestionResult['suggestions'][number][]
> = {
  work: [
    {
      id: 'work-prompt-review-boundaries',
      type: 'reflection_prompt',
      title: 'What boundary would reduce your stress this week?',
      description:
        'Name one boundary you can hold this week and one way to communicate it clearly.',
      sourceType: 'ai_mapped',
      matchReason: 'Detected work-related pressure and deadline language.',
      confidence: 0.91,
      themeId: 'work',
    },
    {
      id: 'work-article-deep-work',
      type: 'talk_or_article',
      title: 'Deep Work notes for focused planning',
      url: 'https://www.calnewport.com/books/deep-work/',
      sourceType: 'curated',
      matchReason: 'Matches work focus and priority planning themes.',
      confidence: 0.74,
      themeId: 'work',
    },
  ],
  family: [
    {
      id: 'family-prompt-listen-first',
      type: 'reflection_prompt',
      title: 'Where can you listen before reacting at home?',
      description:
        'Write one recent moment and how you want to respond differently next time.',
      sourceType: 'ai_mapped',
      matchReason: 'Detected family and relationship language.',
      confidence: 0.9,
      themeId: 'family',
    },
  ],
  gratitude: [
    {
      id: 'gratitude-exercise-three-things',
      type: 'exercise',
      title: 'Three specifics gratitude exercise',
      description:
        'List three specific things from today and why each mattered to you.',
      sourceType: 'curated',
      matchReason: 'Detected gratitude language and positive reflection intent.',
      confidence: 0.82,
      themeId: 'gratitude',
    },
  ],
  stress: [
    {
      id: 'stress-prompt-body-signal',
      type: 'reflection_prompt',
      title: 'Where did stress show up in your body today?',
      description:
        'Describe what you felt physically and what was happening right before it.',
      sourceType: 'ai_mapped',
      matchReason: 'Detected stress, tension, or anxiety keywords.',
      confidence: 0.88,
      themeId: 'stress',
    },
    {
      id: 'stress-quote-pause',
      type: 'quote',
      title: 'Pause before pressure speaks',
      description: 'A short reminder to slow down before reacting.',
      sourceType: 'curated',
      matchReason: 'General stress de-escalation support.',
      confidence: 0.61,
      themeId: 'stress',
    },
  ],
  reflection: [
    {
      id: 'reflection-prompt-next-honest-step',
      type: 'reflection_prompt',
      title: 'What is your next honest step?',
      description:
        'Write one sentence about the most honest next step you can take today.',
      sourceType: 'curated',
      matchReason: 'Fallback reflection prompt when specific themes are unclear.',
      confidence: 0.79,
      themeId: 'reflection',
    },
  ],
};
