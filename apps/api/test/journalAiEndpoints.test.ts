import assert from 'node:assert/strict';
import { Buffer } from 'node:buffer';
import { after, before, test } from 'node:test';

import { createApiServer } from '../src/app.js';
import { AiProviderError } from '../src/ai/providerError.js';

let baseUrl = '';
let failingBaseUrl = '';
const server = createApiServer();
const failingServer = createApiServer({
  aiProvider: {
    async rewrite() {
      throw new Error('rewrite failure');
    },
    async detectThemes() {
      throw new Error('theme failure');
    },
    async transcribe() {
      throw new Error('transcribe failure');
    },
    async suggestResources() {
      throw new Error('resource suggestion failure');
    },
  },
});

before(async () => {
  await new Promise<void>((resolve) => {
    server.listen(0, '127.0.0.1', resolve);
  });

  const address = server.address();

  if (address === null || typeof address === 'string') {
    throw new Error('Expected server to listen on a TCP address.');
  }

  baseUrl = `http://127.0.0.1:${address.port}`;

  await new Promise<void>((resolve) => {
    failingServer.listen(0, '127.0.0.1', resolve);
  });

  const failingAddress = failingServer.address();

  if (failingAddress === null || typeof failingAddress === 'string') {
    throw new Error('Expected failing server to listen on a TCP address.');
  }

  failingBaseUrl = `http://127.0.0.1:${failingAddress.port}`;
});

after(async () => {
  server.closeAllConnections();
  server.closeIdleConnections();

  await new Promise<void>((resolve, reject) => {
    server.close((error) => {
      if (error) {
        reject(error);
        return;
      }

      resolve();
    });
  });

  failingServer.closeAllConnections();
  failingServer.closeIdleConnections();

  await new Promise<void>((resolve, reject) => {
    failingServer.close((error) => {
      if (error) {
        reject(error);
        return;
      }

      resolve();
    });
  });
});

test('rewrite endpoint returns OpenAPI response shape', async () => {
  const response = await postJson('/v1/entries/rewrite', {
    originalText: 'I had a rushed work meeting.',
    personalization: {
      rewriteTone: 'gentle',
      preserveVoice: false,
    },
  });
  const body = await response.json();

  assert.equal(response.status, 200);
  assert.deepEqual(body, {
    rewrittenText:
      '[API mock: rewrite endpoint] Mock rewrite: I had a rushed work meeting.',
    title: 'I had a rushed work meeting',
    summary: 'I had a rushed work meeting.',
  });
});

test('rewrite endpoint defaults personalization when omitted', async () => {
  let capturedRequest: unknown;
  const server = createApiServer({
    aiProvider: {
      async rewrite(request) {
        capturedRequest = request;
        return { rewrittenText: 'ok' };
      },
      async detectThemes() {
        return { themes: [] };
      },
      async transcribe() {
        return { transcript: 'ok' };
      },
      async suggestResources() {
        return { suggestions: [] };
      },
    },
  });

  await new Promise<void>((resolve) => {
    server.listen(0, '127.0.0.1', resolve);
  });

  const address = server.address();

  if (address === null || typeof address === 'string') {
    throw new Error('Expected server to listen on a TCP address.');
  }

  const serverBaseUrl = `http://127.0.0.1:${address.port}`;

  try {
    const response = await postJson(
      '/v1/entries/rewrite',
      { originalText: 'raw note' },
      serverBaseUrl,
    );
    const body = await response.json();

    assert.equal(response.status, 200);
    assert.deepEqual(body, { rewrittenText: 'ok' });
    assert.deepEqual(capturedRequest, {
      originalText: 'raw note',
      personalization: {
        rewriteTone: 'balanced',
        preserveVoice: true,
      },
    });
  } finally {
    server.closeAllConnections();
    server.closeIdleConnections();
    await new Promise<void>((resolve, reject) => {
      server.close((error) => {
        if (error) {
          reject(error);
          return;
        }

        resolve();
      });
    });
  }
});

