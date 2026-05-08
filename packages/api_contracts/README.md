# Lumen API Contracts

`packages/api_contracts` is the source of truth for the Flutter app/backend API
boundary.

## Contents

- `openapi/openapi.json`: OpenAPI 3.1 contract.
- `generated/`: reserved for generated clients.
- `scripts/validate-openapi.mjs`: lightweight structural validation for the
  contract until full OpenAPI tooling is introduced.

## Commands

```sh
npm test
```

## Flutter Client Strategy

The Flutter client will live under `apps/mobile/lib/src/api/generated` once
client generation is added. Until then, app-side DTOs should be hand-written
only as temporary adapters and kept aligned with `openapi/openapi.json`.

When generation is introduced, update this package with the generator command
and make `npm test` fail if generated output is stale.
