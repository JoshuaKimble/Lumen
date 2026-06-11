# GitHub Task Backlog

This is the source backlog for GitHub Issues. Create these as issues in
`JoshuaKimble/Lumen` when GitHub issue-write access is available.

Workflow assumptions:

- Work directly on `master` by default.
- Create a branch or PR only when isolation, review, or risky changes make that
  useful.
- Use GitHub Issues as the project task list.
- Reference or close the relevant issue in commits when practical.

## Issue 1: Workflow: establish master-first GitHub task process

Goal:
Define the lightweight workflow for the two-person project: GitHub Issues as
tasks, direct work on `master` by default, and branches only when useful.

Scope:

- Document when to work directly on `master`.
- Document when to create a branch or PR.
- Keep Conventional Commits active.
- Keep task context in GitHub Issues and repo docs.

Acceptance criteria:

- README or AGENTS documents the master-first workflow.
- Issues are treated as the source of work tracking.
- Each meaningful work chunk references or closes a GitHub issue when practical.

Depends on:

- None.

## Issue 2: Build: migrate Flutter app into monorepo layout

Goal:
Move the current Flutter-root project into `apps/mobile` without changing app
behavior.

Scope:

- Move Flutter app folders and files into `apps/mobile`.
- Preserve package name, bundle id, tests, generated platform folders, and
  current feature-first structure.
- Update commands in README and AGENTS.
- Keep Git hooks at the repo root.

Acceptance criteria:

- `apps/mobile` contains the Flutter app.
- Flutter analyze and tests pass from the new location.
- Root docs describe the new command paths.
- Working tree has no broken references to old root app paths.

Depends on:

- Issue 1.

## Issue 3: Build: add root monorepo scripts and check commands

Goal:
Create root-level commands for checking the repo as apps and packages are added.

Scope:

- Add scripts for Flutter checks.
- Reserve script slots for API and contract checks.
- Document the root commands.

Acceptance criteria:

- A single root command can run Flutter analysis and tests.
- Commands are documented in README and AGENTS.
- Future API/contract checks have a clear place to plug in.

Depends on:

- Issue 2.

## Issue 4: API: scaffold Node TypeScript AI gateway

Goal:
Create `apps/api` as the backend gateway for transcription, rewriting, and theme
detection.

Scope:

- Add Node TypeScript project structure.
- Add health endpoint.
- Add local development command.
- Add test and typecheck commands.
- Add mock AI provider boundary.

Acceptance criteria:

- API starts locally.
- Typecheck passes.
- Tests pass.
- Health endpoint returns success.
- No provider secrets are committed.

Depends on:

- Issue 3.

## Issue 5: Contracts: create OpenAPI package

Goal:
Create `packages/api_contracts` as the source of truth for app/backend API
contracts.

Scope:

- Add OpenAPI spec folder.
- Define initial health, rewrite, theme detection, and transcription contracts.
- Document generated-client strategy.

Acceptance criteria:

- OpenAPI spec validates.
- API endpoint shapes are documented.
- Flutter generated-client path is defined.
- Contract checks can run from the repo root.

Depends on:

- Issue 4.

## Issue 6: Journal: define MVP domain model

Goal:
Replace the starter journal model with the MVP domain types from
`docs/technical-plan.md`.

Scope:

- Add `JournalEntry`, `EntrySource`, `JournalTheme`, `RelatedResource`,
  `TranscriptionResult`, `RewriteResult`, and `ThemeDetectionResult`.
- Preserve original and rewritten text on the same entry.
- Keep domain types independent from UI and persistence details.

Acceptance criteria:

- Domain tests cover text preservation and entry source handling.
- Original and rewritten text cannot accidentally become separate entries.
- Domain names match the technical plan.

Depends on:

- Issue 2.

## Issue 7: Journal: implement local persistence repository

Goal:
Persist journal entries locally behind repository contracts.

Scope:

