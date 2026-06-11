-- Lumen server-managed user capabilities foundation
-- Stores authorization flags that authenticated users can read for themselves
-- but cannot mutate from client-side code.

create table if not exists public.user_capabilities (
  user_id uuid primary key references auth.users (id) on delete cascade,
  is_admin boolean not null default false,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create or replace function public.set_user_capabilities_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;

drop trigger if exists set_user_capabilities_updated_at
  on public.user_capabilities;

create trigger set_user_capabilities_updated_at
before update on public.user_capabilities
for each row
execute function public.set_user_capabilities_updated_at();

revoke all on table public.user_capabilities from anon;
revoke all on table public.user_capabilities from authenticated;

grant select on table public.user_capabilities to authenticated, service_role;
grant insert, update, delete on table public.user_capabilities to service_role;

alter table public.user_capabilities enable row level security;

drop policy if exists user_capabilities_select_own on public.user_capabilities;
create policy user_capabilities_select_own
on public.user_capabilities
for select
to authenticated
using (
  (select auth.uid()) is not null
  and (select auth.uid()) = user_id
);

comment on table public.user_capabilities is
  'Server-managed authorization flags for authenticated users.';

comment on column public.user_capabilities.is_admin is
  'Internal admin capability. Only privileged server-side workflows should modify it.';

insert into public.schema_migrations_meta (name)
values ('20260611033747_add_user_capabilities_table')
on conflict (name) do nothing;
