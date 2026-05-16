import assert from 'node:assert/strict';
import { test } from 'node:test';

import { createConfiguredAiProvider } from '../src/ai/aiProviderFactory.js';
import { MockAiGatewayProvider } from '../src/ai/mockAiGatewayProvider.js';
import { OpenAiGatewayProvider } from '../src/ai/openAiGatewayProvider.js';
import {
  defaultOpenAiModels,
  parseOpenAiProviderConfig,
} from '../src/ai/openAiProviderConfig.js';

test('defaults to mock provider without secrets', () => {
  const provider = createConfiguredAiProvider({});

  assert.ok(provider instanceof MockAiGatewayProvider);
});

test('creates OpenAI provider when configured', () => {
  const provider = createConfiguredAiProvider({
    LUMEN_AI_PROVIDER: 'openai',
    OPENAI_API_KEY: 'test-secret',
  });

  assert.ok(provider instanceof OpenAiGatewayProvider);
  assert.deepEqual(provider.modelConfig, {
    rewriteModel: defaultOpenAiModels.rewrite,
    themeModel: defaultOpenAiModels.themeDetection,
    transcriptionModel: defaultOpenAiModels.transcription,
  });
});

test('parses OpenAI model overrides', () => {
  const config = parseOpenAiProviderConfig({
    OPENAI_API_KEY: 'test-secret',
    LUMEN_OPENAI_REWRITE_MODEL: 'custom-rewrite-model',
    LUMEN_OPENAI_THEME_MODEL: 'custom-theme-model',
    LUMEN_OPENAI_TRANSCRIPTION_MODEL: 'custom-transcription-model',
  });

  assert.equal(config.rewriteModel, 'custom-rewrite-model');
  assert.equal(config.themeModel, 'custom-theme-model');
  assert.equal(config.transcriptionModel, 'custom-transcription-model');
});

test('requires OpenAI API key without leaking secret values', () => {
  assert.throws(
    () =>
      createConfiguredAiProvider({
        LUMEN_AI_PROVIDER: 'openai',
      }),
    /Missing required environment variable OPENAI_API_KEY\./,
  );
});

test('rejects unsupported provider names', () => {
  assert.throws(
    () =>
      createConfiguredAiProvider({
        LUMEN_AI_PROVIDER: 'unknown-provider',
      }),
    /Unsupported AI provider "unknown-provider"\./,
  );
});
