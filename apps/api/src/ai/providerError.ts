export type AiProviderErrorKind =
  | 'rate_limit'
  | 'timeout'
  | 'unavailable'
  | 'malformed_response'
  | 'provider_error';

export class AiProviderError extends Error {
  constructor(
    readonly kind: AiProviderErrorKind,
    message: string,
    options?: { cause?: unknown },
  ) {
    super(message, options);
    this.name = 'AiProviderError';
  }
}

export function createStatusBasedProviderError(status: number): AiProviderError {
  if (status === 408 || status === 504) {
    return new AiProviderError(
      'timeout',
      `AI provider request timed out with status ${status}.`,
    );
  }

  if (status === 429) {
    return new AiProviderError(
      'rate_limit',
      'AI provider rate limit was reached.',
    );
  }

  if (status >= 500) {
    return new AiProviderError(
      'unavailable',
      `AI provider is unavailable with status ${status}.`,
    );
  }

  return new AiProviderError(
    'provider_error',
    `AI provider request failed with status ${status}.`,
  );
}
