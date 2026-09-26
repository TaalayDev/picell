import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/data/models/layer.dart';
import 'package:picell/l10n/strings.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/effects/effects_panel.dart';

void main() {
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
      MaterialApp(
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
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, 'Apply All'));
    await tester.pump();

    expect(convertedEffects, isNotNull);
    expect(convertedEffects!.first, isA<MountainRangeEffect>());
    expect(convertedEffects, hasLength(2));
    expect(directLayerUpdates, 0);
  });
}
