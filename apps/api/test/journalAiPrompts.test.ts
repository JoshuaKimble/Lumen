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
  assert.match(prompt.systemPrompt, /balanced, clear, and natural/);
  assert.match(prompt.systemPrompt, /Stay close to the user wording/);
  assert.equal(prompt.userPrompt, 'raw note');
});

test('rewrite prompt varies tone instructions', () => {
  const gentle = buildRewritePrompt({
    originalText: 'raw note',
    personalization: {
      rewriteTone: 'gentle',
      preserveVoice: true,
    },
  });
  const encouraging = buildRewritePrompt({
    originalText: 'raw note',
    personalization: {
      rewriteTone: 'encouraging',
      preserveVoice: true,
    },
  });
  const reflective = buildRewritePrompt({
    originalText: 'raw note',
    personalization: {
      rewriteTone: 'reflective',
      preserveVoice: true,
    },
  });

  assert.match(gentle.systemPrompt, /gentle, tender wording/);
  assert.match(encouraging.systemPrompt, /steady, encouraging language/);
  assert.match(reflective.systemPrompt, /slower, more contemplative tone/);
});

test('rewrite prompt varies preserve-voice instructions', () => {
  const closeToVoice = buildRewritePrompt({
    originalText: 'raw note',
    personalization: {
      rewriteTone: 'balanced',
      preserveVoice: true,
    },
  });
  const morePolished = buildRewritePrompt({
    originalText: 'raw note',
    personalization: {
      rewriteTone: 'balanced',
      preserveVoice: false,
    },
  });

  assert.match(closeToVoice.systemPrompt, /Prefer light-touch edits/);
  assert.doesNotMatch(closeToVoice.systemPrompt, /restructure and smooth/);
  assert.match(morePolished.systemPrompt, /restructure and smooth the writing more noticeably/);
  assert.match(morePolished.systemPrompt, /keep the original meaning, perspective, and emotional truth intact/);
});

test('theme prompt favors supported high-level themes', () => {
  const prompt = buildThemeDetectionPrompt({ text: 'raw note' });

  assert.match(prompt.systemPrompt, /high-level journal themes/);
  assert.match(prompt.systemPrompt, /supported by the journal text/);
  assert.equal(prompt.userPrompt, 'raw note');
});
