# 0006: Shared Cloud Supabase For Prelaunch

Date: 2026-05-21

## Context

Lumen is not publicly launched yet, but auth, profiles, and future sync work
now need one consistent Supabase target across local development and CI. The
earlier plan assumed separate `dev`, `staging`, and `prod` Supabase projects,
plus regular local CLI stack usage, but that adds setup and process overhead
before we have a hosted product or release pipeline to justify it.

## Decision

Use one shared cloud Supabase project for prelaunch local development and CI.

- Local development connects to the shared cloud project by default.
- CI validates against the shared cloud project by default.
- The repo continues to keep client-safe Flutter keys separate from server-only
  API credentials.
- The local Supabase CLI stack remains available as an optional isolation tool,
  not the default path.
- Separate `dev`, `staging`, and `prod` Supabase projects are deferred until
  prelaunch hardening closer to release.

## Consequences

- Auth and profile work are exercised against one real cloud backend earlier.
- CI can verify shared-cloud connectivity and migration visibility without
  pretending there is already a full environment promotion model.
- Local onboarding/auth bug bashes match the same Supabase target used by CI.
- The shared cloud project must be treated as disposable prelaunch data, not as
  a production-like source of truth.
- Destructive operations against the shared cloud project must stay manual and
  deliberate; CI must not auto-reset or auto-push remote schema changes.