- Choose local database via ADR before implementation.
- Implement create, read, update, delete, list by date, and list by theme.
- Keep repository interfaces in the domain layer.

Acceptance criteria:

- Repository tests cover CRUD, date listing, and theme listing.
- UI-facing providers do not know storage implementation details.
- Data persists across app restarts.

Depends on:

- Issue 6.

## Issue 8: Journal: build entry list and detail screens

Goal:
Let users browse previous entries and inspect a single entry.

Scope:

- Entry list shows date, title or summary, preview text, and themes.
- Entry detail shows original text, rewritten text, themes, resources area,
  created date/time, and optional title/summary.
- Original and rewritten versions are visually distinct.

Acceptance criteria:

- Widget tests cover list and detail rendering.
- Entry detail clearly separates original from AI rewrite.
- Empty state is calm and useful.

Depends on:

- Issue 7.

## Issue 9: Journal: build text entry creation and editing

Goal:
Support typed journal entries as a first-class creation path.

Scope:

- Add text entry creation screen.
- Save original typed text.
- Support edit and delete.
- Prepare regenerate action slot for AI rewrite.

Acceptance criteria:

- User can create, edit, and delete a typed entry.
- Saved original text is preserved exactly except for intentional user edits.
- Widget/provider tests cover the flow.

Depends on:

- Issue 8.

## Issue 10: AI: add mock rewrite and theme workflow in Flutter

Goal:
Build the app-side AI flow with mock responses before live backend integration.

Scope:

- Add AI service/repository contracts.
- Add mock rewrite and theme detection implementation.
- Save rewritten text and themes with the entry.
- Add loading, success, and error states.

Acceptance criteria:

- User can generate a mock rewrite from original text.
- User can see mock themes on the entry.
- AI state is testable without network access.

Depends on:

- Issue 9.

## Issue 11: API: implement rewrite and theme detection endpoints

Goal:
Add backend endpoints for AI rewriting and theme detection.

Scope:

- Implement OpenAPI-backed endpoints.
- Add prompt/request builders.
- Add response validation.
- Use mock provider first, then support real provider behind configuration.

Acceptance criteria:

- Endpoint tests cover valid and malformed requests.
- Response shape matches OpenAPI.
- AI behavior constraints are encoded in prompt/service boundaries.

Depends on:

- Issue 5.
- Issue 10.

## Issue 12: Contracts: generate Flutter API client

Goal:
Connect Flutter to the backend through generated or typed client code from the
OpenAPI contract.

Scope:

- Generate or maintain Flutter client from `packages/api_contracts`.
- Add API repository implementation.
- Keep mock implementation available for local development.

Acceptance criteria:

- Flutter can call typed rewrite and theme endpoints.
- Client generation or update steps are documented.
- Contract drift is caught by checks.

Depends on:

- Issue 11.

## Issue 13: Voice: add Flutter audio recording flow

Goal:
Make voice capture the primary entry path.

Scope:

- Add recording UI.
- Request platform permissions.
- Start and stop recording quickly.
- Store temporary local audio until transcription completes.

Acceptance criteria:

- User can start and stop recording.
- Permission-denied state is handled clearly.
- Recording flow is accessible from the primary capture surface.

Depends on:

- Issue 9.

## Issue 14: API: implement transcription endpoint

Goal:
Transcribe recorded audio through the backend gateway.

Scope:

- Add OpenAPI contract for transcription.
- Accept audio upload.
- Use mock transcription first.
- Add provider boundary for real transcription.
- Validate file size/type limits once chosen.

Acceptance criteria:

- Endpoint tests cover success and invalid upload cases.
- API returns a transcript in the agreed contract shape.
- No provider secrets or audio artifacts are committed.

Depends on:

- Issue 5.
- Issue 13.

## Issue 15: Voice: review transcript before save

Goal:
Complete the voice-first creation flow by letting users review transcribed text
before saving.

Scope:

- Send recorded audio to transcription endpoint.
- Display transcript review/edit screen.
- Save transcript as original entry text.
- Trigger rewrite/theme workflow after save.

