-- Lumen curated resource catalog foundation (#108)
-- Creates server-owned catalog tables that future ranking can retrieve from
-- without mixing catalog source-of-truth data into user-owned suggestion rows.

create table if not exists public.curated_resource_catalog (
  catalog_key text primary key,
  record_kind text not null,
  resource_type text not null,
  provider_key text,
  tradition_key text,
  title text not null,
  description text,
  canonical_url text,
  scripture_reference text,
  prompt_template text,
  content_text text,
  metadata jsonb not null default '{}'::jsonb,
  is_active boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint curated_resource_catalog_key_not_blank
    check (btrim(catalog_key) <> ''),
  constraint curated_resource_catalog_record_kind_check
    check (record_kind in ('resource', 'prompt_template')),
  constraint curated_resource_catalog_resource_type_check
    check (
      resource_type in (
        'reflection_prompt',
        'scripture',
        'talk_or_article',
        'video_or_audio',
        'quote',
        'exercise',
        'internal_entry_link'
      )
    ),
  constraint curated_resource_catalog_provider_key_not_blank
    check (provider_key is null or btrim(provider_key) <> ''),
  constraint curated_resource_catalog_tradition_key_not_blank
    check (tradition_key is null or btrim(tradition_key) <> ''),
  constraint curated_resource_catalog_title_not_blank
    check (btrim(title) <> ''),
  constraint curated_resource_catalog_description_not_blank
    check (description is null or btrim(description) <> ''),
  constraint curated_resource_catalog_canonical_url_not_blank
    check (canonical_url is null or btrim(canonical_url) <> ''),
  constraint curated_resource_catalog_scripture_reference_not_blank
    check (
      scripture_reference is null
      or btrim(scripture_reference) <> ''
    ),
  constraint curated_resource_catalog_prompt_template_not_blank
    check (prompt_template is null or btrim(prompt_template) <> ''),
  constraint curated_resource_catalog_content_text_not_blank
    check (content_text is null or btrim(content_text) <> ''),
  constraint curated_resource_catalog_metadata_object_check
    check (jsonb_typeof(metadata) = 'object'),
  constraint curated_resource_catalog_prompt_template_required_check
    check (
      (record_kind = 'prompt_template' and prompt_template is not null)
      or record_kind = 'resource'
    )
);

create index if not exists curated_resource_catalog_active_type_idx
  on public.curated_resource_catalog (is_active, resource_type);

create index if not exists curated_resource_catalog_tradition_provider_idx
  on public.curated_resource_catalog (tradition_key, provider_key);

create table if not exists public.curated_resource_theme_mappings (
  catalog_key text not null,
  theme_id text not null,
  weight double precision not null default 1,
  created_at timestamptz not null default timezone('utc', now()),
  primary key (catalog_key, theme_id),
  constraint curated_resource_theme_mappings_theme_id_not_blank
    check (btrim(theme_id) <> ''),
  constraint curated_resource_theme_mappings_weight_positive
    check (weight > 0 and weight <= 1),
  constraint curated_resource_theme_mappings_catalog_fk
    foreign key (catalog_key)
    references public.curated_resource_catalog (catalog_key)
    on delete cascade
);

create index if not exists curated_resource_theme_mappings_theme_idx
  on public.curated_resource_theme_mappings (theme_id, weight desc);

create or replace function public.set_curated_resource_catalog_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;

drop trigger if exists set_curated_resource_catalog_updated_at
  on public.curated_resource_catalog;

create trigger set_curated_resource_catalog_updated_at
before update on public.curated_resource_catalog
for each row
execute function public.set_curated_resource_catalog_updated_at();

revoke all on table public.curated_resource_catalog from anon;
revoke all on table public.curated_resource_catalog from authenticated;
revoke all on table public.curated_resource_theme_mappings from anon;
revoke all on table public.curated_resource_theme_mappings from authenticated;

alter table public.curated_resource_catalog enable row level security;
alter table public.curated_resource_theme_mappings enable row level security;

comment on table public.curated_resource_catalog is
  'Server-owned curated catalog source of truth for future resource retrieval and ranking.';

comment on table public.curated_resource_theme_mappings is
  'Reusable semantic mappings between curated catalog records and journal theme ids.';

comment on column public.curated_resource_catalog.record_kind is
  'Distinguishes fixed curated resources from prompt-template-backed catalog records.';

comment on column public.curated_resource_catalog.metadata is
  'Extensible structured metadata for provider/tradition/routing details without fragmenting the schema early.';

comment on column public.curated_resource_theme_mappings.weight is
  'Relative theme affinity used by future candidate retrieval and ranking.';

insert into public.schema_migrations_meta (name)
values ('20260610120000_create_curated_resource_catalog_tables')
on conflict (name) do nothing;
