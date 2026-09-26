import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/fields/ui_field.dart';

void main() {
  group('BanyanMangroveEffect', () {
    test('instantiates with default parameters and isAnimation is true', () {
      final effect = BanyanMangroveEffect();
      expect(effect.type, equals(EffectType.banyanMangrove));
      expect(effect.isAnimation, isTrue);
      expect(effect.isPremium, isFalse);
      expect(effect.parameters['rootDensity'], equals(8));
      expect(effect.parameters['tangleTwist'], equals(0.45));
      expect(effect.parameters['waterlineTideMark'], equals(0.65));
      expect(effect.parameters['mossDrapeLength'], equals(0.5));
      expect(effect.parameters['barkShade'], equals('cypressGrey'));
      expect(effect.parameters['time'], equals(0.0));
      expect(effect.parameters['preserveAlpha'], isFalse);
    });

    test('getFields returns strongly-typed UIField descriptors', () {
      final effect = BanyanMangroveEffect();
      final fields = effect.getFields();

      expect(fields.any((f) => f.key == 'rootDensity' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'tangleTwist' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'waterlineTideMark' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'mossDrapeLength' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'barkShade' && f is SelectField), isTrue);
      expect(fields.any((f) => f.key == 'time' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'preserveAlpha' && f is BoolField), isTrue);
    });

    test('EffectsManager creates and deserializes BanyanMangroveEffect', () {
      final effect = EffectsManager.createEffect(
        EffectType.banyanMangrove,
        {
          'rootDensity': 10,
          'barkShade': 'mangroveRed',
          'waterlineTideMark': 0.55,
        },
      );
      expect(effect, isA<BanyanMangroveEffect>());
      expect(effect.parameters['rootDensity'], equals(10));
      expect(effect.parameters['barkShade'], equals('mangroveRed'));
      expect(effect.parameters['waterlineTideMark'], equals(0.55));
    });

    test('renders aerial root pillars and Spanish moss on canvas', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      // Deep bayou background
      for (int i = 0; i < pixels.length; i++) {
        pixels[i] = 0xFF141A18;
      }

      final effect = BanyanMangroveEffect({
        'rootDensity': 8,
        'waterlineTideMark': 0.65,
        'preserveAlpha': false,
      });

      final out = effect.apply(pixels, width, height);

      int changedPixels = 0;
      for (int i = 0; i < pixels.length; i++) {
        if (out[i] != 0xFF141A18) changedPixels++;
      }
      expect(changedPixels, greaterThan(0));
    });

    test('time animation sways hanging moss fronds and ripples waterline', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);
      for (int i = 0; i < pixels.length; i++) {
        pixels[i] = 0xFF101412;
      }

      final effectT0 = BanyanMangroveEffect({'time': 0.0, 'preserveAlpha': false});
      final effectT1 = BanyanMangroveEffect({'time': 0.5, 'preserveAlpha': false});

      final out0 = effectT0.apply(pixels, width, height);
      final out1 = effectT1.apply(pixels, width, height);

      int diffCount = 0;
      for (int i = 0; i < pixels.length; i++) {
        if (out0[i] != out1[i]) diffCount++;
      }
      expect(diffCount, greaterThan(0));
    });

    test('preserveAlpha restricts roots and moss to sprite silhouette', () {
      const width = 24;
      const height = 24;
      final pixels = Uint32List(width * height);

      // Central tree trunk
      for (int y = 0; y < height; y++) {
        for (int x = 6; x < 18; x++) {
          pixels[y * width + x] = 0xFF3E2723;
        }
      }

      final effect = BanyanMangroveEffect({
        'preserveAlpha': true,
      });

      final out = effect.apply(pixels, width, height);

      expect(out[0], equals(0));
      expect(out[12 * width + 12], isNot(equals(0)));
    });
  });
}
