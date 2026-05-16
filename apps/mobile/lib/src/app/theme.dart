import 'package:flutter/material.dart';

ThemeData buildLumenTheme() {
  return buildLumenLightTheme();
}

ThemeData buildLumenLightTheme() {
  return _buildTheme(LumenThemePalette.heritage, Brightness.light);
}

ThemeData buildLumenDarkTheme() {
  return _buildTheme(LumenThemePalette.midnight, Brightness.dark);
}

ThemeData _buildTheme(LumenThemePalette palette, Brightness brightness) {
  final colorScheme = ColorScheme(
    brightness: brightness,
    primary: palette.primaryBlue,
    onPrimary: palette.elevatedSurface,
    primaryContainer: palette.softBlue,
    onPrimaryContainer: palette.primaryText,
    secondary: palette.sage,
    onSecondary: palette.primaryText,
    secondaryContainer: palette.secondarySurface,
    onSecondaryContainer: palette.primaryText,
    tertiary: palette.brassGold,
    onTertiary: palette.primaryText,
    tertiaryContainer: palette.elevatedSurface,
    onTertiaryContainer: palette.primaryText,
    error: palette.accentRed,
    onError: palette.elevatedSurface,
    errorContainer: palette.softRed,
    onErrorContainer: palette.primaryText,
    surface: palette.primaryBackground,
    onSurface: palette.primaryText,
    surfaceContainerLowest: palette.primaryBackground,
    surfaceContainerLow: palette.secondarySurface,
    surfaceContainer: palette.secondarySurface,
    surfaceContainerHigh: palette.elevatedSurface,
    surfaceContainerHighest: palette.elevatedSurface,
    onSurfaceVariant: palette.secondaryText,
    outline: palette.borderDivider,
    outlineVariant: palette.borderDivider,
    shadow: palette.primaryText.withValues(alpha: 0.18),
    scrim: palette.primaryText.withValues(alpha: 0.36),
    inverseSurface: palette.primaryText,
    onInverseSurface: palette.primaryBackground,
    inversePrimary: palette.softBlue,
  );
  final baseTheme = ThemeData(
    brightness: brightness,
    colorScheme: colorScheme,
    extensions: [LumenThemeColors(palette)],
    scaffoldBackgroundColor: palette.primaryBackground,
    useMaterial3: true,
  );
  final textTheme = _textTheme(baseTheme.textTheme, palette);

  return baseTheme.copyWith(
    textTheme: textTheme,
    primaryTextTheme: textTheme,
    appBarTheme: _appBarTheme(palette, textTheme),
    bottomNavigationBarTheme: _bottomNavigationBarTheme(palette),
    navigationBarTheme: _navigationBarTheme(palette, textTheme),
    filledButtonTheme: _filledButtonTheme(palette),
    outlinedButtonTheme: _outlinedButtonTheme(palette),
    textButtonTheme: _textButtonTheme(palette),
    floatingActionButtonTheme: _floatingActionButtonTheme(palette),
    inputDecorationTheme: _inputDecorationTheme(palette),
    chipTheme: _chipTheme(palette, textTheme),
    dividerTheme: DividerThemeData(
      color: palette.borderDivider,
      space: 1,
      thickness: 1,
    ),
    cardTheme: CardThemeData(
      color: palette.elevatedSurface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: palette.borderDivider),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: palette.elevatedSurface,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: textTheme.titleLarge,
      contentTextStyle: textTheme.bodyMedium,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: palette.borderDivider),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: palette.elevatedSurface,
      contentTextStyle: textTheme.bodyMedium,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  );
}

