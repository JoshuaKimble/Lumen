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
