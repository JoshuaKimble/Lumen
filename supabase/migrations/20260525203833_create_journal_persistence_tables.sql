-- Lumen journal persistence schema (M6 foundation)
-- Creates user-owned journal tables for future local-first cloud sync.

create table if not exists public.journal_entries (
  user_id uuid not null references auth.users (id) on delete cascade,
  id text not null,
  title text,
  summary text,
  source text not null,
  original_text text not null,
  rewritten_text text not null default '',
  last_regenerated_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  client_updated_at timestamptz not null default timezone('utc', now()),
  version bigint not null default 1,
  sync_state text not null default 'synced',
  primary key (user_id, id),
  constraint journal_entries_id_not_blank check (btrim(id) <> ''),
  constraint journal_entries_title_not_blank
    check (title is null or btrim(title) <> ''),
  constraint journal_entries_summary_not_blank
    check (summary is null or btrim(summary) <> ''),
  constraint journal_entries_source_check
    check (source in ('voice', 'text')),
  constraint journal_entries_original_text_not_blank
    check (btrim(original_text) <> ''),
  constraint journal_entries_version_positive
    check (version > 0),
  constraint journal_entries_sync_state_check
    check (
      sync_state in (
        'synced',
        'pending_upsert',
        'pending_delete',
        'conflict'
      )
    )
);

create index if not exists journal_entries_user_updated_at_idx
  on public.journal_entries (user_id, updated_at desc);

create index if not exists journal_entries_user_client_updated_at_idx
  on public.journal_entries (user_id, client_updated_at desc);

create index if not exists journal_entries_user_sync_state_idx
  on public.journal_entries (user_id, sync_state);

create table if not exists public.journal_themes (
  user_id uuid not null references auth.users (id) on delete cascade,
  entry_id text not null,
  theme_id text not null,
  name text not null,
  display_name text not null,
  weight double precision,
  created_at timestamptz not null default timezone('utc', now()),
  primary key (user_id, entry_id, theme_id),
  constraint journal_themes_entry_id_not_blank check (btrim(entry_id) <> ''),
  constraint journal_themes_theme_id_not_blank check (btrim(theme_id) <> ''),
  constraint journal_themes_name_not_blank check (btrim(name) <> ''),
  constraint journal_themes_display_name_not_blank
    check (btrim(display_name) <> ''),
  constraint journal_themes_weight_positive
    check (weight is null or weight >= 0),
  constraint journal_themes_entry_fk
    foreign key (user_id, entry_id)
    references public.journal_entries (user_id, id)
    on delete cascade
);

create index if not exists journal_themes_user_theme_id_idx
  on public.journal_themes (user_id, theme_id);

create table if not exists public.related_resources (
  user_id uuid not null references auth.users (id) on delete cascade,
  resource_id text not null,
  entry_id text,
  theme_id text,
  title text not null,
  type text not null,
  source_type text not null,
  match_reason text not null,
  confidence double precision not null default 0.75,
  url text,
  scripture_reference text,
  description text,
  created_at timestamptz not null default timezone('utc', now()),
  primary key (user_id, resource_id),
  constraint related_resources_resource_id_not_blank
    check (btrim(resource_id) <> ''),
  constraint related_resources_entry_id_not_blank
    check (entry_id is null or btrim(entry_id) <> ''),
  constraint related_resources_theme_id_not_blank
    check (theme_id is null or btrim(theme_id) <> ''),
  constraint related_resources_title_not_blank check (btrim(title) <> ''),
  constraint related_resources_type_check
    check (
      type in (
        'reflection_prompt',
        'scripture',
        'talk_or_article',
        'video_or_audio',
        'quote',
        'exercise',
        'internal_entry_link'
      )
    ),
  constraint related_resources_source_type_check
    check (source_type in ('curated', 'ai_mapped', 'user_created')),
  constraint related_resources_match_reason_not_blank
    check (btrim(match_reason) <> ''),
  constraint related_resources_confidence_range
    check (confidence >= 0 and confidence <= 1),
  constraint related_resources_url_not_blank
    check (url is null or btrim(url) <> ''),
  constraint related_resources_scripture_reference_not_blank
    check (
      scripture_reference is null
      or btrim(scripture_reference) <> ''
    ),
  constraint related_resources_description_not_blank
    check (description is null or btrim(description) <> ''),
  constraint related_resources_entry_fk
    foreign key (user_id, entry_id)
    references public.journal_entries (user_id, id)
    on delete cascade
);