TextTheme _textTheme(TextTheme baseTheme, LumenThemePalette palette) {
  return baseTheme
      .apply(bodyColor: palette.primaryText, displayColor: palette.primaryText)
      .copyWith(
        headlineSmall: baseTheme.headlineSmall?.copyWith(
          color: palette.primaryText,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: baseTheme.titleLarge?.copyWith(
          color: palette.primaryText,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: baseTheme.titleMedium?.copyWith(
          color: palette.primaryText,
          fontWeight: FontWeight.w600,
        ),
        bodyMedium: baseTheme.bodyMedium?.copyWith(
          color: palette.secondaryText,
        ),
        labelLarge: baseTheme.labelLarge?.copyWith(
          color: palette.primaryBlue,
          fontWeight: FontWeight.w600,
        ),
        labelMedium: baseTheme.labelMedium?.copyWith(color: palette.mutedText),
      );
}

AppBarTheme _appBarTheme(LumenThemePalette palette, TextTheme textTheme) {
  return AppBarTheme(
    backgroundColor: palette.primaryBackground,
    foregroundColor: palette.primaryText,
    surfaceTintColor: Colors.transparent,
    centerTitle: false,
    elevation: 0,
    scrolledUnderElevation: 0,
    titleTextStyle: textTheme.titleLarge,
    iconTheme: IconThemeData(color: palette.primaryBlue),
    actionsIconTheme: IconThemeData(color: palette.primaryBlue),
  );
}

BottomNavigationBarThemeData _bottomNavigationBarTheme(
  LumenThemePalette palette,
) {
  return BottomNavigationBarThemeData(
    backgroundColor: palette.elevatedSurface,
    selectedItemColor: palette.primaryBlue,
    unselectedItemColor: palette.mutedText,
  );
}

NavigationBarThemeData _navigationBarTheme(
  LumenThemePalette palette,
  TextTheme textTheme,
) {
  return NavigationBarThemeData(
    backgroundColor: palette.elevatedSurface,
    surfaceTintColor: Colors.transparent,
    indicatorColor: palette.softBlue.withValues(alpha: 0.28),
    iconTheme: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return IconThemeData(color: palette.primaryBlue);
      }

      return IconThemeData(color: palette.mutedText);
    }),
    labelTextStyle: WidgetStateProperty.resolveWith((states) {
      final color = states.contains(WidgetState.selected)
          ? palette.primaryBlue
          : palette.mutedText;

      return textTheme.labelMedium?.copyWith(
        color: color,
        fontWeight: states.contains(WidgetState.selected)
            ? FontWeight.w700
            : FontWeight.w500,
      );
    }),
  );
}

FilledButtonThemeData _filledButtonTheme(LumenThemePalette palette) {
  return FilledButtonThemeData(
    style: ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return palette.borderDivider;
        }

        if (states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.pressed)) {
          return palette.hoverBlue;
        }

        return palette.primaryBlue;
      }),
      foregroundColor: WidgetStateProperty.all(palette.elevatedSurface),
      minimumSize: WidgetStateProperty.all(const Size(48, 44)),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
  );
}

OutlinedButtonThemeData _outlinedButtonTheme(LumenThemePalette palette) {
  return OutlinedButtonThemeData(
    style: ButtonStyle(
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return palette.mutedText;
        }

        if (states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.pressed)) {
          return palette.hoverBlue;
        }

        return palette.primaryBlue;
      }),
      side: WidgetStateProperty.resolveWith((states) {
        final color =
            states.contains(WidgetState.hovered) ||
                states.contains(WidgetState.pressed)
            ? palette.hoverBlue
            : palette.borderDivider;

        return BorderSide(color: color);
      }),
      minimumSize: WidgetStateProperty.all(const Size(48, 44)),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
  );
}

TextButtonThemeData _textButtonTheme(LumenThemePalette palette) {
  return TextButtonThemeData(
    style: ButtonStyle(
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return palette.mutedText;
        }

        if (states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.pressed)) {
          return palette.hoverBlue;
        }

        return palette.primaryBlue;
      }),
      minimumSize: WidgetStateProperty.all(const Size(48, 44)),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
  );
}

FloatingActionButtonThemeData _floatingActionButtonTheme(
  LumenThemePalette palette,
) {
  return FloatingActionButtonThemeData(
    backgroundColor: palette.primaryBlue,
    foregroundColor: palette.elevatedSurface,
    hoverColor: palette.hoverBlue,
    focusColor: palette.hoverBlue,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  );
}

InputDecorationTheme _inputDecorationTheme(LumenThemePalette palette) {
  return InputDecorationTheme(
    filled: true,
    fillColor: palette.elevatedSurface,
    labelStyle: TextStyle(color: palette.secondaryText),
    hintStyle: TextStyle(color: palette.mutedText),
    errorStyle: TextStyle(color: palette.accentRed),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: palette.borderDivider),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: palette.primaryBlue, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: palette.accentRed),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: palette.hoverRed, width: 1.5),
    ),
  );
}

ChipThemeData _chipTheme(LumenThemePalette palette, TextTheme textTheme) {
  return ChipThemeData(
    backgroundColor: palette.secondarySurface,
    selectedColor: palette.softBlue.withValues(alpha: 0.42),
    disabledColor: palette.borderDivider,
    labelStyle: textTheme.labelMedium?.copyWith(color: palette.primaryBlue),
    secondaryLabelStyle: textTheme.labelMedium?.copyWith(
      color: palette.primaryText,
    ),
    side: BorderSide(color: palette.borderDivider),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    padding: const EdgeInsets.symmetric(horizontal: 8),
  );
}

@immutable
class LumenThemeColors extends ThemeExtension<LumenThemeColors> {
  const LumenThemeColors(this.palette);

  final LumenThemePalette palette;

