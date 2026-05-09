import type { IncomingMessage } from 'node:http';

import { BadRequestError } from './requestValidation.js';

export async function readJsonBody(request: IncomingMessage): Promise<unknown> {
  const chunks: Buffer[] = [];

  for await (const chunk of request) {
    chunks.push(Buffer.isBuffer(chunk) ? chunk : Buffer.from(chunk));
  }

  const rawBody = Buffer.concat(chunks).toString('utf8');

  if (rawBody.trim().length === 0) {
    throw new BadRequestError('Expected a JSON request body.');
  }

  try {
    return JSON.parse(rawBody) as unknown;
  } catch {
    throw new BadRequestError('Expected valid JSON.');
  }
}
