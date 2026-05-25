# 0007: Journal Sync Conflict Policy

Date: 2026-05-25

## Context

M6 introduces cloud-backed journal persistence and local/cloud composition.
Once both sides can mutate the same journal entry, Lumen needs one deterministic
rule for merge behavior across startup hydration and queued sync flushes.

The product constraint is stronger than ordinary last-write-wins: the user's
original journal text is the source of truth and must never be silently lost in
concurrent edit or rewrite-regeneration races.

## Decision

Use a conservative journal-entry conflict policy:

- provisional winner is chosen by `client_updated_at`, then `version`, then
  local deterministic tie-break
- rewrite-only conflicts use winner-takes-all last-write-wins
- any `original_text` conflict invalidates AI-derived state
- when originals conflict, preserve the losing original text in conflict
  metadata
- when both original and rewrite state conflict, mark the result as requiring
  manual review and regeneration

AI-derived state includes:

- rewritten text
- title
- summary
- themes
- related resources
- regeneration timestamp

## Consequences

- Startup hydration and queued sync can share one merge rule instead of
  reimplementing conflict logic separately.
- Lumen favors correctness and source-text safety over retaining possibly stale
  rewrite output.
- Some conflicts will intentionally clear derived AI state and require
  regeneration, which is more disruptive than naive last-write-wins but safer.
- Later M6 work can choose how to surface preserved losing text to users or
  diagnostics without changing the merge semantics.
