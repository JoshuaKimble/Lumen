# Local API-Backed Development

This guide runs the Flutter app against `apps/api` without source edits.

## 1. Prepare API Environment

From `apps/api`:

```sh
cp .env.example .env
```

Use one of these modes in `.env`:

1. Mock API mode (no secrets required):

```sh
LUMEN_AI_PROVIDER=mock
```

2. OpenAI API mode:

```sh
LUMEN_AI_PROVIDER=openai
OPENAI_API_KEY=sk-proj-...
```

Optional model overrides:

```sh
LUMEN_OPENAI_REWRITE_MODEL=gpt-5-mini
LUMEN_OPENAI_THEME_MODEL=gpt-5-mini
LUMEN_OPENAI_TRANSCRIPTION_MODEL=gpt-4o-mini-transcribe
```

For the default shared-cloud auth flow, also set the Flutter-safe Supabase
client values in `apps/api/.env`:

```sh
LUMEN_USE_SUPABASE=true
LUMEN_SUPABASE_URL=https://your-project-ref.supabase.co
LUMEN_SUPABASE_PUBLISHABLE_KEY=sb_publishable_...
# Only if the API needs privileged Supabase access:
LUMEN_SUPABASE_SECRET_KEY=sb_secret_...
LUMEN_SUPABASE_DB_URL=postgresql://postgres.<project-ref>:password@aws-0-<region>.pooler.supabase.com:6543/postgres
```

These values are read by `./scripts/dev_web_api.sh` and forwarded into the
Flutter web build as `dart-define`s. Do not use a Supabase secret key in
the web client bundle.

The API allows localhost browser origins by default. `LUMEN_ALLOWED_WEB_ORIGIN`
is only needed in deployed environments to admit the production Flutter web
origin.

For prelaunch work, this shared cloud project is the default local target. The
local Supabase CLI stack remains optional for isolated schema replay only.
If your local code depends on a migration that has not been applied yet, either
push to `master` and wait for CI to deploy it, or run
`./scripts/supabase_push_cloud.sh` manually first.

## 2. Start the API Gateway

Run from repo root:

```sh
./scripts/dev_api.sh
```

Default API URL: `http://127.0.0.1:3000`.

## 3. Run Flutter Web in API Mode

Run from repo root:

```sh
./scripts/dev_web_api.sh
```

Defaults:

- `LUMEN_API_BASE_URL=http://127.0.0.1:3000`
- `LUMEN_WEB_PORT=51910`
- Supabase auth stays disabled unless `apps/api/.env` exports
  `LUMEN_USE_SUPABASE=true` plus the required Flutter client values

Override if needed:

```sh
LUMEN_API_BASE_URL=http://127.0.0.1:3001 LUMEN_WEB_PORT=52000 ./scripts/dev_web_api.sh
```

Then open:

```text
http://127.0.0.1:<LUMEN_WEB_PORT>
```

## 4. Manual Verification Checklist

1. Create a typed entry.
0. If Supabase auth is enabled, confirm the app opens on login instead of the
   journal.
2. Edit and save that entry.
3. Use `Regenerate AI rewrite` on entry detail.
4. Create a voice entry and save transcript.

Expected:

- In mock API mode, rewrites include `[API mock: rewrite endpoint]`.
- In OpenAI mode, rewrites and transcription come from OpenAI responses.

## 5. Mobile/Emulator Base URL Notes

`localhost` differs by device:

- Web browser: `http://127.0.0.1:3000`
- Android emulator: `http://10.0.2.2:3000`
- iOS simulator: usually `http://127.0.0.1:3000`
- Physical devices: use your host machine LAN IP and matching firewall rules.

For non-web runs, pass `LUMEN_API_BASE_URL` explicitly:

```sh
flutter run --dart-define=LUMEN_USE_API_AI=true --dart-define=LUMEN_API_BASE_URL=http://10.0.2.2:3000
```

## 6. Troubleshooting

1. Rewrites still look like Flutter mock output:
`[Flutter mock: ...]`
This means API mode was not enabled in the Flutter build. Rebuild using `./scripts/dev_web_api.sh`.

2. Browser still shows old behavior after changes:
Stop the current static server and run `./scripts/dev_web_api.sh` again.

3. Auth screens show an error before any network request:
This usually means the web build did not receive Supabase `dart-define`s.
Confirm `apps/api/.env` includes:
`LUMEN_USE_SUPABASE=true`
`LUMEN_SUPABASE_URL=...`
`LUMEN_SUPABASE_PUBLISHABLE_KEY=...`
Then rebuild with `./scripts/dev_web_api.sh`.

4. `Regenerate AI rewrite` errors:
Confirm API process is running and `LUMEN_API_BASE_URL` points to the active port.

5. OpenAI mode fails immediately:
Verify `OPENAI_API_KEY` is present in `apps/api/.env` and `LUMEN_AI_PROVIDER=openai`.
