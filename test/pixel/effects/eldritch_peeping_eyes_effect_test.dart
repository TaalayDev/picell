import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/fields/ui_field.dart';

void main() {
  group('EldritchPeepingEyesEffect', () {
    test('instantiates with default parameters and isAnimation is false', () {
      final effect = EldritchPeepingEyesEffect();
      expect(effect.type, equals(EffectType.eldritchPeepingEyes));
      expect(effect.isAnimation, isFalse);
      expect(effect.isPremium, isFalse);
      expect(effect.parameters['eyeCount'], equals(5));
      expect(effect.parameters['pupilType'], equals('slitCat'));
      expect(effect.parameters['eyeSize'], equals(4.5));
      expect(effect.parameters['veinGlow'], isTrue);
      expect(effect.parameters['eyePalette'], equals('crimsonCurse'));
      expect(effect.parameters['behindOnly'], isFalse);
    });

    test('getFields returns strongly-typed UIField descriptors', () {
      final effect = EldritchPeepingEyesEffect();
      final fields = effect.getFields();

      expect(fields.any((f) => f.key == 'eyeCount' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'pupilType' && f is SelectField), isTrue);
      expect(fields.any((f) => f.key == 'eyeSize' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'veinGlow' && f is BoolField), isTrue);
      expect(fields.any((f) => f.key == 'eyePalette' && f is SelectField), isTrue);
      expect(fields.any((f) => f.key == 'behindOnly' && f is BoolField), isTrue);
    });

    test('EffectsManager creates and deserializes EldritchPeepingEyesEffect', () {
      final effect = EffectsManager.createEffect(
        EffectType.eldritchPeepingEyes,
        {
          'eyeCount': 6,
          'pupilType': 'demonicCross',
          'eyePalette': 'voidWatcher',
        },
      );
      expect(effect, isA<EldritchPeepingEyesEffect>());
      expect(effect.parameters['eyeCount'], equals(6));
      expect(effect.parameters['pupilType'], equals('demonicCross'));
      expect(effect.parameters['eyePalette'], equals('voidWatcher'));
    });

    test('renders almond eye scleras, pupils, and veins around contour', () {
      const width = 36;
      const height = 36;
      final pixels = Uint32List(width * height);

      // Centered 10x10 sprite block at (13..22, 13..22)
      for (int y = 13; y <= 22; y++) {
        for (int x = 13; x <= 22; x++) {
          pixels[y * width + x] = 0xFF555555;
        }
      }

      final effect = EldritchPeepingEyesEffect({
        'eyeCount': 5,
        'pupilType': 'slitCat',
        'eyeSize': 4.5,
        'veinGlow': true,
        'eyePalette': 'crimsonCurse',
        'behindOnly': false,
      });

      final result = effect.apply(Uint32List.fromList(pixels), width, height);

      // Verify presence of peeping eye pixels outside the sprite (sclera / iris / pupil)
      int eyePixelsFound = 0;
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final idx = y * width + x;
          if (pixels[idx] == 0 && result[idx] != 0) {
            final a = (result[idx] >> 24) & 0xFF;
            if (a > 60) {
              eyePixelsFound++;
            }
          }
        }
      }

      expect(eyePixelsFound, greaterThan(25), reason: 'Eyeballs and veins should be drawn outside sprite');
    });

    test('voidWatcher palette produces violet scleras and neon purple irises', () {
      const width = 28;
      const height = 28;
      final pixels = Uint32List(width * height);

      for (int y = 10; y <= 17; y++) {
        for (int x = 10; x <= 17; x++) {
          pixels[y * width + x] = 0xFF444444;
        }
      }

      final effect = EldritchPeepingEyesEffect({
        'eyeCount': 6,
        'pupilType': 'roundVoid',
        'eyePalette': 'voidWatcher',
        'behindOnly': false,
      });

      final result = effect.apply(Uint32List.fromList(pixels), width, height);

      // Verify presence of purple / violet iris pixels (R and B high, G lower)
      bool foundPurple = false;
      for (int i = 0; i < width * height; i++) {
        if (pixels[i] == 0 && result[i] != 0) {
          final p = result[i];
          final r = (p >> 16) & 0xFF;
          final g = (p >> 8) & 0xFF;
          final b = p & 0xFF;
          if (r > 150 && b > 180 && g < 100) {
            foundPurple = true;
            break;
          }
        }
      }
      expect(foundPurple, isTrue, reason: 'voidWatcher should generate purple iris pixels');
    });

    test('behindOnly preserves foreground sprite pixels without overwriting', () {
      const width = 24;
      const height = 24;
      final pixels = Uint32List(width * height);

      const spriteColor = 0xFF552277;
      for (int y = 9; y <= 15; y++) {
        for (int x = 9; x <= 15; x++) {
          pixels[y * width + x] = spriteColor;
        }
      }

      final effect = EldritchPeepingEyesEffect({
        'eyeCount': 5,
        'behindOnly': true,
      });

      final result = effect.apply(Uint32List.fromList(pixels), width, height);

      // Foreground sprite pixels must remain untouched
      for (int y = 9; y <= 15; y++) {
        for (int x = 9; x <= 15; x++) {
          expect(result[y * width + x], equals(spriteColor));
        }
      }
    });
  });
}
