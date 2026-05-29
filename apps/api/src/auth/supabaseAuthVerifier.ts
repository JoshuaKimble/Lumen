import { AuthVerificationError, type AuthenticatedUser, type AuthVerifier } from './authVerifier.js';
import type { SupabaseServerConfig } from '../supabase/supabaseConfig.js';

export type AuthVerifierFetch = typeof fetch;

interface SupabaseUserResponse {
  readonly id?: unknown;
  readonly email?: unknown;
}

export class SupabaseAuthVerifier implements AuthVerifier {
  constructor({
    config,
    fetchFn = fetch,
  }: {
    config: SupabaseServerConfig;
    fetchFn?: AuthVerifierFetch;
  }) {
    this._config = config;
    this._fetch = fetchFn;
  }

  private readonly _config: SupabaseServerConfig;
  private readonly _fetch: AuthVerifierFetch;

  async verifyAccessToken(accessToken: string): Promise<AuthenticatedUser> {
    const response = await this._fetch(
      new URL('/auth/v1/user', this._config.url),
      {
        method: 'GET',
        headers: {
          apikey: this._config.secretKey,
          authorization: `Bearer ${accessToken}`,
        },
      },
    );

    if (response.status === 401 || response.status === 403) {
      throw new AuthVerificationError('Missing or invalid bearer token.');
    }

    if (!response.ok) {
      throw new Error(
        `Supabase auth verification failed with status ${response.status}.`,
      );
    }

    const body = (await response.json()) as SupabaseUserResponse;
    if (typeof body.id !== 'string' || body.id.trim().length === 0) {
      throw new Error('Supabase auth verification returned no user id.');
    }

    return {
      id: body.id,
      email: typeof body.email === 'string' ? body.email : undefined,
    };
  }
}
