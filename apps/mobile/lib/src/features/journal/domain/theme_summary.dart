import 'journal_entry.dart';
import 'journal_theme.dart';

class ThemeSummary {
  const ThemeSummary({
    required this.id,
    required this.name,
    required this.displayName,
    required this.entryCount,
    required this.score,
  });

  final String id;
  final String name;
  final String displayName;
  final int entryCount;
  final double score;
}

List<ThemeSummary> summarizeThemes(List<JournalEntry> entries) {
  final builders = <String, _ThemeSummaryBuilder>{};

  for (final entry in entries) {
    final entryThemes = <String, JournalTheme>{};

    for (final theme in entry.themes) {
      entryThemes.putIfAbsent(theme.id, () => theme);
    }

    for (final theme in entryThemes.values) {
      final builder = builders.putIfAbsent(
        theme.id,
        () => _ThemeSummaryBuilder(theme),
      );
      builder.add(theme);
    }
  }

  return builders.values.map((builder) => builder.build()).toList()
    ..sort(_compareThemeSummary);
}

int _compareThemeSummary(ThemeSummary left, ThemeSummary right) {
  final scoreComparison = right.score.compareTo(left.score);

  if (scoreComparison != 0) {
    return scoreComparison;
  }

  final countComparison = right.entryCount.compareTo(left.entryCount);

  if (countComparison != 0) {
    return countComparison;
  }

  return left.displayName.compareTo(right.displayName);
}

class _ThemeSummaryBuilder {
  _ThemeSummaryBuilder(JournalTheme theme)
    : id = theme.id,
      name = theme.name,
      displayName = theme.displayName;

  final String id;
  final String name;
  final String displayName;
  var entryCount = 0;
  var score = 0.0;

  void add(JournalTheme theme) {
    entryCount += 1;
    score += theme.weight ?? 1;
  }

  ThemeSummary build() {
    return ThemeSummary(
      id: id,
      name: name,
      displayName: displayName,
      entryCount: entryCount,
      score: score,
    );
  }
}
