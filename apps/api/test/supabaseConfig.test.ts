import test from 'node:test';
import assert from 'node:assert/strict';

import { parseSupabaseServerConfig } from '../src/supabase/supabaseConfig.js';

test('defaults to disabled when supabase flag is missing', () => {
  const config = parseSupabaseServerConfig({});

  assert.equal(config.enabled, false);
  assert.equal(config.url, '');
  assert.equal(config.serviceRoleKey, '');
});

test('requires url and service key when supabase is enabled', () => {
  assert.throws(
    () => parseSupabaseServerConfig({LUMEN_USE_SUPABASE: 'true'}),
    /LUMEN_SUPABASE_URL/,
  );

  assert.throws(
    () =>
      parseSupabaseServerConfig({
        LUMEN_USE_SUPABASE: 'true',
        LUMEN_SUPABASE_URL: 'https://example.supabase.co',
      }),
    /LUMEN_SUPABASE_SERVICE_ROLE_KEY/,
  );
});

test('parses enabled supabase config', () => {
  const config = parseSupabaseServerConfig({
    LUMEN_USE_SUPABASE: 'true',
    LUMEN_SUPABASE_URL: 'https://example.supabase.co',
    LUMEN_SUPABASE_SERVICE_ROLE_KEY: 'service-role-secret',
  });

  assert.equal(config.enabled, true);
  assert.equal(config.url, 'https://example.supabase.co');
  assert.equal(config.serviceRoleKey, 'service-role-secret');
});
