-- Lumen Supabase deterministic local seed (M1 foundation)
-- Keep this file idempotent.

insert into public.schema_migrations_meta (name)
values ('seed:baseline')
on conflict (name) do nothing;

insert into public.curated_resource_catalog (
  catalog_key,
  record_kind,
  resource_type,
  provider_key,
  tradition_key,
  title,
  description,
  canonical_url,
  scripture_reference,
  prompt_template,
  content_text,
  metadata,
  is_active
)
values
  (
    'catalog:scripture:psalm-46-10',
    'resource',
    'scripture',
    'lds_gospel_library',
    'lds',
    'Psalm 46:10',
    'Be still, and know that I am God.',
    'https://www.churchofjesuschrist.org/study/scriptures/ot/ps/46',
    'Psalm 46:10',
    null,
    'Psalm 46:10 Be still, and know that I am God.',
    '{"kind":"scripture","canonical_book":"Psalms"}'::jsonb,
    true
  ),
  (
    'catalog:article:work-boundaries',
    'resource',
    'talk_or_article',
    'lumen_curated',
    'general_christian',
    'Hold one boundary this week',
    'A curated long-form reflection on protecting rest and attention during demanding work periods.',
    'https://example.com/resources/work-boundaries',
    null,
    null,
    'Curated article about work boundaries, rest, and sustainable reflection.',
    '{"kind":"article"}'::jsonb,
    true
  ),
  (
    'catalog:prompt:stress-breathing-checkin',
    'prompt_template',
    'reflection_prompt',
    'lumen_curated',
    'general',
    'Notice the first signal',
    'Prompt template for stress-oriented body awareness reflection.',
    null,
    null,
    'What was the first signal in your body that told you stress was rising, and what do you wish you had needed in that moment?',
    'Reflection prompt template for stress and regulation.',
    '{"kind":"reflection_prompt_template"}'::jsonb,
    true
  ),
  (
    'catalog:prompt:work-boundary-review',
    'prompt_template',
    'reflection_prompt',
    'lumen_curated',
    'general',
    'Review the boundary you need',
    'Prompt template for clarifying one concrete work boundary and how to communicate it.',
    null,
    null,
    'What is one boundary that would reduce your work stress this week, and how can you communicate it clearly?',
    'Reflection prompt template for work pressure, deadlines, and boundaries.',
    '{"kind":"reflection_prompt_template"}'::jsonb,
    true
  ),
  (
    'catalog:exercise:gratitude-three-specifics',
    'resource',
    'exercise',
    'lumen_curated',
    'general',
    'Three specifics gratitude exercise',
    'List three specific things from today and why each one mattered to you.',
    null,
    null,
    null,
    'Guided gratitude exercise focused on concrete detail instead of vague positivity.',
    '{"kind":"exercise"}'::jsonb,
    true
  ),
  (
    'catalog:prompt:reflection-next-honest-step',
    'prompt_template',
    'reflection_prompt',
    'lumen_curated',
    'general',
    'Name the next honest step',
    'Fallback reflection prompt when no stronger theme match exists.',
    null,
    null,
    'What is the next honest step you can take, and what would make it easier to follow through today?',
    'General reflection prompt template for honest next steps and self-awareness.',
    '{"kind":"reflection_prompt_template"}'::jsonb,
    true
  )
on conflict (catalog_key) do update
set
  record_kind = excluded.record_kind,
  resource_type = excluded.resource_type,
  provider_key = excluded.provider_key,
  tradition_key = excluded.tradition_key,
  title = excluded.title,
  description = excluded.description,
  canonical_url = excluded.canonical_url,
  scripture_reference = excluded.scripture_reference,
  prompt_template = excluded.prompt_template,
  content_text = excluded.content_text,
  metadata = excluded.metadata,
  is_active = excluded.is_active;

insert into public.curated_resource_theme_mappings (
  catalog_key,
  theme_id,
  weight
)
values
  ('catalog:scripture:psalm-46-10', 'faith', 0.95),
  ('catalog:scripture:psalm-46-10', 'peace', 0.72),
  ('catalog:article:work-boundaries', 'work', 0.94),
  ('catalog:article:work-boundaries', 'boundaries', 0.9),
  ('catalog:article:work-boundaries', 'stress', 0.71),
  ('catalog:prompt:stress-breathing-checkin', 'stress', 0.96),
  ('catalog:prompt:stress-breathing-checkin', 'fatigue', 0.68),
  ('catalog:prompt:work-boundary-review', 'work', 0.92),
  ('catalog:prompt:work-boundary-review', 'stress', 0.83),
  ('catalog:exercise:gratitude-three-specifics', 'gratitude', 0.9),
  ('catalog:exercise:gratitude-three-specifics', 'reflection', 0.62),
  ('catalog:prompt:reflection-next-honest-step', 'reflection', 0.95)
on conflict (catalog_key, theme_id) do update
set
  weight = excluded.weight;
