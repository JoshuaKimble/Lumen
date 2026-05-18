# Supabase Environment Strategy (M1)

Status: active for Epic M1 foundation work.

This document defines environment strategy for Supabase across `dev`,
`staging`, and `prod` for Lumen.

## Goals

- Keep environment separation explicit and enforceable.
- Keep secrets out of git and out of Flutter runtime where not appropriate.
- Keep ownership and rotation responsibilities clear.
- Keep local development reproducible for a small team.

## Environment Mapping

Use one Supabase project per environment.

| Environment | Purpose | Supabase Project Naming | Project URL Source | Anon Key Source | Service Role Key Source |
| --- | --- | --- | --- | --- | --- |
| `dev` | Local integration and day-to-day engineering | `lumen-dev` | Supabase dashboard project settings (`Project URL`) | Supabase dashboard API settings (`anon/public`) | Supabase dashboard API settings (`service_role`) |
| `staging` | Pre-release validation and smoke testing | `lumen-staging` | Supabase dashboard project settings (`Project URL`) | Supabase dashboard API settings (`anon/public`) | Supabase dashboard API settings (`service_role`) |
| `prod` | Live user data and production traffic | `lumen-prod` | Supabase dashboard project settings (`Project URL`) | Supabase dashboard API settings (`anon/public`) | Supabase dashboard API settings (`service_role`) |

## Runtime Placement Rules

### Flutter (`apps/mobile`)

- Allowed:
  - Supabase project URL
  - Supabase anon/public key
- Not allowed:
  - Supabase service-role key
  - OpenAI API key or provider secrets

### API (`apps/api`)

- Allowed:
  - Supabase project URL
  - Supabase service-role key (server-side only)
  - OpenAI provider secrets (existing policy unchanged)
- Not allowed:
  - Client-distributed secret handling

## Environment Variable Conventions

The exact variable names can be finalized in issue `#58`, but the ownership
split must remain:

- Flutter runtime vars: public client-safe Supabase values only.
- API runtime vars: server-only Supabase + AI provider secrets.

Do not commit real values. Commit example files only.

## Ownership and Access Control

Use least privilege by default.

- Project owner:
  - `JoshuaKimble` (account owner for initial setup and billing)
- Engineering collaborators:
  - invite as Supabase members with minimum role needed
  - avoid owner-level permissions unless operationally required
- CI/CD secret managers:
  - GitHub repository secrets (or environment-scoped secrets) for runtime keys
  - no plain-text secrets in workflow YAML

## Secret Rotation Policy

- Rotate keys immediately on suspected exposure.
- Planned cadence:
  - `dev`: quarterly or as needed
  - `staging`: quarterly
  - `prod`: quarterly minimum, or earlier for incidents
- Any rotation event requires:
  1. update secret store values
  2. verify runtime startup in affected env
  3. post-rotation smoke check
  4. short changelog note in issue/task history

## Local Development Strategy

- Local development uses Supabase CLI/local stack where practical.
- Local env values come from non-committed env files.
- Seed/migration commands and troubleshooting are documented in:
  - `docs/supabase-local-development.md` (issue `#59`)

## Security Boundaries (Non-Negotiable)

- Service-role key never ships in mobile/web bundle.
- OpenAI credentials remain server-side in `apps/api`.
- Supabase RLS policy work remains part of later security milestones, but M1
  must preserve the key-boundary guarantees above.

## Implementation Dependencies

- Strategy decisions in this doc are authoritative for:
  - `#56` migration workflow setup
  - `#58` runtime config bootstrap
  - `#59` runbook documentation
  - `#60` CI env-safety checks
