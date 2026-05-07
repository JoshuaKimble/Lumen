# Lumen Technical Plan

This is the canonical build roadmap for turning the current Flutter scaffold
into the product described in `docs/product-requirements.md`.

## Summary

Lumen will be developed as a monorepo containing the Flutter app, AI backend
gateway, shared API contracts, documentation, and future support apps. The MVP
will remain local-first for journal data while using a backend gateway for AI
transcription, rewriting, and theme detection.

Technical defaults:

- Monorepo layout: `apps/` and `packages/`.
- Flutter app: `apps/mobile`.
- AI backend gateway: `apps/api`.
- Backend runtime: Node.js and TypeScript.
- API contracts: OpenAPI with generated Flutter client code.
- State management: Riverpod.
- Routing: GoRouter.
- MVP persistence: local-first Flutter storage.
- Voice flow: record audio, transcribe through backend, review transcript, then
  save.

## Target Repository Shape

The current Flutter-root repo should migrate into this layout before major MVP
feature work:

```text
apps/
  mobile/
    lib/
    test/
    android/
    ios/
    web/
  api/
    src/
    test/

packages/
  api_contracts/
    openapi/
    generated/

docs/
  architecture.md
  product-requirements.md
  technical-plan.md
  principles.md
  decisions/
```

Root-level files should own shared project memory, Git hooks, repo scripts, and
future CI. App-specific tooling should stay inside the relevant app directory.

## Architecture

Keep the current Flutter architecture principles:

- `lib/src/app` owns app shell, routing, theme, and app-wide composition.
- `lib/src/features/<feature>` owns product behavior by feature.
- Feature folders use `domain`, `data`, and `presentation` boundaries when they
  reduce complexity.
- Riverpod owns state and dependency injection.
- GoRouter owns navigation.
- Widgets should not call backend, AI, persistence, or platform SDKs directly.
- AI, voice recording, transcription, and persistence should sit behind
  repository or service contracts.

The backend should be a gateway, not the MVP system of record for journal data.
It owns AI provider calls, API secrets, prompt templates, response validation,
and safety constraints.

## Domain Model

Define the journal model around preserving the user's original entry and AI
rewrite together.

Core types:

- `JournalEntry`
  - `id`
  - `createdAt`
  - `updatedAt`
  - `source`
  - `originalText`
  - `rewrittenText`
  - `themes`
  - `resources`
  - optional `title`
  - optional `summary`
  - optional `lastRegeneratedAt`
- `EntrySource`
  - `voice`
  - `text`
- `JournalTheme`
  - `id`
  - `name`
  - `displayName`
  - optional `weight`
- `RelatedResource`
  - `id`
  - `title`
  - `type`
  - optional `url`
  - optional `entryId`
  - optional `themeId`
- `TranscriptionResult`
  - `transcript`
  - optional confidence or provider metadata
- `RewriteResult`
  - `rewrittenText`
  - optional title
  - optional summary
- `ThemeDetectionResult`
  - themes

Do not split original and rewritten text into separate entries. They are two
representations of the same journal entry.

## MVP Roadmap

### 1. Monorepo Migration

- Move the current Flutter project into `apps/mobile`.
- Preserve package name, bundle id, tests, generated platform folders, and
  current feature-first structure.
- Update root docs, Git hooks, README commands, and future scripts for the new
  layout.
- Add an ADR if the migration changes project commands or package boundaries.

### 2. Domain And Local Persistence

- Replace the starter in-memory model with the domain types in this plan.
- Keep repository contracts in the domain layer.
- Add local persistence behind repository interfaces.
- Support create, read, update, delete, list by date, and list by theme.
- Keep storage local for MVP. Defer cloud sync, auth, and encryption until ADRs
  define them.

### 3. Core Journal UX

- Build entry list with date, title or summary, preview text, and themes.
- Build entry detail with original text, rewritten text, themes, resources,
  created date/time, and optional summary/title.
- Build text entry creation.
- Support edit and delete.
- Make original and rewritten versions visually distinct.
- Make rewrite copy clear: AI output is a suggestion, not a replacement.

### 4. Backend AI Gateway

- Create `apps/api` as a Node.js TypeScript service.
- Add endpoints for:
  - audio transcription
  - entry rewriting
  - theme detection
  - future resource suggestions
