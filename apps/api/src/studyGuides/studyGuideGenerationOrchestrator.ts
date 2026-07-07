import type {
  CuratedResourceCatalogRecord,
  CuratedResourceCatalogStore,
  CuratedResourceThemeMapping,
} from '../resourceSuggestions/curatedResourceCatalogStore.js';

export interface StudyGuideGenerationRequest {
  readonly entryId: string;
  readonly originalText: string;
  readonly providerKey: string;
  readonly themeIds: readonly string[];
}

export interface StudyGuideGenerationResponse {
  readonly guideId: string;
  readonly entryId: string;
  readonly providerKey: string;
  readonly generatedAt: string;
  readonly overview: string;
  readonly previewText: string;
  readonly items: readonly StudyGuideItemResponse[];
  readonly reflectionPrompt: StudyGuidePromptResponse;
}

export interface StudyGuideItemResponse {
  readonly id: string;
  readonly kind: string;
  readonly title: string;
  readonly contextLine: string;
  readonly position: number;
  readonly destination: StudyGuideDestinationResponse;
  readonly focusText?: string;
  readonly quote?: string;
  readonly author?: string;
  readonly publishedContext?: string;
}

export interface StudyGuideDestinationResponse {
  readonly providerKey: string;
  readonly contentType: string;
  readonly reference: string;
  readonly url?: string;
  readonly precision: StudyGuideDestinationPrecision;
}

export interface StudyGuidePromptResponse {
  readonly text: string;
}

export type StudyGuideDestinationPrecision =
  | 'verseRange'
  | 'chapter'
  | 'document'
  | 'webFallback';

export interface StudyGuideGenerationOrchestrator {
  generate(
    request: StudyGuideGenerationRequest,
  ): Promise<StudyGuideGenerationResponse>;
}

interface RankedTheme {
  readonly id: string;
  readonly displayName: string;
  readonly requested: boolean;
  readonly weight: number;
}

interface RankedCandidate {
  readonly record: CuratedResourceCatalogRecord;
  readonly primaryTheme: RankedTheme;
  readonly primaryMapping: CuratedResourceThemeMapping;
  readonly confidence: number;
  readonly overlapScore: number;
}

const fallbackTheme: RankedTheme = {
  id: 'reflection',
  displayName: 'Reflection',
  requested: false,
  weight: 0.72,
};

export class CatalogStudyGuideGenerationOrchestrator
  implements StudyGuideGenerationOrchestrator
{
  constructor({
    catalogStore,
    minimumConfidence = 0.62,
    maxItems = 8,
  }: {
    catalogStore: CuratedResourceCatalogStore;
    minimumConfidence?: number;
    maxItems?: number;
  }) {
    this._catalogStore = catalogStore;
    this._minimumConfidence = minimumConfidence;
    this._maxItems = maxItems;
  }

  private readonly _catalogStore: CuratedResourceCatalogStore;
  private readonly _minimumConfidence: number;
  private readonly _maxItems: number;

  async generate(
    request: StudyGuideGenerationRequest,
  ): Promise<StudyGuideGenerationResponse> {
    const normalizedThemeIds = normalizeThemeIds(request.themeIds);
    const effectiveThemes = buildEffectiveThemes(normalizedThemeIds);
    const candidateThemeIds = normalizedThemeIds.length > 0
      ? normalizedThemeIds
      : [fallbackTheme.id];
    const candidates = await this._catalogStore.listCandidatesByThemeIds(
      candidateThemeIds,
    );
    const providerCandidates = candidates.filter(
      (candidate) =>
        normalizeProviderKey(candidate.providerKey) ===
        normalizeProviderKey(request.providerKey),
    );
    const rankedCandidates = rankCandidates({
      requestText: request.originalText,
      candidates: providerCandidates,
      effectiveThemes,
    }).filter((candidate) => candidate.confidence >= this._minimumConfidence);
    const selectedCandidates = selectCandidates(
      rankedCandidates,
      this._targetCount({
        requestText: request.originalText,
        themeCount: effectiveThemes.length,
        availableCount: rankedCandidates.length,
      }),
    );
    const items = selectedCandidates.map((candidate, index) =>
      toItem(candidate, index, request.providerKey),
    );

    return {
      guideId: `study-guide-${request.entryId}`,
      entryId: request.entryId,
      providerKey: request.providerKey,
      generatedAt: new Date().toISOString(),
      overview: buildOverview(effectiveThemes),
      previewText: buildPreviewText(items),
      items,
      reflectionPrompt: {
        text: buildReflectionPrompt(effectiveThemes),
      },
    };
  }

  _targetCount({
    requestText,
    themeCount,
    availableCount,
  }: {
    requestText: string;
    themeCount: number;
    availableCount: number;
  }): number {
    if (availableCount <= 0) {
      return 0;
    }

    const wordCount = countWords(requestText);
    let target = 1;

    if (availableCount >= 2 && (themeCount >= 2 || wordCount >= 60)) {
      target = 2;
    }

    if (availableCount >= 3 && (themeCount >= 4 || wordCount >= 120)) {
      target = 3;
    }

    if (availableCount >= 4 && themeCount >= 6 && wordCount >= 180) {
      target = 4;
    }

    if (availableCount >= 5 && themeCount >= 7 && wordCount >= 240) {
      target = 5;
    }

    return Math.min(this._maxItems, availableCount, target);
  }
}

