# 0001: Flutter Riverpod Foundation

Date: 2026-05-06

## Context

Lumen needs a cross-platform foundation for Android, iOS, and web that remains
easy for Codex sessions and human contributors to understand.

## Decision

Use Flutter for the app, Riverpod for state and dependency injection, GoRouter
for navigation, and repo-canonical documentation for project memory.

## Consequences

- App state and dependencies should be expressed through providers.
- Navigation should be centralized in app routing.
- Architecture changes should update `AGENTS.md`, `docs/architecture.md`, or a
  new decision record in the same change.
