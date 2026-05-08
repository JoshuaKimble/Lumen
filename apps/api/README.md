# Lumen API Gateway

`apps/api` is the Node TypeScript gateway for AI-backed transcription,
rewriting, and theme detection.

Current scope:

- Health endpoint.
- Mock AI provider boundary.
- TypeScript typecheck and tests.

Commands:

```sh
npm install
npm run typecheck
npm test
npm run build
npm run dev
```

The gateway must not commit provider API keys or secrets. Add provider-specific
configuration only through environment variables in later issues.
