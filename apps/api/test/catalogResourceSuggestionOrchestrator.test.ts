import assert from 'node:assert/strict';
import { test } from 'node:test';

import type { ThemeDetectionResult } from '../src/ai/aiGatewayProvider.js';
import { CatalogResourceSuggestionOrchestrator } from '../src/resourceSuggestions/catalogResourceSuggestionOrchestrator.js';
import { InMemoryCuratedResourceCatalogStore } from '../src/resourceSuggestions/inMemoryCuratedResourceCatalogStore.js';

test('orchestrator ranks curated candidates for requested themes', async () => {
  const orchestrator = new CatalogResourceSuggestionOrchestrator({
    themeDetector: {
      async detectThemes(): Promise<ThemeDetectionResult> {
        return {
          themes: [
            { id: 'work', name: 'work', displayName: 'Work', weight: 0.93 },
            { id: 'stress', name: 'stress', displayName: 'Stress', weight: 0.89 },
          ],
        };
      },
    },
    catalogStore: new InMemoryCuratedResourceCatalogStore(),
  });

  const result = await orchestrator.suggest({
    text: 'I feel overwhelmed by work deadlines and need a clearer boundary.',
    themeIds: ['work'],
  });

  assert.deepEqual(result.suggestions.map((suggestion) => suggestion.id), [
    'catalog:prompt:work-boundary-review',
    'catalog:article:work-boundaries',
  ]);
  assert.equal(result.suggestions[0]?.sourceType, 'curated');
  assert.equal(result.suggestions[0]?.themeId, 'work');
});

test('orchestrator preserves scripture references for downstream routing', async () => {
  const orchestrator = new CatalogResourceSuggestionOrchestrator({
    themeDetector: {
      async detectThemes(): Promise<ThemeDetectionResult> {
        return {
          themes: [
            { id: 'faith', name: 'faith', displayName: 'Faith', weight: 0.91 },
          ],
        };
      },
    },
    catalogStore: new InMemoryCuratedResourceCatalogStore(),
  });

  const result = await orchestrator.suggest({
    text: 'I want to be still and trust God tonight.',
    themeIds: ['faith'],
  });

  assert.equal(result.suggestions[0]?.id, 'catalog:scripture:psalm-46-10');
  assert.equal(result.suggestions[0]?.scriptureReference, 'Psalm 46:10');
});

test('orchestrator falls back when no curated candidate clears threshold', async () => {
  const orchestrator = new CatalogResourceSuggestionOrchestrator({
    themeDetector: {
      async detectThemes(): Promise<ThemeDetectionResult> {
        return {
          themes: [
            {
              id: 'family',
              name: 'family',
              displayName: 'Family',
              weight: 0.9,
            },
          ],
        };
      },
    },
    catalogStore: new InMemoryCuratedResourceCatalogStore(),
  });

  const result = await orchestrator.suggest({
    text: 'I need to think about how to respond better at home.',
    themeIds: ['family'],
  });

  assert.deepEqual(result, {
    suggestions: [
      {
        id: 'fallback-reflection-prompt',
        type: 'reflection_prompt',
        title: 'Reflect on the next honest step',
        description:
          'What is the next honest step you can take, and what would make it easier to follow through today?',
        sourceType: 'ai_mapped',
        matchReason:
          'Returned a fallback reflection prompt because no curated resource crossed the confidence threshold.',
        confidence: 0.64,
        themeId: 'reflection',
      },
    ],
  });
});
