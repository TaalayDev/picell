import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/fields/ui_field.dart';

void main() {
  group('HitFlashEffect', () {
    test('instantiates with default parameters and isAnimation is true', () {
      final effect = HitFlashEffect();
      expect(effect.type, equals(EffectType.hitFlash));
      expect(effect.isAnimation, isTrue);
      expect(effect.parameters['mode'], equals('flashDecay'));
      expect(effect.parameters['flashColor'], equals(0xFFFFFFFF));
      expect(effect.parameters['intensity'], equals(1.0));
      expect(effect.parameters['blinkCount'], equals(4));
      expect(effect.parameters['preserveAlpha'], isTrue);

      final defaults = effect.getDefaultParameters();
      expect(defaults['mode'], equals('flashDecay'));

      final metadata = effect.getMetadata();
      expect(metadata.containsKey('mode'), isTrue);
      expect(metadata.containsKey('flashColor'), isTrue);
      expect(metadata.containsKey('intensity'), isTrue);
      expect(metadata.containsKey('blinkCount'), isTrue);
    });

    test('getFields returns strongly-typed UIField descriptors', () {
      final effect = HitFlashEffect();
      final fields = effect.getFields();

      expect(fields.length, equals(6));
      final keys = fields.map((f) => f.key).toList();
      expect(keys, containsAll([
        'mode',
        'flashColor',
        'intensity',
        'blinkCount',
        'time',
        'preserveAlpha',
      ]));

      final modeField = fields.firstWhere((f) => f.key == 'mode') as SelectField;
      expect(modeField.options.containsKey('flashDecay'), isTrue);
      expect(modeField.options.containsKey('blink'), isTrue);
      expect(modeField.options.containsKey('flashAndBlink'), isTrue);

      final colorField = fields.firstWhere((f) => f.key == 'flashColor');
      expect(colorField, isA<ColorField>());
    });

    test('EffectsManager creates and deserializes HitFlashEffect', () {
      final effect = EffectsManager.createEffect(EffectType.hitFlash, {
        'flashColor': 0xFFFF0000,
      });
      expect(effect, isA<HitFlashEffect>());
      expect(effect.parameters['flashColor'], equals(0xFFFF0000));

      final fromJson = EffectsManager.effectFromJson({
        'type': 'hitFlash',
        'parameters': {'flashColor': 0xFF00FF00},
      });
      expect(fromJson, isA<HitFlashEffect>());
      expect(fromJson?.parameters['flashColor'], equals(0xFF00FF00));
    });

    test('flashDecay mode flashes pure white at time=0.0 and decays to original at time=1.0', () {
      const width = 1;
      const height = 1;
      // Blue pixel: 0xFF0000FF
      final pixels = Uint32List.fromList([0xFF0000FF]);

      final effectAt0 = HitFlashEffect({
        'mode': 'flashDecay',
        'flashColor': 0xFFFFFFFF,
        'intensity': 1.0,
        'time': 0.0,
        'preserveAlpha': true,
      });
      final effectAt1 = HitFlashEffect({
        'mode': 'flashDecay',
        'flashColor': 0xFFFFFFFF,
        'intensity': 1.0,
        'time': 1.0,
        'preserveAlpha': true,
      });

      final out0 = effectAt0.apply(pixels, width, height);
      final out1 = effectAt1.apply(pixels, width, height);

      // At time = 0.0: solid white flash (0xFFFFFFFF)
      expect(out0[0], equals(0xFFFFFFFF));

      // At time = 1.0: decayed back to original blue (0xFF0000FF or almost pure blue)
      final r1 = (out1[0] >> 16) & 0xFF;
      final b1 = out1[0] & 0xFF;
      expect(r1, lessThan(10));
      expect(b1, greaterThan(245));
    });

    test('blink mode toggles visibility across cycles', () {
      const width = 1;
      const height = 1;
      final pixels = Uint32List.fromList([0xFF0000FF]);

      // blinkCount = 2 -> cycle = (time * 2) % 1.0
      // at time = 0.1 -> cycle = 0.2 < 0.55 -> visible
      // at time = 0.35 -> cycle = 0.7 >= 0.55 -> invisible
      final effectVisible = HitFlashEffect({
        'mode': 'blink',
        'blinkCount': 2,
        'time': 0.1,
      });
      final effectHidden = HitFlashEffect({
        'mode': 'blink',
        'blinkCount': 2,
        'time': 0.35,
      });

      final outVisible = effectVisible.apply(pixels, width, height);
      final outHidden = effectHidden.apply(pixels, width, height);

      expect((outVisible[0] >> 24) & 0xFF, equals(255));
      expect((outHidden[0] >> 24) & 0xFF, equals(0));
    });

    test('preserves transparent background when preserveAlpha is true', () {
      const width = 2;
      const height = 1;
      final pixels = Uint32List.fromList([0x00000000, 0xFF0000FF]);

      final effect = HitFlashEffect({'preserveAlpha': true});
      final out = effect.apply(pixels, width, height);

      expect(out[0], equals(0));
      expect((out[1] >> 24) & 0xFF, equals(255));
    });
  });
}
