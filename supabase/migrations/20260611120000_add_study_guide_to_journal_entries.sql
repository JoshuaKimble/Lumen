-- Add frozen study guide payload to journal entries for sync persistence.

alter table public.journal_entries
  add column if not exists study_guide jsonb;

comment on column public.journal_entries.study_guide is
  'Frozen Study Guide artifact attached to the journal entry.';

insert into public.schema_migrations_meta (name)
values ('20260611120000_add_study_guide_to_journal_entries')
on conflict (name) do nothing;
