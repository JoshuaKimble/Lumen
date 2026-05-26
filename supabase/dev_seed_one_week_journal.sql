begin;

do $$
declare
  fixture_user_id constant uuid := '33333333-3333-3333-3333-333333333333';
  fixture_identity_id constant uuid := '44444444-4444-4444-4444-444444444444';
  fixture_email constant text := 'seed.user@lumen.test';
  base_created_at constant timestamptz := '2026-05-19T06:45:00Z'::timestamptz;
begin
  delete from auth.users
  where id = fixture_user_id
     or email = fixture_email;

  insert into auth.users (
    instance_id,
    id,
    aud,
    role,
    email,
    encrypted_password,
    phone,
    email_confirmed_at,
    confirmation_token,
    email_change,
    email_change_token_current,
    email_change_token_new,
    recovery_token,
    reauthentication_token,
    raw_app_meta_data,
    raw_user_meta_data,
    created_at,
    updated_at,
    is_sso_user,
    is_anonymous
  )
  values (
    '00000000-0000-0000-0000-000000000000',
    fixture_user_id,
    'authenticated',
    'authenticated',
    fixture_email,
    crypt('LumenSeed123!', gen_salt('bf')),
    '',
    timezone('utc', now()),
    '',
    '',
    '',
    '',
    '',
    '',
    '{"provider":"email","providers":["email"]}',
    jsonb_build_object(
      'sub', fixture_user_id::text,
      'email', fixture_email,
      'email_verified', true,
      'phone_verified', false
    ),
    base_created_at,
    base_created_at,
    false,
    false
  );

  insert into auth.identities (
    id,
    user_id,
    identity_data,
    provider,
    provider_id,
    created_at,
    updated_at
  )
  values (
    fixture_identity_id,
    fixture_user_id,
    jsonb_build_object(
      'sub', fixture_user_id::text,
      'email', fixture_email,
      'email_verified', false,
      'phone_verified', false
    ),
    'email',
    fixture_user_id::text,
    base_created_at,
    base_created_at
  );

  insert into public.profiles (
    id,
    email,
    display_name,
    rewrite_tone,
    preserve_voice,
    preferred_scripture_app,
    theme_preference,
    onboarding_completed,
    created_at,
    updated_at
  )
  values (
    fixture_user_id,
    fixture_email,
    'Seeded Saint',
    'reflective',
    true,
    'gospel_library',
    'system',
    true,
    base_created_at,
    base_created_at + interval '6 days'
  );

  insert into public.journal_entries (
    user_id,
    id,
    title,
    summary,
    source,
    original_text,
    rewritten_text,
    last_regenerated_at,
    created_at,
    updated_at,
    client_updated_at,
    version,
    sync_state
  )
  values
    (
      fixture_user_id,
      'seed-entry-2026-05-19',
      'Starting the week gently',
      'A journal reflection about slowing down and beginning the week with prayer.',
      'text',
      'I woke up tense about everything on my list, but scripture study settled me enough to start with one faithful step instead of trying to control the whole week.',
      'You noticed the tension you carried into the day and chose a steadier beginning. Instead of demanding certainty from the whole week, you returned to one faithful next step and found room to breathe.',
      base_created_at + interval '30 minutes',
      base_created_at,
      base_created_at + interval '30 minutes',
      base_created_at + interval '30 minutes',
      3,
      'synced'
    ),
    (
      fixture_user_id,
      'seed-entry-2026-05-20',
      'A better conversation at home',
      'A family moment that moved from defensiveness to patience.',
      'text',
      'I almost answered sharply tonight, but I paused long enough to hear what was really being asked of me and the conversation ended with more peace than I expected.',
      'You interrupted a familiar pattern before it hardened into hurt. That pause created enough space for patience, and the evening ended with more peace than your first impulse promised.',
      base_created_at + interval '1 day 20 minutes',
      base_created_at + interval '1 day',
      base_created_at + interval '1 day 20 minutes',
      base_created_at + interval '1 day 20 minutes',
      2,
      'synced'
    ),
    (
      fixture_user_id,
      'seed-entry-2026-05-21',
      'Work pressure and honest limits',
      'A stressful workday reframed through healthier expectations.',
      'text',
      'Work felt relentless today and I hated admitting that I could not do everything. I finally wrote down the three things that mattered most and let the rest wait.',
      'You faced a demanding day honestly instead of pretending you had endless capacity. Naming the three things that mattered most turned pressure into a boundary you could actually keep.',
      base_created_at + interval '2 days 35 minutes',
      base_created_at + interval '2 days',
      base_created_at + interval '2 days 35 minutes',
      base_created_at + interval '2 days 35 minutes',
      4,
      'synced'
    ),
    (
      fixture_user_id,
      'seed-entry-2026-05-22',
      'Remembering gratitude in the middle',
      'A midweek note about noticing grace in ordinary moments.',
      'text',
      'Nothing dramatic happened today, but I kept noticing quiet mercies: a kind text, enough energy to finish dinner, and a few minutes outside before dark.',
      'The day did not need drama to be meaningful. You paid attention to quiet mercies, and gratitude gave ordinary moments enough weight to feel like gifts instead of leftovers.',
      base_created_at + interval '3 days 25 minutes',
      base_created_at + interval '3 days',
      base_created_at + interval '3 days 25 minutes',
      base_created_at + interval '3 days 25 minutes',
      2,
      'synced'
    ),
    (
      fixture_user_id,
      'seed-entry-2026-05-23',
      'Voice memo after a long drive',
      'A voice-captured reflection on fatigue and perspective.',
      'voice',
      'I recorded this in the car because I was too tired to type. I felt worn out, but I also realized I had been carried through more of the week than I noticed while rushing.',
      'Even in your fatigue, you could see that you were not carrying the whole week alone. The voice note captured both your weariness and the quiet realization that grace had been present all along.',
      base_created_at + interval '4 days 40 minutes',
      base_created_at + interval '4 days',
      base_created_at + interval '4 days 40 minutes',
      base_created_at + interval '4 days 40 minutes',
      3,
      'synced'
    ),
    (
      fixture_user_id,
      'seed-entry-2026-05-24',
      'Sabbath planning without guilt',
      'A weekend reflection on rest and intention.',
      'text',
      'I made a simple plan for Sunday that leaves room for worship and real rest. It feels small, but maybe small is exactly what keeps rest from becoming another project.',
      'You chose a gentle plan instead of turning rest into another performance. The simplicity feels intentional, and that may be what makes Sabbath rest believable instead of theoretical.',
      base_created_at + interval '5 days 15 minutes',
      base_created_at + interval '5 days',
      base_created_at + interval '5 days 15 minutes',
      base_created_at + interval '5 days 15 minutes',
      2,
      'synced'
    ),
    (
      fixture_user_id,
      'seed-entry-2026-05-25',
      'Closing the week with hope',
      'An end-of-week reflection tying together prayer, family, and steadiness.',
      'text',
      'Looking back at the week, I did not become a different person overnight, but I do feel more anchored. I want to keep choosing small faithful habits that make room for hope.',
      'The week did not transform you through one dramatic breakthrough. It steadied you through repeated small choices, and that steadiness is already becoming a believable form of hope.',
      base_created_at + interval '6 days 50 minutes',
      base_created_at + interval '6 days',
      base_created_at + interval '6 days 50 minutes',
      base_created_at + interval '6 days 50 minutes',
      5,
      'synced'
    );

  insert into public.journal_themes (
    user_id,
    entry_id,
    theme_id,
    name,
    display_name,
    weight,
    created_at
  )
  values
    (fixture_user_id, 'seed-entry-2026-05-19', 'prayer', 'prayer', 'Prayer', 0.89, base_created_at),
    (fixture_user_id, 'seed-entry-2026-05-19', 'peace', 'peace', 'Peace', 0.71, base_created_at),
    (fixture_user_id, 'seed-entry-2026-05-20', 'family', 'family', 'Family', 0.91, base_created_at + interval '1 day'),
    (fixture_user_id, 'seed-entry-2026-05-20', 'patience', 'patience', 'Patience', 0.78, base_created_at + interval '1 day'),
    (fixture_user_id, 'seed-entry-2026-05-21', 'work', 'work', 'Work', 0.93, base_created_at + interval '2 days'),
    (fixture_user_id, 'seed-entry-2026-05-21', 'boundaries', 'boundaries', 'Boundaries', 0.76, base_created_at + interval '2 days'),
    (fixture_user_id, 'seed-entry-2026-05-22', 'gratitude', 'gratitude', 'Gratitude', 0.88, base_created_at + interval '3 days'),
    (fixture_user_id, 'seed-entry-2026-05-23', 'fatigue', 'fatigue', 'Fatigue', 0.83, base_created_at + interval '4 days'),
    (fixture_user_id, 'seed-entry-2026-05-23', 'perspective', 'perspective', 'Perspective', 0.68, base_created_at + interval '4 days'),
    (fixture_user_id, 'seed-entry-2026-05-24', 'rest', 'rest', 'Rest', 0.9, base_created_at + interval '5 days'),
    (fixture_user_id, 'seed-entry-2026-05-25', 'hope', 'hope', 'Hope', 0.95, base_created_at + interval '6 days'),
    (fixture_user_id, 'seed-entry-2026-05-25', 'discipleship', 'discipleship', 'Discipleship', 0.72, base_created_at + interval '6 days');

  insert into public.related_resources (
    user_id,
    resource_id,
    entry_id,
    theme_id,
    title,
    type,
    source_type,
    match_reason,
    confidence,
    url,
    scripture_reference,
    description,
    created_at
  )
  values
    (
      fixture_user_id,
      'seed-resource-prayer',
      'seed-entry-2026-05-19',
      'prayer',
      'Pause and ask for one next step',
      'reflection_prompt',
      'curated',
      'Matches the entry''s move from anxiety to prayerful focus.',
      0.86,
      null,
      'Doctrine and Covenants 6:36',
      'A short reflection prompt about turning toward Christ before tackling the whole week.',
      base_created_at
    ),
    (
      fixture_user_id,
      'seed-resource-family',
      'seed-entry-2026-05-20',
      'family',
      'Soft answers change evenings',
      'quote',
      'ai_mapped',
      'Supports the family and patience themes from the entry.',
      0.8,
      null,
      'Proverbs 15:1',
      'A short proverb-oriented reminder connected to a difficult conversation at home.',
      base_created_at + interval '1 day'
    ),
    (
      fixture_user_id,
      'seed-resource-work',
      'seed-entry-2026-05-21',
      'work',
      'Three faithful priorities',
      'exercise',
      'curated',
      'Reinforces the entry''s decision to name three meaningful tasks.',
      0.84,
      null,
      null,
      'A practical exercise for narrowing the day to three priorities.',
      base_created_at + interval '2 days'
    ),
    (
      fixture_user_id,
      'seed-resource-hope',
      'seed-entry-2026-05-25',
      'hope',
      'Hope grows through repeated small choices',
      'talk_or_article',
      'ai_mapped',
      'Connects directly to the end-of-week hope reflection.',
      0.89,
      'https://www.churchofjesuschrist.org/study/general-conference/2023/10',
      null,
      'A seeded article link for inspecting scripture app routing and resource display.',
      base_created_at + interval '6 days'
    );

  insert into public.resource_feedback (
    user_id,
    resource_id,
    entry_id,
    theme_id,
    action,
    note,
    created_at,
    updated_at,
    client_updated_at,
    version,
    sync_state
  )
  values
    (
      fixture_user_id,
      'seed-resource-prayer',
      'seed-entry-2026-05-19',
      'prayer',
      'save',
      'Helpful for slow mornings.',
      base_created_at + interval '2 hours',
      base_created_at + interval '2 hours',
      base_created_at + interval '2 hours',
      1,
      'synced'
    ),
    (
      fixture_user_id,
      'seed-resource-work',
      'seed-entry-2026-05-21',
      'work',
      'not_helpful',
      'Too tactical for the mood of the day.',
      base_created_at + interval '2 days 2 hours',
      base_created_at + interval '2 days 2 hours',
      base_created_at + interval '2 days 2 hours',
      1,
      'synced'
    );
end
$$;

commit;
