# Study Guide V1 Generation Contract

## Purpose

Define the V1 AI/API generation contract for entry-based Study Guides.

This document supports:

- `#115` Study Guide AI/API: add provider-constrained generation and sizing rules
- `#113` Study Guide domain: define frozen entry-guide model and lifecycle
- `#118` Study Guide content: define V1 Gospel Library-compatible resource catalog and metadata
- `#120` Flutter: build V1 entry-based Study Guide page and manual completion UI

## V1 Objective

Replace generic related-resource suggestion output with a provider-constrained
Study Guide artifact.

The generation pipeline should produce:

- one entry-based study guide per generation event
- `1` or more ranked study resources
- one required reflection prompt
- concise orientation copy for the guide and each resource

The pipeline should not produce an unstructured flat list of mixed resource
cards.

## Input Contract

V1 Study Guide generation should use:

- entry original text
- detected themes
- selected provider ecosystem
- available provider-compatible curated catalog candidates

### Required Inputs

- `entryId`
- `text`
- `themeIds`
- `themeCount`
- `providerKey`

### Derived Inputs

- `entryLength`
- `richness`
- `candidatePool`

For V1:

- `entryLength` can be approximated with character or token count
- `richness` is the total number of detected themes
- `candidatePool` is limited to the chosen provider ecosystem

## Provider Constraint

Provider choice must constrain generation before ranking.

For V1 launch:

- assume `providerKey = gospel_library`
- only retrieve and rank resources that are compatible with Gospel Library
- do not generate resources that require unsupported provider behavior

This constraint applies to:

- scripture candidates
- conference talk candidates
- reflection prompt templates associated with the provider path
- any tertiary resource types admitted to V1

## Candidate Retrieval Rules

The pipeline should retrieve candidates in this order of trust:

1. curated scripture candidates matching the entry themes and text
2. curated conference talk candidates matching the entry themes and text
3. tertiary provider-compatible resources only when their metadata and
   destination precision are strong enough for V1
4. one reflection prompt template or prompt-generation path for the required
   guide prompt

Hard rules:

- do not retrieve cross-provider resources
- do not introduce unsupported resource classes to satisfy count goals
- do not use low-confidence filler items

## Ranking Rules

### Primary Ranking Priorities

Rank resource items by:

1. high-confidence resource availability
2. resource type priority
3. richness support
4. entry-length support

### Resource Type Priority

V1 priority order:

1. scripture
2. conference talk
3. other supported provider-compatible resources

### Confidence Rule

If confidence is low, show fewer items.

The generator should prefer:

- one strong scripture item

over:

- three weak mixed items

### Diversity Rule

When multiple strong candidates exist, the guide should avoid feeling redundant.

Examples:

- avoid returning three nearly identical scripture items from the same passage
- prefer a scripture anchor plus a conference talk when both are strong
- allow multiple scriptures only when the entry is rich enough and the matches
  are distinct

## Guide Sizing Rules

### V1 Bounds

- minimum resource count: `1`
- default target: `2-3`
- hard cap: `8`

The required reflection prompt does not count toward the resource cap.

### Sizing Inputs

Guide size should be driven by:

1. availability of high-confidence resources
2. richness
3. entry length

For V1:

- `richness = themeCount`

### Default Sizing Heuristic

Recommended V1 heuristic:

- start with target `2`
- reduce to `1` when candidate confidence is limited or entry signal is thin
- increase to `3` when both confidence and richness justify it
- expand beyond `3` only when:
  - the entry is long enough to support multiple distinct angles
  - the theme count suggests real breadth
  - the provider-compatible candidate pool contains enough strong items
- never exceed `8`

### Practical Examples

Small entry with one clear theme:

- `1-2` resources

Mid-sized entry with several themes and strong candidate matches:

- `2-3` resources

Long entry with many themes and strong distinct matches:

- `4-8` resources

## Output Contract

The generation pipeline should return a Study Guide artifact, not legacy
resource suggestions.

### Required Guide Fields

- `guideId`
- `entryId`
- `providerKey`
- `generatedAt`
- `overview`
- `previewText`
- `items`
- `reflectionPrompt`

### Required Item Fields

Each resource item must include:

- `itemId`
- `kind`
- `title`
- `contextLine`
- `position`
- `destination`

Type-specific requirements:

#### Scripture

- `focusText`
- verse-aware reference metadata

#### Conference Talk

- `author`
- `publishedContext`
- `quote`

#### Tertiary Resource

- identifying context sufficient for concise rendering

### Reflection Prompt Output

The prompt is required and should include:

- `text`

Prompt rules:

- brief
- reflective
- non-prescriptive
- should connect the guide’s resources without becoming a sermon or advice

## Prompt and Orchestration Guidance

### Tone Constraints

Guide generation should:

- organize
- orient
- motivate study

Guide generation should not:

- moralize
- diagnose
- prescribe actions beyond the study invitation
- replace the source material with long summaries

### Resource Framing Rules

For each item, generate:

- one short explanation of why the resource belongs in the guide
- one short focus line when helpful

For conference talks:

- include one motivating quote
- do not generate a long abstract

For scriptures:

- cite the chapter and verse focus clearly
- if precise deep linking is unavailable, the copy still needs to tell the user
  what verses matter

### Reflection Prompt Rules

Every guide must include one reflection prompt that:

- ties the resources together
- invites continued reflection
- stays concise

## Failure and Fallback Rules

### No Strong Candidate Rule

If no strong candidates exist, do not pad the guide with weak resources.

V1 behavior should be:

- return no guide
- or return the smallest viable guide only when at least one strong resource is
  available

### Provider Incompatibility Rule

If a candidate cannot be rendered and launched reliably within the selected
provider path, exclude it from the guide.

## Testing Expectations

`#115` should make the following testable:

- provider-constrained candidate filtering
- sizing behavior for small, medium, and rich entries
- reflection prompt presence in every generated guide
- scripture-first and talk-second ranking behavior
- no low-confidence filler items

## Migration Note

The current `ResourceSuggestionService` returns `List<RelatedResource>`.

V1 Study Guide generation should replace or sit above that contract with a
dedicated guide-generation path rather than continuing to overload
`RelatedResource` as the final user-facing output type.

