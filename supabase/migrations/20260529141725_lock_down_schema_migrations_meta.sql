-- Lock down internal migration metadata that should not be exposed via Data API.

alter table public.schema_migrations_meta enable row level security;

revoke all on table public.schema_migrations_meta from anon, authenticated;
