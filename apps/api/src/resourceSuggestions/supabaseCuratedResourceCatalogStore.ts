import type { SupabaseServerConfig } from '../supabase/supabaseConfig.js';
import type {
  CuratedResourceCatalogRecord,
  CuratedResourceCatalogStore,
  CuratedResourceThemeMapping,
} from './curatedResourceCatalogStore.js';

export type CuratedResourceCatalogFetch = typeof fetch;

interface ThemeMappingRow {
  readonly catalog_key?: unknown;
  readonly theme_id?: unknown;
  readonly weight?: unknown;
}

interface CatalogRow {
  readonly catalog_key?: unknown;
  readonly record_kind?: unknown;
  readonly resource_type?: unknown;
  readonly provider_key?: unknown;
  readonly tradition_key?: unknown;
  readonly title?: unknown;
  readonly description?: unknown;
  readonly canonical_url?: unknown;
  readonly scripture_reference?: unknown;
  readonly prompt_template?: unknown;
  readonly content_text?: unknown;
  readonly metadata?: unknown;
  readonly is_active?: unknown;
}

interface PostgrestErrorBody {
  readonly message?: unknown;
}

export class SupabaseCuratedResourceCatalogStore
  implements CuratedResourceCatalogStore
{
  constructor({
    config,
    fetchFn = fetch,
  }: {
    config: SupabaseServerConfig;
    fetchFn?: CuratedResourceCatalogFetch;
  }) {
    this._config = config;
    this._fetch = fetchFn;
  }

  private readonly _config: SupabaseServerConfig;
  private readonly _fetch: CuratedResourceCatalogFetch;

  async listCandidatesByThemeIds(
    themeIds: readonly string[],
  ): Promise<readonly CuratedResourceCatalogRecord[]> {
    const normalizedThemeIds = [...new Set(
      themeIds.map((themeId) => themeId.trim().toLowerCase()).filter(Boolean),
    )];

    if (normalizedThemeIds.length === 0) {
      return [];
    }

    const mappings = await this._fetchThemeMappings(normalizedThemeIds);
    if (mappings.length === 0) {
      return [];
    }

    const records = await this._fetchCatalogRecords(
      mappings.map((mapping) => mapping.catalogKey),
    );
    const mappingsByCatalogKey = new Map<string, CuratedResourceThemeMapping[]>();

    for (const mapping of mappings) {
      const existing = mappingsByCatalogKey.get(mapping.catalogKey) ?? [];
      existing.push({
        themeId: mapping.themeId,
        weight: mapping.weight,
      });
      mappingsByCatalogKey.set(mapping.catalogKey, existing);
    }

    return records.map((record) => ({
      ...record,
      themeMappings: mappingsByCatalogKey.get(record.catalogKey) ?? [],
    }));
  }

  private async _fetchThemeMappings(
    themeIds: readonly string[],
  ): Promise<
    readonly (CuratedResourceThemeMapping & { readonly catalogKey: string })[]
  > {
    const url = new URL(
      '/rest/v1/curated_resource_theme_mappings',
      this._config.url,
    );
    url.searchParams.set('select', 'catalog_key,theme_id,weight');
    url.searchParams.set('theme_id', `in.(${joinPostgrestInValues(themeIds)})`);
    url.searchParams.set('order', 'weight.desc');

    const response = await this._fetch(url, {
      method: 'GET',
      headers: {
        apikey: this._config.secretKey,
        authorization: `Bearer ${this._config.secretKey}`,
      },
    });
    const body = (await response.json().catch(() => null)) as
      | ThemeMappingRow[]
      | PostgrestErrorBody
      | null;

    if (!response.ok) {
      throw new Error(postgrestErrorMessage(
        body,
        `Supabase curated resource theme lookup failed with status ${response.status}.`,
      ));
    }

    if (!Array.isArray(body)) {
      throw new Error('Supabase curated resource theme lookup returned no rows.');
    }

    return body.map((row) => {
      const catalogKey = requiredString(row.catalog_key, 'catalog_key');
      return {
        catalogKey,
        themeId: requiredString(row.theme_id, 'theme_id'),
        weight: requiredNumber(row.weight, 'weight'),
      };
    });
  }

  private async _fetchCatalogRecords(
    catalogKeys: readonly string[],
  ): Promise<readonly Omit<CuratedResourceCatalogRecord, 'themeMappings'>[]> {
    const url = new URL('/rest/v1/curated_resource_catalog', this._config.url);
    url.searchParams.set(
      'select',
      [
        'catalog_key',
        'record_kind',
        'resource_type',
        'provider_key',
        'tradition_key',
        'title',
        'description',
        'canonical_url',
        'scripture_reference',
        'prompt_template',
        'content_text',
        'metadata',
        'is_active',
      ].join(','),
    );
    url.searchParams.set(
      'catalog_key',
      `in.(${joinPostgrestInValues(catalogKeys)})`,
    );
    url.searchParams.set('is_active', 'eq.true');

    const response = await this._fetch(url, {
      method: 'GET',
      headers: {
        apikey: this._config.secretKey,
        authorization: `Bearer ${this._config.secretKey}`,
      },
    });
    const body = (await response.json().catch(() => null)) as
      | CatalogRow[]
      | PostgrestErrorBody
      | null;

    if (!response.ok) {
      throw new Error(postgrestErrorMessage(
        body,
        `Supabase curated resource catalog lookup failed with status ${response.status}.`,
      ));
    }

    if (!Array.isArray(body)) {
      throw new Error(
        'Supabase curated resource catalog lookup returned no rows.',
      );
    }

    return body.map((row) => ({
      catalogKey: requiredString(row.catalog_key, 'catalog_key'),
      recordKind: requiredCatalogRecordKind(row.record_kind),
      resourceType: requiredResourceType(row.resource_type),
      providerKey: optionalString(row.provider_key),
      traditionKey: optionalString(row.tradition_key),
      title: requiredString(row.title, 'title'),
      description: optionalString(row.description),
      canonicalUrl: optionalString(row.canonical_url),
      scriptureReference: optionalString(row.scripture_reference),
      promptTemplate: optionalString(row.prompt_template),
      contentText: optionalString(row.content_text),
      metadata: requiredObject(row.metadata, 'metadata'),
      isActive: requiredBoolean(row.is_active, 'is_active'),
    }));
  }
}

