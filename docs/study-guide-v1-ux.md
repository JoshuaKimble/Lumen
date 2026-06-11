# Study Guide V1 UX Spec

## Purpose

Define the V1 user experience for entry-based gospel study guides.

This document is the UX contract for:

- `#114` Study Guide UX: define V1 page structure, copy, and states
- `#113` Study Guide domain: define frozen entry-guide model and lifecycle
- `#118` Study Guide content: define V1 Gospel Library-compatible resource catalog and metadata
- `#116` Gospel Library integration: investigate supported deep-link destinations and precision

V1 only covers study guides generated from a single journal entry. Theme-based
guides are explicitly deferred to V2.

## Product Positioning

Lumen should present the study guide as the primary AI-generated outcome of a
journal entry.

- The journal entry is the input.
- The study guide is the organized path forward.
- The linked study app is where the full resource is consumed.

Lumen should support scripture study, not replace it. The app should provide
brief orientation, then hand the user off cleanly to the resource itself.

## V1 Experience Summary

The entry detail page should introduce the guide early and clearly.

Recommended order:

1. Title
2. Date
3. Summary
4. Study Guide CTA
5. Themes
6. Trust notice
7. Original entry

The current bottom-of-page `Resources` list should no longer be the primary
study experience.

## Entry Detail: Study Guide CTA

### Goal

Show the user that a gospel-focused study guide has been created from the
reflection and give them one clear next step.

### Placement

Place the Study Guide CTA directly below the summary and above themes.

### Content

The module should include:

- section label: `Study guide`
- one-line explanation: `A gospel study guide built from this reflection.`
- strongest resource preview
- guide size preview
- primary action to open the dedicated Study Guide page

### CTA Preview Rules

The CTA should preview the strongest resource in the guide.

Examples:

- `Includes 3 Nephi 1:6-12 and two more resources.`
- `Includes Psalm 46 and a conference talk by Dieter F. Uchtdorf.`
- `Includes one scripture and a reflection prompt.`

The preview should help the user understand what kind of study awaits without
requiring them to open the guide first.

### CTA Copy

Preferred base copy:

- title: `Study guide`
- subtitle: `A gospel study guide built from this reflection.`
- primary action: `Open study guide`

Optional size/supporting copy:

- `1 resource`
- `3 resources`
- `6 resources for a longer study plan`

Avoid:

- `Resources`
- `Study items`
- `Tasks`
- language that feels like homework or a recommendation feed

### Empty State

V1 should aim to generate at least one guide resource when confidence is
sufficient.

If no guide can be produced, the CTA module should remain calm and explicit:

- title: `Study guide`
- message: `A study guide is not available for this entry yet.`

Do not show a generic empty `Resources` container.

## Dedicated Study Guide Page

### Goal

Turn a journal entry into a concise, trustworthy, gospel-focused study path.

The page should feel invitational and organized, not instructional or heavy.

### Page Structure

1. Header
2. Short guide overview
3. Guide resources
4. Reflection prompt

### Header

The header should include:

- title: `Study guide`
- source context: `Built from this reflection`
- progress summary: `{completed} of {total} completed`

The guide is entry-based in V1, so no theme-guide messaging is needed.

### Guide Overview

Include one short paragraph that explains why these resources belong together.

Requirements:

- concise
- orienting
- non-prescriptive
- no life advice
- no attempt to replace the resource with a summary-heavy in-app experience

Example tone:

`These resources connect to the themes in your reflection and offer a few
places to continue your gospel study.`

### Guide Resources

Each resource should appear as a lightweight card in the guide itself.

Each card should answer:

1. What is this resource?
2. Why is it included?
3. What should I focus on?
4. What can I do next?

Each card should include:

- resource title
- resource type context
- short explanation of why it is included
- primary CTA to open the destination
- manual completion checkbox

Completed items should:

- remain tappable
- change style only
- never auto-complete after opening

### Resource Order

Resource order should follow the guide ranking, with these content priorities:

1. Scripture
2. Conference talk
3. Other supported provider-compatible resources

The page should feel conversational, not like a numbered lesson plan.

Do not label items as `Step 1`, `Step 2`, and so on in V1.

### Resource Copy Rules

#### Scripture

Show:

- scripture reference
- short one-line connection
- explicit focus verses when applicable

Example:

- `3 Nephi 1`
- `This passage connects to the waiting and uncertainty in your reflection.`
- `Focus on verses 6-12.`

The CTA should open as precisely as the provider supports. If only chapter-level
linking is available, the card copy must still identify the relevant verses.

#### Conference Talk

Show:

- talk title
- speaker
- date or conference context
- one short quote
- short one-line connection

Do not provide a long summary of the talk in V1.

Link to the full talk, not a quoted segment.

#### Other Supported Resources

Show:

- title
- minimal identifying context
- short one-line connection

Keep secondary resource types concise and easy to scan.

## Reflection Prompt

The reflection prompt is required in every V1 study guide.

Requirements:

- always present
- one sentence or a short paragraph
- ties the guide together
- reflective, not prescriptive
- should not attempt to provide the core teaching itself

This prompt can appear:

- as the final card in the guide
- or as a distinct closing section

The prompt should feel like a natural continuation of study, not homework.

## Guide Size Rules

### V1 Defaults

- absolute minimum: `1` resource
- typical target: `2-3` resources
- upper range for rich entries: `6-8` resources

Guide size should be influenced by:

1. availability of high-confidence resources
2. richness of the entry
3. length of the entry

### Richness Definition for V1

For V1, richness is determined by the total number of themes detected in the
entry.

Weighted theme strength and visual theme prominence are V2 concerns.

### Sizing Principle

Do not inflate the guide just because the entry is long. Resource quality
should limit guide length.

## Interaction Rules

- Opening a resource hands the user off to the destination app or fallback
  destination.
- Lumen should not assume completion from the open action.
- The user manually marks a resource complete.
- Completed resources can be unmarked.
- The guide is not editable in V1.

## Deep-Linking UX Constraints

The design must accommodate varying levels of provider precision.

V1 assumptions:

- prefer exact verse-range linking when supported
- otherwise fall back to chapter-level linking
- conference talks open at the talk level
- the UI must not imply a more precise handoff than the provider can deliver

This means resource cards must carry enough context to remain useful even when
the provider can only open a chapter rather than a verse range.

## V1 Exclusions

The following are out of scope for V1:

- theme-based study guides
- saved guides hub
- recent guides surface
- editable guide contents
- auto-complete from open events
- messaging that a theme guide has evolved
- multi-provider parity beyond the launch-default provider strategy

## Acceptance Criteria

`#114` should be considered complete when:

- V1 copy, page sections, and interaction rules are explicitly defined
- entry detail CTA placement and preview behavior are explicit
- study guide page structure is explicit
- required and optional states are explicit
- V1 exclusions are documented so later issues do not backfill them implicitly

