import type {
  CuratedResourceCatalogRecord,
  CuratedResourceCatalogStore,
} from './curatedResourceCatalogStore.js';

const baselineCatalogRecords: readonly CuratedResourceCatalogRecord[] = [
  {
    catalogKey: 'catalog:scripture:psalm-46-10',
    recordKind: 'resource',
    resourceType: 'scripture',
    providerKey: 'gospel_library',
    traditionKey: 'lds',
    title: 'Psalm 46:10',
    description: 'Be still, and know that I am God.',
    canonicalUrl:
      'https://www.churchofjesuschrist.org/study/scriptures/ot/ps/46?lang=eng',
    scriptureReference: 'Psalm 46:10',
    contentText: 'Psalm 46:10 Be still, and know that I am God.',
    metadata: {
      kind: 'scripture',
      canonicalBook: 'Psalms',
      focus_text: 'Be still before the Lord and trust him.',
      book: 'Psalms',
      chapter: 46,
      verse_start: 10,
      precision_target: 'chapter',
      provider_reference: 'Psalm 46:10',
    },
    isActive: true,
    themeMappings: [
      { themeId: 'faith', weight: 0.95 },
      { themeId: 'peace', weight: 0.72 },
      { themeId: 'reflection', weight: 0.6 },
    ],
  },
  {
    catalogKey: 'catalog:scripture:alma-37-6',
    recordKind: 'resource',
    resourceType: 'scripture',
    providerKey: 'gospel_library',
    traditionKey: 'lds',
    title: 'Alma 37:6',
    description:
      'By small and simple things are great things brought to pass.',
    canonicalUrl:
      'https://www.churchofjesuschrist.org/study/scriptures/bofm/alma/37?lang=eng',
    scriptureReference: 'Alma 37:6',
    contentText:
      'Alma 37:6 By small and simple things are great things brought to pass.',
    metadata: {
      kind: 'scripture',
      canonicalBook: 'Alma',
      focus_text: 'Notice how small and faithful actions can change the course of a day.',
      book: 'Alma',
      chapter: 37,
      verse_start: 6,
      precision_target: 'chapter',
      provider_reference: 'Alma 37:6',
    },
    isActive: true,
    themeMappings: [
      { themeId: 'faith', weight: 0.72 },
      { themeId: 'work', weight: 0.7 },
      { themeId: 'stress', weight: 0.64 },
      { themeId: 'reflection', weight: 0.57 },
    ],
  },
  {
    catalogKey: 'catalog:scripture:3-nephi-1-6-12',
    recordKind: 'resource',
    resourceType: 'scripture',
    providerKey: 'gospel_library',
    traditionKey: 'lds',
    title: '3 Nephi 1:6-12',
    description:
      'A passage about holding to faith when the wait feels long.',
    canonicalUrl:
      'https://www.churchofjesuschrist.org/study/scriptures/bofm/3-ne/1?lang=eng',
    scriptureReference: '3 Nephi 1:6-12',
    contentText:
      '3 Nephi 1:6-12 faith under pressure, patience, and deliverance.',
    metadata: {
      kind: 'scripture',
      canonicalBook: '3 Nephi',
      focus_text: 'Read verses 6-12 for a reminder that faith can steady you while you wait.',
      book: '3 Nephi',
      chapter: 1,
      verse_start: 6,
      verse_end: 12,
      precision_target: 'chapter',
      provider_reference: '3 Nephi 1:6-12',
    },
    isActive: true,
    themeMappings: [
      { themeId: 'faith', weight: 0.88 },
      { themeId: 'hope', weight: 0.74 },
      { themeId: 'reflection', weight: 0.61 },
    ],
  },
  {
    catalogKey: 'catalog:talk:nourish-the-roots',
    recordKind: 'resource',
    resourceType: 'talk_or_article',
    providerKey: 'gospel_library',
    traditionKey: 'lds',
    title: 'Nourish the Roots, and the Branches Will Grow',
    description: 'A talk about steady spiritual growth and deeper roots in Christ.',
    canonicalUrl:
      'https://www.churchofjesuschrist.org/study/general-conference/2024/10/51uchtdorf?lang=eng',
    contentText:
      'General conference talk about nourishment, roots, and growing branches.',
    metadata: {
      kind: 'conference_talk',
      speaker: 'Dieter F. Uchtdorf',
      conference_label: 'General Conference, October 2024',
      published_at: '2024-10',
      provider_reference: 'Nourish the Roots, and the Branches Will Grow',
      quote: 'When we nourish our roots, our branches can grow.',
    },
    isActive: true,
    themeMappings: [
      { themeId: 'faith', weight: 0.79 },
      { themeId: 'work', weight: 0.72 },
      { themeId: 'reflection', weight: 0.6 },
    ],
  },
  {
    catalogKey: 'catalog:article:work-boundaries',
    recordKind: 'resource',
    resourceType: 'talk_or_article',
    providerKey: 'lumen_curated',
    traditionKey: 'general_christian',
    title: 'Hold one boundary this week',
    description:
      'A curated long-form reflection on protecting rest and attention during demanding work periods.',
    canonicalUrl: 'https://example.com/resources/work-boundaries',
    contentText:
      'Curated article about work boundaries, rest, and sustainable reflection.',
    metadata: { kind: 'article' },
    isActive: true,
    themeMappings: [
      { themeId: 'work', weight: 0.94 },
      { themeId: 'boundaries', weight: 0.9 },
      { themeId: 'stress', weight: 0.71 },
    ],
  },
  {
    catalogKey: 'catalog:prompt:stress-breathing-checkin',
    recordKind: 'prompt_template',
    resourceType: 'reflection_prompt',
    providerKey: 'lumen_curated',
    traditionKey: 'general',
    title: 'Notice the first signal',
    description: 'Prompt template for stress-oriented body awareness reflection.',
    promptTemplate:
      'What was the first signal in your body that told you stress was rising, and what do you wish you had needed in that moment?',
    contentText: 'Reflection prompt template for stress and regulation.',
    metadata: { kind: 'reflection_prompt_template' },
    isActive: true,
    themeMappings: [
      { themeId: 'stress', weight: 0.96 },
      { themeId: 'fatigue', weight: 0.68 },
    ],
  },
  {
    catalogKey: 'catalog:prompt:work-boundary-review',
    recordKind: 'prompt_template',
    resourceType: 'reflection_prompt',
    providerKey: 'lumen_curated',
    traditionKey: 'general',
    title: 'Review the boundary you need',
    description:
      'Prompt template for clarifying one concrete work boundary and how to communicate it.',
    promptTemplate:
      'What is one boundary that would reduce your work stress this week, and how can you communicate it clearly?',
    contentText:
      'Reflection prompt template for work pressure, deadlines, and boundaries.',
    metadata: { kind: 'reflection_prompt_template' },
    isActive: true,
    themeMappings: [
      { themeId: 'work', weight: 0.92 },
      { themeId: 'stress', weight: 0.83 },
    ],
  },
  {
    catalogKey: 'catalog:exercise:gratitude-three-specifics',
    recordKind: 'resource',
    resourceType: 'exercise',
    providerKey: 'lumen_curated',
    traditionKey: 'general',
    title: 'Three specifics gratitude exercise',
    description:
      'List three specific things from today and why each one mattered to you.',
    contentText:
      'Guided gratitude exercise focused on concrete detail instead of vague positivity.',
    metadata: { kind: 'exercise' },
    isActive: true,
    themeMappings: [
      { themeId: 'gratitude', weight: 0.9 },
      { themeId: 'reflection', weight: 0.62 },
    ],
  },
  {
    catalogKey: 'catalog:prompt:reflection-next-honest-step',
    recordKind: 'prompt_template',
    resourceType: 'reflection_prompt',
    providerKey: 'lumen_curated',
    traditionKey: 'general',
    title: 'Name the next honest step',
    description: 'Fallback reflection prompt when no stronger theme match exists.',
    promptTemplate:
      'What is the next honest step you can take, and what would make it easier to follow through today?',
    contentText:
      'General reflection prompt template for honest next steps and self-awareness.',
    metadata: { kind: 'reflection_prompt_template' },
    isActive: true,
    themeMappings: [{ themeId: 'reflection', weight: 0.95 }],
  },
];

export class InMemoryCuratedResourceCatalogStore
  implements CuratedResourceCatalogStore
{
  constructor(
    records: readonly CuratedResourceCatalogRecord[] = baselineCatalogRecords,
  ) {
    this._records = records;
  }

  private readonly _records: readonly CuratedResourceCatalogRecord[];

  async listCandidatesByThemeIds(
    themeIds: readonly string[],
  ): Promise<readonly CuratedResourceCatalogRecord[]> {
    const normalizedThemeIds = new Set(
      themeIds.map((themeId) => themeId.trim().toLowerCase()).filter(Boolean),
    );

    return this._records.filter((record) =>
      record.isActive &&
      record.themeMappings.some((mapping) =>
        normalizedThemeIds.has(mapping.themeId),
      ),
    );
  }
}
