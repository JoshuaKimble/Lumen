# 0002: Clean Code Principles

Date: 2026-05-06

## Context

The project needs durable coding principles before product details are fully
defined. The team values clean code, simplicity, consistency, and maintainable
architecture.

## Decision

Use `docs/principles.md` as the canonical engineering principles guide and keep
the most operational rules summarized in `AGENTS.md` for Codex sessions.

## Consequences

- Future implementation should favor readable, simple, focused code over clever
  or highly configurable designs.
- Changes that establish or revise engineering standards should update project
  memory in the same commit.
- Tests should optimize for behavioral clarity, speed, independence, and
  repeatability.
