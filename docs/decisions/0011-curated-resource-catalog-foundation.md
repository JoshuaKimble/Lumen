# 0011: Curated Resource Catalog Foundation

- Status: Accepted
- Date: 2026-06-10

## Context

Lumen already has:

- a user-visible `RelatedResource` model
- Flutter UI for entry-level and theme-level suggestions
- scripture preference routing
- user-owned cloud tables for `related_resources` and `resource_feedback`

What it does not have is a durable server-side source of truth for real
resource generation. The current API path can return lightweight placeholder
AI-mapped prompts, but it does not yet rank against a curated catalog.

If Lumen keeps using `related_resources` as both:

- the generation source of truth
- and the user-visible per-entry/per-theme output store

then the catalog, orchestration, and feedback layers will blur together.
That would make ranking brittle and future provider/tradition support harder to
add cleanly.

## Decision

Lumen will separate the server-owned curated catalog foundation from the
user-owned `related_resources` output table.

The curated foundation will use two tables:

- `public.curated_resource_catalog`
- `public.curated_resource_theme_mappings`

### Catalog table

`curated_resource_catalog` stores the durable source material that the API can
retrieve and rank against.

It supports both:

- fixed curated resources such as scripture, talks/articles, quotes, exercises,
  and media
- prompt-template-backed resources for reflection prompts

This is modeled with a `record_kind` field rather than creating a totally
separate prompt-template system up front.

### Theme mapping table

`curated_resource_theme_mappings` stores reusable semantic associations between
catalog records and high-level journal themes.

This gives the future ranking layer a stable candidate-retrieval boundary
without forcing all matching logic into prompts or free-form text search.

### Access model

The curated catalog is server-owned and should not be directly readable by
anonymous or authenticated Flutter clients.

It exists for:

- server-side retrieval
- ranking
- seeding and editorial maintenance

Generated user-visible suggestions continue to materialize into the
user-owned `related_resources` table as output records.

## Consequences

Positive:

- separates source-of-truth catalog data from user-visible suggestion output
- keeps the resource generation path reusable across resource types
- allows reflection prompts to be one catalog-backed resource class rather than
  a one-off path
- gives ranking work a stable foundation for provider/tradition metadata
- keeps future evaluation/tuning work focused on orchestration quality rather
  than mixed storage concerns

Tradeoffs:

- adds more schema surface area before ranking is implemented
- requires seed/ingestion ownership for curated content
- does not by itself improve suggestion quality until ranking/orchestration work
  lands

## Notes

- `related_resources` remains the user-visible output store.
- `resource_feedback` remains the per-user signal store.
- Future ranking/orchestration work should retrieve from the curated catalog,
  then shape final suggestions into `related_resources` records.
