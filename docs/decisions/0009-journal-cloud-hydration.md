# 0009: Journal Cloud Hydration

- Status: Accepted
- Date: 2026-05-25

## Context

M6 adds cloud-backed journal persistence for signed-in users, but Lumen remains
usable offline and local-first. Returning users need their cloud-backed journal
data to reappear after sign-in without blocking immediate entry creation or
editing.

The app already has:

- a local journal store for the current device state
- a write-through sync queue for pending upserts and deletes
- a conflict policy for deciding when local or cloud content wins

Startup hydration needs to reuse those primitives instead of bypassing them.

## Decision

Lumen will hydrate journal entries from the cloud in the background after the
authenticated repository is built.

The hydration design is:

- startup hydration never blocks local journaling
- cloud reads happen in pages so larger datasets can merge incrementally
- cloud-only entries are written into local storage immediately
- queued local deletes prevent the deleted cloud entry from being restored
- queued local upserts are treated as the effective local version during merge
- when both local and cloud versions exist, the journal conflict resolver makes
  the final decision before local storage is updated
- hydration publishes a repository refresh signal after changed pages so Riverpod
  readers can rebuild with the merged data

## Consequences

Positive:

- returning signed-in users see cloud-backed entries reappear without a blocking
  splash or migration step
- offline-first behavior stays intact because local reads and writes remain
  available during hydration
- large accounts can hydrate progressively instead of requiring one full fetch
- merge behavior stays consistent with the existing sync conflict policy

Tradeoffs:

- hydration adds another background process to repository composition
- provider refreshes are coarse-grained and may rebuild more UI than a future
  streaming approach
- the current hydration pass only covers journal entries and embedded related
  resources; resource feedback remains on the local/API path until later cloud
  persistence work lands
