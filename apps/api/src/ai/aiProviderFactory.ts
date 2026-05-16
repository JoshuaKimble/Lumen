import type { AiGatewayProvider } from './aiGatewayProvider.js';
import { MockAiGatewayProvider } from './mockAiGatewayProvider.js';
import { OpenAiGatewayProvider } from './openAiGatewayProvider.js';
import { parseOpenAiProviderConfig } from './openAiProviderConfig.js';

export function createConfiguredAiProvider(
  env: NodeJS.ProcessEnv = process.env,
): AiGatewayProvider {
  const providerName = (env.LUMEN_AI_PROVIDER ?? 'mock').trim().toLowerCase();

  if (providerName === 'mock') {
    return new MockAiGatewayProvider();
  }

  if (providerName === 'openai') {
    return new OpenAiGatewayProvider(parseOpenAiProviderConfig(env));
  }

  throw new Error(`Unsupported AI provider "${providerName}".`);
}
