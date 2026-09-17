import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/fields/ui_field.dart';

void main() {
  group('SquashStretchEffect', () {
    test('instantiates with default parameters and isAnimation is true', () {
      final effect = SquashStretchEffect();
      expect(effect.type, equals(EffectType.squashStretch));
      expect(effect.isAnimation, isTrue);
      expect(effect.parameters['amount'], equals(0.2));
      expect(effect.parameters['frequency'], equals(1.0));
      expect(effect.parameters['anchor'], equals('bottom'));
      expect(effect.parameters['preserveAlpha'], isTrue);

      final defaults = effect.getDefaultParameters();
      expect(defaults['amount'], equals(0.2));

      final metadata = effect.getMetadata();
      expect(metadata.containsKey('amount'), isTrue);
      expect(metadata.containsKey('frequency'), isTrue);
      expect(metadata.containsKey('anchor'), isTrue);
    });

    test('getFields returns strongly-typed UIField descriptors', () {
      final effect = SquashStretchEffect();
      final fields = effect.getFields();

      expect(fields.length, equals(6));
      final keys = fields.map((f) => f.key).toList();
      expect(keys, containsAll([
        'amount',
        'frequency',
        'phase',
        'anchor',
        'time',
        'preserveAlpha',
      ]));

      final anchorField = fields.firstWhere((f) => f.key == 'anchor') as SelectField;
      expect(anchorField.options.containsKey('bottom'), isTrue);
      expect(anchorField.options.containsKey('center'), isTrue);
      expect(anchorField.options.containsKey('top'), isTrue);
    });

    test('EffectsManager creates and deserializes SquashStretchEffect', () {
      final effect = EffectsManager.createEffect(EffectType.squashStretch, {
        'amount': 0.3,
      });
      expect(effect, isA<SquashStretchEffect>());
      expect(effect.parameters['amount'], equals(0.3));

      final fromJson = EffectsManager.effectFromJson({
        'type': 'squashStretch',
        'parameters': {'amount': 0.4},
      });
      expect(fromJson, isA<SquashStretchEffect>());
      expect(fromJson?.parameters['amount'], equals(0.4));
    });

    test('bottom anchor keeps base row stationary while deforming upper rows', () {
      const width = 5;
      const height = 5;
      final pixels = Uint32List(width * height);
      // Fill bottom row with solid white
      for (int x = 0; x < width; x++) {
        pixels[4 * width + x] = 0xFFFFFFFF;
      }
      // Fill top row with solid white
      for (int x = 0; x < width; x++) {
        pixels[0 * width + x] = 0xFFFFFFFF;
      }

      // Stretch: phase = 0.25 (sin(pi/2) = 1.0 -> sy = 1.0 + 0.3 = 1.3)
      final effect = SquashStretchEffect({
        'amount': 0.3,
        'frequency': 1.0,
        'phase': 0.25,
        'anchor': 'bottom',
        'time': 0.0,
        'preserveAlpha': true,
      });

      final out = effect.apply(pixels, width, height);

      // Bottom anchor row (y = 4) remains solid white
      expect(out[4 * width + 2], equals(0xFFFFFFFF));
    });

    test('time parameter advances squash/stretch oscillation cycle', () {
      const width = 5;
      const height = 5;
      final pixels = Uint32List(width * height);
      pixels[0 * width + 2] = 0xFFFFFFFF;
      pixels[4 * width + 2] = 0xFFFFFFFF;

      final t0 = SquashStretchEffect({
        'amount': 0.4,
        'frequency': 1.0,
        'time': 0.0, // sin(0) = 0 -> no deformation
      });
      final tQuarter = SquashStretchEffect({
        'amount': 0.4,
        'frequency': 1.0,
        'time': 0.25, // sin(pi/2) = 1.0 -> max deformation
      });

      final out0 = t0.apply(pixels, width, height);
      final outQuarter = tQuarter.apply(pixels, width, height);

      expect(out0[0 * width + 2], equals(0xFFFFFFFF));
      expect(out0[4 * width + 2], equals(0xFFFFFFFF));
      expect(outQuarter, isNot(equals(out0)));
    });

    test('preserves transparent background when preserveAlpha is true', () {
      const width = 3;
      const height = 3;
      final pixels = Uint32List(width * height);
      pixels[1 * width + 1] = 0xFFFFFFFF;

      final effect = SquashStretchEffect({'preserveAlpha': true});
      final out = effect.apply(pixels, width, height);

      expect(out[0], equals(0));
      expect(out[8], equals(0));
    });
  });
}
