# Journal Sync Conflict Policy (M6)

This document defines the baseline conflict policy for cloud sync of journal
entries.

## Goals

- Keep merge behavior deterministic.
- Never silently lose a user's original journal text.
- Prefer safe fallback over preserving stale AI output.
- Give later sync layers one reusable policy for queue flushes and startup
  hydration.

## Ordering Rule

The baseline winner selection order is:

1. Newer `client_updated_at`
2. Higher `version`
3. Local row wins ties deterministically

This only decides which side is the provisional winner. It does **not** mean
every field from the winner is always safe to keep.

## Resolution Rules

### 1. No meaningful conflict

If original text and AI-derived fields match, keep the winner unchanged.

### 2. Rewrite-only conflict

If `original_text` matches but AI-derived fields differ:

- keep the winning row
- preserve the losing rewritten text in conflict metadata
- do not require manual review

This is standard last-write-wins because the user's original words are still
identical.

### 3. Original-text conflict with matching AI state

If `original_text` differs but the rewrite, title, summary, themes, and
resources match:

- keep the winning original text
- clear rewritten text, title, summary, themes, resources, and regeneration
  timestamp
- require rewrite regeneration
- preserve the losing original text in conflict metadata

The rewrite is treated as stale because it can no longer be trusted to match
the surviving original text.

### 4. Original-text conflict with AI conflict

If both `original_text` and AI-derived fields differ:

- keep the winning original text
- clear rewritten text, title, summary, themes, resources, and regeneration
  timestamp
- mark the result as manual conflict
- require rewrite regeneration
- preserve the losing original text and losing rewritten text in conflict
  metadata

This is the safest fallback for concurrent edit and regeneration races.

## Why Clear AI-Derived Fields

Lumen treats the original entry as the source of truth. When originals diverge,
the rewrite, title, summary, themes, and related resources can all be stale or
derived from a different text body. Keeping them would risk presenting
plausible but incorrect content as if it still belonged to the surviving entry.

Clearing that derived state is intentionally conservative.

## Intended Reuse

This policy is the baseline for:

- write-through sync queue flushes
- startup cloud hydration with local merge
- future conflict diagnostics surfaced to users or logs

The current implementation lives in:

- [journal_entry_conflict_resolver.dart](/Users/joshuakimble/Documents/workspace/apps/Lumen/apps/mobile/lib/src/features/journal/domain/journal_entry_conflict_resolver.dart)
