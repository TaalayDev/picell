import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/fields/ui_field.dart';

void main() {
  group('WindSwayEffect', () {
    test('instantiates with default parameters and isAnimation is true', () {
      final effect = WindSwayEffect();
      expect(effect.type, equals(EffectType.windSway));
      expect(effect.isAnimation, isTrue);
      expect(effect.parameters['amplitude'], equals(6.0));
      expect(effect.parameters['speed'], equals(1.0));
      expect(effect.parameters['frequency'], equals(0.8));
      expect(effect.parameters['anchor'], equals('bottom'));
      expect(effect.parameters['preserveAlpha'], isTrue);

      final defaults = effect.getDefaultParameters();
      expect(defaults['amplitude'], equals(6.0));

      final metadata = effect.getMetadata();
      expect(metadata.containsKey('amplitude'), isTrue);
      expect(metadata.containsKey('speed'), isTrue);
      expect(metadata.containsKey('anchor'), isTrue);
    });

    test('getFields returns strongly-typed UIField descriptors', () {
      final effect = WindSwayEffect();
      final fields = effect.getFields();

      expect(fields.length, equals(7));
      final keys = fields.map((f) => f.key).toList();
      expect(keys, containsAll([
        'amplitude',
        'speed',
        'frequency',
        'stiffness',
        'anchor',
        'time',
        'preserveAlpha',
      ]));

      final ampField = fields.firstWhere((f) => f.key == 'amplitude') as SliderField;
      expect(ampField.min, equals(1.0));
      expect(ampField.max, equals(24.0));

      final anchorField = fields.firstWhere((f) => f.key == 'anchor') as SelectField;
      expect(anchorField.options.containsKey('bottom'), isTrue);
      expect(anchorField.options.containsKey('top'), isTrue);
      expect(anchorField.options.containsKey('left'), isTrue);
    });

    test('EffectsManager creates and deserializes WindSwayEffect', () {
      final effect = EffectsManager.createEffect(EffectType.windSway, {
        'amplitude': 8.0,
      });
      expect(effect, isA<WindSwayEffect>());
      expect(effect.parameters['amplitude'], equals(8.0));

      final fromJson = EffectsManager.effectFromJson({
        'type': 'windSway',
        'parameters': {'amplitude': 10.0},
      });
      expect(fromJson, isA<WindSwayEffect>());
      expect(fromJson?.parameters['amplitude'], equals(10.0));
    });

    test('bottom anchor leaves root row unaffected while displacing top row', () {
      const width = 11;
      const height = 11;
      final pixels = Uint32List(width * height);
      // Vertical line of white pixels right down center column (x = 5)
      for (int y = 0; y < height; y++) {
        pixels[y * width + 5] = 0xFFFFFFFF;
      }

      // time = 0.25 -> sin(2pi * 0.25) = sin(pi/2) = 1.0 (maximum sway to the side)
      final effect = WindSwayEffect({
        'amplitude': 4.0,
        'speed': 1.0,
        'frequency': 0.0,
        'stiffness': 1.0,
        'anchor': 'bottom',
        'time': 0.25,
        'preserveAlpha': true,
      });

      final out = effect.apply(pixels, width, height);

      // Root row (y = 10) must remain at x = 5 (displacement = 0 at root)
      expect(out[10 * width + 5], equals(0xFFFFFFFF));

      // Top row (y = 0) has maximum displacement of 4px -> sampled from x = 5 - 4 = 1 -> so out[0 * width + (5 + 4)] = out[0*width + 9] should have the white pixel
      expect(out[0 * width + 9], equals(0xFFFFFFFF));
      expect(out[0 * width + 5], equals(0)); // Original position at top is now displaced
    });

    test('time parameter advances wind oscillation cycle', () {
      const width = 9;
      const height = 9;
      final pixels = Uint32List(width * height);
      for (int y = 0; y < height; y++) {
        pixels[y * width + 4] = 0xFFFFFFFF;
      }

      final t0 = WindSwayEffect({
        'amplitude': 3.0,
        'speed': 1.0,
        'frequency': 0.0,
        'time': 0.0,
      });
      final tHalf = WindSwayEffect({
        'amplitude': 3.0,
        'speed': 1.0,
        'frequency': 0.0,
        'time': 0.25,
      });

      final out0 = t0.apply(pixels, width, height);
      final outHalf = tHalf.apply(pixels, width, height);

      expect(out0, isNot(equals(outHalf)));
    });

    test('preserves transparent background when preserveAlpha is true', () {
      const width = 5;
      const height = 5;
      final pixels = Uint32List(width * height);
      pixels[2 * width + 2] = 0xFFFFFFFF;

      final effect = WindSwayEffect({'preserveAlpha': true});
      final out = effect.apply(pixels, width, height);

      expect(out[0], equals(0));
      expect(out[24], equals(0));
    });
  });
}
