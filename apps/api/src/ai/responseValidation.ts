import type {
  JournalTheme,
  RewriteResult,
  ThemeDetectionResult,
  TranscriptionResult,
} from './aiGatewayProvider.js';

export function validateTranscriptionResult(
  result: TranscriptionResult,
): TranscriptionResult {
  if (typeof result.transcript !== 'string') {
    throw new Error('AI transcription response must include transcript.');
  }

  return {
    transcript: result.transcript,
  };
}

export function validateRewriteResult(result: RewriteResult): RewriteResult {
  if (result.rewrittenText.trim().length === 0) {
    throw new Error('AI rewrite response must include rewrittenText.');
  }

  return {
    rewrittenText: result.rewrittenText,
    title: optionalString(result.title),
    summary: optionalString(result.summary),
  };
}

export function validateThemeDetectionResult(
  result: ThemeDetectionResult,
): ThemeDetectionResult {
  return {
    themes: result.themes.map(validateTheme),
  };
}

function validateTheme(theme: JournalTheme): JournalTheme {
  if (
    theme.id.trim().length === 0 ||
    theme.name.trim().length === 0 ||
    theme.displayName.trim().length === 0
  ) {
    throw new Error('AI theme response must include id, name, and displayName.');
  }

  return {
    id: theme.id,
    name: theme.name,
    displayName: theme.displayName,
    weight: theme.weight,
  };
}

function optionalString(value: string | undefined): string | undefined {
  if (value === undefined) {
    return undefined;
  }

  return value;
}
