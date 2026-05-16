import {
  buildRewritePrompt,
  buildThemeDetectionPrompt,
} from './journalAiPrompts.js';
import { Buffer } from 'node:buffer';
import type {
  AiGatewayProvider,
  JournalTheme,
  RewriteRequest,
  RewriteResult,
  ThemeDetectionRequest,
  ThemeDetectionResult,
  TranscriptionRequest,
  TranscriptionResult,
} from './aiGatewayProvider.js';
import type { OpenAiProviderConfig } from './openAiProviderConfig.js';

export interface OpenAiTransportResponse {
  readonly status: number;
  readonly data: unknown;
}

export interface OpenAiTransport {
  postJson(path: string, body: unknown): Promise<OpenAiTransportResponse>;
  postFormData(
    path: string,
    body: FormData,
  ): Promise<OpenAiTransportResponse>;
}

export class OpenAiGatewayProvider implements AiGatewayProvider {
  private readonly transport: OpenAiTransport;

  constructor(
    private readonly config: OpenAiProviderConfig,
    transport?: OpenAiTransport,
  ) {
    this.transport = transport ?? new FetchOpenAiTransport(config.apiKey);
  }

  get modelConfig(): Omit<OpenAiProviderConfig, 'apiKey'> {
    return {
      rewriteModel: this.config.rewriteModel,
      themeModel: this.config.themeModel,
      transcriptionModel: this.config.transcriptionModel,
    };
  }

  async transcribe(request: TranscriptionRequest): Promise<TranscriptionResult> {
    const body = new FormData();
    body.append('model', this.config.transcriptionModel);
    body.append(
      'file',
      new Blob([Buffer.from(request.audio)], { type: request.mimeType }),
      extensionForMimeType(request.mimeType),
    );
    body.append('response_format', 'json');

    const response = await this.transport.postFormData(
      '/audio/transcriptions',
      body,
    );
    assertSuccessStatus(response.status);

    const transcript = extractTranscriptionText(response.data);

    return { transcript };
  }

  async rewrite(request: RewriteRequest): Promise<RewriteResult> {
    const prompt = buildRewritePrompt(request);
    const response = await this.transport.postJson('/chat/completions', {
      model: this.config.rewriteModel,
      messages: [
        { role: 'system', content: prompt.systemPrompt },
        { role: 'user', content: prompt.userPrompt },
      ],
      response_format: {
        type: 'json_schema',
        json_schema: {
          name: 'journal_rewrite',
          strict: true,
          schema: {
            type: 'object',
            additionalProperties: false,
            properties: {
              rewrittenText: { type: 'string' },
              title: { type: 'string' },
              summary: { type: 'string' },
            },
            required: ['rewrittenText'],
          },
        },
      },
    });
    assertSuccessStatus(response.status);

    const parsed = parseJsonObjectFromCompletionContent(response.data);
    const rewrittenText = requiredString(parsed, 'rewrittenText');

    return {
      rewrittenText,
      title: optionalString(parsed, 'title'),
      summary: optionalString(parsed, 'summary'),
    };
  }

  async detectThemes(
    request: ThemeDetectionRequest,
  ): Promise<ThemeDetectionResult> {
    const prompt = buildThemeDetectionPrompt(request);
    const response = await this.transport.postJson('/chat/completions', {
      model: this.config.themeModel,
      messages: [
        { role: 'system', content: prompt.systemPrompt },
        { role: 'user', content: prompt.userPrompt },
      ],
      response_format: {
        type: 'json_schema',
        json_schema: {
          name: 'journal_theme_detection',
          strict: true,
          schema: {
            type: 'object',
            additionalProperties: false,
            properties: {
              themes: {
                type: 'array',
                maxItems: 8,
                items: {
                  type: 'object',
                  additionalProperties: false,
                  properties: {
                    id: { type: 'string' },
                    name: { type: 'string' },
                    displayName: { type: 'string' },
                    weight: { type: 'number' },
                  },
                  required: ['id', 'name', 'displayName'],
                },
              },
            },
            required: ['themes'],
          },
        },
      },
    });
    assertSuccessStatus(response.status);

    const parsed = parseJsonObjectFromCompletionContent(response.data);
    const themes = parseThemes(parsed.themes);

    return { themes };
  }
}

class FetchOpenAiTransport implements OpenAiTransport {
  constructor(private readonly apiKey: string) {}

  async postJson(path: string, body: unknown): Promise<OpenAiTransportResponse> {
    const response = await fetch(`https://api.openai.com/v1${path}`, {
      method: 'POST',
      headers: {
        authorization: `Bearer ${this.apiKey}`,
        'content-type': 'application/json',
      },
      body: JSON.stringify(body),
    });

    return {
      status: response.status,
      data: await readResponseJson(response),
    };
  }

