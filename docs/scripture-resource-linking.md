# Scripture Resource Linking

This document defines how Lumen routes scripture-oriented resource suggestions
to the user-selected preference in settings.

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
