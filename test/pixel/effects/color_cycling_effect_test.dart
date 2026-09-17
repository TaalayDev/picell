import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/fields/ui_field.dart';

void main() {
  group('ColorCyclingEffect', () {
    test('instantiates with default parameters and isAnimation is true', () {
      final effect = ColorCyclingEffect();
      expect(effect.type, equals(EffectType.colorCycling));
      expect(effect.isAnimation, isTrue);
      expect(effect.parameters['mode'], equals('hueCycle'));
      expect(effect.parameters['speed'], equals(1.0));
      expect(effect.parameters['phase'], equals(0.0));
      expect(effect.parameters['time'], equals(0.0));
      expect(effect.parameters['preserveAlpha'], isTrue);

      final defaults = effect.getDefaultParameters();
      expect(defaults['mode'], equals('hueCycle'));

      final metadata = effect.getMetadata();
      expect(metadata.containsKey('mode'), isTrue);
      expect(metadata.containsKey('speed'), isTrue);
      expect(metadata.containsKey('phase'), isTrue);
      expect(metadata.containsKey('time'), isTrue);
    });

    test('getFields returns strongly-typed UIField descriptors', () {
      final effect = ColorCyclingEffect();
      final fields = effect.getFields();

      expect(fields.length, equals(5));
      final keys = fields.map((f) => f.key).toList();
      expect(keys, containsAll([
        'mode',
        'speed',
        'phase',
        'time',
        'preserveAlpha',
      ]));

      final modeField = fields.firstWhere((f) => f.key == 'mode') as SelectField;
      expect(modeField.options.containsKey('hueCycle'), isTrue);
      expect(modeField.options.containsKey('waterfall'), isTrue);
      expect(modeField.options.containsKey('fireLava'), isTrue);
      expect(modeField.options.containsKey('neonPulse'), isTrue);

      final speedField = fields.firstWhere((f) => f.key == 'speed') as SliderField;
      expect(speedField.min, equals(0.1));
      expect(speedField.max, equals(4.0));
    });

    test('EffectsManager creates and deserializes ColorCyclingEffect', () {
      final effect = EffectsManager.createEffect(EffectType.colorCycling, {
        'phase': 0.5,
      });
      expect(effect, isA<ColorCyclingEffect>());
      expect(effect.parameters['phase'], equals(0.5));

      final fromJson = EffectsManager.effectFromJson({
        'type': 'colorCycling',
        'parameters': {'phase': 0.75},
      });
      expect(fromJson, isA<ColorCyclingEffect>());
      expect(fromJson?.parameters['phase'], equals(0.75));
    });

    test('hueCycle mode rotates color wheel with phase offset', () {
      const width = 1;
      const height = 1;
      // Pure red: 0xFFFF0000 (Hue = 0°)
      final pixels = Uint32List.fromList([0xFFFF0000]);

      // Phase = 0.333 (1/3 rotation = 120° = Pure Green)
      final effect120 = ColorCyclingEffect({
        'mode': 'hueCycle',
        'speed': 1.0,
        'phase': 1.0 / 3.0,
        'time': 0.0,
        'preserveAlpha': true,
      });

      final out120 = effect120.apply(pixels, width, height);
      final r120 = (out120[0] >> 16) & 0xFF;
      final g120 = (out120[0] >> 8) & 0xFF;
      final b120 = out120[0] & 0xFF;

      // At 120 degrees, Green is dominant
      expect(g120, greaterThan(200));
      expect(r120, lessThan(50));
      expect(b120, lessThan(50));
    });

    test('time parameter advances cycle similarly to phase for animation frames', () {
      const width = 1;
      const height = 1;
      final pixels = Uint32List.fromList([0xFFFF0000]);

      final withPhase = ColorCyclingEffect({
        'mode': 'hueCycle',
        'speed': 1.0,
        'phase': 0.5,
        'time': 0.0,
      });
      final withTime = ColorCyclingEffect({
        'mode': 'hueCycle',
        'speed': 1.0,
        'phase': 0.0,
        'time': 0.5,
      });

      final outPhase = withPhase.apply(pixels, width, height);
      final outTime = withTime.apply(pixels, width, height);

      expect(outPhase[0], equals(outTime[0]));
    });

    test('preserves transparent background when preserveAlpha is true', () {
      const width = 2;
      const height = 1;
      final pixels = Uint32List.fromList([0x00000000, 0xFFFF0000]);

      final effect = ColorCyclingEffect({'preserveAlpha': true});
      final out = effect.apply(pixels, width, height);

      expect(out[0], equals(0));
      expect((out[1] >> 24) & 0xFF, equals(255));
    });
  });
}
