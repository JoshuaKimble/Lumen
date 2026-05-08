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
}

export interface ThemeDetectionRequest {
  readonly text: string;
}

export interface ThemeDetectionResult {
  readonly themes: readonly string[];
}

export interface AiGatewayProvider {
  transcribe(request: TranscriptionRequest): Promise<TranscriptionResult>;
  rewrite(request: RewriteRequest): Promise<RewriteResult>;
  detectThemes(
    request: ThemeDetectionRequest,
  ): Promise<ThemeDetectionResult>;
}
