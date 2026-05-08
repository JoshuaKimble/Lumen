import { createServer, type IncomingMessage, type Server } from 'node:http';

import type { AiGatewayProvider } from './ai/aiGatewayProvider.js';
import { MockAiGatewayProvider } from './ai/mockAiGatewayProvider.js';
import { sendJson } from './http/json.js';

export interface AppDependencies {
  readonly aiProvider?: AiGatewayProvider;
}

export function createApiServer(dependencies: AppDependencies = {}): Server {
  const aiProvider = dependencies.aiProvider ?? new MockAiGatewayProvider();

  return createServer(async (request, response) => {
    try {
      await routeRequest(request, response, aiProvider);
    } catch (error) {
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

  if (request.method === 'POST' && request.url === '/mock/rewrite') {
    const originalText = await readTextBody(request);
    const result = await aiProvider.rewrite({ originalText });

    sendJson(response, 200, result);
    return;
  }

  sendJson(response, 404, {
    error: 'not_found',
  });
}

async function readTextBody(request: IncomingMessage): Promise<string> {
  const chunks: Buffer[] = [];

  for await (const chunk of request) {
    chunks.push(Buffer.isBuffer(chunk) ? chunk : Buffer.from(chunk));
  }

  return Buffer.concat(chunks).toString('utf8');
}
