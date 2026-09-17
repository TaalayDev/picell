import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/fields/ui_field.dart';

void main() {
  group('NormalMapEffect', () {
    test('instantiates with default parameters and metadata', () {
      final effect = NormalMapEffect();
      expect(effect.type, equals(EffectType.normalMap));
      expect(effect.parameters['strength'], equals(2.5));
      expect(effect.parameters['bevelEdges'], isTrue);
      expect(effect.parameters['bevelRadius'], equals(2));
      expect(effect.parameters['invertY'], isFalse);
      expect(effect.parameters['preserveAlpha'], isTrue);

      final defaults = effect.getDefaultParameters();
      expect(defaults['strength'], equals(2.5));

      final metadata = effect.getMetadata();
      expect(metadata.containsKey('strength'), isTrue);
      expect(metadata.containsKey('bevelEdges'), isTrue);
      expect(metadata.containsKey('invertY'), isTrue);
    });

    test('getFields returns strongly-typed UIField descriptors', () {
      final effect = NormalMapEffect();
      final fields = effect.getFields();

      expect(fields.length, equals(6));
      final keys = fields.map((f) => f.key).toList();
      expect(keys, containsAll([
        'strength',
        'bevelEdges',
        'bevelRadius',
        'invertY',
        'smoothness',
        'preserveAlpha',
      ]));

      final strengthField = fields.firstWhere((f) => f.key == 'strength') as SliderField;
      expect(strengthField.min, equals(0.2));
      expect(strengthField.max, equals(8.0));

      final invertYField = fields.firstWhere((f) => f.key == 'invertY');
      expect(invertYField, isA<BoolField>());
    });

    test('EffectsManager creates and deserializes NormalMapEffect', () {
      final effect = EffectsManager.createEffect(EffectType.normalMap, {
        'strength': 3.0,
      });
      expect(effect, isA<NormalMapEffect>());
      expect(effect.parameters['strength'], equals(3.0));

      final fromJson = EffectsManager.effectFromJson({
        'type': 'normalMap',
        'parameters': {'strength': 4.0},
      });
      expect(fromJson, isA<NormalMapEffect>());
      expect(fromJson?.parameters['strength'], equals(4.0));
    });

    test('flat interior region produces tangent-space normal pointing upwards (128, 128, 255)', () {
      // 5x5 image of uniform white without edge beveling
      const width = 5;
      const height = 5;
      final pixels = Uint32List(width * height)..fillRange(0, width * height, 0xFFFFFFFF);

      final effect = NormalMapEffect({
        'strength': 2.0,
        'bevelEdges': false, // pure height-based, flat surface
        'invertY': false,
        'smoothness': 0,
        'preserveAlpha': true,
      });

      final out = effect.apply(pixels, width, height);
      final center = out[2 * width + 2];

      final r = (center >> 16) & 0xFF;
      final g = (center >> 8) & 0xFF;
      final b = center & 0xFF;

      // With zero gradient, Nx = 0 -> R = 128, Ny = 0 -> G = 128, Nz = 1 -> B = 255
      expect(r, closeTo(128, 2));
      expect(g, closeTo(128, 2));
      expect(b, closeTo(255, 2));
    });

    test('invertY flips the green normal channel on vertical gradient', () {
      // 3x3 image with top half black (0) and bottom half white (255)
      const width = 3;
      const height = 3;
      final pixels = Uint32List.fromList([
        0xFF000000, 0xFF000000, 0xFF000000,
        0xFF808080, 0xFF808080, 0xFF808080,
        0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF,
      ]);

      final effectOpenGL = NormalMapEffect({
        'strength': 2.0,
        'bevelEdges': false,
        'invertY': false,
        'preserveAlpha': true,
      });
      final effectDirectX = NormalMapEffect({
        'strength': 2.0,
        'bevelEdges': false,
        'invertY': true,
        'preserveAlpha': true,
      });

      final outOpenGL = effectOpenGL.apply(pixels, width, height);
      final outDirectX = effectDirectX.apply(pixels, width, height);

      final gOpenGL = (outOpenGL[1 * width + 1] >> 8) & 0xFF;
      final gDirectX = (outDirectX[1 * width + 1] >> 8) & 0xFF;

      // When Y is inverted, the green channel shifts to the opposite side of 128
      expect((gOpenGL - 128).sign, equals(-(gDirectX - 128).sign));
    });

    test('preserves transparent background when preserveAlpha is true', () {
      const width = 3;
      const height = 3;
      final pixels = Uint32List(width * height);
      pixels[1 * width + 1] = 0xFFFFFFFF; // Center only

      final effect = NormalMapEffect({
        'preserveAlpha': true,
      });

      final out = effect.apply(pixels, width, height);
      // Corner remains 0x00000000
      expect(out[0], equals(0));
      // Center has alpha 255
      expect((out[1 * width + 1] >> 24) & 0xFF, equals(255));
    });
  });
}
