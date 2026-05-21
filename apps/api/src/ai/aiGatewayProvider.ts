export interface TranscriptionRequest {
  readonly audio: Uint8Array;
  readonly mimeType: string;
}

export interface TranscriptionResult {
  readonly transcript: string;
}

export const rewriteToneValues = [
  'balanced',
  'gentle',
  'encouraging',
  'reflective',
] as const;

export type RewriteTone = (typeof rewriteToneValues)[number];

export interface RewritePersonalization {
  readonly rewriteTone: RewriteTone;
  readonly preserveVoice: boolean;
}

export const defaultRewritePersonalization: RewritePersonalization = {
  rewriteTone: 'balanced',
  preserveVoice: true,
};

export interface RewriteRequest {
  readonly originalText: string;
  readonly personalization?: RewritePersonalization;
}

export interface RewriteResult {
  readonly rewrittenText: string;
  readonly title?: string;
  readonly summary?: string;
}

export interface ThemeDetectionRequest {
  readonly text: string;
}

export interface JournalTheme {
  readonly id: string;
  readonly name: string;
  readonly displayName: string;
  readonly weight?: number;
}

export interface ThemeDetectionResult {
  readonly themes: readonly JournalTheme[];
}

export interface ResourceSuggestionRequest {
  readonly text: string;
  readonly themeIds?: readonly string[];
}

export interface ResourceSuggestion {
  readonly id: string;
  readonly type:
    | 'reflection_prompt'
    | 'scripture'
    | 'talk_or_article'
    | 'video_or_audio'
    | 'quote'
    | 'exercise'
    | 'internal_entry_link';
  readonly title: string;
  readonly description?: string;
  readonly url?: string;
  readonly sourceType: 'curated' | 'ai_mapped' | 'user_created';
  readonly matchReason: string;
  readonly confidence: number;
  readonly themeId?: string;
}

export interface ResourceSuggestionResult {
  readonly suggestions: readonly ResourceSuggestion[];
}

export interface AiGatewayProvider {
  transcribe(request: TranscriptionRequest): Promise<TranscriptionResult>;
  rewrite(request: RewriteRequest): Promise<RewriteResult>;
  detectThemes(
    request: ThemeDetectionRequest,
  ): Promise<ThemeDetectionResult>;
  suggestResources(
    request: ResourceSuggestionRequest,
  ): Promise<ResourceSuggestionResult>;
}
