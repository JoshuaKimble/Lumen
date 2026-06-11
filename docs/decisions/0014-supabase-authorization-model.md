# 0014: Supabase Authorization Model Review

- Status: accepted
- Date: 2026-06-11

## Context

Lumen uses Supabase Auth for signed-in identity and RLS-protected tables in the
`public` schema for user-owned data. A recent change introduced an internal
admin-only UI action for AI regeneration, which required an authorization
decision beyond basic user ownership.

The team wanted to validate that the implementation follows Supabase guidance
closely enough to remain maintainable, understandable, and easy to evolve. The
main goal of this review was to avoid drifting into a custom authorization model
that would be harder for future developers and AI agents to reason about.

## Current State

Lumen's current admin capability model is intentionally small:

- signed-in identity comes from Supabase Auth
- user-owned data access is enforced with RLS
- internal admin access is represented by a server-managed
  `public.user_capabilities` table keyed 1:1 to `auth.users`
- the first capability is `is_admin boolean not null default false`

This model is implemented in:

- [20260611033747_add_user_capabilities_table.sql](/Users/joshuakimble/Documents/workspace/apps/Lumen/supabase/migrations/20260611033747_add_user_capabilities_table.sql)
- [0012-supabase-user-capabilities.md](/Users/joshuakimble/Documents/workspace/apps/Lumen/docs/decisions/0012-supabase-user-capabilities.md)

Admin handling currently works like this:

- `authenticated` users may only `select` their own capability row through RLS
- `authenticated` users may not `insert`, `update`, or `delete`
- `service_role` may manage capability rows for administrative workflows
- the Flutter client hydrates the current user's capability row and derives
  admin UI access from `is_admin`

This is currently used to gate an internal UI control, not to grant broad
cross-user privileges.

This approach was chosen because it:

- removed the earlier hardcoded email allowlist
- kept authorization data out of user-editable profile data
- stayed compatible with browser-safe Supabase access patterns
- solved the immediate need without introducing JWT hooks or a broader RBAC
  system prematurely

## Investigation Summary

This review compared Lumen's implementation against Supabase's current
documentation for:

- users and access tokens
- row level security
- custom access token hooks
- role-based access control with custom claims

Relevant Supabase references:

- Users:
  https://supabase.com/docs/guides/auth/users
- Row Level Security:
  https://supabase.com/docs/guides/database/postgres/row-level-security
- Custom Access Token Hook:
  https://supabase.com/docs/guides/auth/auth-hooks/custom-access-token-hook
- Custom Claims and RBAC:
  https://supabase.com/docs/guides/api/custom-claims-and-role-based-access-control-rbac

Key findings:

1. Lumen aligns with Supabase guidance in important ways.
   - Authorization data is not stored in `raw_user_meta_data`.
   - Authorization data is not stored in the user-owned `profiles` table.
   - RLS is enabled on the exposed authorization table.
   - `service_role` is reserved for server-side writes.

2. Lumen diverges from Supabase's documented RBAC pattern.
   - Supabase's standard RBAC guidance is to model roles in SQL, add them to
     JWT claims via a custom access token hook, and use those claims in RLS or
     authorization helpers.
   - Lumen does not currently use JWT custom claims, a custom access token
     hook, `user_roles`, or `role_permissions`.
   - Instead, Lumen reads a server-managed capability row after sign-in and
     uses that result for client capability gating.

3. The divergence is acceptable for the current scope, but it is not a full
   long-term authorization model.
   - The current design behaves more like a service-managed feature or
     capability flag than a full RBAC system.
   - It is simple and understandable for one internal admin affordance.
   - It does not yet provide the clean Supabase-native path needed for richer
     roles, permission-based RLS, or privileged server workflows.

Intentional divergences:

- Lumen currently prefers a direct table read over JWT-carried role claims for
  this admin capability. This avoids adding hook complexity before it solves a
  real problem and avoids depending on JWT refresh timing for a narrow internal
  UI gate.

Unnecessary complexity that was explicitly avoided:

- putting authorization in user-editable metadata
- mixing authorization into the user-owned `profiles` model
- introducing RBAC tables and hooks before Lumen has multiple roles or
  permission classes to justify them

## Decision

Lumen will keep the current `public.user_capabilities` implementation for now.

This is an intentional temporary decision, not a declaration that the current
model is the final authorization architecture.

### Reasoning

The current approach is the right level of complexity for the problem it solves
today:

- one internal admin capability
- one signed-in user reading their own capability row
- one client-side UI gate

It is more maintainable than the earlier hardcoded email check and does not
conflict with Supabase security guidance.

At the same time, the team should treat this as a bounded capability model, not
as a general-purpose roles system. The current design is intentionally boring
for the present use case, but it should not be stretched into a larger
authorization framework if requirements expand.

Tradeoffs considered:

- Keeping the current model avoids premature hook and JWT-claim complexity.
- Moving immediately to full RBAC would be more aligned with Supabase's
  documented pattern, but it would add infrastructure that Lumen does not yet
  need.
- Remaining on the current model too long would create friction if future work
  needs server-side admin enforcement, multi-role support, or permission-based
  policies.

## Future Migration Considerations

If Lumen's authorization requirements grow, the preferred future direction is
to adopt Supabase's documented RBAC pattern:

1. Add SQL-backed application roles such as `app_role` and `user_roles`.
2. Add `role_permissions` if permissions become more granular than simple role
   membership.
3. Use a custom access token hook to project role information into JWT claims.
4. Use those claims in RLS policies and focused authorization helpers for
   privileged workflows.

This is the likely migration target because it is the clearest match for
Supabase's published guidance and the easiest model for future engineers to
recognize.

Scenarios that should trigger a revisit:

- more than one privileged role is introduced
- permissions need to differ by feature, object type, or tenant boundary
- admin functionality starts affecting data owned by other users
- privileged access needs to be enforced on the API or in database policies,
  not just reflected in the UI
- capability checks become common enough that repeated client-side hydration is
  awkward or error-prone

High-level migration notes:

- keep user-owned profile data separate from authorization data
- do not use `raw_user_meta_data` for authorization
- validate the current Supabase hook and RBAC guidance before implementation
- plan for JWT refresh semantics when moving role data into claims
- prefer a migration that preserves the existing `user_capabilities` table
  temporarily as a bridge rather than forcing a single-cutover rewrite

## Periodic Re-evaluation

This decision should be revisited before any significant authorization change.

In particular, revisit it before:

- adding new admin or moderator capabilities
- introducing cross-user administrative actions
- implementing tenant or team boundaries
- pushing role checks into APIs or database policies

Supabase guidance changes over time. Any future migration work should begin by
revalidating the relevant Supabase documentation so the implementation follows
current platform conventions rather than assumptions captured in this record.

## Related Records

- [0010-user-owned-rls.md](/Users/joshuakimble/Documents/workspace/apps/Lumen/docs/decisions/0010-user-owned-rls.md)
- [0012-supabase-user-capabilities.md](/Users/joshuakimble/Documents/workspace/apps/Lumen/docs/decisions/0012-supabase-user-capabilities.md)
