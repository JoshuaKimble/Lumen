import assert from 'node:assert/strict';
import { test } from 'node:test';

import { createApiServer } from '../src/app.js';
import type { AuthenticatedUser, AuthVerifier } from '../src/auth/authVerifier.js';
import { AuthVerificationError } from '../src/auth/authVerifier.js';
import {
  ResourceFeedbackStoreError,
  type ResourceFeedbackRecord,
  type ResourceFeedbackStore,
} from '../src/resourceFeedback/resourceFeedbackStore.js';

class RecordingAuthVerifier implements AuthVerifier {
  user: AuthenticatedUser = { id: 'user-1' };
  error?: Error;
  lastToken?: string;

  async verifyAccessToken(accessToken: string): Promise<AuthenticatedUser> {
    this.lastToken = accessToken;

    if (this.error != null) {
      throw this.error;
    }

    return this.user;
  }
}

class RecordingResourceFeedbackStore implements ResourceFeedbackStore {
  readonly records: ResourceFeedbackRecord[] = [];
  error?: Error;

  async saveFeedback(record: ResourceFeedbackRecord): Promise<void> {
    if (this.error != null) {
      throw this.error;
    }

    this.records.length = 0;
    this.records.push(record);
  }
}

test('accepts authenticated resource feedback and persists it', async () => {
  const recordingVerifier = new RecordingAuthVerifier();
  const recordingStore = new RecordingResourceFeedbackStore();
  recordingVerifier.user = { id: 'user-1' };

  await withTestServer(
    {
      authVerifier: recordingVerifier,
      resourceFeedbackStore: recordingStore,
    },
    async (baseUrl) => {
      const response = await postFeedback(
        baseUrl,
        {
          resourceId: 'resource-1',
          action: 'save',
          entryId: 'entry-1',
          themeId: 'hope',
          note: 'Helpful prompt.',
        },
        'token-1',
      );
      const body = await response.json();

      assert.equal(response.status, 202);
      assert.deepEqual(body, { status: 'accepted' });
      assert.equal(recordingVerifier.lastToken, 'token-1');
      assert.deepEqual(recordingStore.records, [
        {
          userId: 'user-1',
          resourceId: 'resource-1',
          action: 'save',
          entryId: 'entry-1',
          themeId: 'hope',
          note: 'Helpful prompt.',
        },
      ]);
    },
  );
});

test('rejects feedback without bearer token', async () => {
  await withTestServer({}, async (baseUrl) => {
    const response = await postFeedback(baseUrl, {
      resourceId: 'resource-1',
      action: 'dismiss',
    });
    const body = await response.json();

    assert.equal(response.status, 401);
    assert.deepEqual(body, {
      error: 'unauthorized',
      message: 'Missing bearer token.',
    });
  });
});

test('rejects invalid feedback actions', async () => {
  await withTestServer(
    {
      authVerifier: new RecordingAuthVerifier(),
      resourceFeedbackStore: new RecordingResourceFeedbackStore(),
    },
    async (baseUrl) => {
      const response = await postFeedback(
        baseUrl,
        {
          resourceId: 'resource-1',
          action: 'archive',
        },
        'token-1',
      );
      const body = await response.json();

      assert.equal(response.status, 400);
      assert.deepEqual(body, {
        error: 'bad_request',
        message: 'Expected "action" to be one of: save, dismiss, not_helpful.',
      });
    },
  );
});

test('maps invalid token failures to 401', async () => {
  const recordingVerifier = new RecordingAuthVerifier();
  recordingVerifier.error = new AuthVerificationError(
    'Missing or invalid bearer token.',
  );

  await withTestServer(
    {
      authVerifier: recordingVerifier,
      resourceFeedbackStore: new RecordingResourceFeedbackStore(),
    },
    async (baseUrl) => {
      const response = await postFeedback(
        baseUrl,
        {
          resourceId: 'resource-1',
          action: 'save',
        },
        'bad-token',
      );
      const body = await response.json();

      assert.equal(response.status, 401);
      assert.deepEqual(body, {
        error: 'unauthorized',
        message: 'Missing or invalid bearer token.',
      });
    },
  );
});

test('maps invalid reference store failures to 400', async () => {
  const recordingVerifier = new RecordingAuthVerifier();
  const recordingStore = new RecordingResourceFeedbackStore();
  recordingVerifier.user = { id: 'user-1' };
  recordingStore.error = new ResourceFeedbackStoreError(
    'invalid_reference',
    'Referenced entry does not exist.',
  );

  await withTestServer(
    {
      authVerifier: recordingVerifier,
      resourceFeedbackStore: recordingStore,
    },
    async (baseUrl) => {
      const response = await postFeedback(
        baseUrl,
        {
          resourceId: 'resource-1',
          action: 'save',
          entryId: 'missing-entry',
        },
        'token-1',
      );
      const body = await response.json();

      assert.equal(response.status, 400);
      assert.deepEqual(body, {
        error: 'bad_request',
        message: 'Referenced entry does not exist.',
      });
    },
  );
});

async function postFeedback(
  baseUrl: string,
  body: Record<string, unknown>,
  bearerToken?: string,
): Promise<Response> {
  const headers: Record<string, string> = {
    'content-type': 'application/json',
  };

  if (bearerToken != null) {
    headers.authorization = `Bearer ${bearerToken}`;
  }

  return fetch(`${baseUrl}/v1/resources/feedback`, {
    method: 'POST',
    headers,
    body: JSON.stringify(body),
  });
}

async function withTestServer(
  dependencies: Parameters<typeof createApiServer>[0],
  callback: (baseUrl: string) => Promise<void>,
): Promise<void> {
  const server = createApiServer(dependencies);

  await new Promise<void>((resolve) => {
    server.listen(0, '127.0.0.1', resolve);
  });

  const address = server.address();

  if (address === null || typeof address === 'string') {
    throw new Error('Expected server to listen on a TCP address.');
  }

  const baseUrl = `http://127.0.0.1:${address.port}`;

  try {
    await callback(baseUrl);
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
}
