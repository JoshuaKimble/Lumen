# Lumen Theme System

Lumen uses two named palettes:

- **Heritage**: the light theme, built around warm cream paper tones, navy blue, muted heritage red, brass, sage, and dusty blue.
- **Midnight**: the dark theme, built as a warm low-light study palette with cream-tinted text and softened blue/red accents.

Color values live in `apps/mobile/lib/src/app/theme.dart` as `LumenThemePalette` tokens. UI code should prefer `ThemeData`, `ColorScheme`, component themes, or `LumenThemeColors` instead of copying raw hex values into screens.

## Usage Guidance

- Use blue for primary actions, selected navigation, active states, links, and focused inputs.
- Use muted heritage red sparingly for recording states, destructive actions, warnings, errors, and emotional emphasis.
- Use brass/gold as a supporting accent, not as the dominant action color.
- Use sage for calm secondary accents and success-adjacent states.
- Use primary text for headings and high-emphasis content.
- Use secondary text for body copy and supporting details.
- Use muted text for low-emphasis metadata, counts, and helper labels.

Avoid pure black, pure white, and generic Material default colors unless they are being used through a deliberate branded token.

## Accessibility Checks

Current baseline checks:

- Primary and secondary text must maintain readable contrast on their primary backgrounds in both Heritage and Midnight.
- Muted text is allowed lower contrast but should remain readable for metadata and helper text.
- Interactive components should use at least `48x48` touch targets for mobile ergonomics.
- Focused, selected, disabled, and destructive states must remain visually distinguishable in both themes.

Manual spot-check targets:

- Journal list, entry detail, entry editor, theme cloud/detail, and settings.
- Chips, inputs, dialogs, and navigation surfaces in both light and dark modes.

## Texture Exploration Decision

Status: deferred.

Recommendation:

- Keep solid tokenized surfaces for now (no paper/noise texture layer in MVP).
- Revisit texture only after auth/cloud sync milestones are stable and we can
  afford focused visual/performance tuning.

Rationale:

- Current Heritage + Midnight palettes already establish visual identity.
- A texture layer adds render complexity and accessibility risk (contrast drift
  behind text-heavy journal content).
- The app currently benefits more from deterministic, low-risk surfaces across
  mobile and web than decorative treatment.

Implementation guardrails for any future texture work:

- Apply only to large background surfaces, not input containers/cards.
- Keep alpha subtle enough to preserve all contrast baselines.
- Validate frame/render impact on low-end mobile hardware before rollout.

## Visual Regression Tests

Theme goldens cover representative light/dark component states in:

- `apps/mobile/test/app/theme_golden_test.dart`

Run:

```sh
cd apps/mobile
flutter test test/app/theme_golden_test.dart
```

Update baselines intentionally:

```sh
cd apps/mobile
flutter test --update-goldens test/app/theme_golden_test.dart
```
