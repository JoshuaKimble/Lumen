import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumen/src/app/theme.dart';
import 'dart:math' as math;

void main() {
  test('defines Heritage palette tokens', () {
    const palette = LumenThemePalette.heritage;

    expect(palette.name, 'Heritage');
    expect(palette.primaryBackground, const Color(0xFFF6F1E7));
    expect(palette.elevatedSurface, const Color(0xFFFBF7EF));
    expect(palette.primaryText, const Color(0xFF2A241D));
    expect(palette.primaryBlue, const Color(0xFF1F3A5F));
    expect(palette.accentRed, const Color(0xFFA6473D));
    expect(palette.brassGold, const Color(0xFFB08A4A));
  });

  test('defines Midnight palette tokens', () {
    const palette = LumenThemePalette.midnight;

    expect(palette.name, 'Midnight');
    expect(palette.primaryBackground, const Color(0xFF16181C));
    expect(palette.elevatedSurface, const Color(0xFF262B33));
    expect(palette.primaryText, const Color(0xFFECE4D8));
    expect(palette.primaryBlue, const Color(0xFF6E8FB8));
    expect(palette.accentRed, const Color(0xFFC16A60));
    expect(palette.brassGold, const Color(0xFFD0AE6A));
  });

  test('builds branded light and dark ThemeData', () {
    final lightTheme = buildLumenLightTheme();
    final darkTheme = buildLumenDarkTheme();

    expect(lightTheme.brightness, Brightness.light);
    expect(darkTheme.brightness, Brightness.dark);
    expect(lightTheme.extension<LumenThemeColors>()?.palette.name, 'Heritage');
    expect(darkTheme.extension<LumenThemeColors>()?.palette.name, 'Midnight');
    expect(lightTheme.scaffoldBackgroundColor, const Color(0xFFF6F1E7));
    expect(darkTheme.scaffoldBackgroundColor, const Color(0xFF16181C));
    expect(lightTheme.colorScheme.primary, const Color(0xFF1F3A5F));
    expect(darkTheme.colorScheme.primary, const Color(0xFF6E8FB8));
    expect(lightTheme.iconButtonTheme.style, isNotNull);
    expect(lightTheme.segmentedButtonTheme.style, isNotNull);
    expect(lightTheme.listTileTheme.iconColor, const Color(0xFF1F3A5F));
    expect(darkTheme.listTileTheme.iconColor, const Color(0xFF6E8FB8));
    expect(lightTheme.progressIndicatorTheme.color, const Color(0xFF1F3A5F));
    expect(darkTheme.progressIndicatorTheme.color, const Color(0xFF6E8FB8));
  });

  test('meets baseline text contrast expectations in both themes', () {
    const light = LumenThemePalette.heritage;
    const dark = LumenThemePalette.midnight;

    expect(
      _contrastRatio(light.primaryText, light.primaryBackground),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      _contrastRatio(dark.primaryText, dark.primaryBackground),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      _contrastRatio(light.secondaryText, light.primaryBackground),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      _contrastRatio(dark.secondaryText, dark.primaryBackground),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      _contrastRatio(light.mutedText, light.elevatedSurface),
      greaterThanOrEqualTo(3.0),
    );
    expect(
      _contrastRatio(dark.mutedText, dark.elevatedSurface),
      greaterThanOrEqualTo(3.0),
    );
  });

  test('enforces accessible touch target sizes for button themes', () {
    final lightTheme = buildLumenLightTheme();

    expect(
      lightTheme.filledButtonTheme.style?.minimumSize?.resolve({}),
      const Size(48, 48),
    );
    expect(
      lightTheme.outlinedButtonTheme.style?.minimumSize?.resolve({}),
      const Size(48, 48),
    );
    expect(
      lightTheme.textButtonTheme.style?.minimumSize?.resolve({}),
      const Size(48, 48),
    );
    expect(
      lightTheme.iconButtonTheme.style?.minimumSize?.resolve({}),
      const Size(48, 48),
    );
    expect(
      lightTheme.segmentedButtonTheme.style?.minimumSize?.resolve({}),
      const Size(48, 48),
    );
  });
}

double _contrastRatio(Color foreground, Color background) {
  final lighter = math.max(
    foreground.computeLuminance(),
    background.computeLuminance(),
  );
  final darker = math.min(
    foreground.computeLuminance(),
    background.computeLuminance(),
  );

  return (lighter + 0.05) / (darker + 0.05);
}
