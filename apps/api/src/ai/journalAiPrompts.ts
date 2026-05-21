import type {
  RewriteRequest,
  RewriteTone,
  ThemeDetectionRequest,
} from './aiGatewayProvider.js';

export interface PromptRequest {
  readonly systemPrompt: string;
  readonly userPrompt: string;
}

export function buildRewritePrompt(request: RewriteRequest): PromptRequest {
  const rewriteTone = request.personalization?.rewriteTone ?? 'balanced';
  const preserveVoice = request.personalization?.preserveVoice ?? true;

  return {
    systemPrompt: [
      'You are a reflective writing assistant for a private journal app.',
      'Preserve the user meaning, perspective, and emotional nuance.',
      'Improve clarity and organization without adding facts or conclusions.',
      preserveVoice
        ? 'Stay close to the user wording, cadence, and personality. Prefer light-touch edits over polished rewriting.'
        : 'You may restructure and smooth the writing more noticeably, but you must keep the original meaning, perspective, and emotional truth intact.',
      toneInstructionFor(rewriteTone),
      'Do not diagnose, judge, preach, coach, or turn the entry into advice.',
    ].join(' '),
    userPrompt: request.originalText,
  };
}

export function buildThemeDetectionPrompt(
  request: ThemeDetectionRequest,
): PromptRequest {
  return {
    systemPrompt: [
      'Identify a small set of meaningful high-level journal themes.',
      'Prefer recurring life themes over overly specific labels.',
      'Return only themes that are supported by the journal text.',
    ].join(' '),
    userPrompt: request.text,
  };
}

function toneInstructionFor(rewriteTone: RewriteTone): string {
  switch (rewriteTone) {
    case 'gentle':
      return 'Use gentle, tender wording when the entry feels heavy or vulnerable.';
    case 'encouraging':
      return 'Use steady, encouraging language that feels hopeful without overstating positivity.';
    case 'reflective':
      return 'Use a slower, more contemplative tone that supports later reflection.';
    case 'balanced':
    default:
      return 'Keep the tone balanced, clear, and natural without sounding overly soft or overly polished.';
  }
}
