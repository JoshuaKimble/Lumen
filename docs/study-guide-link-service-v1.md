# Study Guide Link Service V1

## Purpose

Define the provider-aware deep-link service boundary for V1 Study Guides.

This document supports:

- `#117` Study Guide integrations: implement provider-aware deep-link service with Gospel Library adapter
- `#116` Gospel Library integration: investigate supported deep-link destinations and precision
- `#120` Flutter: build V1 entry-based Study Guide page and manual completion UI

## Problem

The current resolver, [scripture_resource_link_resolver.dart](/Users/joshuakimble/Documents/workspace/apps/Lumen/apps/mobile/lib/src/features/journal/data/scripture_resource_link_resolver.dart), is tied to the legacy `RelatedResource` model and builds broad scripture-search URLs from a reference string.

That is not sufficient for V1 Study Guides because:

- Study Guide items need provider-aware destination metadata
- precision needs to be explicit
- conference talks need full-talk destinations, not generic search behavior
- UI rendering should not know provider-specific URL construction rules

## V1 Service Objective

Provide a focused service that turns Study Guide destination metadata into a
launchable target plus explicit precision.

The service should:

- accept structured Study Guide destination data
- apply provider-specific URL construction
- expose handoff precision to callers
- degrade gracefully when exact precision is unavailable

## Recommended Service Boundary

### Domain Input

The UI should pass a `StudyGuideDestination` to the link service.

Recommended input fields:

- `providerKey`
- `contentType`
- `reference`
- `url`
- `precision`

These fields come from the Study Guide generation output, not from UI
interpretation.

### Resolver Output

The link service should return a resolved launch target with:

- `uri`
- `precision`
- `providerKey`
- `contentType`

Recommended type name:

- `ResolvedStudyGuideLink`

This gives the UI enough information to:

- open the resource
- choose CTA copy later if needed
- avoid guessing how precise the handoff is

## Recommended Interfaces

### Link Resolver

Suggested interface:

- `StudyGuideLinkResolver`

Responsibilities:

- inspect `StudyGuideDestination`
- dispatch to the correct provider adapter
- return the best available resolved destination

### Provider Adapter

Suggested interface:

- `StudyGuideProviderLinkAdapter`

Responsibilities:

- resolve provider-specific destination formats
- map unsupported exact precision to the best verified fallback

### Link Opener

The existing `ResourceLinkOpener` pattern can remain, but it should be reused
against the new resolved link type rather than the legacy resource model.

## Gospel Library Adapter

### V1 Scope

The Gospel Library adapter should support:

- scripture chapter destinations
- full general conference talk destinations

### Scripture Resolution

Input assumptions:

- content type is `scripture`
- destination carries canonical scripture reference metadata

V1 baseline:

- resolve to the official Church study chapter URL
- preserve `chapter` precision when verse-range precision is not verified

Expected canonical pattern:

- `https://www.churchofjesuschrist.org/study/scriptures/<collection>/<book>/<chapter>?lang=eng`

If the destination declares `verse_range` but V1 cannot verify a stable
verse-range URL contract, the adapter should:

- resolve the chapter URL
- downgrade precision to `chapter`

### Conference Talk Resolution

Input assumptions:

- content type is `conference_talk`
- destination carries a stable talk identifier or canonical URL

V1 baseline:

- resolve to the official Church study talk URL
- preserve `document` precision

Expected canonical pattern:

- `https://www.churchofjesuschrist.org/study/general-conference/<year>/<month>/<talk-id>?lang=eng`

### Unsupported Content

If a V1 Study Guide item uses an unsupported content type:

- prefer an explicit canonical URL when present
- otherwise return no resolved link

The service should not invent low-confidence search URLs for unsupported guide
content.

## Precision Model

The link service should expose precision as a first-class enum.

Recommended V1 values:

- `verse_range`
- `chapter`
- `document`
- `web_fallback`

V1 expected outcomes for Gospel Library:

- scripture: `chapter`
- conference talk: `document`

The enum should exist even when a provider currently resolves to only one or
two precision levels, because later ranking and UI copy will depend on it.

## Fallback Behavior

### When Exact Precision Is Not Supported

If exact precision is requested but not verified:

- resolve the best supported target
- downgrade the returned precision
- do not throw

Example:

- requested scripture precision: `verse_range`
- resolved precision: `chapter`

### When No Resolvable Target Exists

If the service cannot build a trustworthy destination:

- return `null`
- let the UI keep the card visible without an open CTA, or show graceful
  failure behavior if invoked unexpectedly

### Browser Fallback

Canonical `churchofjesuschrist.org/study/...` URLs are acceptable V1 fallback
targets because they can open in the browser even when native app interception
does not occur.

## Separation of Concerns

The Study Guide page should not:

- build provider URLs
- parse provider-specific reference formats
- decide whether verse-range or chapter fallback is needed

Those responsibilities belong in the link service layer.

The generator should not:

- generate UI CTA text based on guessed precision behavior

It should provide destination metadata; the adapter resolves the final target.

## Migration Path from Current Resolver

Current state:

- `ScriptureResourceLinkResolver` accepts `RelatedResource`
- scripture and talk resources route through broad preference-based URL builders

Recommended V1 transition:

1. introduce Study Guide-specific link types and resolver
2. add Gospel Library adapter
3. keep legacy resource resolver in place temporarily for old resource UI
4. move new Study Guide UI to the new resolver only
5. remove or simplify legacy resolver later when the old resource flow is gone

This avoids forcing the new guide destination model into the old resource card
contract.

## Testing Expectations

`#117` should make the following testable:

- scripture destination resolves to canonical chapter URL
- conference talk destination resolves to canonical talk URL
- requested `verse_range` degrades to `chapter` when exact support is not
  verified
- unsupported content returns `null` or explicit fallback behavior without
  crashing
- provider-specific URL construction is isolated from UI rendering

