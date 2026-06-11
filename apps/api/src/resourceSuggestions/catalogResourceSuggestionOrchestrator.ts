import type {
  JournalTheme,
  ResourceSuggestion,
  ResourceSuggestionRequest,
  ResourceSuggestionResult,
  ThemeDetectionRequest,
  ThemeDetectionResult,
} from '../ai/aiGatewayProvider.js';
import type {
  CuratedResourceCatalogRecord,
  CuratedResourceCatalogStore,
  CuratedResourceThemeMapping,
} from './curatedResourceCatalogStore.js';

interface ThemeDetector {
  detectThemes(request: ThemeDetectionRequest): Promise<ThemeDetectionResult>;
}

export interface ResourceSuggestionOrchestrator {
  suggest(
    request: ResourceSuggestionRequest,
  ): Promise<ResourceSuggestionResult>;
}

interface RankedTheme extends JournalTheme {
  readonly weight: number;
  readonly requested: boolean;
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
  name: 'reflection',
  displayName: 'Reflection',
  weight: 0.72,
  requested: false,
};

export class CatalogResourceSuggestionOrchestrator
  implements ResourceSuggestionOrchestrator
{
  constructor({
    themeDetector,
    catalogStore,
    maxSuggestions = 5,
    minimumConfidence = 0.62,
  }: {
    themeDetector: ThemeDetector;
    catalogStore: CuratedResourceCatalogStore;
    maxSuggestions?: number;
    minimumConfidence?: number;
  }) {
    this._themeDetector = themeDetector;
    this._catalogStore = catalogStore;
    this._maxSuggestions = maxSuggestions;
    this._minimumConfidence = minimumConfidence;
  }

  private readonly _themeDetector: ThemeDetector;
  private readonly _catalogStore: CuratedResourceCatalogStore;
  private readonly _maxSuggestions: number;
  private readonly _minimumConfidence: number;

  async suggest(
    request: ResourceSuggestionRequest,
  ): Promise<ResourceSuggestionResult> {
    const detectedThemes = await this._themeDetector.detectThemes({
      text: request.text,
    });
    const effectiveThemes = buildEffectiveThemes(detectedThemes, request.themeIds);
    const candidates = await this._catalogStore.listCandidatesByThemeIds(
      effectiveThemes.map((theme) => theme.id),
    );
    const ranked = rankCandidates({
      requestText: request.text,
      candidates,
      effectiveThemes,
    })
      .filter((candidate) => candidate.confidence >= this._minimumConfidence)
      .slice(0, this._maxSuggestions);

    if (ranked.length === 0) {
      return {
        suggestions: [buildFallbackSuggestion(request.text)],
      };
    }

    return {
      suggestions: ranked.map(toSuggestion),
    };
  }
}

function buildEffectiveThemes(
  detectedResult: ThemeDetectionResult,
  requestedThemeIds: readonly string[] | undefined,
): readonly RankedTheme[] {
  const detectedThemes = detectedResult.themes.map((theme) => ({
    ...theme,
    weight: normalizeThemeWeight(theme.weight),
    requested: false,
  }));
  const detectedById = new Map(
    detectedThemes.map((theme) => [theme.id.toLowerCase(), theme]),
  );
  const normalizedRequestedIds = [...new Set(
    (requestedThemeIds ?? [])
      .map((themeId) => themeId.trim().toLowerCase())
      .filter(Boolean),
  )];

  if (normalizedRequestedIds.length > 0) {
    return normalizedRequestedIds.map((themeId) => {
      const detected = detectedById.get(themeId);
      if (detected != null) {
        return {
          ...detected,
          weight: Math.max(detected.weight, 0.8),
          requested: true,
        };
      }

      return {
        id: themeId,
        name: themeId,
        displayName: toDisplayName(themeId),
        weight: 0.8,
        requested: true,
      };
    });
  }

  return detectedThemes.length > 0 ? detectedThemes : [fallbackTheme];
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
        primaryMapping.weight * 0.52 +
          primaryTheme.weight * 0.24 +
          overlapScore * 0.16 +
          (primaryTheme.requested ? 0.08 : 0) +
          (record.recordKind === 'prompt_template' ? 0.05 : 0),
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

      return left.record.catalogKey.localeCompare(right.record.catalogKey);
    });
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

function toSuggestion(candidate: RankedCandidate): ResourceSuggestion {
  return {
    id: candidate.record.catalogKey,
    type: candidate.record.resourceType,
    title: candidate.record.title,
    description:
      candidate.record.recordKind === 'prompt_template'
        ? candidate.record.promptTemplate
        : candidate.record.description,
    url: candidate.record.canonicalUrl,
    scriptureReference: candidate.record.scriptureReference,
    sourceType: 'curated',
    matchReason: buildMatchReason(candidate),
    confidence: candidate.confidence,
    themeId: candidate.primaryTheme.id,
  };
}

function buildMatchReason(candidate: RankedCandidate): string {
  const themeLabel = candidate.primaryTheme.displayName;
  const overlapPhrase =
    candidate.overlapScore >= 0.2
      ? ' It also overlaps with the language in this entry.'
      : '';

  return `Matched curated ${candidate.record.resourceType.replaceAll('_', ' ')} content for ${themeLabel.toLowerCase()} (${Math.round(candidate.primaryMapping.weight * 100)}% theme affinity).${overlapPhrase}`;
}

function buildFallbackSuggestion(text: string): ResourceSuggestion {
  const title = text.trim().length === 0
    ? 'Name the next honest step'
    : 'Reflect on the next honest step';

  return {
    id: 'fallback-reflection-prompt',
    type: 'reflection_prompt',
    title,
    description:
      'What is the next honest step you can take, and what would make it easier to follow through today?',
    sourceType: 'ai_mapped',
    matchReason:
      'Returned a fallback reflection prompt because no curated resource crossed the confidence threshold.',
    confidence: 0.64,
    themeId: fallbackTheme.id,
  };
}

function normalizeThemeWeight(weight: number | undefined): number {
  if (weight == null || !Number.isFinite(weight)) {
    return 0.7;
  }

  return clampConfidence(weight);
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