test('theme endpoint returns OpenAPI response shape', async () => {
  const response = await postJson('/v1/entries/themes/detect', {
    text: 'I had a rushed work meeting with family nearby.',
  });
  const body = await response.json();

  assert.equal(response.status, 200);
  assert.deepEqual(body, {
    themes: [
      { id: 'work', name: 'work', displayName: 'Work' },
      { id: 'family', name: 'family', displayName: 'Family' },
      { id: 'stress', name: 'stress', displayName: 'Stress' },
    ],
  });
});

test('transcription endpoint returns OpenAPI response shape', async () => {
  const response = await postJson('/v1/transcriptions', {
    audioBase64: Buffer.from('recorded audio').toString('base64'),
    mimeType: 'audio/mp4',
  });
  const body = await response.json();

  assert.equal(response.status, 200);
  assert.deepEqual(body, {
    transcript: 'Mock transcript from recorded audio.',
  });
});

test('resource suggestion endpoint returns deterministic mock response', async () => {
  const response = await postJson('/v1/resources/suggest', {
    text: 'I am overwhelmed with work and stress.',
    themeIds: ['work'],
  });
  const body = await response.json();

  assert.equal(response.status, 200);
  assert.deepEqual(body, {
    suggestions: [
      {
        id: 'work-prompt-review-boundaries',
        type: 'reflection_prompt',
        title: 'What boundary would reduce your stress this week?',
        description:
          'Name one boundary you can hold this week and one way to communicate it clearly.',
        sourceType: 'ai_mapped',
        matchReason: 'Detected work-related pressure and deadline language.',
        confidence: 0.91,
        themeId: 'work',
      },
      {
        id: 'stress-prompt-body-signal',
        type: 'reflection_prompt',
        title: 'Where did stress show up in your body today?',
        description:
          'Describe what you felt physically and what was happening right before it.',
        sourceType: 'ai_mapped',
        matchReason: 'Detected stress, tension, or anxiety keywords.',
        confidence: 0.88,
        themeId: 'stress',
      },
      {
        id: 'work-article-deep-work',
        type: 'talk_or_article',
        title: 'Deep Work notes for focused planning',
        url: 'https://www.calnewport.com/books/deep-work/',
        sourceType: 'curated',
        matchReason: 'Matches work focus and priority planning themes.',
        confidence: 0.74,
        themeId: 'work',
      },
    ],
  });
});

test('rewrite endpoint rejects malformed requests', async () => {
  const response = await postJson('/v1/entries/rewrite', {
    originalText: '',
  });
  const body = await response.json();

  assert.equal(response.status, 400);
  assert.deepEqual(body, {
    error: 'bad_request',
    message: 'Expected non-empty string "originalText".',
  });
});

test('rewrite endpoint rejects invalid personalization payloads', async () => {
  const response = await postJson('/v1/entries/rewrite', {
    originalText: 'raw note',
    personalization: {
      rewriteTone: 'unknown',
      preserveVoice: 'yes',
    },
  });
  const body = await response.json();

  assert.equal(response.status, 400);
  assert.deepEqual(body, {
    error: 'bad_request',
    message:
      'Expected "rewriteTone" to be one of: balanced, gentle, encouraging, reflective.',
  });
});

test('theme endpoint rejects unknown fields', async () => {
  const response = await postJson('/v1/entries/themes/detect', {
    text: 'work',
    extra: true,
  });
  const body = await response.json();

  assert.equal(response.status, 400);
  assert.deepEqual(body, {
    error: 'bad_request',
    message: 'Unexpected field "extra".',
  });
});

test('resource suggestion endpoint rejects invalid themeIds', async () => {
  const response = await postJson('/v1/resources/suggest', {
    text: 'work stress',
    themeIds: [7],
  });
  const body = await response.json();

  assert.equal(response.status, 400);
  assert.deepEqual(body, {
    error: 'bad_request',
    message: 'Expected "themeIds[0]" to be a non-empty string.',
  });
});

test('transcription endpoint rejects invalid audio uploads', async () => {
  const response = await postJson('/v1/transcriptions', {
    audioBase64: 'not base64',
    mimeType: 'audio/mp4',
  });
  const body = await response.json();

  assert.equal(response.status, 400);
  assert.deepEqual(body, {
    error: 'bad_request',
    message: 'Expected valid base64 audio.',
  });
});