function buildEffectiveThemes(themeIds: readonly string[]): readonly RankedTheme[] {
  if (themeIds.length === 0) {
    return [fallbackTheme];
  }

  return themeIds.map((themeId) => ({
    id: themeId,
    displayName: toDisplayName(themeId),
    requested: true,
    weight: 0.8,
  }));
}

function rankCandidates({
  requestText,
  candidates,
  effectiveThemes,
}: {
  requestText: string;
  candidates: readonly CuratedResourceCatalogRecord[];
  effectiveThemes: readonly RankedTheme[];
}): readonly RankedCandidate[] {
  const requestTokens = tokenize(requestText);
  const effectiveThemesById = new Map(
    effectiveThemes.map((theme) => [theme.id, theme]),
  );

  return candidates
    .map((record) => {
      const primaryMapping = strongestMapping(record, effectiveThemesById);
      if (primaryMapping == null) {
        return null;
      }

      const primaryTheme = effectiveThemesById.get(primaryMapping.themeId);
      if (primaryTheme == null) {
        return null;
      }

      const overlapScore = calculateTokenOverlap(requestTokens, record);
      const confidence = clampConfidence(
        primaryMapping.weight * 0.5 +
          primaryTheme.weight * 0.2 +
          overlapScore * 0.18 +
          (primaryTheme.requested ? 0.08 : 0) +
          resourceTypeBonus(record),
      );

      return {
        record,
        primaryTheme,
        primaryMapping,
        confidence,
        overlapScore,
      };
    })
    .filter((candidate): candidate is RankedCandidate => candidate != null)
    .sort((left, right) => {
      if (right.confidence !== left.confidence) {
        return right.confidence - left.confidence;
      }

      const leftPriority = resourceTypePriority(left.record);
      const rightPriority = resourceTypePriority(right.record);
      if (leftPriority !== rightPriority) {
        return leftPriority - rightPriority;
      }

      return left.record.catalogKey.localeCompare(right.record.catalogKey);
    });
}

function selectCandidates(
  rankedCandidates: readonly RankedCandidate[],
  targetCount: number,
): readonly RankedCandidate[] {
  if (targetCount <= 0) {
    return [];
  }

  const selected: RankedCandidate[] = [];
  const seenKeys = new Set<string>();

  const pushCandidate = (candidate: RankedCandidate | undefined) => {
    if (candidate == null || seenKeys.has(candidate.record.catalogKey)) {
      return;
    }

    seenKeys.add(candidate.record.catalogKey);
    selected.push(candidate);
  };

  pushCandidate(
    rankedCandidates.find((candidate) => candidate.record.resourceType === 'scripture'),
  );
  if (selected.length < targetCount) {
    pushCandidate(
      rankedCandidates.find(
        (candidate) => resourceKind(candidate.record) === 'conference_talk',
      ),
    );
  }

  for (const candidate of rankedCandidates) {
    if (selected.length >= targetCount) {
      break;
    }

    pushCandidate(candidate);
  }

  return selected.slice(0, targetCount);
}

function strongestMapping(
  record: CuratedResourceCatalogRecord,
  effectiveThemesById: ReadonlyMap<string, RankedTheme>,
): CuratedResourceThemeMapping | undefined {
  let best: CuratedResourceThemeMapping | undefined;
  let bestScore = -1;

  for (const mapping of record.themeMappings) {
    const theme = effectiveThemesById.get(mapping.themeId);
    if (theme == null) {
      continue;
    }

    const score = mapping.weight * theme.weight;
    if (score > bestScore) {
      best = mapping;
      bestScore = score;
    }
  }

  return best;
}

function calculateTokenOverlap(
  requestTokens: ReadonlySet<string>,
  record: CuratedResourceCatalogRecord,
): number {
  if (requestTokens.size === 0) {
    return 0;
  }

  const candidateTokens = tokenize([
    record.title,
    record.description,
    record.contentText,
    record.promptTemplate,
    record.scriptureReference,
  ]
    .filter((value): value is string => typeof value === 'string')
    .join(' '));
  let overlap = 0;

  for (const token of requestTokens) {
    if (candidateTokens.has(token)) {
      overlap += 1;
    }
  }

  return overlap / requestTokens.size;
}

function tokenize(value: string): ReadonlySet<string> {
  return new Set(
    value
      .toLowerCase()
      .split(/[^a-z0-9]+/u)
      .map((token) => token.trim())
      .filter((token) => token.length >= 3),
  );
}

function countWords(value: string): number {
  return value
    .trim()
    .split(/\s+/u)
    .map((word) => word.trim())
    .filter((word) => word.length > 0)
    .length;
}

