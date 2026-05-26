# Dev/QA Seed Fixture

This document defines the first local-only seeded user workflow for issue
`#93`.

## Purpose

The fixture gives local development and QA a deterministic signed-in account
with roughly one week of realistic journal history in the local Supabase stack.

It is intentionally local-only:

- it uses the local Supabase Docker stack
- it does not touch the shared cloud project
- it can be safely reset and re-applied at any time

## Seeded Account

- Email: `seed.user@lumen.test`
- Password: `LumenSeed123!`

The profile is preconfigured with:

- `display_name = Seeded Saint`
- onboarding completed
- rewrite tone = `reflective`
- preferred scripture app = `gospel_library`
- theme preference = `system`

## Seeded Content

The fixture inserts:

- 1 confirmed local auth user
- 1 profile row
- 7 journal entries across one week
- mocked rewritten text for every entry
- mocked journal themes across the week
- a small set of related resources
- a couple of feedback rows for inspection

The journal dates are deterministic and fixed in May 2026 so the fixture is
stable across resets and screenshots.

## Commands

Start local Supabase first if needed:

```sh
./scripts/supabase_start.sh
```

Apply the fixture:

```sh
./scripts/supabase_seed_dev_fixture.sh
```

Reset only the fixture user and its cascaded content:

```sh
./scripts/supabase_reset_dev_fixture.sh
```

Reset the entire local database back to baseline migrations and baseline seed:

```sh
./scripts/supabase_reset.sh
```

## App Verification

Run the app in Supabase mode against the local stack, then sign in with the
seeded credentials:

```sh
cd apps/mobile
flutter run \
  --dart-define=LUMEN_USE_SUPABASE=true \
  --dart-define=LUMEN_SUPABASE_URL=http://127.0.0.1:54321 \
  --dart-define=LUMEN_SUPABASE_PUBLISHABLE_KEY=sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH
```

Expected behavior after login:

- the user bypasses onboarding because the profile is already complete
- the journal home screen hydrates roughly one week of entries from Supabase
- entry detail screens show mocked rewritten text and themes

## Notes

- Re-running the seed script is safe. It deletes and recreates the deterministic
  fixture user before inserting fresh content.
- This fixture is a local QA helper, not production or shared-cloud seed data.
- Cloud-shared seeded users can be designed later once the team wants a stable
  shared QA environment.
