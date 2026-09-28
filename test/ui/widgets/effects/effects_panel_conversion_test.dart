import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:picell/data/models/layer.dart';
import 'package:picell/data/storage/local_storage.dart';
import 'package:picell/l10n/strings.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/effects/effects_editor_dialog.dart';
import 'package:picell/ui/widgets/effects/effects_panel.dart';
import 'package:picell/ui/widgets/effects/effects_selector_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.init();
  });
  testWidgets('Apply All routes procedural stacks through conversion',
      (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final layer = Layer(
      layerId: 1,
      id: 'procedural',
      name: 'Procedural',
      pixels: Uint32List(32 * 32),
      effects: [MountainRangeEffect(), BrightnessEffect()],
    );
    List<Effect>? convertedEffects;
    var directLayerUpdates = 0;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: Strings.localizationsDelegates,
          supportedLocales: Strings.supportedLocales,
          home: Scaffold(
            body: EffectsPanel(
              layer: layer,
              width: 32,
              height: 32,
              onLayerUpdated: (_) => directLayerUpdates++,
              onConvertToPixels: (effects) {
                convertedEffects = effects;
                return true;
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, 'Apply All'));
    await tester.pump();

    expect(convertedEffects, isNotNull);
    expect(convertedEffects!.first, isA<MountainRangeEffect>());
    expect(convertedEffects, hasLength(2));
    expect(directLayerUpdates, 0);
  });

  testWidgets('selecting animation effect invokes onAnimate without adding to layer stack',
      (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final layer = Layer(
      layerId: 1,
      id: 'layer1',
      name: 'Layer 1',
      pixels: Uint32List(32 * 32)..[0] = 0xFFFFFFFF,
    );

    Effect? animatedEffect;
    var directLayerUpdates = 0;

    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: Strings.localizationsDelegates,
          supportedLocales: Strings.supportedLocales,
          home: Scaffold(
            body: EffectsPanel(
              layer: layer,
              width: 32,
              height: 32,
              onLayerUpdated: (_) => directLayerUpdates++,
              onAnimate: (effect, effects, effectIndex) {
                animatedEffect = effect;
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap Add Effect
    final firstEffectBtn = find.text('Add your first effect');
    if (firstEffectBtn.evaluate().isNotEmpty) {
      await tester.tap(firstEffectBtn);
    } else {
      await tester.tap(find.text('Add Effect').first);
    }
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(EffectSelectorDialog), findsOneWidget);

    // Scroll workspace chip list to reveal Animation
    await tester.drag(find.text('Filters'), const Offset(-300, 0));
    await tester.pump(const Duration(milliseconds: 300));

    // Tap Animation tab in dialog
    await tester.tap(find.text('Animation'));
    await tester.pump(const Duration(milliseconds: 300));

    // Tap Special effects
    await tester.tap(find.byKey(const ValueKey('animation-kind-specialEffect')));
    await tester.pump(const Duration(milliseconds: 300));

    // Select Frost Glaze & Crystal Freeze
    await tester.enterText(find.byType(TextField), 'Frost Glaze');
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('Frost Glaze & Crystal Freeze'));
    await tester.pump(const Duration(milliseconds: 300));

    // Verify onAnimate was called with FrostGlazeEffect
    expect(animatedEffect, isNotNull);
    expect(animatedEffect, isA<FrostGlazeEffect>());

    // Verify layer effects were NOT updated
    expect(directLayerUpdates, 0);
  });

  testWidgets(
      'selecting generator effect opens EffectEditorDialog and applying updates layer pixels directly',
      (tester) async {
    final layer = Layer(
      layerId: 1,
      id: 'layer1',
      name: 'Layer 1',
      pixels: Uint32List(32 * 32),
    );

    Layer? updatedLayer;

    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: Strings.localizationsDelegates,
          supportedLocales: Strings.supportedLocales,
          home: Scaffold(
            body: EffectsPanel(
              layer: layer,
              width: 32,
              height: 32,
              onLayerUpdated: (l) => updatedLayer = l,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap Add Effect
    final firstEffectBtn = find.text('Add your first effect');
    if (firstEffectBtn.evaluate().isNotEmpty) {
      await tester.tap(firstEffectBtn);
    } else {
      await tester.tap(find.text('Add Effect').first);
    }
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(EffectSelectorDialog), findsOneWidget);

    // Tap Generators tab in selector dialog
    await tester.tap(find.text('Generators'));
    await tester.pump(const Duration(milliseconds: 300));

    // Select Mountain Range
    await tester.enterText(find.byType(TextField), 'Mountain Range');
    await tester.pump(const Duration(milliseconds: 300));

    final mountainItem = find.descendant(
      of: find.byType(GridView),
      matching: find.text('Mountain Range'),
    );
    await tester.tap(mountainItem);
    await tester.pump(const Duration(milliseconds: 500));

    // Verify EffectEditorDialog is now open
    expect(find.byType(EffectEditorDialog), findsOneWidget);

    // Tap Apply in EffectEditorDialog
    final applyBtn = find.widgetWithText(ElevatedButton, 'Apply');
    expect(applyBtn, findsOneWidget);
    await tester.tap(applyBtn);
    await tester.pump(const Duration(milliseconds: 300));

    // Verify layer was updated with generated pixels
    expect(updatedLayer, isNotNull);
    expect(updatedLayer!.effects, isEmpty);
    expect(updatedLayer!.pixels.any((p) => p != 0), isTrue);
  });
}
