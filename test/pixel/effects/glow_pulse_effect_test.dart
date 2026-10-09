import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';

void main() {
  test('halo is symmetric, preserves sprite and does not mutate input', () {
    final pixels = Uint32List(49)..[24] = 0xFFFF0000;
    final effect =
        GlowPulseEffect({'time': 0.5, 'radius': 2, 'color': 0xFF00FF00});
    final output = effect.apply(pixels, 7, 7);
    expect(output[24], pixels[24]);
    expect(output[23], output[25]);
    expect(output[17], output[31]);
    expect(output[23] >>> 24, greaterThan(0));
    expect(output[0], 0);
    expect(pixels[23], 0);
  });
  test('pulse fades fully and wraps seamlessly', () {
    final pixels = Uint32List(49)..[24] = 0xFFFFFFFF;
    final effect = GlowPulseEffect({'minimum': 0.0});
    final start = effect.apply(pixels, 7, 7);
    expect(start, orderedEquals(pixels));
    effect.parameters['time'] = 0.5;
    expect(effect.apply(pixels, 7, 7)[23] >>> 24, greaterThan(0));
    effect.parameters['time'] = 1.0;
    expect(effect.apply(pixels, 7, 7), orderedEquals(start));
  });
  test('transparent images stay empty and factory serialization works', () {
    final effect = EffectsManager.createEffect(EffectType.glowPulse);
    expect(effect, isA<GlowPulseEffect>());
    expect(effect.isSeamlessLoop, isTrue);
    expect(effect.isAnimation, isTrue);
    expect(EffectsManager.effectFromJson({'type': 'glowPulse', 'parameters': effect.parameters}), isA<GlowPulseEffect>());
    final empty = Uint32List(9);
    expect(effect.apply(empty, 3, 3), orderedEquals(empty));
  });
}
