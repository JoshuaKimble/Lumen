# Lumen Technical Context Dump (Supabase Transition)

Last updated: 2026-05-17
Repository: `JoshuaKimble/Lumen`

## 1) Snapshot Summary

Lumen is a Flutter-first, voice-enabled AI journaling application in a monorepo. It currently supports local-first journaling with AI-assisted summary metadata, theme detection, and an entry-based Study Guide flow. The architecture is transitioning to Supabase for user-owned cloud persistence, authentication, and security boundaries.

The current backend API remains an AI gateway and should continue to own provider secrets and prompt orchestration. OpenAI access should not move to the Flutter client.

## 2) Monorepo Structure

- `apps/mobile` (Flutter app: iOS, Android, Web)
- `apps/api` (Node.js + TypeScript AI gateway)
- `packages/api_contracts` (OpenAPI source + generated Dart client)
- `docs` (product, architecture, ADRs, workflow, backlog)

## 3) Current Product State

### Implemented in Flutter

- Journal entry list/detail/create/edit/delete
- Voice recording and transcript review
- AI rewrite generation and rewrite regeneration
- Theme cloud and theme detail views
- Related resources UI
- Resource feedback UI/actions
- Persisted theme preference settings (light/dark/system)
- Cross-page navigation improvements for easier test workflows

### Persistence Today

- Journal entries: local persistence (SharedPreferences-backed repository)
- Resource feedback: local persistence
- No cloud sync yet

### API Runtime Today

Implemented endpoints:
- `GET /health`
- `POST /v1/entries/rewrite`
- `POST /v1/entries/themes/detect`
- `POST /v1/transcriptions`
- `POST /v1/resources/suggest`

Contract-defined but pending runtime implementation:
- `POST /v1/resources/feedback`

## 4) Architecture and Standards Already Established

- Flutter + Riverpod + GoRouter foundation
- OpenAPI-first contract workflow with generated Flutter client
- Monorepo ADR decision captured (`docs/decisions/0004-monorepo-ai-backend.md`)
- Clean code principles documented (`docs/decisions/0002-clean-code-principles.md`)
- Conventional Commits ADR documented (`docs/decisions/0003-conventional-commits.md`)
- GitHub Issues used as the primary task system

## 5) Supabase Plan (Authoritative Direction)

Supabase is the planned system of record for user-owned data and auth:

- Supabase Auth for account/session management
- Postgres for durable user-owned journaling and preference data
- Row Level Security (RLS) for strict per-user isolation
- Migration tooling and environment isolation (dev/staging/prod)
- Hybrid local + cloud sync model (offline-capable UX retained)

### Critical boundary decisions

- Keep AI provider credentials server-side in `apps/api`
- Keep `apps/api` as AI gateway/orchestrator
- Do not place OpenAI keys or direct provider access in Flutter

## 6) Open Gaps (Not Yet Implemented)

- Supabase integration in mobile and API
- Authentication + account lifecycle
- User profile model and onboarding completion workflow
- Cloud persistence and sync engine
- Conflict resolution policy and sync diagnostics
- RLS policies and security hardening
- Full account deletion orchestration
- Monetization-ready entitlement scaffolding

## 7) Planned Delivery Structure (Epics + Child Issues)

Open epics:

- `#46` Epic M1: Supabase Foundation
- `#47` Epic M2: Authentication (Email/Password + Verification)
- `#48` Epic M3: Profiles and Onboarding
- `#55` Epic M4: AI Personalization Settings
- `#50` Epic M5: Scripture App Preference Routing
- `#51` Epic M6: User-Owned Cloud Persistence + Sync
- `#49` Epic M7: Security and RLS Hardening
- `#54` Epic M8: Account Management + Deletion
- `#53` Epic M9: Monetization-Ready Entitlement Architecture
- `#52` Epic M10: API and OpenAPI Contract Alignment

Child issues are already created (currently `#56` through `#89` for this roadmap slice), including:

- Supabase environments/migrations/bootstrap/runbook/CI drift checks
- Auth UI + services + auth-aware routing + error handling
- Profiles schema + onboarding + profile settings
- AI personalization model and prompt integration
- Scripture preference model + recommendation routing
- Journal schema + hybrid repositories + sync queue + conflict policy
- RLS policies + security boundary hardening + privacy planning
- Account settings + destructive account deletion orchestration
- Entitlement and AI usage metering foundation
- API contract alignment + authenticated client/session propagation

## 8) Recommended Execution Order

1. M1 Foundation (`#56-#60`)
2. M2 Auth (`#61-#64`)
3. M3 Profiles/Onboarding (`#65-#68`)
4. M6 Cloud Persistence Core (`#74`, `#76`, `#77`, `#75`)
5. M7 Security/RLS (`#81`, `#80`, `#79`)
6. M10 API/Contracts (`#87`, `#88`, `#89`)
7. M4 + M5 personalization and scripture routing (`#69-#73`)
8. M8 account management/deletion (`#82-#83`)
9. M9 monetization readiness (`#84-#86`)

## 9) Proposed Data Model Direction (Supabase)

Core tables:
- `profiles` (1:1 with `auth.users`)
- `journal_entries`
- `journal_themes`
- `related_resources`
- `resource_feedback`

Likely sync metadata on user-owned rows:
- `client_updated_at`
- `sync_state`
- `version`

Ownership:
- every user-owned row keyed by `user_id`
- enforce access with RLS (never trust client-submitted `user_id` blindly)

## 10) Auth + Onboarding Direction (V1)

V1 auth strategy:
- email/password only
- email verification required

Target flow:
1. Register
2. Verify email
3. Complete profile setup
4. Enter app

Future providers (Google/Apple) are explicitly future work.

## 11) AI Personalization Direction

Move from hardcoded rewrite behavior to profile-driven prompts:

- rewrite tone preference
- preserve-original-voice preference
- scripture ecosystem preference routing

AI should remain reflective and non-diagnostic, with original text preserved as source of truth.

## 12) Security and Privacy Requirements

- RLS on all user-owned tables
- authenticated-only access patterns for user data
- clear account deletion path in V1
- clear data ownership messaging
- retention/export/audit approach documented and incrementally implemented

## 13) Monetization Constraint to Preserve

Future subscription gating must not block access to existing journal history.

Architecture should separate:
- journal data read/write ownership
- AI generation entitlement

## 14) Build/Validation Commands

Repository checks:
- `./scripts/check.sh`
- `./scripts/check_mobile.sh`
- `./scripts/check_api.sh`
- `./scripts/check_contracts.sh`

## 15) Prompt Block for ChatGPT (Copy/Paste)

Use this context as the source of truth for planning and implementation guidance:

- App: Lumen (Flutter journal app; iOS/Android/Web)
- Monorepo: Flutter app + Node/TypeScript AI gateway + OpenAPI contracts package
- Current state: local-first journaling with AI rewrite/themes/resources; no cloud sync yet
- Direction: adopt Supabase for auth + Postgres + RLS + user-owned cloud persistence
- Constraint: keep OpenAI/provider access server-side in AI gateway, not in Flutter
- Workflow: GitHub Issues and Conventional Commits
- Existing roadmap: Epics #46-#55 and implementation issues #56-#89 already created
- Product priority: preserve original journal entries, reflective AI assistance, privacy and trust
- Security priority: strict user isolation and account deletion support in V1
- Future constraint: monetization can gate AI generation, but must not block reading existing journals

When proposing implementation details, align with Riverpod + GoRouter patterns in Flutter, OpenAPI-first contracts, and incremental rollout across milestones.
