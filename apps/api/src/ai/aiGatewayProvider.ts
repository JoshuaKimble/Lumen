export interface TranscriptionRequest {
  readonly audio: Uint8Array;
  readonly mimeType: string;
}

export interface TranscriptionResult {
  readonly transcript: string;
}

export interface RewriteRequest {
  readonly originalText: string;
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

export interface AiGatewayProvider {
  transcribe(request: TranscriptionRequest): Promise<TranscriptionResult>;
  rewrite(request: RewriteRequest): Promise<RewriteResult>;
  detectThemes(
    request: ThemeDetectionRequest,
  ): Promise<ThemeDetectionResult>;
}
