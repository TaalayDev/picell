import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/fields/ui_field.dart';

void main() {
  group('LostSoulWispsEffect', () {
    test('instantiates with default parameters and isAnimation is false', () {
      final effect = LostSoulWispsEffect();
      expect(effect.type, equals(EffectType.lostSoulWisps));
      expect(effect.isAnimation, isFalse);
      expect(effect.parameters['soulCount'], equals(4));
      expect(effect.parameters['wispDistance'], equals(9.0));
      expect(effect.parameters['tailLength'], equals(6.0));
      expect(effect.parameters['spectralPalette'], equals('ghastlyCyan'));
      expect(effect.parameters['eyeGlow'], isTrue);
      expect(effect.parameters['behindOnly'], isFalse);
    });

    test('getFields returns strongly-typed UIField descriptors', () {
      final effect = LostSoulWispsEffect();
      final fields = effect.getFields();

      expect(fields.any((f) => f.key == 'soulCount' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'wispDistance' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'tailLength' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'spectralPalette' && f is SelectField), isTrue);
      expect(fields.any((f) => f.key == 'eyeGlow' && f is BoolField), isTrue);
      expect(fields.any((f) => f.key == 'behindOnly' && f is BoolField), isTrue);
    });

    test('EffectsManager creates and deserializes LostSoulWispsEffect', () {
      final effect = EffectsManager.createEffect(
        EffectType.lostSoulWisps,
        {
          'soulCount': 5,
          'wispDistance': 12.0,
          'spectralPalette': 'bansheeGreen',
        },
      );
      expect(effect, isA<LostSoulWispsEffect>());
      expect(effect.parameters['soulCount'], equals(5));
      expect(effect.parameters['wispDistance'], equals(12.0));
      expect(effect.parameters['spectralPalette'], equals('bansheeGreen'));
    });

    test('renders floating skull heads and vapor tails orbiting upper body', () {
      const width = 36;
      const height = 36;
      final pixels = Uint32List(width * height);

      // Centered character block at (14..21, 10..22)
      for (int y = 10; y <= 22; y++) {
        for (int x = 14; x <= 21; x++) {
          pixels[y * width + x] = 0xFF555555;
        }
      }

      final effect = LostSoulWispsEffect({
        'soulCount': 4,
        'wispDistance': 9.0,
        'tailLength': 6.0,
        'spectralPalette': 'ghastlyCyan',
        'eyeGlow': true,
        'behindOnly': false,
      });

      final result = effect.apply(Uint32List.fromList(pixels), width, height);

      // Verify that spectral soul pixels are drawn around the head/crown outside the sprite
      int soulPixelsFound = 0;
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final idx = y * width + x;
          if (pixels[idx] == 0 && result[idx] != 0) {
            final a = (result[idx] >> 24) & 0xFF;
            if (a > 60) {
              soulPixelsFound++;
            }
          }
        }
      }

      expect(soulPixelsFound, greaterThan(20), reason: 'Spectral souls and tails should be drawn in orbit');
    });

    test('bansheeGreen palette produces emerald and lime ectoplasm colors', () {
      const width = 28;
      const height = 28;
      final pixels = Uint32List(width * height);

      for (int y = 8; y <= 16; y++) {
        for (int x = 11; x <= 16; x++) {
          pixels[y * width + x] = 0xFF333333;
        }
      }

      final effect = LostSoulWispsEffect({
        'soulCount': 4,
        'wispDistance': 8.0,
        'spectralPalette': 'bansheeGreen',
        'behindOnly': false,
      });

      final result = effect.apply(Uint32List.fromList(pixels), width, height);

      // Verify presence of lime/emerald ectoplasm (G high, R and B lower)
      bool foundEmerald = false;
      for (int i = 0; i < width * height; i++) {
        if (pixels[i] == 0 && result[i] != 0) {
          final p = result[i];
          final r = (p >> 16) & 0xFF;
          final g = (p >> 8) & 0xFF;
          final b = p & 0xFF;
          if (g > 180 && r < 120 && b < 120) {
            foundEmerald = true;
            break;
          }
        }
      }
      expect(foundEmerald, isTrue, reason: 'bansheeGreen should generate green ectoplasm pixels');
    });

    test('behindOnly preserves foreground sprite pixels without overwriting', () {
      const width = 24;
      const height = 24;
      final pixels = Uint32List(width * height);

      const spriteColor = 0xFF114488;
      for (int y = 8; y <= 16; y++) {
        for (int x = 9; x <= 14; x++) {
          pixels[y * width + x] = spriteColor;
        }
      }

      final effect = LostSoulWispsEffect({
        'soulCount': 4,
        'wispDistance': 6.0,
        'behindOnly': true,
      });

      final result = effect.apply(Uint32List.fromList(pixels), width, height);

      // Foreground sprite pixels must remain untouched
      for (int y = 8; y <= 16; y++) {
        for (int x = 9; x <= 14; x++) {
          expect(result[y * width + x], equals(spriteColor));
        }
      }
    });
  });
}
