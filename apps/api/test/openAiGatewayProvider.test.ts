import assert from 'node:assert/strict';
import { test } from 'node:test';

import { OpenAiGatewayProvider } from '../src/ai/openAiGatewayProvider.js';
import { AiProviderError } from '../src/ai/providerError.js';

const config = {
  apiKey: 'test-key',
  rewriteModel: 'rewrite-model',
  themeModel: 'theme-model',
  transcriptionModel: 'transcribe-model',
} as const;

test('rewrites entries via OpenAI completions', async () => {
  const transport = new FakeTransport({
    jsonResponse: {
      status: 200,
      data: {
        choices: [
          {
            message: {
              content: JSON.stringify({
                rewrittenText: 'Clear rewrite',
                title: 'New title',
                summary: 'New summary',
              }),
            },
          },
        ],
      },
    },
  });
  const provider = new OpenAiGatewayProvider(config, transport);

  const result = await provider.rewrite({ originalText: 'raw note' });

  assert.equal(result.rewrittenText, 'Clear rewrite');
  assert.equal(result.title, 'New title');
  assert.equal(result.summary, 'New summary');
  assert.equal(transport.lastJsonPath, '/chat/completions');
  assert.equal((transport.lastJsonBody as { model: string }).model, 'rewrite-model');
});

test('detects themes via OpenAI completions', async () => {
  const transport = new FakeTransport({
    jsonResponse: {
      status: 200,
      data: {
        choices: [
          {
            message: {
              content: JSON.stringify({
                themes: [
                  { id: 'work', name: 'work', displayName: 'Work', weight: 0.8 },
                ],
              }),
            },
          },
        ],
      },
    },
  });
  const provider = new OpenAiGatewayProvider(config, transport);

  const result = await provider.detectThemes({ text: 'work note' });

  assert.deepEqual(result, {
    themes: [{ id: 'work', name: 'work', displayName: 'Work', weight: 0.8 }],
  });
  assert.equal(transport.lastJsonPath, '/chat/completions');
  assert.equal((transport.lastJsonBody as { model: string }).model, 'theme-model');
});

test('transcribes audio via OpenAI transcription endpoint', async () => {
  const transport = new FakeTransport({
    formResponse: {
      status: 200,
      data: {
        text: 'transcribed text',
      },
    },
  });
  const provider = new OpenAiGatewayProvider(config, transport);

  const result = await provider.transcribe({
    audio: new Uint8Array([1, 2, 3]),
    mimeType: 'audio/mp4',
  });

  assert.equal(result.transcript, 'transcribed text');
  assert.equal(transport.lastFormPath, '/audio/transcriptions');
  assert.ok(transport.lastFormData instanceof FormData);
  assert.equal(transport.lastFormData?.get('model'), 'transcribe-model');
  assert.equal(transport.lastFormData?.get('response_format'), 'json');
});

test('rejects malformed rewrite payloads', async () => {
  const transport = new FakeTransport({
    jsonResponse: {
      status: 200,
      data: {
        choices: [{ message: { content: 'not-json' } }],
      },
    },
  });
  const provider = new OpenAiGatewayProvider(config, transport);

  await assert.rejects(
    provider.rewrite({ originalText: 'raw note' }),
    /not valid JSON/,
  );
});

test('rejects rewrite payload without choices', async () => {
  const transport = new FakeTransport({
    jsonResponse: {
      status: 200,
      data: {},
    },
  });
  const provider = new OpenAiGatewayProvider(config, transport);

  await assert.rejects(
    provider.rewrite({ originalText: 'raw note' }),
    /did not include choices/,
  );
});

test('rejects rewrite payload without message content', async () => {
  const transport = new FakeTransport({
    jsonResponse: {
      status: 200,
      data: {
        choices: [{}],
      },
    },
  });
  const provider = new OpenAiGatewayProvider(config, transport);

  await assert.rejects(
    provider.rewrite({ originalText: 'raw note' }),
    /did not include a message/,
  );
});

test('rejects themes payload without themes array', async () => {
  const transport = new FakeTransport({
    jsonResponse: {
      status: 200,
      data: {
        choices: [
          {
            message: {
              content: JSON.stringify({
                missingThemes: [],
              }),
            },
          },
        ],
      },
    },
  });
  const provider = new OpenAiGatewayProvider(config, transport);

  await assert.rejects(
    provider.detectThemes({ text: 'raw note' }),
    /did not include a themes array/,
  );
});

test('rejects themes payload with invalid weight type', async () => {
  const transport = new FakeTransport({
    jsonResponse: {
      status: 200,
      data: {
        choices: [
          {
            message: {
              content: JSON.stringify({
                themes: [
                  {
                    id: 'work',
                    name: 'work',
                    displayName: 'Work',
                    weight: 'heavy',
                  },
                ],
              }),
            },
          },
        ],
      },
    },
  });
  const provider = new OpenAiGatewayProvider(config, transport);

  await assert.rejects(
    provider.detectThemes({ text: 'raw note' }),
    /invalid "weight"/,
  );
});

test('rejects transcription payload without text', async () => {
  const transport = new FakeTransport({
    formResponse: {
      status: 200,
      data: {
        text: '',
      },
    },
  });
  const provider = new OpenAiGatewayProvider(config, transport);

  await assert.rejects(
    provider.transcribe({
      audio: new Uint8Array([1, 2, 3]),
      mimeType: 'audio/mp4',
    }),
    /did not include text/,
  );
});

test('rejects non-2xx OpenAI responses', async () => {
  const transport = new FakeTransport({
    jsonResponse: {
      status: 429,
      data: {
        error: { message: 'rate limit' },
      },
    },
  });
  const provider = new OpenAiGatewayProvider(config, transport);

  await assert.rejects(
    provider.detectThemes({ text: 'raw note' }),
    (error: unknown) => {
      assert.ok(error instanceof AiProviderError);
      assert.equal(error.kind, 'rate_limit');
      return true;
    },
  );
});

class FakeTransport {
  constructor(
    private readonly responses: {
      jsonResponse?: { status: number; data: unknown };
      formResponse?: { status: number; data: unknown };
    },
  ) {}

  lastJsonPath: string | undefined;
  lastJsonBody: unknown;
  lastFormPath: string | undefined;
  lastFormData: FormData | undefined;

  async postJson(path: string, body: unknown) {
    this.lastJsonPath = path;
    this.lastJsonBody = body;

    return this.responses.jsonResponse ?? { status: 200, data: {} };
  }

  async postFormData(path: string, body: FormData) {
    this.lastFormPath = path;
    this.lastFormData = body;

    return this.responses.formResponse ?? { status: 200, data: {} };
  }
}
