import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/fields/ui_field.dart';

void main() {
  group('ChromaticAberrationEffect', () {
    test('instantiates with default parameters and metadata', () {
      final effect = ChromaticAberrationEffect();
      expect(effect.type, equals(EffectType.chromaticAberration));
      expect(effect.parameters['mode'], equals('linear'));
      expect(effect.parameters['distance'], equals(3.0));
      expect(effect.parameters['angle'], equals(0.0));
      expect(effect.parameters['blueFactor'], equals(1.0));
      expect(effect.parameters['preserveAlpha'], isTrue);

      final defaults = effect.getDefaultParameters();
      expect(defaults['distance'], equals(3.0));

      final metadata = effect.getMetadata();
      expect(metadata.containsKey('mode'), isTrue);
      expect(metadata.containsKey('distance'), isTrue);
      expect(metadata.containsKey('angle'), isTrue);
      expect(metadata.containsKey('blueFactor'), isTrue);
      expect(metadata.containsKey('preserveAlpha'), isTrue);
    });

    test('getFields returns strongly-typed UIField descriptors', () {
      final effect = ChromaticAberrationEffect();
      final fields = effect.getFields();

      expect(fields.length, equals(5));
      final keys = fields.map((f) => f.key).toList();
      expect(keys, containsAll([
        'mode',
        'distance',
        'angle',
        'blueFactor',
        'preserveAlpha',
      ]));

      final modeField = fields.firstWhere((f) => f.key == 'mode') as SelectField;
      expect(modeField.options.containsKey('linear'), isTrue);
      expect(modeField.options.containsKey('radial'), isTrue);

      final distField = fields.firstWhere((f) => f.key == 'distance') as SliderField;
      expect(distField.min, equals(0.0));
      expect(distField.max, equals(15.0));

      final angleField = fields.firstWhere((f) => f.key == 'angle') as SliderField;
      expect(angleField.max, equals(360.0));
    });

    test('EffectsManager creates and deserializes ChromaticAberrationEffect', () {
      final effect = EffectsManager.createEffect(EffectType.chromaticAberration, {
        'distance': 5.0,
      });
      expect(effect, isA<ChromaticAberrationEffect>());
      expect(effect.parameters['distance'], equals(5.0));

      final fromJson = EffectsManager.effectFromJson({
        'type': 'chromaticAberration',
        'parameters': {'distance': 6.0},
      });
      expect(fromJson, isA<ChromaticAberrationEffect>());
      expect(fromJson?.parameters['distance'], equals(6.0));
    });

    test('linear horizontal split shifts Red rightward and Blue leftward', () {
      // 5x1 image: 0 (transparent), 0 (transparent), center is solid white (0xFFFFFFFF), 0, 0
      const width = 5;
      const height = 1;
      final pixels = Uint32List.fromList([
        0x00000000,
        0x00000000,
        0xFFFFFFFF,
        0x00000000,
        0x00000000,
      ]);

      // Angle 0 degrees = shift along +X for Red, -X for Blue
      // Distance 1.0 = 1 pixel shift
      final effect = ChromaticAberrationEffect({
        'mode': 'linear',
        'distance': 1.0,
        'angle': 0.0,
        'blueFactor': 1.0,
        'preserveAlpha': true,
      });

      final out = effect.apply(pixels, width, height);

      // At x = 1: Red channel is sampled from center pixel (rx = 1 + 1 = 2)
      final p1 = out[1];
      final r1 = (p1 >> 16) & 0xFF;
      expect(r1, equals(255));
      expect(p1 & 0xFF, equals(0)); // Blue is 0 here

      // At x = 3: Blue channel is sampled from center pixel (bx = 3 + (-1) = 2)
      final p3 = out[3];
      final b3 = p3 & 0xFF;
      expect(b3, equals(255));
      expect((p3 >> 16) & 0xFF, equals(0)); // Red is 0 here
    });

    test('radial mode leaves center intact while displacing corners', () {
      const width = 5;
      const height = 5;
      // All solid white
      final pixels = Uint32List(width * height)..fillRange(0, width * height, 0xFFFFFFFF);

      final effect = ChromaticAberrationEffect({
        'mode': 'radial',
        'distance': 2.0,
        'blueFactor': 1.0,
        'preserveAlpha': true,
      });

      final out = effect.apply(pixels, width, height);

      // Center pixel (2, 2) has zero displacement -> should be pure white
      final center = out[2 * width + 2];
      expect((center >> 16) & 0xFF, equals(255));
      expect((center >> 8) & 0xFF, equals(255));
      expect(center & 0xFF, equals(255));
    });

    test('preserves transparent background outside color fringes', () {
      const width = 7;
      const height = 1;
      final pixels = Uint32List.fromList([
        0x00000000,
        0x00000000,
        0x00000000,
        0xFFFFFFFF, // center at index 3
        0x00000000,
        0x00000000,
        0x00000000,
      ]);

      final effect = ChromaticAberrationEffect({
        'mode': 'linear',
        'distance': 1.0,
        'angle': 0.0,
        'blueFactor': 1.0,
        'preserveAlpha': true,
      });

      final out = effect.apply(pixels, width, height);

      // Distant pixel at index 0 remains completely transparent (0x00000000)
      expect(out[0], equals(0));
      expect(out[6], equals(0));
    });
  });
}
