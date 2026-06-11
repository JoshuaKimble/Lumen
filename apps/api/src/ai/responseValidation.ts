import type {
  JournalTheme,
  ResourceSuggestion,
  ResourceSuggestionResult,
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

export function validateResourceSuggestionResult(
  result: ResourceSuggestionResult,
): ResourceSuggestionResult {
  if (!Array.isArray(result.suggestions)) {
    throw new Error('AI resource response must include suggestions.');
  }

  return {
    suggestions: result.suggestions.map(validateSuggestion),
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

function validateSuggestion(suggestion: ResourceSuggestion): ResourceSuggestion {
  if (
    suggestion.id.trim().length === 0 ||
    suggestion.type.trim().length === 0 ||
    suggestion.title.trim().length === 0 ||
    suggestion.sourceType.trim().length === 0 ||
    suggestion.matchReason.trim().length === 0
  ) {
    throw new Error(
      'AI resource suggestion must include id, type, title, sourceType, and matchReason.',
    );
  }

  if (
    !Number.isFinite(suggestion.confidence) ||
    suggestion.confidence < 0 ||
    suggestion.confidence > 1
  ) {
    throw new Error(
      'AI resource suggestion must include confidence from 0 to 1.',
    );
  }

  return {
    id: suggestion.id,
    type: suggestion.type,
    title: suggestion.title,
    description: optionalString(suggestion.description),
    url: optionalString(suggestion.url),
    scriptureReference: optionalString(suggestion.scriptureReference),
    sourceType: suggestion.sourceType,
    matchReason: suggestion.matchReason,
    confidence: suggestion.confidence,
    themeId: optionalString(suggestion.themeId),
  };
}
