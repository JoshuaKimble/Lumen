import assert from 'node:assert/strict';
import test from 'node:test';

import { ResourceFeedbackStoreError } from '../src/resourceFeedback/resourceFeedbackStore.js';
import { SupabaseResourceFeedbackStore } from '../src/resourceFeedback/supabaseResourceFeedbackStore.js';

test('upserts resource feedback into Supabase rest api', async () => {
  let lastRequest: Request | undefined;
  const store = new SupabaseResourceFeedbackStore({
    config: {
      enabled: true,
      url: 'https://example.supabase.co',
      secretKey: 'sb_secret_example',
    },
    fetchFn: async (input, init) => {
      lastRequest = new Request(input, init);
      return new Response(null, {status: 201});
    },
  });

  await store.saveFeedback({
    userId: 'user-1',
    resourceId: 'resource-1',
    action: 'dismiss',
    entryId: 'entry-1',
    themeId: 'hope',
    note: 'Not relevant.',
  });

  assert.equal(
    lastRequest?.url,
    'https://example.supabase.co/rest/v1/resource_feedback?on_conflict=user_id,resource_id',
  );
  assert.equal(lastRequest?.method, 'POST');
  assert.equal(
    lastRequest?.headers.get('prefer'),
    'resolution=merge-duplicates,return=minimal',
  );
  assert.equal(
    lastRequest?.headers.get('authorization'),
    'Bearer sb_secret_example',
  );
  assert.deepEqual(await lastRequest?.json(), {
    user_id: 'user-1',
    resource_id: 'resource-1',
    action: 'dismiss',
    entry_id: 'entry-1',
    theme_id: 'hope',
    note: 'Not relevant.',
  });
});

test('maps invalid reference write failures', async () => {
  const store = new SupabaseResourceFeedbackStore({
    config: {
      enabled: true,
      url: 'https://example.supabase.co',
      secretKey: 'sb_secret_example',
    },
    fetchFn: async () =>
      new Response(
        JSON.stringify({
          code: '23503',
          message: 'insert or update violates foreign key constraint',
        }),
        {status: 409, headers: {'content-type': 'application/json'}},
      ),
  });

  await assert.rejects(
    store.saveFeedback({
      userId: 'user-1',
      resourceId: 'resource-1',
      action: 'save',
      entryId: 'missing-entry',
    }),
    new ResourceFeedbackStoreError(
      'invalid_reference',
      'insert or update violates foreign key constraint',
    ),
  );
});
