-- Lumen Supabase deterministic local seed (M1 foundation)
-- Keep this file idempotent.

insert into public.schema_migrations_meta (name)
values ('seed:baseline')
on conflict (name) do nothing;
