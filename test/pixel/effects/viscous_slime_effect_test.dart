import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/fields/ui_field.dart';

void main() {
  group('ViscousSlimeEffect', () {
    test('instantiates with default parameters and isAnimation is false', () {
      final effect = ViscousSlimeEffect();
      expect(effect.type, equals(EffectType.viscousSlime));
      expect(effect.isAnimation, isFalse);
      expect(effect.isPremium, isFalse);
      expect(effect.parameters['slimeViscosity'], equals(0.6));
      expect(effect.parameters['dripFrequency'], equals(0.5));
      expect(effect.parameters['slimeHeight'], equals(3.5));
      expect(effect.parameters['slimePalette'], equals('toxicLime'));
      expect(effect.parameters['specularGloss'], equals(0.75));
      expect(effect.parameters['hangDripLength'], equals(8.0));
    });

    test('getFields returns strongly-typed UIField descriptors', () {
      final effect = ViscousSlimeEffect();
      final fields = effect.getFields();

      expect(fields.any((f) => f.key == 'slimeViscosity' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'dripFrequency' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'slimeHeight' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'slimePalette' && f is SelectField), isTrue);
      expect(fields.any((f) => f.key == 'specularGloss' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'hangDripLength' && f is SliderField), isTrue);
    });

    test('EffectsManager creates and deserializes ViscousSlimeEffect', () {
      final effect = EffectsManager.createEffect(
        EffectType.viscousSlime,
        {
          'slimeViscosity': 0.8,
          'slimePalette': 'eldritchPurple',
          'hangDripLength': 12.0,
        },
      );
      expect(effect, isA<ViscousSlimeEffect>());
      expect(effect.parameters['slimeViscosity'], equals(0.8));
      expect(effect.parameters['slimePalette'], equals('eldritchPurple'));
      expect(effect.parameters['hangDripLength'], equals(12.0));
    });

    test('coats top surface of sprite with convex fluid slime cap', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      // Block at (10..22, 14..22)
      for (int y = 14; y <= 22; y++) {
        for (int x = 10; x <= 22; x++) {
          pixels[y * width + x] = 0xFF444444;
        }
      }

      final effect = ViscousSlimeEffect({
        'slimeHeight': 4.0,
        'dripFrequency': 0.0, // test top slime cap independently
      });

      final result = effect.apply(Uint32List.fromList(pixels), width, height);

      // Slime cap should rise above top surface (y in 10..13, x in 10..22)
      bool foundSlimeCap = false;
      for (int y = 10; y < 14; y++) {
        for (int x = 10; x <= 22; x++) {
          final p = result[y * width + x];
          if (((p >> 24) & 0xFF) > 0) {
            foundSlimeCap = true;
            break;
          }
        }
        if (foundSlimeCap) break;
      }
      expect(foundSlimeCap, isTrue, reason: 'Viscous slime cap should form above top-facing surface');
    });

    test('stretches downward dripping slime teardrops from bottom overhangs', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      // Ledge at y in 8..12, x in 6..26
      for (int y = 8; y <= 12; y++) {
        for (int x = 6; x <= 26; x++) {
          pixels[y * width + x] = 0xFF555555;
        }
      }

      final effect = ViscousSlimeEffect({
        'slimeHeight': 1.5,
        'dripFrequency': 1.0, // high frequency to ensure drips emerge
        'hangDripLength': 10.0,
      });

      final result = effect.apply(Uint32List.fromList(pixels), width, height);

      // Below the ledge (y in 13..22, x in 6..26) slime strands should drip downward
      bool foundDripStrands = false;
      for (int y = 13; y <= 22; y++) {
        for (int x = 6; x <= 26; x++) {
          final p = result[y * width + x];
          if (((p >> 24) & 0xFF) > 0) {
            foundDripStrands = true;
            break;
          }
        }
        if (foundDripStrands) break;
      }
      expect(foundDripStrands, isTrue, reason: 'Slime teardrops should stretch and drip downward from overhangs');
    });

    test('eldritchPurple palette applies purple and orchid ooze coloration', () {
      const width = 24;
      const height = 24;
      final pixels = Uint32List(width * height);

      // Small 4x4 block at (10..13, 10..13)
      for (int y = 10; y <= 13; y++) {
        for (int x = 10; x <= 13; x++) {
          pixels[y * width + x] = 0xFF222222;
        }
      }

      final effect = ViscousSlimeEffect({
        'slimeHeight': 3.0,
        'slimePalette': 'eldritchPurple',
        'specularGloss': 0.0,
      });

      final result = effect.apply(Uint32List.fromList(pixels), width, height);

      // In eldritchPurple, Red and Blue are both strong (purple/orchid) while Green is low
      bool foundEldritchPurple = false;
      for (int y = 7; y < 10; y++) {
        for (int x = 10; x <= 13; x++) {
          final p = result[y * width + x];
          final a = (p >> 24) & 0xFF;
          if (a > 100) {
            final r = (p >> 16) & 0xFF;
            final g = (p >> 8) & 0xFF;
            final b = p & 0xFF;
            if (r > 120 && b > 180 && g < 120) {
              foundEldritchPurple = true;
              break;
            }
          }
        }
        if (foundEldritchPurple) break;
      }
      expect(foundEldritchPurple, isTrue, reason: 'eldritchPurple palette should produce bright purple/orchid ooze');
    });
  });
}
