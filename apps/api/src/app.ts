import { Buffer } from 'node:buffer';
import { createServer, type IncomingMessage, type Server } from 'node:http';

import type { AiGatewayProvider } from './ai/aiGatewayProvider.js';
import { createConfiguredAiProvider } from './ai/aiProviderFactory.js';
import { AiProviderError } from './ai/providerError.js';
import {
  buildRewritePrompt,
  buildThemeDetectionPrompt,
} from './ai/journalAiPrompts.js';
import {
  validateResourceSuggestionResult,
  validateRewriteResult,
  validateThemeDetectionResult,
  validateTranscriptionResult,
} from './ai/responseValidation.js';
import { sendJson } from './http/json.js';
import { readJsonBody } from './http/readJson.js';
import {
  BadRequestError,
  rejectUnknownKeys,
  requireNonEmptyString,
  requireObject,
} from './http/requestValidation.js';

export interface AppDependencies {
  readonly aiProvider?: AiGatewayProvider;
}

const acceptedAudioMimeTypes = new Set([
  'audio/mp4',
  'audio/mpeg',
  'audio/wav',
  'audio/webm',
  'audio/x-m4a',
]);
const maxAudioBytes = 10 * 1024 * 1024;

export function createApiServer(dependencies: AppDependencies = {}): Server {
  const aiProvider = dependencies.aiProvider ?? createConfiguredAiProvider();

  return createServer(async (request, response) => {
    try {
      await routeRequest(request, response, aiProvider);
    } catch (error) {
      if (error instanceof BadRequestError) {
        sendJson(response, 400, {
          error: 'bad_request',
          message: error.message,
        });
        return;
      }

      if (error instanceof AiProviderError) {
        const mapped = mapProviderErrorToHttp(error);
        sendJson(response, mapped.statusCode, {
          error: mapped.errorCode,
          message: mapped.message,
        });
        return;
      }

      sendJson(response, 500, {
        error: 'internal_server_error',
      });
    }
  });
}

async function routeRequest(
  request: IncomingMessage,
  response: Parameters<typeof sendJson>[0],
  aiProvider: AiGatewayProvider,
): Promise<void> {
  if (request.method === 'GET' && request.url === '/health') {
    sendJson(response, 200, {
      status: 'ok',
      service: 'lumen-api',
    });
    return;
  }

  if (request.method === 'POST' && request.url === '/v1/entries/rewrite') {
    const body = requireObject(await readJsonBody(request));
    rejectUnknownKeys(body, ['originalText']);
    const requestBody = {
      originalText: requireNonEmptyString(body, 'originalText'),
    };
    buildRewritePrompt(requestBody);
    const result = validateRewriteResult(await aiProvider.rewrite(requestBody));

    sendJson(response, 200, result);
    return;
  }

  if (
    request.method === 'POST' &&
    request.url === '/v1/entries/themes/detect'
  ) {
    const body = requireObject(await readJsonBody(request));
    rejectUnknownKeys(body, ['text']);
    const requestBody = {
      text: requireNonEmptyString(body, 'text'),
    };
    buildThemeDetectionPrompt(requestBody);
    const result = validateThemeDetectionResult(
      await aiProvider.detectThemes(requestBody),
    );

    sendJson(response, 200, result);
    return;
  }

  if (request.method === 'POST' && request.url === '/v1/resources/suggest') {
    const body = requireObject(await readJsonBody(request));
    rejectUnknownKeys(body, ['text', 'themeIds']);
    const requestBody = {
      text: requireNonEmptyString(body, 'text'),
      themeIds: requireOptionalStringArray(body, 'themeIds'),
    };
    const result = validateResourceSuggestionResult(
      await aiProvider.suggestResources(requestBody),
    );

    sendJson(response, 200, result);
    return;
  }

  if (request.method === 'POST' && request.url === '/v1/transcriptions') {
    const body = requireObject(await readJsonBody(request));
    rejectUnknownKeys(body, ['audioBase64', 'mimeType']);
    const requestBody = {
      audio: decodeAudioBase64(requireNonEmptyString(body, 'audioBase64')),
      mimeType: requireAcceptedAudioMimeType(body),
    };
    const result = validateTranscriptionResult(
      await aiProvider.transcribe(requestBody),
    );

    sendJson(response, 200, result);
    return;
  }

  sendJson(response, 404, {
    error: 'not_found',
  });
}

function decodeAudioBase64(value: string): Uint8Array {
  if (!isBase64(value)) {
    throw new BadRequestError('Expected valid base64 audio.');
  }

  const audio = Buffer.from(value, 'base64');

  if (audio.byteLength === 0) {
    throw new BadRequestError('Expected non-empty audio upload.');
  }

  if (audio.byteLength > maxAudioBytes) {
    throw new BadRequestError('Audio upload exceeds 10 MB.');
  }

  return new Uint8Array(audio);
}

function requireAcceptedAudioMimeType(body: Record<string, unknown>): string {
  const mimeType = requireNonEmptyString(body, 'mimeType').toLowerCase();

  if (!acceptedAudioMimeTypes.has(mimeType)) {
    throw new BadRequestError(`Unsupported audio mime type "${mimeType}".`);
  }

  return mimeType;
}

function isBase64(value: string): boolean {
  if (value.length % 4 !== 0) {
    return false;
  }

  return /^[A-Za-z0-9+/]+={0,2}$/.test(value);
}

function requireOptionalStringArray(
  body: Record<string, unknown>,
  key: string,
): readonly string[] | undefined {
  const value = body[key];

  if (value === undefined) {
    return undefined;
  }

  if (!Array.isArray(value)) {
    throw new BadRequestError(`Expected "${key}" to be an array.`);
  }

  return value.map((item, index) => {
    if (typeof item !== 'string' || item.trim().length === 0) {
      throw new BadRequestError(
        `Expected "${key}[${index}]" to be a non-empty string.`,
      );
    }

    return item.trim();
  });
}

function mapProviderErrorToHttp(
  error: AiProviderError,
): { statusCode: number; errorCode: string; message: string } {
  switch (error.kind) {
    case 'rate_limit':
      return {
        statusCode: 429,
        errorCode: 'provider_rate_limited',
        message: 'AI provider is rate-limited. Please retry shortly.',
      };
    case 'timeout':
      return {
        statusCode: 504,
        errorCode: 'provider_timeout',
        message: 'AI provider timed out. Please retry.',
      };
    case 'unavailable':
      return {
        statusCode: 503,
        errorCode: 'provider_unavailable',
        message: 'AI provider is temporarily unavailable. Please retry.',
      };
    case 'malformed_response':
      return {
        statusCode: 502,
        errorCode: 'provider_response_invalid',
        message: 'AI provider returned an invalid response.',
      };
    case 'provider_error':
      return {
        statusCode: 502,
        errorCode: 'provider_error',
        message: 'AI provider request failed.',
      };
  }
}
