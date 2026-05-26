begin;

create or replace function pg_temp.assert_true(condition boolean, message text)
returns void
language plpgsql
as $$
begin
  if not condition then
    raise exception '%', message;
  end if;
end;
$$;

do $$
declare
  owner_id constant uuid := '11111111-1111-1111-1111-111111111111';
  other_id constant uuid := '22222222-2222-2222-2222-222222222222';
begin
  insert into auth.users (
    instance_id,
    id,
    aud,
    role,
    email,
    encrypted_password,
    email_confirmed_at,
    raw_app_meta_data,
    raw_user_meta_data,
    created_at,
    updated_at
  )
  values
    (
      '00000000-0000-0000-0000-000000000000',
      owner_id,
      'authenticated',
      'authenticated',
      'owner@lumen.test',
      'test-password-hash',
      timezone('utc', now()),
      '{"provider":"email","providers":["email"]}',
      '{}',
      timezone('utc', now()),
      timezone('utc', now())
    ),
    (
      '00000000-0000-0000-0000-000000000000',
      other_id,
      'authenticated',
      'authenticated',
      'other@lumen.test',
      'test-password-hash',
      timezone('utc', now()),
      '{"provider":"email","providers":["email"]}',
      '{}',
      timezone('utc', now()),
      timezone('utc', now())
    )
  on conflict (id) do nothing;

  insert into public.profiles (
    id,
    email,
    display_name,
    onboarding_completed
  )
  values
    (owner_id, 'owner@lumen.test', 'Owner', true),
    (other_id, 'other@lumen.test', 'Other', true);

  insert into public.journal_entries (
    user_id,
    id,
    source,
    original_text,
    rewritten_text,
    created_at,
    updated_at,
    client_updated_at
  )
  values
    (
      owner_id,
      'entry-owner',
      'text',
      'Owner entry',
      '',
      timezone('utc', now()),
      timezone('utc', now()),
      timezone('utc', now())
    ),
    (
      other_id,
      'entry-other',
      'text',
      'Other entry',
      '',
      timezone('utc', now()),
      timezone('utc', now()),
      timezone('utc', now())
    );

  insert into public.journal_themes (
    user_id,
    entry_id,
    theme_id,
    name,
    display_name,
    weight
  )
  values
    (owner_id, 'entry-owner', 'hope', 'hope', 'Hope', 0.8),
    (other_id, 'entry-other', 'grief', 'grief', 'Grief', 0.6);

  insert into public.related_resources (
    user_id,
    resource_id,
    entry_id,
    theme_id,
    title,
    type,
    source_type,
    match_reason,
    confidence
  )
  values
    (
      owner_id,
      'resource-owner',
      'entry-owner',
      'hope',
      'Owner resource',
      'reflection_prompt',
      'curated',
      'Owned by the current user',
      0.8
    ),
    (
      other_id,
      'resource-other',
      'entry-other',
      'grief',
      'Other resource',
      'reflection_prompt',
      'curated',
      'Owned by another user',
      0.7
    );

  insert into public.resource_feedback (
    user_id,
    resource_id,
    entry_id,
    theme_id,
    action,
    created_at,
    updated_at,
    client_updated_at
  )
  values
    (
      owner_id,
      'resource-owner',
      'entry-owner',
      'hope',
      'save',
      timezone('utc', now()),
      timezone('utc', now()),
      timezone('utc', now())
    ),
    (
      other_id,
      'resource-other',
      'entry-other',
      'grief',
      'dismiss',
      timezone('utc', now()),
      timezone('utc', now()),
      timezone('utc', now())
    );
end
$$;

set local role authenticated;
select set_config(
  'request.jwt.claims',
  '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}',
  true
);

select pg_temp.assert_true(
  exists(select 1 from public.profiles where id = '11111111-1111-1111-1111-111111111111'),
  'owner should read own profile'
);
select pg_temp.assert_true(
  not exists(select 1 from public.profiles where id = '22222222-2222-2222-2222-222222222222'),
  'owner should not read another profile'
);

with attempted as (
  update public.profiles
  set display_name = 'Nope'
  where id = '22222222-2222-2222-2222-222222222222'
  returning 1
)
select pg_temp.assert_true(
  (select count(*) from attempted) = 0,
  'owner should not update another profile'
);

do $$
begin
  insert into public.profiles (id, email, display_name, onboarding_completed)
  values (
    '22222222-2222-2222-2222-222222222222',
    'blocked@lumen.test',
    'Blocked',
    true
  );
  raise exception 'owner inserted another profile';
exception
  when insufficient_privilege then
    null;
  when others then
    if position('row-level security' in sqlerrm) = 0 then
      raise;
    end if;
end
$$;

select pg_temp.assert_true(
  exists(select 1 from public.journal_entries where id = 'entry-owner'),
  'owner should read own journal entry'
);
select pg_temp.assert_true(
  not exists(select 1 from public.journal_entries where id = 'entry-other'),
  'owner should not read another journal entry'
);

with attempted as (
  delete from public.journal_entries
  where id = 'entry-other'
  returning 1
)
select pg_temp.assert_true(
  (select count(*) from attempted) = 0,
  'owner should not delete another journal entry'
);

select pg_temp.assert_true(
  exists(select 1 from public.journal_themes where theme_id = 'hope'),
  'owner should read own journal theme'
);
select pg_temp.assert_true(
  not exists(select 1 from public.journal_themes where theme_id = 'grief'),
  'owner should not read another journal theme'
);

select pg_temp.assert_true(
  exists(select 1 from public.related_resources where resource_id = 'resource-owner'),
  'owner should read own related resource'
);
select pg_temp.assert_true(
  not exists(select 1 from public.related_resources where resource_id = 'resource-other'),
  'owner should not read another related resource'
);

with attempted as (
  update public.related_resources
  set title = 'Hijacked'
  where resource_id = 'resource-other'
  returning 1
)
select pg_temp.assert_true(
  (select count(*) from attempted) = 0,
  'owner should not update another related resource'
);

select pg_temp.assert_true(
  exists(select 1 from public.resource_feedback where resource_id = 'resource-owner'),
  'owner should read own resource feedback'
);
select pg_temp.assert_true(
  not exists(select 1 from public.resource_feedback where resource_id = 'resource-other'),
  'owner should not read another resource feedback row'
);

with attempted as (
  update public.resource_feedback
  set action = 'not_helpful'
  where resource_id = 'resource-other'
  returning 1
)
select pg_temp.assert_true(
  (select count(*) from attempted) = 0,
  'owner should not update another resource feedback row'
);

reset role;
set local role anon;

do $$
begin
  perform 1 from public.profiles;
  raise exception 'anon unexpectedly read profiles';
exception
  when insufficient_privilege then
    null;
end
$$;

rollback;
