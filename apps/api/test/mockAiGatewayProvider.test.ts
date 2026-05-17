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
    '[API mock: rewrite endpoint] Mock rewrite: I am thinking about work today.',
  );
  assert.equal(result.title, 'I am thinking about work today');
  assert.equal(result.summary, 'I am thinking about work today.');
});

test('mock provider detects simple themes', async () => {
  const provider = new MockAiGatewayProvider();

  const result = await provider.detectThemes({
    text: 'I feel gratitude for my family after a long work week.',
  });

  assert.deepEqual(
    result.themes.map((theme) => theme.displayName),
    ['Work', 'Family', 'Gratitude'],
  );
});

test('mock provider returns deterministic resource suggestions with provenance', async () => {
  const provider = new MockAiGatewayProvider();

  const result = await provider.suggestResources({
    text: 'I am overwhelmed by work deadlines and stress this week.',
    themeIds: ['work'],
  });

  assert.deepEqual(result.suggestions, [
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
      id: 'work-article-deep-work',
      type: 'talk_or_article',
      title: 'Deep Work notes for focused planning',
      url: 'https://www.calnewport.com/books/deep-work/',
      sourceType: 'curated',
      matchReason: 'Matches work focus and priority planning themes.',
      confidence: 0.74,
      themeId: 'work',
    },
  ]);
});
