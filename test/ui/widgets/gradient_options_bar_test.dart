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

  Future<ProviderContainer> pump(WidgetTester tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    // LocalStorage is initialised once per isolate, so settings leak
    // between tests unless reset.
    container.read(editorSettingsNotifierProvider.notifier).resetToDefaults();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: Strings.localizationsDelegates,
          supportedLocales: Strings.supportedLocales,
          home: Scaffold(body: Center(child: GradientOptionsBar())),
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

  testWidgets('toggles shape and paint area', (tester) async {
    final c = await pump(tester);

    await tester.tap(find.byKey(const ValueKey('gradient-type')));
    await tester.pumpAndSettle();
    expect(settings(c).gradientType, GradientType.radial);

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
}
