import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:picell/data/models/layer.dart';
import 'package:picell/pixel/effects/effects.dart';

void main() {
  // A 4×2 canvas: effects used to guess the width as sqrt(8) = 2 and ran on
  // a 2×2 image, shifting results on every non-square canvas.
  const width = 4;
  const height = 2;
  final pixels = Uint32List.fromList([
    0xFFFF0000, 0, 0, 0, //
    0, 0, 0xFF00FF00, 0,
  ]);
  Effect shadow() => EffectsManager.createEffect(EffectType.dropShadow);

  Layer layer() => Layer(layerId: 1, id: 'layer', name: 'Layer', pixels: pixels, effects: [shadow()]);

  test('applies effects with the real canvas size', () {
    final expected = EffectsManager.applyMultipleEffects(pixels, width, height, [shadow()]);

    expect(layer().processedPixels(width, height), expected);
  });

  test('prepared pixels match the lazy result and are cached', () async {
    final prepared = layer();
    expect(prepared.needsEffectProcessing, isTrue);

    await Layer.prepareProcessedPixels([prepared], width, height);

    expect(prepared.needsEffectProcessing, isFalse);
    expect(prepared.processedPixels(width, height), layer().processedPixels(width, height));
  });

  test('layers without effects return their own pixels', () {
    final plain = Layer(layerId: 2, id: 'plain', name: 'Plain', pixels: pixels);

    expect(plain.needsEffectProcessing, isFalse);
    expect(identical(plain.processedPixels(width, height), pixels), isTrue);
  });
}
