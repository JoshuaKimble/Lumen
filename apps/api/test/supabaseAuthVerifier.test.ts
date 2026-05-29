import assert from 'node:assert/strict';
import test from 'node:test';

import { AuthVerificationError } from '../src/auth/authVerifier.js';
import { SupabaseAuthVerifier } from '../src/auth/supabaseAuthVerifier.js';

test('verifies bearer token against Supabase auth user endpoint', async () => {
  let lastRequest: Request | undefined;
  const verifier = new SupabaseAuthVerifier({
    config: {
      enabled: true,
      url: 'https://example.supabase.co',
      secretKey: 'sb_secret_example',
    },
    fetchFn: async (input, init) => {
      lastRequest = new Request(input, init);
      return new Response(
        JSON.stringify({id: 'user-1', email: 'user@example.com'}),
        {status: 200, headers: {'content-type': 'application/json'}},
      );
    },
  });

  const user = await verifier.verifyAccessToken('jwt-token');

  assert.equal(user.id, 'user-1');
  assert.equal(user.email, 'user@example.com');
  assert.equal(lastRequest?.url, 'https://example.supabase.co/auth/v1/user');
  assert.equal(lastRequest?.headers.get('authorization'), 'Bearer jwt-token');
  assert.equal(lastRequest?.headers.get('apikey'), 'sb_secret_example');
});

test('maps Supabase auth 401 to auth verification failure', async () => {
  const verifier = new SupabaseAuthVerifier({
    config: {
      enabled: true,
      url: 'https://example.supabase.co',
      secretKey: 'sb_secret_example',
    },
    fetchFn: async () => new Response('{}', {status: 401}),
  });

  await assert.rejects(
    verifier.verifyAccessToken('bad-token'),
    new AuthVerificationError('Missing or invalid bearer token.'),
  );
});
