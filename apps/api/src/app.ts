import { createServer, type IncomingMessage, type Server } from 'node:http';

import type { AiGatewayProvider } from './ai/aiGatewayProvider.js';
import { createConfiguredAiProvider } from './ai/aiProviderFactory.js';
import {
  buildRewritePrompt,
  buildThemeDetectionPrompt,
} from './ai/journalAiPrompts.js';
import {
  validateRewriteResult,
  validateThemeDetectionResult,
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

  sendJson(response, 404, {
    error: 'not_found',
  });
}
