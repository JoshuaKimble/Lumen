# Study Guide V1 Domain and Lifecycle

## Purpose

Define the V1 domain model and lifecycle for entry-based Study Guides.

This document is the domain contract for:

- `#113` Study Guide domain: define frozen entry-guide model and lifecycle
- `#115` Study Guide AI/API: add provider-constrained generation and sizing rules
- `#117` Study Guide integrations: implement provider-aware deep-link service with Gospel Library adapter
- `#120` Flutter: build V1 entry-based Study Guide page and manual completion UI

V1 only covers entry-based guides. Theme guides are deferred to V2.

## Core Decisions

### One Guide Per Entry in V1

Each journal entry may have zero or one Study Guide in V1.

- `zero` means a guide has not been generated yet or could not be generated
  with sufficient confidence
- `one` means a frozen guide artifact exists for that entry

V1 does not support multiple saved guide versions for a single entry.

### Frozen Artifact

An entry-based guide is a generated snapshot.

Once created, it does not auto-refresh when:

- the user opens the entry
- the user marks guide items complete
- related theme data changes elsewhere

The artifact is replaced only by an explicit future regeneration flow. V1 does
not require that regeneration flow to ship, but the model must allow a full
guide replacement later.

### Separate Artifact and Progress State

The guide artifact and completion state should persist separately.

Reason:

- the guide content is generated and mostly immutable
- completion state is lightweight user interaction state
- manual checkbox toggles should not rewrite the guide artifact itself

## V1 Domain Model

### `JournalEntry`

`JournalEntry` should gain an optional `studyGuide` field in V1.

This makes the guide a first-class generated outcome of the entry rather than a
transient suggestion list.

Recommended shape:

- existing journal entry fields remain unchanged
- add `StudyGuide? studyGuide`

`RelatedResource` can remain temporarily for migration compatibility, but new
Study Guide work should not expand the old resources model further.

### `StudyGuide`

Recommended fields:

- `id`
- `entryId`
- `providerKey`
- `generatedAt`
- `overview`
- `previewText`
- `items`
- `reflectionPrompt`

Field intent:

- `id`: stable guide identifier for persistence and progress lookups
- `entryId`: owning journal entry
- `providerKey`: selected study ecosystem used to generate the guide, such as
  `gospel_library`
- `generatedAt`: auditability for frozen-artifact behavior
- `overview`: short orienting paragraph shown near the top of the guide page
- `previewText`: short CTA preview text used on entry detail
- `items`: ordered study resources
- `reflectionPrompt`: required closing prompt

### `StudyGuideItem`

Recommended fields:

- `id`
- `kind`
- `title`
- `contextLine`
- `focusText`
- `quote`
- `author`
- `publishedContext`
- `position`
- `destination`

Field intent:

- `id`: stable item identifier inside the guide
- `kind`: `scripture`, `conference_talk`, or other supported V1 kind
- `title`: primary user-facing label
- `contextLine`: one-line explanation of why the item is included
- `focusText`: optional focus instruction such as `Focus on verses 6-12`
- `quote`: optional short excerpt, mainly for conference talks
- `author`: optional speaker/author display value
- `publishedContext`: optional date or conference context
- `position`: frozen order within the guide
- `destination`: provider-aware launch metadata

### `StudyGuidePrompt`

The required reflection prompt should be modeled separately from resource items.

Recommended fields:

- `text`

Reason:

- the prompt is required in every guide
- it does not behave like a provider-linked resource
- it should not complicate progress counting or deep-link routing

V1 should treat the reflection prompt as a required guide section, not as a
completion-tracked resource.

### `StudyGuideDestination`

Recommended fields:

- `providerKey`
- `contentType`
- `reference`
- `url`
- `precision`

Field intent:

- `providerKey`: target ecosystem, initially `gospel_library`
- `contentType`: `scripture`, `conference_talk`, or another supported provider
  content class
- `reference`: canonical provider-aware identifier or reference string
- `url`: fallback or launchable URL when available
- `precision`: degree of handoff accuracy

Recommended V1 precision enum values:

- `verse_range`
- `chapter`
- `document`
- `web_fallback`

This leaves room for `#116` and `#117` without forcing those link details into
the UI layer.

## Progress Model

### What Is Tracked

V1 tracks completion for resource items only.

- each `StudyGuideItem` can be complete or incomplete
- the reflection prompt is not part of completion counts in V1

### State Shape

Recommended V1 progress record:

- `guideId`
- `itemId`
- `isCompleted`
- `updatedAt`

### Persistence Decision

V1 completion state should persist outside the journal entry artifact in a
small local-only store.

Recommended implementation:

- SharedPreferences-backed JSON store keyed by `guideId`
- each guide maps item ids to completion state

Reason:

- matches current app patterns for lightweight per-user UI state
- avoids mutating the guide artifact for checkbox toggles
- avoids forcing cloud schema work into V1

Cloud-backed progress can be introduced later with a dedicated persistence
design rather than overloading entry writes.

## Lifecycle Rules

### Creation

A guide is generated from:

- the journal entry content
- detected themes
- the selected provider ecosystem

The generated guide should include:

- at least `1` study resource when confidence is sufficient
- a required reflection prompt

### Replacement

If a future explicit regeneration flow runs for an entry, the guide should be
replaced as a whole.

Replacement rules:

- old item ordering is discarded
- old guide metadata is discarded
- old progress should reset because item ids may no longer be valid

V1 does not support preserving completion state across regenerated guides.

### Entry Editing

Editing an entry should not silently mutate an existing guide artifact.

In V1:

- the entry can change
- the previously generated guide remains frozen
- a separate explicit regeneration action is required to replace it

This keeps the frozen-artifact rule consistent even if the entry text changes.

### Deletion

Deleting an entry should also remove:

- the attached guide artifact
- local completion state for that guide

## Sizing Inputs

The guide generation pipeline should size the guide using these V1 inputs:

1. high-confidence resource availability
2. richness
3. entry length

For V1, richness is the total number of detected themes on the entry.

Weighted theme influence is deferred to V2.

## Compatibility Boundaries

### Provider Constraint

Guide generation must be constrained by the selected provider ecosystem.

If the provider is `gospel_library`, the guide should only include resources
that the Gospel Library integration can support.

This applies to:

- candidate selection
- ranking
- destination metadata
- CTA precision expectations

### Reuse Boundary for V2

The model should remain reusable for future theme guides, but V1 should not add
theme-guide lifecycle behavior now.

Practical implication:

- keep `StudyGuide` entry-owned in V1
- avoid adding refresh scheduling, theme aggregation, or multi-origin guide
  semantics yet

## Recommended V1 Implementation Notes

- add `studyGuide` to the journal entry domain model and JSON mapping
- create a dedicated `StudyGuide` domain type instead of extending
  `RelatedResource`
- create a dedicated local progress repository/controller for guide completion
- keep the guide page rendering against the new domain model, not the legacy
  resources list

## Follow-Up Work Needed

This domain decision implies follow-up implementation work in:

- `#115` for provider-constrained generation output
- `#117` for destination metadata resolution
- `#120` for guide rendering and completion state UI

If progress persistence needs its own issue beyond `#120`, it should be split
out before implementation begins.

