import assert from 'node:assert/strict';
import test from 'node:test';

import { AccountDeletionStoreError } from '../src/accountDeletion/accountDeletionStore.js';
import { SupabaseAccountDeletionStore } from '../src/accountDeletion/supabaseAccountDeletionStore.js';

test('deletes auth user through Supabase admin endpoint', async () => {
  let lastRequest: Request | undefined;
  const store = new SupabaseAccountDeletionStore({
    config: {
      enabled: true,
      url: 'https://example.supabase.co',
      secretKey: 'sb_secret_example',
    },
    fetchFn: async (input, init) => {
      lastRequest = new Request(input, init);
      return new Response(null, {status: 200});
    },
  });

  await store.deleteAccount('user-1');

  assert.equal(
    lastRequest?.url,
    'https://example.supabase.co/auth/v1/admin/users/user-1',
  );
  assert.equal(lastRequest?.method, 'DELETE');
  assert.equal(lastRequest?.headers.get('apikey'), 'sb_secret_example');
  assert.equal(
    lastRequest?.headers.get('authorization'),
    'Bearer sb_secret_example',
  );
});

test('maps supabase errors to unavailable account deletion failures', async () => {
  const store = new SupabaseAccountDeletionStore({
    config: {
      enabled: true,
      url: 'https://example.supabase.co',
      secretKey: 'sb_secret_example',
    },
    fetchFn: async () =>
      new Response(
        JSON.stringify({
          message: 'permission denied',
        }),
        {status: 500, headers: {'content-type': 'application/json'}},
      ),
  });

  await assert.rejects(
    store.deleteAccount('user-1'),
    new AccountDeletionStoreError('unavailable', 'permission denied'),
  );
});
