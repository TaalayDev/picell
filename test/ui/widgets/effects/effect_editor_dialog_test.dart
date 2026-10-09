import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/data/storage/local_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:picell/l10n/strings.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/effects/effects_editor_dialog.dart';
import 'package:picell/ui/widgets/effects/pixlel_preview_painter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.init();
  });

  const size = 8;
  final pixels = Uint32List(size * size)..fillRange(0, size * size, 0xFF808080);

  Future<List<Effect>> pump(WidgetTester tester, Size screen,
      {Effect? effect}) async {
    final applied = <Effect>[];
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = screen;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
        child: MaterialApp(
      localizationsDelegates: Strings.localizationsDelegates,
      supportedLocales: Strings.supportedLocales,
      home: Scaffold(
        body: EffectEditorDialog(
          effect: effect ?? BrightnessEffect(),
          layerWidth: size,
          layerHeight: size,
          layerPixels: pixels,
          onEffectUpdated: applied.add,
        ),
      ),
    )));
    await tester.pump(const Duration(milliseconds: 200));
    return applied;
  }

  testWidgets('desktop shows source and result together in a larger dialog',
      (tester) async {
    await pump(tester, const Size(1000, 900));
    expect(find.text('Result'), findsOneWidget);
    expect(find.text('Original'), findsOneWidget);
    expect(find.byKey(const ValueKey('effect-before-preview')), findsOneWidget);
    expect(find.byKey(const ValueKey('effect-after-preview')), findsOneWidget);
    expect(
        tester
            .getSize(find.byKey(const ValueKey('effect-editor-content')))
            .width,
        greaterThan(760));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'revert is disabled until a value changes and restores the opening state',
      (tester) async {
    await pump(tester, const Size(1000, 900));
    final revert = find.widgetWithIcon(IconButton, Icons.undo);
    expect(tester.widget<IconButton>(revert).onPressed, isNull);

    await tester.tap(find.widgetWithIcon(IconButton, Icons.refresh));
    await tester.pump();
    // Brightness opens at its default, so nothing changed yet.
    expect(tester.widget<IconButton>(revert).onPressed, isNull);

    await tester.pumpWidget(const SizedBox()); // drop the previous dialog state
    final changed = BrightnessEffect({'value': 0.5});
    await pump(tester, const Size(1000, 900), effect: changed);
    await tester.tap(find.widgetWithIcon(IconButton, Icons.refresh));
    await tester.pump();
    expect(tester.widget<IconButton>(revert).onPressed, isNotNull);

    await tester.tap(revert);
    await tester.pump();
    expect(tester.widget<IconButton>(revert).onPressed, isNull);
  });

  testWidgets('presets are available on small screens too', (tester) async {
    await pump(tester, const Size(420, 900));
    // Brightness has quick presets; they used to be desktop-only.
    expect(find.byType(ListView), findsWidgets);
    expect(find.text('Original'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('comparison preserves source while rendering adjusted pixels',
      (tester) async {
    await pump(tester, const Size(1440, 900),
        effect: BrightnessEffect({'value': 0.5}));
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 150));
    });
    await tester.pump();
    PixelPreviewPainter painter(String key) => tester
        .widget<CustomPaint>(find
            .descendant(
                of: find.byKey(ValueKey(key)),
                matching: find.byWidgetPredicate((widget) =>
                    widget is CustomPaint &&
                    widget.painter is PixelPreviewPainter))
            .first)
        .painter! as PixelPreviewPainter;
    expect(painter('effect-before-preview').pixels, orderedEquals(pixels));
    expect(painter('effect-after-preview').pixels.first, isNot(pixels.first));
    expect(tester.takeException(), isNull);
  });

  testWidgets('short desktop viewport stays within available height',
      (tester) async {
    await pump(tester, const Size(1000, 480));
    expect(
        tester
            .getSize(find.byKey(const ValueKey('effect-editor-content')))
            .height,
        lessThanOrEqualTo(432));
    expect(tester.takeException(), isNull);
  });
  testWidgets('mobile comparison is opt-in and can be switched off',
      (tester) async {
    await pump(tester, const Size(390, 844));
    final toggle = find.byKey(const ValueKey('effect-mobile-compare-switch'));
    expect(tester.widget<SwitchListTile>(toggle).value, isFalse);
    expect(find.byKey(const ValueKey('effect-before-preview')), findsNothing);
    await tester.tap(toggle);
    await tester.pump();
    expect(find.byKey(const ValueKey('effect-before-preview')), findsOneWidget);
    expect(find.byKey(const ValueKey('effect-after-preview')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(toggle);
    await tester.pump();
    expect(find.byKey(const ValueKey('effect-before-preview')), findsNothing);
    expect(tester.widget<SwitchListTile>(toggle).value, isFalse);
  });

  testWidgets('show presents a mobile bottom sheet', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
        child: MaterialApp(
      localizationsDelegates: Strings.localizationsDelegates,
      supportedLocales: Strings.supportedLocales,
      home: Scaffold(
          body: Builder(
              builder: (context) => TextButton(
                    onPressed: () => EffectEditorDialog.show(
                        context: context,
                        effect: BrightnessEffect(),
                        layerWidth: size,
                        layerHeight: size,
                        layerPixels: pixels,
                        onApply: (_) {}),
                    child: const Text('open'),
                  ))),
    )));
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.byType(Dialog), findsNothing);
    expect(
        tester
            .widget<SwitchListTile>(
                find.byKey(const ValueKey('effect-mobile-compare-switch')))
            .value,
        isFalse);
    expect(tester.takeException(), isNull);
  });
}
