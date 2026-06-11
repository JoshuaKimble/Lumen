# 0012: Supabase User Capabilities For Admin Authorization

- Status: Accepted
- Date: 2026-06-11

## Context

Lumen now has an internal admin-only UI action for AI regeneration. The first
implementation used a hardcoded email allowlist in Flutter. That is sufficient
for a narrow local test, but it is the wrong long-term authorization model.

The app already uses:

- Supabase Auth for signed-in identity
- RLS-protected user-owned data in `public`
- a shared prelaunch cloud Supabase project

Admin capability needs to be:

- service-managed
- non-user-editable
- readable by the signed-in client for capability gating
- reusable for future privileged features

It should not live in:

- `raw_user_meta_data`, which users can change
- `public.profiles`, which is intentionally user-owned and editable

## Decision

Lumen will add a server-managed `public.user_capabilities` table keyed 1:1 to
`auth.users`.

The first capability is:

- `is_admin boolean not null default false`

### Access model

- `authenticated` users may only `select` their own row through RLS
- `authenticated` users may not `insert`, `update`, or `delete`
- `service_role` may manage rows for administrative workflows

### App model

Flutter will hydrate a current-user capability state from Supabase and derive
admin UI access from that state instead of from a hardcoded email list.

## Consequences

Positive:

- removes authorization logic from user-editable data
- keeps admin access compatible with RLS and browser-safe Supabase access
- creates a reusable capability path for future privileged features

Tradeoffs:

- adds one more auth-adjacent table and hydration step
- requires a separate administrative workflow to grant admin access to a user

## Notes

- This table is intentionally small and service-managed.
- If richer role modeling is needed later, it can grow into a broader
  capability or role system without moving user-owned profile fields again.
