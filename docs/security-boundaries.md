# Security Boundaries

Status: active guidance for M7 security hardening.

This document defines Lumen's current application security boundaries for
Supabase-backed user data and the API gateway.

## Current Boundary Model

Lumen currently has two different backend surfaces:

- Supabase for authenticated user-owned data such as profiles and journal data
- the Node API gateway for stateless AI operations such as rewrite, theme
  detection, transcription, and resource suggestions

These two surfaces have different trust rules.

## Supabase User-Owned Data

For user-owned data, the source of authorization is:

1. the authenticated Supabase session
2. database RLS policies

Current rules:

- Flutter clients may only access rows owned by the signed-in user
- repository and cloud-store code must not silently operate on another
  `userId`
- RLS remains the final enforcement layer even if client code is buggy
- `service_role` keys are reserved for server-only workflows and never exposed
  to Flutter

The canonical RLS policy design lives in
[0010-user-owned-rls.md](/Users/joshuakimble/Documents/workspace/apps/Lumen/docs/decisions/0010-user-owned-rls.md).

## API Gateway

The current API gateway does not yet expose authenticated user-owned journal or
profile endpoints.

Current rules:

- the API accepts AI task input only
- the API must reject malformed enum and payload values
- the API must not trust request bodies for ownership decisions
- any future authenticated route must derive identity from a verified auth
  token or server-side session, never from a user-supplied `userId`

Until authenticated routes exist, `#80` hardening on the API side is limited to
request validation, safe error handling, and documentation of the future
boundary.

## Future Authenticated Endpoint Rule

When Lumen adds authenticated API endpoints for user-owned data:

- require a verified auth token on every protected route
- resolve the acting user from the verified token/session
- ignore or reject any body/query/path ownership field that conflicts with the
  verified identity
- validate enum-like settings values server-side even if Flutter already
  constrains them in UI
- keep server logs free of raw journal text and secrets

## Current Coverage

Current M7 coverage now includes:

- RLS policies and negative verification SQL for profiles and journal tables
- client-side ownership assertions in Supabase profile and journal cloud data
  access layers
- API request validation for rewrite personalization and other enum-like inputs

Open follow-up work:

- [#80](https://github.com/JoshuaKimble/Lumen/issues/80): additional boundary
  hardening as authenticated API routes appear
- [#83](https://github.com/JoshuaKimble/Lumen/issues/83): full account deletion
  orchestration
- [#101](https://github.com/JoshuaKimble/Lumen/issues/101): export path
- [#102](https://github.com/JoshuaKimble/Lumen/issues/102): audit baseline
