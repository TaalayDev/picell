import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:picell/data/storage/local_storage.dart';
import 'package:picell/l10n/strings.dart';
import 'package:picell/pixel/gradient/gradient_options.dart';
import 'package:picell/pixel/gradient/gradient_renderer.dart';
import 'package:picell/providers/editor_settings_provider.dart';
import 'package:picell/ui/widgets/gradient_options_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.init();
  });

  Future<ProviderContainer> pump(WidgetTester tester, {Color? primary}) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    // LocalStorage is initialised once per isolate, so settings leak
    // between tests unless reset.
    container.read(editorSettingsNotifierProvider.notifier).resetToDefaults();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: Strings.localizationsDelegates,
          supportedLocales: Strings.supportedLocales,
          home: Scaffold(
            body: Center(child: GradientOptionsBar(primaryColor: primary)),
          ),
        ),
      ),
    );
    return container;
  }

  Finder menuRow(String text) => find.ancestor(
        of: find.text(text).last,
        matching: find.byWidgetPredicate((w) => w is PopupMenuEntry),
      );

  EditorSettings settings(ProviderContainer c) => c.read(editorSettingsNotifierProvider);

  testWidgets('picks shape and toggles paint area', (tester) async {
    final c = await pump(tester);

    await tester.tap(find.byKey(const ValueKey('gradient-type')));
    await tester.pumpAndSettle();
    await tester.tap(menuRow('Diamond'));
    await tester.pumpAndSettle();
    expect(settings(c).gradientType, GradientType.diamond);

    await tester.tap(find.byKey(const ValueKey('gradient-target')));
    await tester.pumpAndSettle();
    expect(settings(c).gradientTarget, GradientTarget.contiguous);
  });

  testWidgets('picking Smooth hides the dither control', (tester) async {
    final c = await pump(tester);
    expect(find.byKey(const ValueKey('gradient-dither')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('gradient-steps')));
    await tester.pumpAndSettle();
    await tester.tap(menuRow('Smooth'));
    await tester.pumpAndSettle();

    expect(settings(c).gradientSteps, 0);
    expect(find.byKey(const ValueKey('gradient-dither')), findsNothing);
  });

  testWidgets('dither and blend menus write settings', (tester) async {
    final c = await pump(tester);

    await tester.tap(find.byKey(const ValueKey('gradient-dither')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bayer 8×8'));
    await tester.pumpAndSettle();
    expect(settings(c).gradientDither, GradientDither.bayer8);

    await tester.tap(find.byKey(const ValueKey('gradient-blend')));
    await tester.pumpAndSettle();
    await tester.tap(menuRow('Keep transparency'));
    await tester.pumpAndSettle();
    expect(settings(c).gradientBlend, GradientBlend.lockAlpha);

    await tester.tap(find.byKey(const ValueKey('gradient-end')));
    await tester.pumpAndSettle();
    await tester.tap(menuRow('To transparent'));
    await tester.pumpAndSettle();
    expect(settings(c).gradientEnd, GradientEnd.transparent);
  });

  testWidgets('choosing a color ramp opens the editor and builds the ramp', (tester) async {
    final c = await pump(tester, primary: const Color(0xFF112233));

    await tester.tap(find.byKey(const ValueKey('gradient-end')));
    await tester.pumpAndSettle();
    await tester.tap(menuRow('Color ramp'));
    await tester.pumpAndSettle();
    expect(settings(c).gradientEnd, GradientEnd.ramp);
    expect(find.text('No colors yet'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('gradient-ramp-add-primary')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('gradient-ramp-add-secondary')));
    await tester.pump();
    expect(settings(c).gradientRamp, const [Color(0xFF112233), Color(0xFFFFFFFF)]);

    await tester.tap(find.byKey(const ValueKey('gradient-ramp-reverse')));
    await tester.pump();
    expect(settings(c).gradientRamp.first, const Color(0xFFFFFFFF));

    await tester.tap(find.byKey(const ValueKey('gradient-ramp-color-0')));
    await tester.pump();
    expect(settings(c).gradientRamp, const [Color(0xFF112233)]);

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    // With fewer than two colours the ramp falls back, so bands stay editable.
    expect(find.byKey(const ValueKey('gradient-steps')), findsOneWidget);
    expect(find.byKey(const ValueKey('gradient-ramp')), findsOneWidget);
  });

  testWidgets('a ramp of 2+ colors replaces the bands control', (tester) async {
    final c = await pump(tester);
    c.read(editorSettingsNotifierProvider.notifier)
      ..setGradientRamp(const [Colors.red, Colors.green, Colors.blue])
      ..setGradientEnd(GradientEnd.ramp);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('gradient-steps')), findsNothing);
    expect(find.byKey(const ValueKey('gradient-dither')), findsOneWidget);
    expect(find.byType(GradientRampStrip), findsOneWidget);
  });
}