function joinPostgrestInValues(values: readonly string[]): string {
  return values.map((value) => `"${value.replaceAll('"', '\\"')}"`).join(',');
}

function postgrestErrorMessage(
  body: PostgrestErrorBody | ThemeMappingRow[] | CatalogRow[] | null,
  fallback: string,
): string {
  if (
    body != null &&
    !Array.isArray(body) &&
    typeof body.message === 'string' &&
    body.message.trim().length > 0
  ) {
    return body.message;
  }

  return fallback;
}

function requiredString(value: unknown, key: string): string {
  if (typeof value !== 'string' || value.trim().length === 0) {
    throw new Error(`Supabase curated resource row is missing ${key}.`);
  }

  return value;
}

function optionalString(value: unknown): string | undefined {
  return typeof value === 'string' && value.trim().length > 0
    ? value
    : undefined;
}

function requiredNumber(value: unknown, key: string): number {
  if (typeof value !== 'number' || !Number.isFinite(value)) {
    throw new Error(`Supabase curated resource row is missing ${key}.`);
  }

  return value;
}

function requiredBoolean(value: unknown, key: string): boolean {
  if (typeof value !== 'boolean') {
    throw new Error(`Supabase curated resource row is missing ${key}.`);
  }

  return value;
}

function requiredObject(
  value: unknown,
  key: string,
): Readonly<Record<string, unknown>> {
  if (value == null || typeof value !== 'object' || Array.isArray(value)) {
    throw new Error(`Supabase curated resource row is missing ${key}.`);
  }

  return value as Readonly<Record<string, unknown>>;
}

function requiredCatalogRecordKind(
  value: unknown,
): CuratedResourceCatalogRecord['recordKind'] {
  if (value === 'resource' || value === 'prompt_template') {
    return value;
  }

  throw new Error('Supabase curated resource row has invalid record_kind.');
}

function requiredResourceType(
  value: unknown,
): CuratedResourceCatalogRecord['resourceType'] {
  switch (value) {
    case 'reflection_prompt':
    case 'scripture':
    case 'talk_or_article':
    case 'video_or_audio':
    case 'quote':
    case 'exercise':
    case 'internal_entry_link':
      return value;
    default:
      throw new Error('Supabase curated resource row has invalid resource_type.');
  }
}