  @override
  LumenThemeColors copyWith({LumenThemePalette? palette}) {
    return LumenThemeColors(palette ?? this.palette);
  }

  @override
  LumenThemeColors lerp(
    covariant ThemeExtension<LumenThemeColors>? other,
    double t,
  ) {
    if (other is! LumenThemeColors) {
      return this;
    }

    return LumenThemeColors(LumenThemePalette.lerp(palette, other.palette, t));
  }

  static LumenThemePalette of(BuildContext context) {
    return Theme.of(context).extension<LumenThemeColors>()!.palette;
  }
}

@immutable
class LumenThemePalette {
  const LumenThemePalette({
    required this.name,
    required this.primaryBackground,
    required this.secondarySurface,
    required this.elevatedSurface,
    required this.borderDivider,
    required this.primaryText,
    required this.secondaryText,
    required this.mutedText,
    required this.primaryBlue,
    required this.hoverBlue,
    required this.softBlue,
    required this.accentRed,
    required this.hoverRed,
    required this.softRed,
    required this.brassGold,
    required this.sage,
    required this.supportingBlue,
  });

  final String name;
  final Color primaryBackground;
  final Color secondarySurface;
  final Color elevatedSurface;
  final Color borderDivider;
  final Color primaryText;
  final Color secondaryText;
  final Color mutedText;
  final Color primaryBlue;
  final Color hoverBlue;
  final Color softBlue;
  final Color accentRed;
  final Color hoverRed;
  final Color softRed;
  final Color brassGold;
  final Color sage;
  final Color supportingBlue;

  static const heritage = LumenThemePalette(
    name: 'Heritage',
    primaryBackground: Color(0xFFF6F1E7),
    secondarySurface: Color(0xFFEFE7D8),
    elevatedSurface: Color(0xFFFBF7EF),
    borderDivider: Color(0xFFD7CCB8),
    primaryText: Color(0xFF2A241D),
    secondaryText: Color(0xFF5C5348),
    mutedText: Color(0xFF85796A),
    primaryBlue: Color(0xFF1F3A5F),
    hoverBlue: Color(0xFF294B78),
    softBlue: Color(0xFF5D7694),
    accentRed: Color(0xFFA6473D),
    hoverRed: Color(0xFF8D3931),
    softRed: Color(0xFFC98A83),
    brassGold: Color(0xFFB08A4A),
    sage: Color(0xFF7C8B74),
    supportingBlue: Color(0xFFB6C4D2),
  );

  static const midnight = LumenThemePalette(
    name: 'Midnight',
    primaryBackground: Color(0xFF16181C),
    secondarySurface: Color(0xFF1E2228),
    elevatedSurface: Color(0xFF262B33),
    borderDivider: Color(0xFF3A414C),
    primaryText: Color(0xFFECE4D8),
    secondaryText: Color(0xFFC5BAAA),
    mutedText: Color(0xFF938A7E),
    primaryBlue: Color(0xFF6E8FB8),
    hoverBlue: Color(0xFF85A6CC),
    softBlue: Color(0xFFA8BDD6),
    accentRed: Color(0xFFC16A60),
    hoverRed: Color(0xFFA8554C),
    softRed: Color(0xFFE09A93),
    brassGold: Color(0xFFD0AE6A),
    sage: Color(0xFF8FA08A),
    supportingBlue: Color(0xFF556376),
  );

  static LumenThemePalette lerp(
    LumenThemePalette left,
    LumenThemePalette right,
    double t,
  ) {
    Color color(Color leftColor, Color rightColor) {
      return Color.lerp(leftColor, rightColor, t)!;
    }

    return LumenThemePalette(
      name: t < 0.5 ? left.name : right.name,
      primaryBackground: color(left.primaryBackground, right.primaryBackground),
      secondarySurface: color(left.secondarySurface, right.secondarySurface),
      elevatedSurface: color(left.elevatedSurface, right.elevatedSurface),
      borderDivider: color(left.borderDivider, right.borderDivider),
      primaryText: color(left.primaryText, right.primaryText),
      secondaryText: color(left.secondaryText, right.secondaryText),
      mutedText: color(left.mutedText, right.mutedText),
      primaryBlue: color(left.primaryBlue, right.primaryBlue),
      hoverBlue: color(left.hoverBlue, right.hoverBlue),
      softBlue: color(left.softBlue, right.softBlue),
      accentRed: color(left.accentRed, right.accentRed),
      hoverRed: color(left.hoverRed, right.hoverRed),
      softRed: color(left.softRed, right.softRed),
      brassGold: color(left.brassGold, right.brassGold),
      sage: color(left.sage, right.sage),
      supportingBlue: color(left.supportingBlue, right.supportingBlue),
    );
  }
}
