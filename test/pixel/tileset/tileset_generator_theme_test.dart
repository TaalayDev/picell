import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/app/theme/pv_tokens.dart';
import 'package:picell/ui/screens/tileset_generator/tileset_generator_screen.dart';

ThemeData themed(Brightness brightness, Color seed, double radius) {
  final scheme = ColorScheme.fromSeed(seedColor: seed, brightness: brightness);
  return ThemeData(
    colorScheme: scheme,
    fontFamily: 'serif',
    extensions: [
      PvTokens(
        gradient: LinearGradient(colors: [scheme.primary, scheme.secondary]),
        ink: scheme.onPrimary,
        background: scheme.surface,
        surface: scheme.surfaceContainerLow,
        surfaceHigh: scheme.surfaceContainerHigh,
        divider: scheme.outlineVariant,
        textPrimary: scheme.onSurface,
        textSecondary: scheme.onSurfaceVariant,
        primary: scheme.primary,
        accent: scheme.secondary,
        ok: scheme.tertiary,
        warn: scheme.secondary,
        err: scheme.error,
        checkerA: scheme.surfaceContainer,
        checkerB: scheme.surfaceContainerHighest,
        cardRadius: radius,
        buttonRadius: radius,
        chipRadius: radius,
        cardBorderWidth: 1,
        cardElevation: 0,
        shadowColor: Colors.transparent,
        isDark: brightness == Brightness.dark,
      )
    ],
  );
}

void main() {
  testWidgets('generator follows live app theme colors, typography and geometry', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final screenKey = GlobalKey<TilesetGeneratorScreenState>();
    TilesetGeneratorScreenState? originalState;
    for (final theme in [themed(Brightness.light, Colors.amber, 2), themed(Brightness.dark, Colors.teal, 18)]) {
      await tester.pumpWidget(MaterialApp(
        theme: theme,
        home: TilesetGeneratorScreen(key: screenKey),
      ));
      await tester.pumpAndSettle();
      originalState ??= screenKey.currentState;
      expect(screenKey.currentState, same(originalState));
      final tokens = theme.extension<PvTokens>()!;
      final labelContext = tester.element(find.text('1 · PERSPECTIVE'));
      expect(Theme.of(labelContext).brightness, theme.brightness);
      expect(Theme.of(labelContext).textTheme.bodyMedium!.fontFamily, 'serif');
      final label = tester.widget<Text>(find.text('1 · PERSPECTIVE'));
      expect(label.style!.color, tokens.textSecondary);
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, tokens.background);
      final chip =
          tester.widget<ChoiceChip>(find.ancestor(of: find.text('Side View'), matching: find.byType(ChoiceChip)));
      expect(chip.side!.color, tokens.primary);
      expect((chip.shape! as RoundedRectangleBorder).borderRadius, BorderRadius.circular(tokens.chipRadius));
      final panels = tester.widgetList<ColoredBox>(find.byType(ColoredBox));
      expect(panels.any((panel) => panel.color == tokens.surface), isTrue);
      expect(tester.takeException(), isNull);
    }
  });
}
