import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../domain/theme_summary.dart';
import 'theme_summaries_provider.dart';

class ThemeCloudScreen extends ConsumerWidget {
  const ThemeCloudScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeSummaries = ref.watch(themeSummariesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Themes')),
      body: SafeArea(
        child: themeSummaries.when(
          data: (summaries) {
            if (summaries.isEmpty) {
              return const _EmptyThemesState();
            }

            return _ThemeCloud(summaries: summaries);
          },
          error: (error, stackTrace) =>
              const Center(child: Text('Unable to load themes.')),
          loading: () => const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }
}

class _ThemeCloud extends StatelessWidget {
  const _ThemeCloud({required this.summaries});

  final List<ThemeSummary> summaries;

  @override
  Widget build(BuildContext context) {
    final highestScore = summaries.first.score;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Recurring themes',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          'A quiet view of what has been showing up across your entries.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final summary in summaries)
              _ThemeCloudChip(
                themeId: summary.id,
                displayName: summary.displayName,
                entryCount: summary.entryCount,
                prominence: summary.score / highestScore,
              ),
          ],
        ),
      ],
    );
  }
}

class _ThemeCloudChip extends StatelessWidget {
  const _ThemeCloudChip({
    required this.themeId,
    required this.displayName,
    required this.entryCount,
    required this.prominence,
  });

  final String themeId;
  final String displayName;
  final int entryCount;
  final double prominence;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final constrainedProminence = prominence.clamp(0.45, 1.0);
    final titleFontSize = 15 + (constrainedProminence * 3);
    final accentSize = 7 + (constrainedProminence * 4);
    final horizontalPadding = 14 + (constrainedProminence * 4);
    final verticalPadding = 11 + (constrainedProminence * 3);
    final backgroundColor = Color.lerp(
      colorScheme.surfaceContainerHighest,
      colorScheme.primaryContainer,
      0.08 + (constrainedProminence * 0.08),
    )!;
    final borderColor = Color.lerp(
      colorScheme.outlineVariant,
      colorScheme.primary,
      0.22 + (constrainedProminence * 0.28),
    )!;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => context.goNamed(
        themeDetailRouteName,
        pathParameters: {'themeId': themeId},
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: accentSize,
                height: accentSize,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: textTheme.labelLarge?.copyWith(
                      color: colorScheme.onSurface,
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    entryCount == 1 ? '1 entry' : '$entryCount entries',
                    style: textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 12.5,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyThemesState extends StatelessWidget {
  const _EmptyThemesState();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bubble_chart_outlined,
              size: 48,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'No themes yet',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Themes will appear after entries are rewritten and tagged.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
