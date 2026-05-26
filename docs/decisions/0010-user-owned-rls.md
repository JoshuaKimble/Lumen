# 0010: User-Owned Table RLS

- Status: Accepted
- Date: 2026-05-25

## Context

M7 secures the Supabase-backed profile and journal tables introduced in earlier
milestones. These tables live in `public`, which is an exposed schema in the
Supabase Data API, so ownership must be enforced in the database rather than in
client code alone.

Lumen already distinguishes:

- browser and mobile clients that should only access the signed-in user's rows
- server-side paths that may need `service_role` access for privileged
  operations

## Decision

Lumen will enable RLS on every user-owned `public` table and apply explicit
ownership policies.

The policy model is:

- `anon` gets no access to user-owned tables
- `authenticated` gets `select`, `insert`, `update`, and `delete` only when the
  row owner matches `auth.uid()`
- `update` policies include both `USING` and `WITH CHECK`
- profile ownership is `profiles.id = auth.uid()`
- journal ownership is `user_id = auth.uid()` on parent and child tables
- `service_role` keeps explicit grants for server-only workflows and continues
  to stay out of public clients

## Consequences

Positive:

- cross-user reads and writes are denied in the database
- user-owned tables remain safe even when exposed through Supabase APIs
- child tables inherit the same ownership model as parent journal rows
- local verification can assert negative access cases after every migration

Tradeoffs:

- any future table in `public` now needs explicit grants and policies, not just
  schema creation
- service-role paths still need code review discipline because `service_role`
  bypasses RLS by design
