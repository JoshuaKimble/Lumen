# Supabase Migration Workflow (M1)

This runbook defines the migration workflow used by Lumen before public launch.
It supports both the shared cloud Supabase project and optional local CLI
isolation.

## Prerequisites

- Install Supabase CLI:
  https://supabase.com/docs/guides/cli/getting-started
- Docker Desktop running locally only if you choose the optional local stack

## Repository Structure

- Supabase config: `supabase/config.toml`
- Migrations: `supabase/migrations/*.sql`
- Seed data: `supabase/seed.sql`

## Shared Cloud Defaults

The default prelaunch path is the shared cloud Supabase project described in
[supabase-environment-strategy.md](/Users/joshuakimble/Documents/workspace/apps/Lumen/docs/supabase-environment-strategy.md).

Expected local env source:

- `apps/api/.env`

Required shared-cloud vars:

- `LUMEN_USE_SUPABASE=true`
- `LUMEN_SUPABASE_URL=...`
- `LUMEN_SUPABASE_DB_URL=...`

Current default:

- Use the Supabase transaction-pooler connection string for
  `LUMEN_SUPABASE_DB_URL`.
- Do not use the direct connection string from this local environment because
  it is not currently routable.

## Optional Local Stack Commands

From repo root:

```sh
./scripts/supabase_start.sh
./scripts/supabase_status.sh
./scripts/supabase_reset.sh
./scripts/supabase_stop.sh
```

## New Contributor Quickstart

For the default shared-cloud flow:

```sh
./scripts/check_supabase.sh
./scripts/check_supabase_cloud.sh
```

Bootstrap is considered successful when:

- shared-cloud env vars are present
- the cloud database answers a health query
- remote migration history is readable

Known limitation:

- Transaction-pooler connections can intermittently fail Supabase CLI
  verification steps with prepared-statement errors even when connectivity and
  migration application are otherwise working.

To manually apply pending repo migrations to the shared cloud project:

```sh
./scripts/supabase_push_cloud.sh
```

For optional isolated local stack work:

```sh
./scripts/supabase_start.sh
./scripts/supabase_reset.sh
./scripts/supabase_status.sh
```

Bootstrap is considered successful when:

- `supabase status` returns running service details
- migrations apply without manual SQL edits
- seed runs without errors

Create a migration file:

```sh
./scripts/supabase_migration_new.sh <migration_name>
```

Example:

```sh
./scripts/supabase_migration_new.sh add_profiles_table
```

## Standard Workflow

1. Create migration:
   `./scripts/supabase_migration_new.sh <name>`
2. Edit generated SQL migration under `supabase/migrations/`
3. Run static Supabase safety checks:
   `./scripts/check_supabase.sh`
4. Run shared cloud connectivity + migration-history checks:
   `./scripts/check_supabase_cloud.sh`
5. Commit and push to `master`; CI is the canonical shared-cloud migration
   deploy path and runs `./scripts/supabase_push_cloud.sh` after the other
   checks pass.
6. If the shared cloud schema must be updated before CI runs, manually run:
   `./scripts/supabase_push_cloud.sh`
7. If you need isolated schema verification, optionally run:
   `./scripts/check_supabase_migrations.sh`

## Seed Strategy

- `supabase/seed.sql` must stay deterministic and idempotent.
- Do not add non-deterministic seed data that can break tests or local repro.
- Avoid environment-specific values in seed scripts.

## Rules

- Do not make manual schema edits outside migration SQL files.
- Every schema change must have a committed migration file.
- Keep migrations additive and reviewable; avoid opaque generated diffs.

## CI Expectations

CI runs `./scripts/check_supabase.sh` and will fail if:

- migration files are missing or use invalid naming format
- duplicate migration timestamps exist
- required env-file ignore patterns are missing in `.gitignore`
- obvious secret-like values are committed in tracked source files

On `push` to `master`, CI also runs `./scripts/check_supabase_cloud.sh` and
`./scripts/supabase_push_cloud.sh`. The deploy job will fail if:

- required shared-cloud Supabase vars are missing
- the shared cloud database cannot be reached
- remote migration history cannot be read
- pending migrations cannot be applied cleanly

Run locally before pushing:

```sh
./scripts/check_supabase.sh
./scripts/check_supabase_cloud.sh
```

Run `./scripts/check_supabase_migrations.sh` only when you explicitly want the
optional local-stack migration replay.

Run `./scripts/supabase_push_cloud.sh` only when you intentionally want to
apply repo migrations from your local machine instead of waiting for the CI
deploy job.

## Troubleshooting

### Supabase CLI not found

Install CLI and ensure `supabase` is in `PATH`.

### Docker not running

Start Docker Desktop and rerun `./scripts/supabase_start.sh`.

### Dirty local state

Run:

```sh
./scripts/supabase_stop.sh
./scripts/supabase_start.sh
./scripts/supabase_reset.sh
```

### Port conflicts

If Supabase reports local port collisions, stop the conflicting processes and
rerun:

```sh
./scripts/supabase_stop.sh
./scripts/supabase_start.sh
```

### Shared cloud validation fails

Confirm `apps/api/.env` or your shell exports include:

- `LUMEN_USE_SUPABASE=true`
- `LUMEN_SUPABASE_URL`
- `LUMEN_SUPABASE_DB_URL`

If the failure mentions prepared statements already existing, retry with a fresh
CLI process and remember that this is a known transaction-pooler limitation
rather than necessarily a bad credential or unreachable project.
