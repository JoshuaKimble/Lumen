import { type SupabaseServerConfig } from '../supabase/supabaseConfig.js';
import {
  AccountDeletionStoreError,
  type AccountDeletionStore,
} from './accountDeletionStore.js';

export type AccountDeletionFetch = typeof fetch;

interface SupabaseApiErrorPayload {
  readonly message?: unknown;
}

export class SupabaseAccountDeletionStore implements AccountDeletionStore {
  constructor({
    config,
    fetchFn,
  }: {
    config: SupabaseServerConfig;
    fetchFn?: AccountDeletionFetch;
  }) {
    this._config = config;
    this._fetch = fetchFn ?? fetch;
  }

  private readonly _config: SupabaseServerConfig;
  private readonly _fetch: AccountDeletionFetch;

  async deleteAccount(userId: string): Promise<void> {
    const response = await this._fetch(
      new URL(`/auth/v1/admin/users/${encodeURIComponent(userId)}`, this._config.url),
      {
        method: 'DELETE',
        headers: {
          apikey: this._config.secretKey,
          authorization: `Bearer ${this._config.secretKey}`,
          'content-type': 'application/json',
        },
      },
    );

    if (response.ok || response.status === 404) {
      return;
    }

    const message = await parseErrorMessage(response);
    throw new AccountDeletionStoreError('unavailable', message);
  }
}

async function parseErrorMessage(response: Response): Promise<string> {
  try {
    const payload = (await response.json()) as SupabaseApiErrorPayload;
    if (typeof payload.message === 'string' && payload.message.length > 0) {
      return payload.message;
    }
  } catch (_) {
    // Fall back to status-only message.
  }

  return `Supabase account deletion failed with status ${response.status}.`;
}
