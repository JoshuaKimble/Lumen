# Scripture Resource Linking

This document defines how Lumen routes scripture-oriented Study Guide resources
to the user-selected preference in settings.

V1 Study Guide implementation is currently in transition:

- legacy entry detail still uses the existing `ScriptureResourceLinkResolver`
  for `RelatedResource` payloads
- the new Study Guide direction is documented in
  [gospel-library-link-discovery.md](/Users/joshuakimble/Documents/workspace/apps/Lumen/docs/gospel-library-link-discovery.md)
  and
  [study-guide-link-service-v1.md](/Users/joshuakimble/Documents/workspace/apps/Lumen/docs/study-guide-link-service-v1.md)

## Preference Options

- No preference
- Gospel Library (LDS)
- YouVersion Bible
- Bible Gateway
- Catholic study

## Current Resolver Behavior

Resolver implementation: `apps/mobile/lib/src/features/journal/data/scripture_resource_link_resolver.dart`

For scripture/talk/quote resources, Lumen uses the selected preference to build
a platform-friendly external URL from the resource reference/title:

- Gospel Library (LDS):
  `https://www.churchofjesuschrist.org/search?lang=eng&facet=scriptures&query=<reference>`
- YouVersion Bible (Protestant-friendly):
  `https://www.bible.com/search/bible?query=<reference>`
- Bible Gateway (Protestant-friendly fallback):
  `https://www.biblegateway.com/passage/?search=<reference>`
- Catholic study fallback:
  `https://bible.usccb.org/search?search_api_fulltext=<reference>`

If the user has no preference (or the resource type is not scripture-oriented),
Lumen uses the resource URL provided by the suggestion payload when present.

If no URL can be resolved or launched, the app degrades gracefully by showing a
non-crashing snackbar message.

## Study Guide V1 Baseline

For the dedicated Study Guide experience, the current V1 baseline is:

- prefer Gospel Library as the launch-default provider
- use chapter-level scripture precision when exact verse-range support is not
  verified
- use full-talk precision for conference talks
- provide enough in-app context that the user still knows what verses to focus
  on if the destination lands at chapter level

The current resolver document remains useful for the legacy preference-routing
path, but future Study Guide link work should follow the dedicated Study Guide
link service contract rather than expanding this older resolver model.
