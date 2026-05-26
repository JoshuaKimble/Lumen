-- Lumen user-owned table RLS policies (M7)
-- Protects profile and journal tables with authenticated ownership checks.

revoke all on table public.profiles from anon;
revoke all on table public.journal_entries from anon;
revoke all on table public.journal_themes from anon;
revoke all on table public.related_resources from anon;
revoke all on table public.resource_feedback from anon;

grant select, insert, update, delete on table public.profiles
  to authenticated, service_role;
grant select, insert, update, delete on table public.journal_entries
  to authenticated, service_role;
grant select, insert, update, delete on table public.journal_themes
  to authenticated, service_role;
grant select, insert, update, delete on table public.related_resources
  to authenticated, service_role;
grant select, insert, update, delete on table public.resource_feedback
  to authenticated, service_role;

alter table public.profiles enable row level security;
alter table public.journal_entries enable row level security;
alter table public.journal_themes enable row level security;
alter table public.related_resources enable row level security;
alter table public.resource_feedback enable row level security;

alter function public.set_profiles_updated_at()
  set search_path = pg_catalog, public;
alter function public.set_journal_row_updated_at()
  set search_path = pg_catalog, public;

drop policy if exists profiles_select_own on public.profiles;
create policy profiles_select_own
on public.profiles
for select
to authenticated
using ((select auth.uid()) is not null and (select auth.uid()) = id);

drop policy if exists profiles_insert_own on public.profiles;
create policy profiles_insert_own
on public.profiles
for insert
to authenticated
with check ((select auth.uid()) is not null and (select auth.uid()) = id);

drop policy if exists profiles_update_own on public.profiles;
create policy profiles_update_own
on public.profiles
for update
to authenticated
using ((select auth.uid()) is not null and (select auth.uid()) = id)
with check ((select auth.uid()) is not null and (select auth.uid()) = id);

drop policy if exists profiles_delete_own on public.profiles;
create policy profiles_delete_own
on public.profiles
for delete
to authenticated
using ((select auth.uid()) is not null and (select auth.uid()) = id);

drop policy if exists journal_entries_select_own on public.journal_entries;
create policy journal_entries_select_own
on public.journal_entries
for select
to authenticated
using (
  (select auth.uid()) is not null
  and (select auth.uid()) = user_id
);

drop policy if exists journal_entries_insert_own on public.journal_entries;
create policy journal_entries_insert_own
on public.journal_entries
for insert
to authenticated
with check (
  (select auth.uid()) is not null
  and (select auth.uid()) = user_id
);

drop policy if exists journal_entries_update_own on public.journal_entries;
create policy journal_entries_update_own
on public.journal_entries
for update
to authenticated
using (
  (select auth.uid()) is not null
  and (select auth.uid()) = user_id
)
with check (
  (select auth.uid()) is not null
  and (select auth.uid()) = user_id
);

drop policy if exists journal_entries_delete_own on public.journal_entries;
create policy journal_entries_delete_own
on public.journal_entries
for delete
to authenticated
using (
  (select auth.uid()) is not null
  and (select auth.uid()) = user_id
);

drop policy if exists journal_themes_select_own on public.journal_themes;
create policy journal_themes_select_own
on public.journal_themes
for select
to authenticated
using (
  (select auth.uid()) is not null
  and (select auth.uid()) = user_id
);

drop policy if exists journal_themes_insert_own on public.journal_themes;
create policy journal_themes_insert_own
on public.journal_themes
for insert
to authenticated
with check (
  (select auth.uid()) is not null
  and (select auth.uid()) = user_id
);

drop policy if exists journal_themes_update_own on public.journal_themes;
create policy journal_themes_update_own
on public.journal_themes
for update
to authenticated
using (
  (select auth.uid()) is not null
  and (select auth.uid()) = user_id
)
with check (
  (select auth.uid()) is not null
  and (select auth.uid()) = user_id
);

drop policy if exists journal_themes_delete_own on public.journal_themes;
create policy journal_themes_delete_own
on public.journal_themes
for delete
to authenticated
using (
  (select auth.uid()) is not null
  and (select auth.uid()) = user_id
);

drop policy if exists related_resources_select_own on public.related_resources;
create policy related_resources_select_own
on public.related_resources
for select
to authenticated
using (
  (select auth.uid()) is not null
  and (select auth.uid()) = user_id
);

drop policy if exists related_resources_insert_own on public.related_resources;
create policy related_resources_insert_own
on public.related_resources
for insert
to authenticated
with check (
  (select auth.uid()) is not null
  and (select auth.uid()) = user_id
);

drop policy if exists related_resources_update_own on public.related_resources;
create policy related_resources_update_own
on public.related_resources
for update
to authenticated
using (
  (select auth.uid()) is not null
  and (select auth.uid()) = user_id
)
with check (
  (select auth.uid()) is not null
  and (select auth.uid()) = user_id
);

drop policy if exists related_resources_delete_own on public.related_resources;
create policy related_resources_delete_own
on public.related_resources
for delete
to authenticated
using (
  (select auth.uid()) is not null
  and (select auth.uid()) = user_id
);

drop policy if exists resource_feedback_select_own on public.resource_feedback;
create policy resource_feedback_select_own
on public.resource_feedback
for select
to authenticated
using (
  (select auth.uid()) is not null
  and (select auth.uid()) = user_id
);

drop policy if exists resource_feedback_insert_own on public.resource_feedback;
create policy resource_feedback_insert_own
on public.resource_feedback
for insert
to authenticated
with check (
  (select auth.uid()) is not null
  and (select auth.uid()) = user_id
);

drop policy if exists resource_feedback_update_own on public.resource_feedback;
create policy resource_feedback_update_own
on public.resource_feedback
for update
to authenticated
using (
  (select auth.uid()) is not null
  and (select auth.uid()) = user_id
)
with check (
  (select auth.uid()) is not null
  and (select auth.uid()) = user_id
);

drop policy if exists resource_feedback_delete_own on public.resource_feedback;
create policy resource_feedback_delete_own
on public.resource_feedback
for delete
to authenticated
using (
  (select auth.uid()) is not null
  and (select auth.uid()) = user_id
);

insert into public.schema_migrations_meta (name)
values ('20260526035537_add_user_owned_rls_policies')
on conflict (name) do nothing;