- Keep provider API keys and prompt templates on the backend.
- Validate requests and responses.
- Provide local mock mode so Flutter UI work can continue without live AI calls.
- Store no permanent journal data in the backend for MVP.

### 5. OpenAPI Contracts

- Create `packages/api_contracts`.
- Define backend request/response contracts in OpenAPI.
- Generate or maintain typed Flutter API client code from the OpenAPI spec.
- Add contract checks so backend and Flutter changes do not drift.
- Treat OpenAPI as the source of truth for the app/backend boundary.

### 6. AI Workflow Integration

- Flutter sends transcript or typed original text to the backend gateway.
- Backend returns rewritten text and themes.
- Flutter saves original text, rewritten text, and themes together on the entry.
- Add regenerate flow for rewritten text after the first MVP loop works.
- Keep AI behavior aligned with product requirements:
  - preserve meaning and perspective
  - avoid diagnosis
  - avoid unsupported conclusions
  - avoid clinical, preachy, generic, or overly polished language
  - avoid turning every entry into advice

### 7. Voice-First Capture

- Add audio recording as the primary capture path.
- Request platform permissions clearly.
- Let users start and stop recording quickly.
- Send audio to backend transcription endpoint.
- Let users review and edit transcript text before saving.
- Store the transcript as the original entry text.
- Keep typed entry creation available as a first-class alternative.

### 8. Themes And Reflection

- Aggregate themes across entries.
- Add a basic word cloud or theme visualization.
- Make theme prominence reflect frequency or significance.
- Let users tap a theme to view related entries.
- Add theme detail with related entries and room for future AI insights.
- Defer related resources until the core theme loop works, unless needed for an
  early product demo.

### 9. Privacy And Trust

- Make entries feel private and user-owned.
- Preserve original text at all times unless the user deletes the entry.
- Add edit, delete, regenerate, and view-original actions.
- Avoid implying AI is a therapist, judge, preacher, or coach.
- Add explicit copy where needed to explain that rewrites are suggestions.
- Defer auth, cloud sync, encryption, and export until ADRs establish their
  product and technical requirements.

## Backend Gateway Responsibilities

`apps/api` should stay focused:

- Accept audio for transcription.
- Accept text for rewriting and theme detection.
- Own provider credentials.
- Own prompt templates and response schemas.
- Apply AI behavior constraints.
- Return structured responses to Flutter.
- Support mock responses for tests and offline UI development.

It should not own journal history, user accounts, billing, notifications, or
analytics in the MVP.

## Testing Strategy

### Flutter

- Run `flutter analyze`.
- Run `flutter test`.
- Add domain tests for entry source handling, text preservation, and theme
  aggregation.
- Add repository tests for create, update, delete, list by date, and list by
  theme.
- Add provider tests for entry loading, transcription states, rewrite states,
  and theme states.
- Add widget tests for entry list, entry detail, text creation, original vs
  rewritten display, and theme navigation.

### API

- Run TypeScript type checks.
- Add unit tests for request validation, prompt builders, and response parsing.
- Add endpoint tests using mock AI providers.
- Add contract tests against the OpenAPI spec.
- Add tests that reject malformed AI responses before they reach Flutter.

### Monorepo

- Add root commands that check all apps and packages.
- Keep `.githooks/commit-msg` active for Conventional Commits.
- Add CI later to run Flutter checks, API checks, and contract checks together.

## Release Readiness Checklist

MVP is ready for user testing when:

- Users can create entries by voice and text.
- Voice entries are transcribed and reviewed before save.
- Original text is saved and always viewable.
- AI rewritten text is generated and displayed separately.
- Themes are detected, saved, visualized, and tappable.
- Entry list and entry detail work from persisted local data.
- Users can edit, delete, and regenerate entries.
- AI responses follow product tone and safety requirements.
- Android, iOS, and web have been manually smoke-tested.
- Known local setup blockers from `AGENTS.md` have been resolved or documented.

## Open Decisions

These need ADRs before implementation:

- Local database choice.
- Whether and when to encrypt local journal data.
- Authentication and cloud sync strategy.
- Backend deployment platform.
- AI provider selection.
- Audio format and upload limits.
- Generated client tooling for OpenAPI.
- Related resources source and policy.
- Export format and data portability.

