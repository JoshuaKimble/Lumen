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
    return {
      rewrittenText: `Mock rewrite: ${request.originalText.trim()}`,
    };
  }

  async detectThemes(
    request: ThemeDetectionRequest,
  ): Promise<ThemeDetectionResult> {
    const text = request.text.toLowerCase();
    const themes = [
      text.includes('work') ? 'Work' : undefined,
      text.includes('family') ? 'Family' : undefined,
      text.includes('gratitude') ? 'Gratitude' : undefined,
    ].filter((theme): theme is string => theme !== undefined);

    return {
      themes: themes.length > 0 ? themes : ['Reflection'],
    };
  }
}
