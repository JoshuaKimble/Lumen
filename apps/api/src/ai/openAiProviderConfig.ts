export interface OpenAiProviderConfig {
  readonly apiKey: string;
  readonly rewriteModel: string;
  readonly themeModel: string;
  readonly transcriptionModel: string;
  readonly timeoutMs: number;
  readonly transcriptionChunkDurationSeconds: number;
}

export const defaultOpenAiModels = {
  rewrite: 'gpt-5-mini',
  themeDetection: 'gpt-5-mini',
  transcription: 'gpt-4o-mini-transcribe',
} as const;

export const defaultOpenAiTimeoutMs = 60_000;
export const defaultOpenAiTranscriptionChunkDurationSeconds = 45;

export function parseOpenAiProviderConfig(
  env: NodeJS.ProcessEnv,
): OpenAiProviderConfig {
  return {
    apiKey: requireSecret(env, 'OPENAI_API_KEY'),
    rewriteModel: optionalValue(
      env,
      'LUMEN_OPENAI_REWRITE_MODEL',
      defaultOpenAiModels.rewrite,
    ),
    themeModel: optionalValue(
      env,
      'LUMEN_OPENAI_THEME_MODEL',
      defaultOpenAiModels.themeDetection,
    ),
    transcriptionModel: optionalValue(
      env,
      'LUMEN_OPENAI_TRANSCRIPTION_MODEL',
      defaultOpenAiModels.transcription,
    ),
    timeoutMs: optionalPositiveInt(
      env,
      'LUMEN_OPENAI_TIMEOUT_MS',
      defaultOpenAiTimeoutMs,
    ),
    transcriptionChunkDurationSeconds: optionalPositiveInt(
      env,
      'LUMEN_OPENAI_TRANSCRIPTION_CHUNK_SECONDS',
      defaultOpenAiTranscriptionChunkDurationSeconds,
    ),
  };
}

function requireSecret(env: NodeJS.ProcessEnv, key: string): string {
  const value = env[key]?.trim();

  if (!value) {
    throw new Error(`Missing required environment variable ${key}.`);
  }

  return value;
}

function optionalValue(
  env: NodeJS.ProcessEnv,
  key: string,
  fallback: string,
): string {
  return env[key]?.trim() || fallback;
}

function optionalPositiveInt(
  env: NodeJS.ProcessEnv,
  key: string,
  fallback: number,
): number {
  const raw = env[key]?.trim();

  if (!raw) {
    return fallback;
  }

  const parsed = Number.parseInt(raw, 10);
  if (!Number.isFinite(parsed) || parsed <= 0) {
    throw new Error(`Expected ${key} to be a positive integer.`);
  }

  return parsed;
}
