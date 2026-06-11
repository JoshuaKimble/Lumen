# Gospel Library Link Discovery

## Purpose

Document the current Gospel Library linking findings for V1 Study Guides.

This document supports:

- `#116` Gospel Library integration: investigate supported deep-link destinations and precision
- `#117` Study Guide integrations: implement provider-aware deep-link service with Gospel Library adapter
- `#118` Study Guide content: define V1 Gospel Library-compatible resource catalog and metadata

## Discovery Date

Findings reflect source review performed on June 11, 2026.

## Summary

The official Church study website gives us strong evidence for stable:

- scripture chapter URLs
- full general conference talk URLs

The available primary sources reviewed here do **not** confirm:

- an official external Gospel Library app URL scheme
- supported verse-range deep links from third-party apps
- verse highlighting behavior from third-party apps
- a documented way to pass metadata into the app beyond the destination URL

Because of that, V1 should treat official study URLs as the canonical
destination format and treat app-level interception or richer native deep
linking as unverified until stronger documentation is found.

## Confirmed Official URL Shapes

### Scripture

Official study pages use chapter-level scripture URLs under the `study`
hierarchy.

Example source:

- [Mosiah 1](https://www.churchofjesuschrist.org/study/scriptures/bofm/mosiah/1?lang=eng)

Observed pattern:

- `https://www.churchofjesuschrist.org/study/scriptures/<collection>/<book>/<chapter>?lang=eng`

Confirmed from source review:

- the page is a chapter page
- verse numbers are rendered on the page
- the URL shape clearly identifies collection, book, and chapter

Not confirmed from source review:

- a documented verse-range URL format
- a documented verse anchor format that Lumen can rely on externally

### General Conference Talks

Official study pages use full-talk URLs under the general conference hierarchy.

Example sources:

- [October 2024 general conference](https://www.churchofjesuschrist.org/study/general-conference/2024/10?lang=eng)
- [Nourish the Roots, and the Branches Will Grow](https://www.churchofjesuschrist.org/study/general-conference/2024/10/51uchtdorf?lang=eng)

Observed pattern:

- `https://www.churchofjesuschrist.org/study/general-conference/<year>/<month>/<talk-id>?lang=eng`

Confirmed from source review:

- the conference index page links to specific talk pages
- talk pages expose stable talk-level identifiers in the URL
- talk pages expose speaker, conference context, and talk text

## Precision Assessment

### Confirmed

- scripture: `chapter`
- conference talk: `document`

### Unconfirmed

- scripture: `verse_range`
- scripture: verse highlighting
- conference talk: section-level deep link behavior in app
- app-to-app parameter passing

## Product Implications

### Launch-Safe Behavior

For V1, Lumen should safely assume:

- scripture links can reliably target a chapter page
- conference talks can reliably target a full talk page

This means guide items should:

- name the exact scripture focus in the card copy
- say `Focus on verses X-Y` when the relevant passage is narrower than the
  target chapter
- link conference talks to the full talk

### Do Not Promise More Than We Can Verify

Until stronger documentation is found, the UX should not claim:

- automatic verse highlighting
- automatic verse-range scrolling
- precise segment-level conference talk opening

Any of those may still work in some environments, but they are not verified
enough to be a V1 contract.

## Recommended V1 Technical Strategy

### Canonical Destination Format

Use official `churchofjesuschrist.org/study/...` URLs as the canonical
destination representation for Gospel Library resources.

Reason:

- officially published content pages are verifiable
- the URL shapes are stable enough to model
- they provide acceptable browser fallback if native handoff is unavailable

### Adapter Behavior

The Gospel Library adapter should initially support:

- scripture chapter destinations
- full general conference talk destinations

The adapter should preserve a precision value on each destination:

- `chapter`
- `document`
- future `verse_range` if later verified

### Future Upgrade Path

If stronger official documentation or verified implementation evidence appears
later, the adapter can be extended to support:

- verse-range linking
- richer in-app anchors
- provider-specific app links distinct from canonical web URLs

## Open Questions

The following remain unresolved after current source review:

1. Does Gospel Library expose an official external URL scheme for third-party
   apps?
2. Can a third-party app navigate directly to a verse range rather than a
   chapter?
3. Can a third-party app cause a verse range to be highlighted or preselected?
4. Are there stable provider identifiers for conference talks beyond the public
   talk slug?
5. Does the installed app universally intercept these official study URLs on
   iOS and Android, or is behavior platform-dependent?

## Recommendation for `#116`

Treat `chapter` scripture precision and `document` talk precision as the V1
baseline.

Treat verse-range and native app-specific behaviors as a follow-up discovery
track rather than a launch assumption.

