import assert from 'node:assert/strict';
import { test } from 'node:test';

import {
  buildRewritePrompt,
  buildThemeDetectionPrompt,
} from '../src/ai/journalAiPrompts.js';

test('rewrite prompt encodes product behavior constraints', () => {
  const prompt = buildRewritePrompt({ originalText: 'raw note' });

  assert.match(prompt.systemPrompt, /Preserve the user meaning/);
  assert.match(prompt.systemPrompt, /without adding facts/);
  assert.match(prompt.systemPrompt, /Do not diagnose/);
  assert.equal(prompt.userPrompt, 'raw note');
});

test('theme prompt favors supported high-level themes', () => {
  const prompt = buildThemeDetectionPrompt({ text: 'raw note' });

  assert.match(prompt.systemPrompt, /high-level journal themes/);
  assert.match(prompt.systemPrompt, /supported by the journal text/);
  assert.equal(prompt.userPrompt, 'raw note');
});
