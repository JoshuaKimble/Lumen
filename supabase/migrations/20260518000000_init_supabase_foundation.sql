-- Lumen Supabase foundation schema (M1 baseline)
-- This migration establishes deterministic local structure for future M2+ work.

create extension if not exists pgcrypto;

create table if not exists public.schema_migrations_meta (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  applied_at timestamptz not null default now()
);

insert into public.schema_migrations_meta (name)
values ('20260518000000_init_supabase_foundation')
on conflict (name) do nothing;
