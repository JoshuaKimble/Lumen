# Privacy Controls V1

Status: active prelaunch guidance for M7.

This document defines Lumen's current V1 privacy controls for retention,
export, and auditability.

It is intentionally narrow:

- document what Lumen does today
- document what Lumen does not promise yet
- point future implementation work at explicit follow-up issues

## Product Baseline

Lumen is a private journaling product.

Current product commitments:

- the user's original entry remains the source of truth
- AI rewrites are suggestions, not replacements
- users can edit and delete entries
- user-owned cloud data is isolated with Supabase RLS
- server-only credentials stay out of Flutter clients

These product expectations come from
[product-requirements.md](/Users/joshuakimble/Documents/workspace/apps/Lumen/docs/product-requirements.md)
and the M6-M7 Supabase decisions.

## Data Surfaces

Lumen currently stores or processes user-owned data in these places:

- device-local journal storage in Flutter
- device-local sync queue metadata for signed-in journal writes
- shared prelaunch cloud Supabase tables for profiles and journal data
- transient API request/response handling for AI rewrite, theme detection, and
  transcription

Lumen should treat journal text, transcript text, profile data, and derived AI
content as sensitive user data.

## Retention Policy

### Journal and Profile Data

- Local device data is retained until the user deletes the entry, signs out and
  later removes local app data, or uninstalls/clears storage.
- Shared-cloud Supabase data is retained until the user deletes it or until the
  team performs a deliberate prelaunch environment reset.
- The shared cloud project is prelaunch infrastructure, not a production-grade
  archival promise.

This means Lumen should not yet promise indefinite retention, formal backup
recovery, or production-style restore guarantees before public launch.

### Deletion Expectations

- Entry deletion should remove the local copy immediately and queue cloud
  deletion when signed in.
- Full account deletion is tracked separately in
  [#83](https://github.com/JoshuaKimble/Lumen/issues/83).
- Until `#83` lands, Lumen should not claim that one action removes all
  profile, journal, and auth data everywhere.

### Logs and Debug Output

- Raw journal text, transcripts, prompts, provider payloads, and secrets must
  not be written to routine application or API logs.
- Operational logs may record safe metadata such as status codes, retry counts,
  sync state, and coarse error categories.

## Export Stance

Lumen does not yet provide a user-facing export feature in V1.

Current policy:

- do not promise structured export yet
- do not imply that Supabase tables or local storage are a supported user
  export format
- keep the data model and ownership boundaries stable enough to add export
  later without breaking user trust

Export planning and implementation are tracked in
[#101](https://github.com/JoshuaKimble/Lumen/issues/101).

When export lands, the default target should be user-owned data only:

- profile row
- journal entries
- related themes and resources
- resource feedback

Future export work should prefer a simple, inspectable format first, likely
JSON before any richer packaged export flow.

## Auditability Baseline

Lumen does not yet have a dedicated audit event store.

Current baseline:

- rely on database ownership controls and safe operational logs
- avoid storing raw journal text in any future audit event stream
- distinguish internal audit records from user-visible activity history

The first audit event set should focus on sensitive actions, not routine
journaling edits:

- account deletion request and completion
- password reset and other security-sensitive account recovery actions
- future export requests and completions
- privileged server-only maintenance actions when they affect user-owned data

Audit event planning and later implementation are tracked in
[#102](https://github.com/JoshuaKimble/Lumen/issues/102).

## Security Boundaries

Current M7 boundaries are:

- database ownership is enforced with RLS, not trusted client `user_id` input
- `service_role` access is reserved for server-only paths
- Flutter clients only receive client-safe Supabase credentials
- API routes must continue to avoid logging raw sensitive payloads

The current user-owned table policy is documented in
[0010-user-owned-rls.md](/Users/joshuakimble/Documents/workspace/apps/Lumen/docs/decisions/0010-user-owned-rls.md).

## Follow-Up Issues

- [#83](https://github.com/JoshuaKimble/Lumen/issues/83): full account
  deletion orchestration
- [#101](https://github.com/JoshuaKimble/Lumen/issues/101): user-owned export
  path
- [#102](https://github.com/JoshuaKimble/Lumen/issues/102): audit event
  baseline

Issue [#80](https://github.com/JoshuaKimble/Lumen/issues/80) remains the next
security hardening step for authenticated API and Supabase access patterns once
those user-owned API boundaries are implemented.