Acceptance criteria:

- User can review and edit transcript before saving.
- Transcript is stored as the original entry text.
- Voice-created entry follows the same detail/list flow as typed entries.

Depends on:

- Issue 12.
- Issue 14.

## Issue 16: Themes: build aggregation and visualization

Goal:
Surface recurring themes across entries.

Scope:

- Aggregate themes from persisted entries.
- Add basic word cloud or theme visualization.
- Make frequency or significance visually prominent.
- Keep the view reflective, not gamified.

Acceptance criteria:

- Theme visualization shows saved themes.
- More frequent/significant themes are more prominent.
- Widget/provider tests cover theme aggregation.

Depends on:

- Issue 10.

## Issue 17: Themes: build theme detail view

Goal:
Let users tap a theme and review related entries.

Scope:

- Add route and screen for theme detail.
- Show entries associated with the selected theme.
- Leave room for future AI insights/resources.

Acceptance criteria:

- Tapping a theme opens detail view.
- Detail view lists related entries.
- Empty and loading states are handled.

Depends on:

- Issue 16.

## Issue 18: Privacy: add trust-focused entry actions and copy

Goal:
Make the app clearly communicate privacy, ownership, and AI boundaries.

Scope:

- Add or refine copy explaining original entries are preserved.
- Add view-original, edit, delete, and regenerate actions.
- Avoid presenting AI as therapist, coach, preacher, or judge.

Acceptance criteria:

- Entry detail makes original vs rewritten text obvious.
- User can delete and edit entries.
- Regenerate action is available once AI rewrite flow exists.
- Product copy matches `docs/product-requirements.md`.

Depends on:

- Issue 15.

## Issue 19: CI: add GitHub Actions checks

Goal:
Run project checks automatically in GitHub.

Scope:

- Add workflow for Flutter analyze/test.
- Add API typecheck/test once `apps/api` exists.
- Add OpenAPI contract check once contracts exist.
- Keep workflow compatible with master-first development.

Acceptance criteria:

- GitHub Actions runs on pushes to `master`.
- Checks cover all existing apps/packages.
- Failing checks provide actionable output.

Depends on:

- Issue 3.
- Issue 4.
- Issue 5.

## Issue 20: Platform: resolve local Android and iOS readiness blockers

Goal:
Clear known local setup blockers for platform testing.

Scope:

- Resolve `adb` Rosetta/code-signing crash.
- Install missing iOS simulator runtime.
- Re-run `flutter doctor`.
- Smoke-test Android, iOS, and web when possible.

Acceptance criteria:

- `flutter doctor` has no blocking Android/iOS issues.
- Android app can run on emulator/device.
- iOS app can run on simulator.
- Web app can run locally.

Depends on:

- Issue 2.

## Issue 21: MVP: release readiness pass

Goal:
Verify the MVP journaling loop is ready for user testing.

Scope:

- Verify voice and text entry creation.
- Verify original text preservation.
- Verify AI rewriting and theme detection.
- Verify list, detail, theme visualization, and theme detail.
- Verify edit, delete, regenerate, and view-original actions.
- Smoke-test Android, iOS, and web.

Acceptance criteria:

- MVP release checklist in `docs/technical-plan.md` is complete.
- Known gaps are documented as GitHub issues.
- App is ready for first private user testing.

Depends on:

- Issue 18.
- Issue 19.
- Issue 20.

## Issue 22: Backlog: define Study Guides and reflection prompts

Goal:
Turn the Study Guide / reflection prompt concept into a clear
future feature plan.

Scope:

- Decide resource types and sources.
- Define policy for helpful vs random recommendations.
- Define whether resources are generated, curated, user-created, or mixed.
- Plan entry/theme association rules.

Acceptance criteria:

- Product and technical docs describe Study Guides clearly.
- Follow-up implementation issues are created if the feature moves into scope.

Depends on:

- Issue 17.
