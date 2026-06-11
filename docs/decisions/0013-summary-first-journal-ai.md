# 0013: Summary-First Journal AI

- Status: accepted
- Date: 2026-06-11

## Context

Lumen started with a rewrite-first journal AI flow. Saving a typed or voice
entry automatically generated:

- rewritten text
- title and summary
- themes

Entry detail also displayed the AI rewrite as a primary artifact.

That default behavior worked better for thought organization and note cleanup
than for private journaling. For emotionally sensitive or stream-of-consciousness
entries, automatic rewriting added too much product weight to a transformation
that is not core to the current app value.

The product direction is to prioritize:

- preserving the original entry
- generating a short summary
- detecting themes
- suggesting related resources

The existing rewrite capability should remain available as a lower-level
backend capability for a future, explicitly-invoked editor experience.

## Decision

Lumen will use a summary-first AI pipeline for core journal flows.

Current typed save, voice save, and admin regenerate behavior will:

- generate title and summary metadata
- detect themes
- refresh related resource suggestions through theme invalidation

They will not:

- automatically generate a rewrite
- display stored rewrite text in the core journal detail experience

Existing `rewritten_text` data remains in the model for backward compatibility
and future editor work, but it is no longer part of the default journaling UX.

When a user edits original journal text, any previously stored rewrite is
cleared so stale transformed content does not silently remain attached to a
different source entry.

## Consequences

### Positive

- Core journaling becomes more trustworthy and less intrusive.
- The product emphasizes summary, themes, and resources, which are more broadly
  useful across personal journaling and note-taking.
- Future editor work can be designed as a deliberate, reusable feature instead
  of inherited from automatic save behavior.

### Negative

- Existing rewrite personalization settings remain mostly dormant until the
  future editor capability is built.
- The data model still carries `rewritten_text` and related fields for now,
  which adds some temporary conceptual overhead.

## Follow-up

- Keep rewrite endpoint support for future manual editor work.
- Design the future editor as a separate feature with explicit user intent,
  separate UX framing, and likely separate storage semantics from the original
  journal entry summary pipeline.
