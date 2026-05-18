# Supabase Migration Workflow (M1)

This runbook defines the migration and seed workflow used by Lumen during M1.
It is designed to be reproducible from a clean machine.

## Prerequisites

- Install Supabase CLI:
  https://supabase.com/docs/guides/cli/getting-started
- Docker Desktop running locally (required by Supabase local stack)

## Repository Structure

- Supabase config: `supabase/config.toml`
- Migrations: `supabase/migrations/*.sql`
- Seed data: `supabase/seed.sql`

## Core Commands

From repo root:

```sh
./scripts/supabase_start.sh
./scripts/supabase_status.sh
./scripts/supabase_reset.sh
./scripts/supabase_stop.sh
```

Create a migration file:

```sh
./scripts/supabase_migration_new.sh <migration_name>
```

Example:

```sh
./scripts/supabase_migration_new.sh add_profiles_table
```

## Standard Local Flow

1. Start local Supabase:
   `./scripts/supabase_start.sh`
2. Create migration:
   `./scripts/supabase_migration_new.sh <name>`
3. Edit generated SQL migration under `supabase/migrations/`
4. Apply all migrations and seed from scratch:
   `./scripts/supabase_reset.sh`
5. Check service health:
   `./scripts/supabase_status.sh`
6. Stop stack when done:
   `./scripts/supabase_stop.sh`

## Seed Strategy

- `supabase/seed.sql` must stay deterministic and idempotent.
- Do not add non-deterministic seed data that can break tests or local repro.
- Avoid environment-specific values in seed scripts.

## Rules

- Do not make manual schema edits outside migration SQL files.
- Every schema change must have a committed migration file.
- Keep migrations additive and reviewable; avoid opaque generated diffs.

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
