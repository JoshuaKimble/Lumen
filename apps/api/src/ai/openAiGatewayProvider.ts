import type {
  AiGatewayProvider,
  RewriteRequest,
  RewriteResult,
  ThemeDetectionRequest,
  ThemeDetectionResult,
  TranscriptionRequest,
  TranscriptionResult,
} from './aiGatewayProvider.js';
import type { OpenAiProviderConfig } from './openAiProviderConfig.js';

export class OpenAiGatewayProvider implements AiGatewayProvider {
  constructor(private readonly config: OpenAiProviderConfig) {}

  get modelConfig(): Omit<OpenAiProviderConfig, 'apiKey'> {
    return {
      rewriteModel: this.config.rewriteModel,
      themeModel: this.config.themeModel,
      transcriptionModel: this.config.transcriptionModel,
    };
  }

  transcribe(_request: TranscriptionRequest): Promise<TranscriptionResult> {
    throw new Error('OpenAI transcription is not implemented yet.');
  }

  rewrite(_request: RewriteRequest): Promise<RewriteResult> {
    throw new Error('OpenAI rewrite is not implemented yet.');
  }

  detectThemes(
    _request: ThemeDetectionRequest,
  ): Promise<ThemeDetectionResult> {
    throw new Error('OpenAI theme detection is not implemented yet.');
  }
}