  async postFormData(
    path: string,
    body: FormData,
  ): Promise<OpenAiTransportResponse> {
    const response = await fetch(`https://api.openai.com/v1${path}`, {
      method: 'POST',
      headers: {
        authorization: `Bearer ${this.apiKey}`,
      },
      body,
    });

    return {
      status: response.status,
      data: await readResponseJson(response),
    };
  }
}

async function readResponseJson(response: Response): Promise<unknown> {
  try {
    return (await response.json()) as unknown;
  } catch {
    return {};
  }
}

function assertSuccessStatus(status: number): void {
  if (status < 200 || status >= 300) {
    throw new Error(`OpenAI request failed with status ${status}.`);
  }
}

function parseJsonObjectFromCompletionContent(data: unknown): Record<string, unknown> {
  if (typeof data !== 'object' || data === null) {
    throw new Error('OpenAI response did not include a completion payload.');
  }

  const content = (data as Record<string, unknown>).choices;

  if (!Array.isArray(content) || content.length === 0) {
    throw new Error('OpenAI completion response did not include choices.');
  }

  const firstChoice = content[0];

  if (typeof firstChoice !== 'object' || firstChoice === null) {
    throw new Error('OpenAI completion response included an invalid choice.');
  }

  const message = (firstChoice as Record<string, unknown>).message;

  if (typeof message !== 'object' || message === null) {
    throw new Error('OpenAI completion response did not include a message.');
  }

  const rawContent = (message as Record<string, unknown>).content;
  const text = extractMessageContentText(rawContent);

  try {
    const parsed = JSON.parse(text) as unknown;

    if (typeof parsed !== 'object' || parsed === null || Array.isArray(parsed)) {
      throw new Error();
    }

    return parsed as Record<string, unknown>;
  } catch {
    throw new Error('OpenAI completion response was not valid JSON.');
  }
}

function extractMessageContentText(content: unknown): string {
  if (typeof content === 'string') {
    return content;
  }

  if (Array.isArray(content)) {
    for (const item of content) {
      if (typeof item === 'object' && item !== null) {
        const text = (item as Record<string, unknown>).text;

        if (typeof text === 'string' && text.trim().length > 0) {
          return text;
        }
      }
    }
  }

  throw new Error('OpenAI completion response did not include text content.');
}

function parseThemes(value: unknown): readonly JournalTheme[] {
  if (!Array.isArray(value)) {
    throw new Error('OpenAI theme response did not include a themes array.');
  }

  return value.map((theme) => {
    if (typeof theme !== 'object' || theme === null) {
      throw new Error('OpenAI theme response included an invalid theme item.');
    }

    const record = theme as Record<string, unknown>;
    const parsedTheme: JournalTheme = {
      id: requiredString(record, 'id'),
      name: requiredString(record, 'name'),
      displayName: requiredString(record, 'displayName'),
      weight: optionalNumber(record, 'weight'),
    };

    return parsedTheme;
  });
}

function extractTranscriptionText(value: unknown): string {
  if (typeof value !== 'object' || value === null) {
    throw new Error('OpenAI transcription response was malformed.');
  }

  const text = (value as Record<string, unknown>).text;

  if (typeof text !== 'string' || text.trim().length === 0) {
    throw new Error('OpenAI transcription response did not include text.');
  }

  return text;
}

function requiredString(
  record: Record<string, unknown>,
  key: string,
): string {
  const value = record[key];

  if (typeof value !== 'string' || value.trim().length === 0) {
    throw new Error(`OpenAI response did not include a valid "${key}".`);
  }

  return value;
}

function optionalString(
  record: Record<string, unknown>,
  key: string,
): string | undefined {
  const value = record[key];

  if (value === undefined) {
    return undefined;
  }

  if (typeof value !== 'string') {
    throw new Error(`OpenAI response included an invalid "${key}".`);
  }

  return value;
}

function optionalNumber(
  record: Record<string, unknown>,
  key: string,
): number | undefined {
  const value = record[key];

  if (value === undefined) {
    return undefined;
  }

  if (typeof value !== 'number') {
    throw new Error(`OpenAI response included an invalid "${key}".`);
  }

  return value;
}

function extensionForMimeType(mimeType: string): string {
  return (
    {
      'audio/mp4': 'audio.mp4',
      'audio/mpeg': 'audio.mp3',
      'audio/wav': 'audio.wav',
      'audio/webm': 'audio.webm',
      'audio/x-m4a': 'audio.m4a',
    }[mimeType] ?? 'audio.bin'
  );
}
