# Seed Users

This document is the quick reference for local seeded users in Lumen.

Right now there is one deterministic local-only fixture user. It is intended
for development and QA against the local Supabase stack.

## Before You Use It

Start local Supabase:

```sh
./scripts/supabase_start.sh
```

Apply the seed fixture:

```sh
./scripts/supabase_seed_dev_fixture.sh
```

Reset just the fixture user and its cascaded journal data:

```sh
./scripts/supabase_reset_dev_fixture.sh
```

## Seeded Users

### 1. Primary Dev/QA Journal User

- Purpose: inspect the signed-in app with realistic journal history
- Scope: local Supabase only
- Email / username: `seed.user@lumen.test`
- Password: `LumenSeed123!`

Profile summary:

- Display name: `Seeded Saint`
- Onboarding: completed
- Rewrite tone: `reflective`
- Preserve voice: `true`
- Preferred scripture app: `gospel_library`
- Theme preference: `system`

Seeded content statistics:

- Journal entries: `7`
- Journal themes: `12`
- Related resources: `4`
- Resource feedback rows: `2`
- Journal time span: `2026-05-19` through `2026-05-25`
- Entry source mix: `6` text entries, `1` voice entry

What this user is for:

- verifying login against the local Supabase auth flow
- bypassing onboarding to inspect the signed-in journal experience
- testing cloud hydration into the local-first journal repository
- reviewing mocked rewrites, themes, and resource rendering in the UI
- checking scripture-app-aware resource links with a non-default preference

## Useful Notes

- This fixture is deterministic. Re-running the seed script recreates the same
  user and the same content.
- The fixture is local only. It does not seed the shared cloud environment.
- The reset script deletes the fixture user from `auth.users`; profile and
  journal rows cascade automatically.
- If you want the app to show this seeded content, run the Flutter app with
  Supabase mode enabled and sign in with the credentials above.

Example:

```sh
cd apps/mobile
flutter run \
  --dart-define=LUMEN_USE_SUPABASE=true \
  --dart-define=LUMEN_SUPABASE_URL=http://127.0.0.1:54321 \
  --dart-define=LUMEN_SUPABASE_PUBLISHABLE_KEY=sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH
```
