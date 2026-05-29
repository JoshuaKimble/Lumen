import type { SupabaseServerConfig } from '../supabase/supabaseConfig.js';
import {
  ResourceFeedbackStoreError,
  type ResourceFeedbackRecord,
  type ResourceFeedbackStore,
} from './resourceFeedbackStore.js';

export type ResourceFeedbackFetch = typeof fetch;

interface PostgrestErrorBody {
  readonly message?: unknown;
  readonly code?: unknown;
}

export class SupabaseResourceFeedbackStore implements ResourceFeedbackStore {
  constructor({
    config,
    fetchFn = fetch,
  }: {
    config: SupabaseServerConfig;
    fetchFn?: ResourceFeedbackFetch;
  }) {
    this._config = config;
    this._fetch = fetchFn;
  }

  private readonly _config: SupabaseServerConfig;
  private readonly _fetch: ResourceFeedbackFetch;

  async saveFeedback(record: ResourceFeedbackRecord): Promise<void> {
    const response = await this._fetch(
      new URL(
        '/rest/v1/resource_feedback?on_conflict=user_id,resource_id',
        this._config.url,
      ),
      {
        method: 'POST',
        headers: {
          apikey: this._config.secretKey,
          authorization: `Bearer ${this._config.secretKey}`,
          'content-type': 'application/json',
          prefer: 'resolution=merge-duplicates,return=minimal',
        },
        body: JSON.stringify({
          user_id: record.userId,
          resource_id: record.resourceId,
          action: record.action,
          entry_id: record.entryId ?? null,
          theme_id: record.themeId ?? null,
          note: record.note ?? null,
        }),
      },
    );

    if (response.ok) {
      return;
    }

    const body = (await response.json().catch(() => null)) as
      | PostgrestErrorBody
      | null;
    const message =
      typeof body?.message === 'string'
        ? body.message
        : `Supabase resource feedback write failed with status ${response.status}.`;
    const code = typeof body?.code === 'string' ? body.code : '';

    if (
      response.status === 400 ||
      response.status === 404 ||
      response.status === 409 ||
      code.startsWith('23503') ||
      code.startsWith('23514')
    ) {
      throw new ResourceFeedbackStoreError('invalid_reference', message);
    }

    throw new ResourceFeedbackStoreError('unavailable', message);
  }
}