test('transcription endpoint rejects unsupported audio types', async () => {
  const response = await postJson('/v1/transcriptions', {
    audioBase64: Buffer.from('recorded audio').toString('base64'),
    mimeType: 'text/plain',
  });
  const body = await response.json();

  assert.equal(response.status, 400);
  assert.deepEqual(body, {
    error: 'bad_request',
    message: 'Unsupported audio mime type "text/plain".',
  });
});

test('endpoint rejects invalid JSON', async () => {
  const response = await fetch(`${baseUrl}/v1/entries/rewrite`, {
    method: 'POST',
    body: '{',
    headers: {
      'content-type': 'application/json',
    },
  });
  const body = await response.json();

  assert.equal(response.status, 400);
  assert.deepEqual(body, {
    error: 'bad_request',
    message: 'Expected valid JSON.',
  });
});

test('returns not_found for unknown routes', async () => {
  const response = await fetch(`${baseUrl}/v1/unknown-path`);
  const body = await response.json();

  assert.equal(response.status, 404);
  assert.deepEqual(body, {
    error: 'not_found',
  });
});

test('transcription endpoint responds to CORS preflight', async () => {
  const response = await fetch(`${baseUrl}/v1/transcriptions`, {
    method: 'OPTIONS',
    headers: {
      origin: 'http://127.0.0.1:51910',
      'access-control-request-method': 'POST',
      'access-control-request-headers': 'content-type',
    },
  });

  assert.equal(response.status, 204);
  assert.equal(
    response.headers.get('access-control-allow-origin'),
    'http://127.0.0.1:51910',
  );
  assert.equal(
    response.headers.get('access-control-allow-methods'),
    'GET, POST, OPTIONS',
  );
  assert.equal(
    response.headers.get('access-control-allow-headers'),
    'content-type',
  );
});

test('transcription endpoint rejects audio larger than 10 MB', async () => {
  const tooLargeAudio = Buffer.alloc(10 * 1024 * 1024 + 1).toString('base64');

  const response = await postJson('/v1/transcriptions', {
    audioBase64: tooLargeAudio,
    mimeType: 'audio/mp4',
  });
  const body = await response.json();

  assert.equal(response.status, 400);
  assert.deepEqual(body, {
    error: 'bad_request',
    message: 'Audio upload exceeds 10 MB.',
  });
});

test('maps rewrite provider failures to internal_server_error', async () => {
  const response = await postJson(
    '/v1/entries/rewrite',
    {
      originalText: 'raw note',
    },
    failingBaseUrl,
  );
  const body = await response.json();

  assert.equal(response.status, 500);
  assert.deepEqual(body, {
    error: 'internal_server_error',
  });
});

test('maps theme provider failures to internal_server_error', async () => {
  const response = await postJson(
    '/v1/entries/themes/detect',
    {
      text: 'raw note',
    },
    failingBaseUrl,
  );
  const body = await response.json();

  assert.equal(response.status, 500);
  assert.deepEqual(body, {
    error: 'internal_server_error',
  });
});

test('maps transcription provider failures to internal_server_error', async () => {
  const response = await postJson(
    '/v1/transcriptions',
    {
      audioBase64: Buffer.from('recorded audio').toString('base64'),
      mimeType: 'audio/mp4',
    },
    failingBaseUrl,
  );
  const body = await response.json();

  assert.equal(response.status, 500);
  assert.deepEqual(body, {
    error: 'internal_server_error',
  });
});

test('maps resource suggestion provider failures to internal_server_error', async () => {
  const response = await postJson(
    '/v1/resources/suggest',
    {
      text: 'work',
      themeIds: ['work'],
    },
    failingBaseUrl,
  );
  const body = await response.json();

  assert.equal(response.status, 500);
  assert.deepEqual(body, {
    error: 'internal_server_error',
  });
});

test('maps provider rate limits to safe 429 response', async () => {
  await assertProviderError(
    new AiProviderError('rate_limit', 'raw provider detail'),
    '/v1/entries/rewrite',
    { originalText: 'raw note' },
    429,
    {
      error: 'provider_rate_limited',
      message: 'AI provider is rate-limited. Please retry shortly.',
    },
  );
});

