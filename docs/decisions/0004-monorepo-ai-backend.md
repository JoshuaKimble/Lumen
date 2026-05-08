# 0004: Monorepo With AI Backend

Date: 2026-05-06

## Context

Lumen is a voice-first AI journal. The Flutter app needs backend-supported
transcription, rewriting, theme detection, and future resource suggestions.
Keeping product requirements, architecture, API contracts, app code, and backend
code in one Codex-designed project will make cross-cutting changes easier to
reason about.

## Decision

Use a monorepo for Lumen. Standardize on:

- `apps/mobile` for the Flutter app.
- `apps/api` for a Node.js TypeScript AI backend gateway.
- `packages/api_contracts` for OpenAPI contracts and generated clients.
- `docs/` for product, architecture, technical planning, and decision records.

The Flutter app remains local-first for MVP journal data. The backend gateway
owns AI provider credentials, prompts, transcription, rewriting, theme
detection, validation, and mock AI responses.

## Consequences

- App and backend changes can evolve together in one Git history.
- OpenAPI becomes the source of truth for the Flutter/backend boundary.
- The Flutter project lives in `apps/mobile`.
- Root-level commands and CI should eventually validate Flutter, API, and
  contract packages together.
- Cloud sync, auth, encryption, backend deployment, and AI provider selection
  still require separate ADRs.
