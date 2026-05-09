import 'package:flutter/material.dart';

import '../domain/journal_theme.dart';

class JournalThemeChips extends StatelessWidget {
  const JournalThemeChips({required this.themes, super.key});

  final List<JournalTheme> themes;

  @override
  Widget build(BuildContext context) {
    if (themes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final theme in themes)
          Chip(
            label: Text(theme.displayName),
            visualDensity: VisualDensity.compact,
            side: BorderSide.none,
          ),
      ],
    );
  }
}