test('maps provider timeout to safe 504 response', async () => {
  await assertProviderError(
    new AiProviderError('timeout', 'raw provider detail'),
    '/v1/entries/themes/detect',
    { text: 'raw note' },
    504,
    {
      error: 'provider_timeout',
      message: 'AI provider timed out. Please retry.',
    },
  );
});

test('maps provider unavailable to safe 503 response', async () => {
  await assertProviderError(
    new AiProviderError('unavailable', 'raw provider detail'),
    '/v1/transcriptions',
    {
      audioBase64: Buffer.from('recorded audio').toString('base64'),
      mimeType: 'audio/mp4',
    },
    503,
    {
      error: 'provider_unavailable',
      message: 'AI provider is temporarily unavailable. Please retry.',
    },
  );
});

test('maps provider malformed response to safe 502 response', async () => {
  await assertProviderError(
    new AiProviderError('malformed_response', 'raw provider detail'),
    '/v1/entries/rewrite',
    { originalText: 'raw note' },
    502,
    {
      error: 'provider_response_invalid',
      message: 'AI provider returned an invalid response.',
    },
  );
});

test('resource suggestion endpoint rejects malformed provider responses', async () => {
  const malformedServer = createApiServer({
    aiProvider: {
      async rewrite() {
        return { rewrittenText: 'ok' };
      },
      async detectThemes() {
        return { themes: [] };
      },
      async transcribe() {
        return { transcript: 'ok' };
      },
      async suggestResources() {
        return {
          suggestions: [
            {
              id: '',
              type: 'reflection_prompt',
              title: 'broken',
              sourceType: 'ai_mapped',
              matchReason: 'broken',
              confidence: 2,
            },
          ],
        };
      },
    },
  });

  await new Promise<void>((resolve) => {
    malformedServer.listen(0, '127.0.0.1', resolve);
  });

  const address = malformedServer.address();

  if (address === null || typeof address === 'string') {
    throw new Error('Expected server to listen on a TCP address.');
  }

  const malformedBaseUrl = `http://127.0.0.1:${address.port}`;

  try {
    const response = await postJson(
      '/v1/resources/suggest',
      { text: 'work' },
      malformedBaseUrl,
    );
    const body = await response.json();

    assert.equal(response.status, 500);
    assert.deepEqual(body, { error: 'internal_server_error' });
  } finally {
    malformedServer.closeAllConnections();
    malformedServer.closeIdleConnections();
    await new Promise<void>((resolve, reject) => {
      malformedServer.close((error) => {
        if (error) {
          reject(error);
          return;
        }

        resolve();
      });
    });
  }
});

async function postJson(
  path: string,
  body: unknown,
  targetBaseUrl: string = baseUrl,
): Promise<Response> {
  return fetch(`${targetBaseUrl}${path}`, {
    method: 'POST',
    body: JSON.stringify(body),
    headers: {
      'content-type': 'application/json',
    },
  });
}

async function assertProviderError(
  providerError: AiProviderError,
  path: string,
  body: unknown,
  expectedStatus: number,
  expectedBody: unknown,
): Promise<void> {
  const errorServer = createApiServer({
    aiProvider: {
      async rewrite() {
        throw providerError;
      },
      async detectThemes() {
        throw providerError;
      },
      async transcribe() {
        throw providerError;
      },
      async suggestResources() {
        throw providerError;
      },
    },
  });

  await new Promise<void>((resolve) => {
    errorServer.listen(0, '127.0.0.1', resolve);
  });

  const address = errorServer.address();

  if (address === null || typeof address === 'string') {
    throw new Error('Expected server to listen on a TCP address.');
  }

  const serverBaseUrl = `http://127.0.0.1:${address.port}`;

  try {
    const response = await postJson(path, body, serverBaseUrl);
    const responseBody = await response.json();

    assert.equal(response.status, expectedStatus);
    assert.deepEqual(responseBody, expectedBody);
  } finally {
    errorServer.closeAllConnections();
    errorServer.closeIdleConnections();
    await new Promise<void>((resolve, reject) => {
      errorServer.close((error) => {
        if (error) {
          reject(error);
          return;
        }

        resolve();
      });
    });
  }
}
