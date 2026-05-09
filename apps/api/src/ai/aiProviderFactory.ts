import type { AiGatewayProvider } from './aiGatewayProvider.js';
import { MockAiGatewayProvider } from './mockAiGatewayProvider.js';

export function createConfiguredAiProvider(): AiGatewayProvider {
  const providerName = process.env.LUMEN_AI_PROVIDER ?? 'mock';

  if (providerName === 'mock') {
    return new MockAiGatewayProvider();
  }

  throw new Error(`Unsupported AI provider "${providerName}".`);
}
