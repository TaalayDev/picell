import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:picell/data/storage/local_storage.dart';
import 'package:picell/l10n/strings.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/effects/effect_animation_generator_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.init();
  });

  testWidgets('EffectAnimationGeneratorDialog renders Parameters inline without separate window',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final effect = FrostGlazeEffect();
    final pixels = Uint32List(32 * 32);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: Strings.localizationsDelegates,
          supportedLocales: Strings.supportedLocales,
          home: Scaffold(
            body: EffectAnimationGeneratorDialog(
              effect: effect,
              layerWidth: 32,
              layerHeight: 32,
              layerPixels: pixels,
              effects: [effect],
              effectIndex: 0,
              onFramesGenerated: (_) async {},
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    // Verify "Parameters" title is displayed
    expect(find.text('Parameters'), findsOneWidget);
    expect(find.text('Effect parameters'), findsNothing);

    // Verify no separate "Edit Parameters" button exists
    expect(find.text('Edit Parameters'), findsNothing);

    // Verify parameter fields are rendered directly inline (e.g. Sliders for Crystal Density, Frost Branching)
    expect(find.text('Crystal Density'), findsOneWidget);
    expect(find.text('Frost Branching'), findsOneWidget);
    expect(find.text('Specular Shimmer'), findsOneWidget);

    // Verify sliders exist inline
    final sliders = find.byType(Slider);
    expect(sliders, findsWidgets);
  });
}
