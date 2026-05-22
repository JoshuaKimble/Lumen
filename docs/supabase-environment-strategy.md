# Supabase Environment Strategy

Status: active for prelaunch development.

This document defines how Lumen uses Supabase before the app is publicly
launched.

## Current Strategy

Lumen uses one shared cloud Supabase project for local development and CI.

This is intentional.

- The app is not publicly launched yet.
- Auth, profiles, and future cloud-backed features need one consistent backend.
- We want local bug bashes and CI validation to exercise the same real target.
- Separate `dev`, `staging`, and `prod` Supabase projects are deferred until
  release hardening is closer and the deployment process is worth formalizing.

The durable decision record is:

- [0006-shared-cloud-supabase-prelaunch.md](/Users/joshuakimble/Documents/workspace/apps/Lumen/docs/decisions/0006-shared-cloud-supabase-prelaunch.md)

## Goals

- Keep one shared source of truth for prelaunch auth/profile behavior.
- Keep secrets out of git and out of Flutter runtime where not appropriate.
- Make CI and local manual testing use the same Supabase target.
- Preserve a clean path to future environment splitting without pretending it
  already exists.

## Environment Mapping

| Stage | Current Supabase Model | Notes |
| --- | --- | --- |
| Local development | Shared cloud project | Default path for Flutter and API work. |
| CI | Shared cloud project | Used for connectivity and migration-history validation. |
| Release hardening | Separate projects later | Split into `dev` / `staging` / `prod` when publishing becomes real. |

## Runtime Placement Rules

### Flutter (`apps/mobile`)

- Allowed:
  - Supabase project URL
  - Supabase publishable key
- Not allowed:
  - Supabase secret key
  - OpenAI API key or provider secrets

### API (`apps/api`)

- Allowed:
  - Supabase project URL
  - Supabase secret key (server-side only, if needed)
  - Database connection string for CLI/cloud validation
  - OpenAI provider secrets
- Not allowed:
  - Client-distributed secret handling

## Environment Variable Conventions

### Flutter (`dart-define`)

- `LUMEN_USE_SUPABASE=true|false`
- `LUMEN_SUPABASE_URL=<project-url>`
- `LUMEN_SUPABASE_PUBLISHABLE_KEY=<publishable-key>`

### API and Local Tooling (`apps/api/.env`)

- `LUMEN_USE_SUPABASE=true|false`
- `LUMEN_SUPABASE_URL=<project-url>`
- `LUMEN_SUPABASE_PUBLISHABLE_KEY=<publishable-key>`
- `LUMEN_SUPABASE_SECRET_KEY=<secret-key>` for privileged server access only
- `LUMEN_SUPABASE_DB_URL=<percent-encoded-db-connection-string>`

Do not commit real values. Commit example files only.

## CI Strategy

CI uses the shared cloud Supabase project as the canonical schema deploy path
for `master`.

Current expectations:

- `./scripts/check_supabase.sh` remains the static safety guard.
- Pull requests and non-deploy CI runs validate code and migration files, but
  must not mutate the shared cloud project.
- On `push` to `master`, CI runs `./scripts/check_supabase_cloud.sh` and then
  `./scripts/supabase_push_cloud.sh`.
- CI must not auto-reset or auto-seed the shared cloud database.

Required GitHub secrets:

- `LUMEN_SUPABASE_URL`
- `LUMEN_SUPABASE_DB_URL`

## Local Development Strategy

Use the shared cloud project by default.

- Flutter web builds should receive Supabase client values through
  `./scripts/dev_web_api.sh`.
- Local auth/profile testing should hit the same Supabase project that CI uses.
- `apps/api/.env` is the canonical local source for shared-cloud Supabase
  values.
- `LUMEN_SUPABASE_DB_URL` currently uses the Supabase transaction pooler
  because direct database connections are not reachable from the current local
  environment.
- When schema changes need to exist before the next CI deploy, run
  `./scripts/supabase_push_cloud.sh` manually from your local environment.

The local Supabase CLI stack is still allowed for isolated schema experiments,
but it is no longer the default prelaunch workflow.

## Operational Guardrails

- Treat the shared cloud project as prelaunch data, not production data.
- Avoid destructive remote commands in automation.
- Keep secret keys server-only.
- Prefer additive, forward-safe migrations because app commits may land before
  the `master` deploy job finishes.
- Expect occasional Supabase CLI verification issues against the transaction
  pooler because transaction mode does not fully support prepared statements.
- Rotate keys immediately if exposure is suspected.
- Revisit the single-project strategy before public release and split
  environments then.
