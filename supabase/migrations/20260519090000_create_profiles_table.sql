-- Lumen profiles schema (M3 foundation)
-- Creates the user-owned profile row that later milestones hydrate and edit.

create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  email text not null,
  display_name text,
  rewrite_tone text not null default 'balanced',
  preserve_voice boolean not null default true,
  preferred_scripture_app text not null default 'none',
  theme_preference text not null default 'system',
  onboarding_completed boolean not null default false,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint profiles_email_not_blank check (btrim(email) <> ''),
  constraint profiles_display_name_not_blank
    check (display_name is null or btrim(display_name) <> ''),
  constraint profiles_rewrite_tone_check
    check (rewrite_tone in ('balanced', 'gentle', 'encouraging', 'reflective')),
  constraint profiles_preferred_scripture_app_check
    check (
      preferred_scripture_app in (
        'none',
        'gospel_library',
        'you_version',
        'bible_gateway',
        'catholic'
      )
    ),
  constraint profiles_theme_preference_check
    check (theme_preference in ('system', 'light', 'dark'))
);

create unique index if not exists profiles_email_lower_idx
  on public.profiles (lower(email));

create or replace function public.set_profiles_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;

drop trigger if exists set_profiles_updated_at on public.profiles;

create trigger set_profiles_updated_at
before update on public.profiles
for each row
execute function public.set_profiles_updated_at();

comment on table public.profiles is
  'User-owned profile row keyed 1:1 to auth.users for onboarding and preferences.';

comment on column public.profiles.id is
  'Matches auth.users.id and should be enforced by authenticated-user RLS policies.';

comment on column public.profiles.onboarding_completed is
  'Controls first-run routing after email verification and profile setup.';

insert into public.schema_migrations_meta (name)
values ('20260519090000_create_profiles_table')
on conflict (name) do nothing;
