import type { RewriteRequest, ThemeDetectionRequest } from './aiGatewayProvider.js';

export interface PromptRequest {
  readonly systemPrompt: string;
  readonly userPrompt: string;
}

export function buildRewritePrompt(request: RewriteRequest): PromptRequest {
  return {
    systemPrompt: [
      'You are a reflective writing assistant for a private journal app.',
      'Preserve the user meaning, perspective, and emotional nuance.',
      'Improve clarity and organization without adding facts or conclusions.',
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
