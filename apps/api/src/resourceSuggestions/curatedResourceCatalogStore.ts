export interface CuratedResourceThemeMapping {
  readonly themeId: string;
  readonly weight: number;
}

export interface CuratedResourceCatalogRecord {
  readonly catalogKey: string;
  readonly recordKind: 'resource' | 'prompt_template';
  readonly resourceType:
    | 'reflection_prompt'
    | 'scripture'
    | 'talk_or_article'
    | 'video_or_audio'
    | 'quote'
    | 'exercise'
    | 'internal_entry_link';
  readonly providerKey?: string;
  readonly traditionKey?: string;
  readonly title: string;
  readonly description?: string;
  readonly canonicalUrl?: string;
  readonly scriptureReference?: string;
  readonly promptTemplate?: string;
  readonly contentText?: string;
  readonly metadata: Readonly<Record<string, unknown>>;
  readonly isActive: boolean;
  readonly themeMappings: readonly CuratedResourceThemeMapping[];
}

export interface CuratedResourceCatalogStore {
  listCandidatesByThemeIds(
    themeIds: readonly string[],
  ): Promise<readonly CuratedResourceCatalogRecord[]>;
}
