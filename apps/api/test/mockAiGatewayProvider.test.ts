import assert from 'node:assert/strict';
import { test } from 'node:test';

import { MockAiGatewayProvider } from '../src/ai/mockAiGatewayProvider.js';

test('mock provider returns deterministic rewrite output', async () => {
  const provider = new MockAiGatewayProvider();

  const result = await provider.rewrite({
    originalText: '  I am thinking about work today.  ',
  });

  assert.equal(
    result.rewrittenText,
    'Mock rewrite: I am thinking about work today.',
  );
});

test('mock provider detects simple themes', async () => {
  const provider = new MockAiGatewayProvider();

  const result = await provider.detectThemes({
    text: 'I feel gratitude for my family after a long work week.',
  });

  assert.deepEqual(result.themes, ['Work', 'Family', 'Gratitude']);
});
