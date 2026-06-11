# Study Guide V1 Content Catalog

## Purpose

Define the V1 supported Study Guide resource catalog and required metadata for a
Gospel Library-first launch.

This document is the content contract for:

- `#118` Study Guide content: define V1 Gospel Library-compatible resource catalog and metadata
- `#115` Study Guide AI/API: add provider-constrained generation and sizing rules
- `#116` Gospel Library integration: investigate supported deep-link destinations and precision
- `#117` Study Guide integrations: implement provider-aware deep-link service with Gospel Library adapter

## Launch Principle

V1 should only generate Study Guide resources that the selected provider
ecosystem can support with acceptable confidence.

For the launch-default provider, that means:

- assume `gospel_library`
- prefer resources that can be linked with clear destination behavior
- avoid catalog types that require vague or weak handoff experiences

## V1 Supported Resource Types

### Tier 1: Scripture

Scripture is the highest-priority Study Guide resource type in V1.

This should be the default anchor resource whenever a strong scripture match is
available.

### Tier 2: Conference Talk

Conference talks are the second-priority resource type in V1.

These provide supportive depth after scripture and should link to the full talk
rather than a quoted segment.

### Tier 3: Other Provider-Compatible Resources

Other Gospel Library-compatible resources are allowed only if both are true:

1. the provider supports a reliable destination
2. the catalog record contains enough metadata for a concise, trustworthy card

These items are tertiary in ranking and should not displace a stronger
scripture or conference-talk match.

## V1 Exclusions

The following should not ship as primary Study Guide item types in V1:

- `video_or_audio`
- `exercise`
- `internal_entry_link`
- standalone `quote`
- weakly linked article/manual/resource types that do not yet have clear
  provider metadata

Notes:

- a quote may appear as supporting metadata on a conference talk card
- the required reflection prompt remains part of the Study Guide experience,
  but it is not part of the provider-linked content catalog in the same sense
  as scripture or conference talks

## Resource Type Definitions

### Scripture

Scripture records should represent a canonical reference that can be shown
clearly in-app and linked as precisely as the provider allows.

Required user-facing metadata:

- reference display text
- book
- chapter
- verse start
- verse end when applicable
- one-line connection text

Required routing metadata:

- provider key
- provider content type
- canonical reference string
- precision target
- fallback URL when available

Optional metadata:

- short scripture excerpt when editorially safe and available
- tradition or canon metadata when provider support expands later

### Conference Talk

Conference talk records should represent a single full talk entry.

Required user-facing metadata:

- talk title
- speaker
- conference or published context
- short quote
- one-line connection text

Required routing metadata:

- provider key
- provider content type
- canonical talk identifier or stable reference
- fallback URL when available

Optional metadata:

- publication date
- topical tags

### Other Provider-Compatible Resources

Any tertiary resource admitted to V1 must include:

- title
- minimal identifying context
- one-line connection text
- provider key
- provider content type
- stable destination metadata

If that minimum metadata is not available, the resource should be excluded from
V1 generation.

## Catalog Record Requirements

The curated catalog foundation already supports shared fields such as:

- `catalog_key`
- `record_kind`
- `resource_type`
- `provider_key`
- `tradition_key`
- `title`
- `description`
- `canonical_url`
- `scripture_reference`
- `content_text`
- `metadata`
- `is_active`

For V1 Study Guides, the catalog should require these conventions.

### Scripture Catalog Records

Use:

- `record_kind = resource`
- `resource_type = scripture`
- `provider_key = gospel_library`

Recommended `metadata` shape:

- `book`
- `chapter`
- `verse_start`
- `verse_end`
- `precision_target`
- `provider_reference`
- `focus_text`

### Conference Talk Catalog Records

Use:

- `record_kind = resource`
- `resource_type = conference_talk`
- `provider_key = gospel_library`

Recommended `metadata` shape:

- `speaker`
- `conference_label`
- `published_at`
- `provider_reference`
- `quote`

### Reflection Prompt Records

Reflection prompts may still be stored in the curated catalog foundation for
generation support, but they should be treated as a separate guide component.

Use:

- `record_kind = prompt_template`
- `provider_key = gospel_library` only when the prompt is intended for that
  ecosystem's guide generation path

Prompt records do not need deep-link routing metadata.

## Output Metadata Requirements

Regardless of how the backend stores source material, each generated V1 guide
item should carry enough data for Flutter rendering and handoff.

### Scripture Output

Required:

- item id
- type `scripture`
- display title
- context line
- focus text
- destination provider key
- destination reference
- destination precision

### Conference Talk Output

Required:

- item id
- type `conference_talk`
- display title
- speaker
- conference context
- quote
- context line
- destination provider key
- destination reference
- destination precision

### Tertiary Resource Output

Required:

- item id
- supported type
- display title
- identifying context
- context line
- destination provider key
- destination reference or URL
- destination precision

## Ranking Constraints

The Study Guide generator should rank only within the provider-constrained
catalog.

Ranking priorities for V1:

1. scripture relevance and confidence
2. conference talk relevance and confidence
3. tertiary provider-compatible resource relevance and confidence

Hard rules:

- do not use low-confidence resources just to fill the guide
- do not include unsupported provider content
- do not elevate tertiary items above stronger scripture or talk matches

## Precision Expectations

The content catalog should declare the intended destination precision for each
resource so generation and rendering can stay aligned.

Expected V1 precision levels:

- `verse_range`
- `chapter`
- `document`
- `web_fallback`

For scriptures:

- prefer `verse_range`
- accept `chapter` when the provider cannot land more precisely

For conference talks:

- target `document`

If a resource can only support weak fallback behavior and the UI would need to
overpromise its precision, exclude it from V1.

## Acceptance Boundary for V1

`#118` should be considered complete when:

- V1 resource tiers are explicit
- required metadata is explicit for scripture and conference talks
- tertiary-resource admission rules are explicit
- excluded resource classes are explicit
- the result is specific enough for AI generation, deep linking, and Flutter
  rendering to align without inventing unsupported resource shapes during
  implementation