create index if not exists related_resources_user_entry_id_idx
  on public.related_resources (user_id, entry_id);

create index if not exists related_resources_user_theme_id_idx
  on public.related_resources (user_id, theme_id);

create table if not exists public.resource_feedback (
  user_id uuid not null references auth.users (id) on delete cascade,
  resource_id text not null,
  entry_id text,
  theme_id text,
  action text not null,
  note text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  client_updated_at timestamptz not null default timezone('utc', now()),
  version bigint not null default 1,
  sync_state text not null default 'synced',
  primary key (user_id, resource_id),
  constraint resource_feedback_resource_id_not_blank
    check (btrim(resource_id) <> ''),
  constraint resource_feedback_entry_id_not_blank
    check (entry_id is null or btrim(entry_id) <> ''),
  constraint resource_feedback_theme_id_not_blank
    check (theme_id is null or btrim(theme_id) <> ''),
  constraint resource_feedback_action_check
    check (action in ('save', 'dismiss', 'not_helpful')),
  constraint resource_feedback_note_length
    check (note is null or char_length(note) <= 500),
  constraint resource_feedback_note_not_blank
    check (note is null or btrim(note) <> ''),
  constraint resource_feedback_version_positive
    check (version > 0),
  constraint resource_feedback_sync_state_check
    check (
      sync_state in (
        'synced',
        'pending_upsert',
        'pending_delete',
        'conflict'
      )
    ),
  constraint resource_feedback_entry_fk
    foreign key (user_id, entry_id)
    references public.journal_entries (user_id, id)
    on delete cascade
);

create index if not exists resource_feedback_user_entry_id_idx
  on public.resource_feedback (user_id, entry_id);

create index if not exists resource_feedback_user_theme_id_idx
  on public.resource_feedback (user_id, theme_id);

create index if not exists resource_feedback_user_sync_state_idx
  on public.resource_feedback (user_id, sync_state);

create or replace function public.set_journal_row_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;

drop trigger if exists set_journal_entries_updated_at on public.journal_entries;

create trigger set_journal_entries_updated_at
before update on public.journal_entries
for each row
execute function public.set_journal_row_updated_at();

drop trigger if exists set_resource_feedback_updated_at
  on public.resource_feedback;

create trigger set_resource_feedback_updated_at
before update on public.resource_feedback
for each row
execute function public.set_journal_row_updated_at();

comment on table public.journal_entries is
  'User-owned journal entry source of truth for local-first sync hydration.';

comment on table public.journal_themes is
  'Normalized theme rows derived from journal entries for cloud-backed lookup and summaries.';

comment on table public.related_resources is
  'User-visible related resources that may be attached to a journal entry or theme context.';

comment on table public.resource_feedback is
  'Per-user feedback signals for related resources, keyed by resource identifier.';

comment on column public.journal_entries.user_id is
  'Owned by auth.users.id and reserved for authenticated-user RLS policies in M7.';

comment on column public.journal_entries.client_updated_at is
  'Latest client-side modification timestamp used for future merge and retry logic.';

comment on column public.journal_entries.sync_state is
  'Client-managed sync lifecycle marker. Tables remain unexposed until RLS and grants land.';

comment on column public.related_resources.theme_id is
  'Semantic theme key from the Flutter app. It is intentionally not a strict foreign key for theme-only suggestions.';

comment on column public.resource_feedback.sync_state is
  'Client-managed sync lifecycle marker for queued or conflicted feedback writes.';

insert into public.schema_migrations_meta (name)
values ('20260525203833_create_journal_persistence_tables')
on conflict (name) do nothing;
