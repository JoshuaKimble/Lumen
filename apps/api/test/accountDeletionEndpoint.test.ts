import assert from 'node:assert/strict';
import { test } from 'node:test';

import { createApiServer } from '../src/app.js';
import {
  AuthVerificationError,
  type AuthenticatedUser,
  type AuthVerifier,
} from '../src/auth/authVerifier.js';
import {
  AccountDeletionStoreError,
  type AccountDeletionStore,
} from '../src/accountDeletion/accountDeletionStore.js';

class RecordingAuthVerifier implements AuthVerifier {
  user: AuthenticatedUser = {id: 'user-1'};
  error?: Error;

  async verifyAccessToken(_accessToken: string): Promise<AuthenticatedUser> {
    if (this.error != null) {
      throw this.error;
    }

    return this.user;
  }
}

class RecordingAccountDeletionStore implements AccountDeletionStore {
  deletedUserIds: string[] = [];
  error?: Error;

  async deleteAccount(userId: string): Promise<void> {
    if (this.error != null) {
      throw this.error;
    }
    this.deletedUserIds.push(userId);
  }
}

test('accepts authenticated account deletion request', async () => {
  const verifier = new RecordingAuthVerifier();
  const store = new RecordingAccountDeletionStore();

  await withTestServer(
    {
      authVerifier: verifier,
      accountDeletionStore: store,
    },
    async (baseUrl) => {
      const response = await postDeleteAccount(baseUrl, {
        confirmation: 'DELETE',
      });
      const body = await response.json();

      assert.equal(response.status, 202);
      assert.deepEqual(body, {status: 'deleted'});
      assert.deepEqual(store.deletedUserIds, ['user-1']);
    },
  );
});

test('rejects deletion without bearer token', async () => {
  const verifier = new RecordingAuthVerifier();
  const store = new RecordingAccountDeletionStore();

  await withTestServer(
    {
      authVerifier: verifier,
      accountDeletionStore: store,
    },
    async (baseUrl) => {
      const response = await fetch(`${baseUrl}/v1/account/delete`, {
        method: 'POST',
        headers: {
          'content-type': 'application/json',
        },
        body: JSON.stringify({confirmation: 'DELETE'}),
      });
      const body = await response.json();

      assert.equal(response.status, 401);
      assert.deepEqual(body, {
        error: 'unauthorized',
        message: 'Missing bearer token.',
      });
    },
  );
});

test('rejects invalid deletion confirmation payload', async () => {
  const verifier = new RecordingAuthVerifier();
  const store = new RecordingAccountDeletionStore();

  await withTestServer(
    {
      authVerifier: verifier,
      accountDeletionStore: store,
    },
    async (baseUrl) => {
      const response = await postDeleteAccount(
        baseUrl,
        {confirmation: 'NOPE'},
        'token-1',
      );
      const body = await response.json();

      assert.equal(response.status, 400);
      assert.deepEqual(body, {
        error: 'bad_request',
        message: 'Expected "confirmation" to be "DELETE".',
      });
    },
  );
});

test('maps store failures to 503', async () => {
  const verifier = new RecordingAuthVerifier();
  const store = new RecordingAccountDeletionStore();
  store.error = new AccountDeletionStoreError('unavailable', 'unavailable');

  await withTestServer(
    {
      authVerifier: verifier,
      accountDeletionStore: store,
    },
    async (baseUrl) => {
      const response = await postDeleteAccount(
        baseUrl,
        {confirmation: 'DELETE'},
        'token-1',
      );
      const body = await response.json();

      assert.equal(response.status, 503);
      assert.deepEqual(body, {
        error: 'internal_server_error',
        message: 'Account deletion is temporarily unavailable.',
      });
    },
  );
});

test('maps token verification failures to 401', async () => {
  const verifier = new RecordingAuthVerifier();
  verifier.error = new AuthVerificationError('Missing or invalid bearer token.');

  await withTestServer(
    {
      authVerifier: verifier,
      accountDeletionStore: new RecordingAccountDeletionStore(),
    },
    async (baseUrl) => {
      const response = await postDeleteAccount(
        baseUrl,
        {confirmation: 'DELETE'},
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

async function postDeleteAccount(
  baseUrl: string,
  body: Record<string, unknown>,
  bearerToken = 'token-1',
): Promise<Response> {
  return fetch(`${baseUrl}/v1/account/delete`, {
    method: 'POST',
    headers: {
      'content-type': 'application/json',
      authorization: `Bearer ${bearerToken}`,
    },
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
