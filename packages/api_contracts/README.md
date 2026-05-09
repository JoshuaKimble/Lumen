# Lumen API Contracts

`packages/api_contracts` is the source of truth for the Flutter app/backend API
boundary.

## Contents

- `openapi/openapi.json`: OpenAPI 3.1 contract.
- `generated/`: reserved for generated clients or generator metadata.
- `scripts/validate-openapi.mjs`: lightweight structural validation for the
  contract until full OpenAPI tooling is introduced.
- `scripts/generate-dart-client.mjs`: generates the Flutter client from the
  OpenAPI operations used by the app.

## Commands

```sh
npm test
```

Regenerate the Flutter client after changing rewrite or theme contracts:

```sh
npm run generate:flutter
```

## Flutter Client Strategy

The Flutter client lives under `apps/mobile/lib/src/api/generated`. Generated
output is checked by `npm test`, so contract drift fails in the normal
repository check path.