function toItem(
  candidate: RankedCandidate,
  position: number,
  providerKey: string,
): StudyGuideItemResponse {
  const record = candidate.record;
  const kind = resourceKind(record);
  const themeLabel = candidate.primaryTheme.displayName.toLowerCase();

  if (kind === 'conference_talk') {
    return {
      id: record.catalogKey,
      kind,
      title: record.title,
      contextLine: `A conference talk that supports ${themeLabel}.`,
      position,
      destination: {
        providerKey,
        contentType: 'conference_talk',
        reference: record.title,
        url: record.canonicalUrl,
        precision: 'document',
      },
      author: metadataString(record, 'speaker'),
      publishedContext:
        metadataString(record, 'conference_label') ??
        metadataString(record, 'published_at'),
      quote: metadataString(record, 'quote') ?? record.description,
    };
  }

  return {
    id: record.catalogKey,
    kind: 'scripture',
    title: record.title,
    contextLine: `A scripture anchor for ${themeLabel}.`,
    position,
    destination: {
      providerKey,
      contentType: 'scripture',
      reference: record.scriptureReference ?? record.title,
      url: buildScriptureUrl(record),
      precision: scripturePrecision(record),
    },
    focusText:
      metadataString(record, 'focus_text') ??
      record.description ??
      undefined,
  };
}

function resourceKind(
  record: CuratedResourceCatalogRecord,
): 'scripture' | 'conference_talk' | 'other' {
  if (record.resourceType === 'scripture') {
    return 'scripture';
  }

  if (
    record.resourceType === 'talk_or_article' &&
    (metadataString(record, 'kind') === 'conference_talk' ||
      (record.canonicalUrl?.includes('/study/general-conference/') ?? false))
  ) {
    return 'conference_talk';
  }

  return 'other';
}

function resourceTypePriority(
  record: CuratedResourceCatalogRecord,
): number {
  return resourceKind(record) === 'scripture'
    ? 0
    : resourceKind(record) === 'conference_talk'
      ? 1
      : 2;
}

function resourceTypeBonus(record: CuratedResourceCatalogRecord): number {
  return resourceKind(record) === 'scripture'
    ? 0.12
    : resourceKind(record) === 'conference_talk'
      ? 0.08
      : 0.03;
}

function buildScriptureUrl(
  record: CuratedResourceCatalogRecord,
): string | undefined {
  const canonicalUrl = record.canonicalUrl;
  if (canonicalUrl == null) {
    return undefined;
  }

  const verseStart = metadataNumber(record, 'verse_start');
  if (verseStart == null) {
    return canonicalUrl;
  }

  const url = new URL(canonicalUrl);
  const verseAnchor = `p${verseStart}`;
  url.searchParams.set('id', verseAnchor);
  url.hash = verseAnchor;
  return url.toString();
}

function scripturePrecision(
  record: CuratedResourceCatalogRecord,
): StudyGuideDestinationPrecision {
  return metadataNumber(record, 'verse_start') == null
    ? 'chapter'
    : 'verseRange';
}

function buildOverview(
  themes: readonly RankedTheme[],
): string {
  if (themes.length === 0) {
    return 'A gospel study guide built from this reflection.';
  }

  const themeNames = themes
    .slice(0, 2)
    .map((theme) => theme.displayName.toLowerCase())
    .join(' and ');
  return `A gospel study guide built around ${themeNames}.`;
}

function buildPreviewText(items: readonly StudyGuideItemResponse[]): string {
  if (items.length === 0) {
    return 'A gospel study guide built from this reflection.';
  }

  if (items.length === 1) {
    const firstItem = items[0]!;
    return firstItem.title;
  }

  const firstItem = items[0]!;

  return `${firstItem.title} and ${items.length - 1} more resource${
    items.length - 1 === 1 ? '' : 's'
  }`;
}

function buildReflectionPrompt(themes: readonly RankedTheme[]): string {
  if (themes.length === 0) {
    return 'As you study these resources, what feels most worth carrying into the rest of your day?';
  }

  const themeNames = themes
    .slice(0, 2)
    .map((theme) => theme.displayName.toLowerCase())
    .join(' and ');

  return `As you study these resources, what do you notice about ${themeNames} in your life right now?`;
}

function normalizeThemeIds(themeIds: readonly string[]): readonly string[] {
  return [...new Set(
    themeIds.map((themeId) => themeId.trim().toLowerCase()).filter(Boolean),
  )];
}

function normalizeProviderKey(providerKey: string | undefined): string {
  return providerKey?.trim().toLowerCase() ?? '';
}

function metadataString(
  record: CuratedResourceCatalogRecord,
  key: string,
): string | undefined {
  const value = record.metadata[key];
  return typeof value === 'string' && value.trim().length > 0
    ? value
    : undefined;
}

function metadataNumber(
  record: CuratedResourceCatalogRecord,
  key: string,
): number | undefined {
  const value = record.metadata[key];
  return typeof value === 'number' && Number.isFinite(value) ? value : undefined;
}

function clampConfidence(value: number): number {
  const bounded = Math.max(0, Math.min(1, value));
  return Math.round(bounded * 100) / 100;
}

function toDisplayName(themeId: string): string {
  return themeId
    .split(/[-_ ]+/u)
    .filter(Boolean)
    .map((part) => part.charAt(0).toUpperCase() + part.slice(1))
    .join(' ');
}
