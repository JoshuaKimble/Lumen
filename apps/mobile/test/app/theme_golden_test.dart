import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumen/src/app/theme.dart';

void main() {
  testWidgets('light theme visual regression baseline', (tester) async {
    await _pumpPreview(tester, mode: ThemeMode.light);

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/theme_preview_light.png'),
    );
  }, skip: !Platform.isMacOS);

  testWidgets('dark theme visual regression baseline', (tester) async {
    await _pumpPreview(tester, mode: ThemeMode.dark);

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/theme_preview_dark.png'),
    );
  }, skip: !Platform.isMacOS);
}

Future<void> _pumpPreview(WidgetTester tester, {required ThemeMode mode}) async {
  await tester.binding.setSurfaceSize(const Size(430, 932));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildLumenLightTheme(),
      darkTheme: buildLumenDarkTheme(),
      themeMode: mode,
      home: const _ThemePreviewScreen(),
    ),
  );
  await tester.pumpAndSettle();
}

class _ThemePreviewScreen extends StatelessWidget {
  const _ThemePreviewScreen();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Theme preview'),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.tune_outlined),
            tooltip: 'Theme settings',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Journal', style: textTheme.headlineSmall),
          const SizedBox(height: 6),
          Text(
            'Visual baseline for key theme components.',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Original entry',
              hintText: 'Write what happened today.',
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              Chip(label: Text('Family')),
              Chip(label: Text('Stress')),
              Chip(label: Text('Gratitude')),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Actions', style: textTheme.titleMedium),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.save_outlined),
                          label: const Text('Save'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: Icon(
                            Icons.delete_outline,
                            color: colorScheme.error,
                          ),
                          label: const Text('Delete'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Dialog(
            insetPadding: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Delete entry?', style: textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    'This action permanently removes the entry from this device.',
                    style: textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(onPressed: () {}, child: const Text('Cancel')),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () {},
                        style: FilledButton.styleFrom(
                          backgroundColor: colorScheme.error,
                          foregroundColor: colorScheme.onError,
                        ),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.book_outlined),
            selectedIcon: Icon(Icons.book),
            label: 'Journal',
          ),
          NavigationDestination(
            icon: Icon(Icons.mic_none_outlined),
            selectedIcon: Icon(Icons.mic),
            label: 'Voice',
          ),
          NavigationDestination(
            icon: Icon(Icons.bubble_chart_outlined),
            selectedIcon: Icon(Icons.bubble_chart),
            label: 'Themes',
          ),
        ],
      ),
    );
  }
}
