import assert from 'node:assert/strict';
import { Buffer } from 'node:buffer';
import { after, before, test } from 'node:test';

import { createApiServer } from '../src/app.js';

let baseUrl = '';
const server = createApiServer();

before(async () => {
  await new Promise<void>((resolve) => {
    server.listen(0, '127.0.0.1', resolve);
  });

  const address = server.address();

  if (address === null || typeof address === 'string') {
    throw new Error('Expected server to listen on a TCP address.');
  }

  baseUrl = `http://127.0.0.1:${address.port}`;
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
});

test('rewrite endpoint returns OpenAPI response shape', async () => {
  const response = await postJson('/v1/entries/rewrite', {
    originalText: 'I had a rushed work meeting.',
  });
  const body = await response.json();

  assert.equal(response.status, 200);
  assert.deepEqual(body, {
    rewrittenText: 'Mock rewrite: I had a rushed work meeting.',
    title: 'I had a rushed work meeting',
    summary: 'I had a rushed work meeting.',
  });
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

async function postJson(path: string, body: unknown): Promise<Response> {
  return fetch(`${baseUrl}${path}`, {
    method: 'POST',
    body: JSON.stringify(body),
    headers: {
      'content-type': 'application/json',
    },
  });
}
