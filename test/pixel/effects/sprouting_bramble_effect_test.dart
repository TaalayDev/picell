import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/fields/ui_field.dart';

void main() {
  group('SproutingBrambleEffect', () {
    test('instantiates with default parameters and isAnimation is false', () {
      final effect = SproutingBrambleEffect();
      expect(effect.type, equals(EffectType.sproutingBramble));
      expect(effect.isAnimation, isFalse);
      expect(effect.isPremium, isFalse);
      expect(effect.parameters['growthSpread'], equals(10.0));
      expect(effect.parameters['brambleHeight'], equals(5.0));
      expect(effect.parameters['flowerDensity'], equals(0.6));
      expect(effect.parameters['naturePalette'], equals('enchantedMeadow'));
      expect(effect.parameters['behindOnly'], isFalse);
    });

    test('getFields returns strongly-typed UIField descriptors', () {
      final effect = SproutingBrambleEffect();
      final fields = effect.getFields();

      expect(fields.any((f) => f.key == 'growthSpread' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'brambleHeight' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'flowerDensity' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'naturePalette' && f is SelectField), isTrue);
      expect(fields.any((f) => f.key == 'behindOnly' && f is BoolField), isTrue);
    });

    test('EffectsManager creates and deserializes SproutingBrambleEffect', () {
      final effect = EffectsManager.createEffect(
        EffectType.sproutingBramble,
        {
          'growthSpread': 14.0,
          'naturePalette': 'autumnFoliage',
          'brambleHeight': 7.0,
        },
      );
      expect(effect, isA<SproutingBrambleEffect>());
      expect(effect.parameters['growthSpread'], equals(14.0));
      expect(effect.parameters['naturePalette'], equals('autumnFoliage'));
      expect(effect.parameters['brambleHeight'], equals(7.0));
    });

    test('renders creeping ground moss, vines, and flower blooms along baseline', () {
      const width = 36;
      const height = 36;
      final pixels = Uint32List(width * height);

      // Centered 8x8 character at (14..21, 10..17)
      for (int y = 10; y <= 17; y++) {
        for (int x = 14; x <= 21; x++) {
          pixels[y * width + x] = 0xFF555555;
        }
      }

      final effect = SproutingBrambleEffect({
        'growthSpread': 10.0,
        'brambleHeight': 6.0,
        'flowerDensity': 0.8,
        'naturePalette': 'enchantedMeadow',
        'behindOnly': false,
      });

      final result = effect.apply(Uint32List.fromList(pixels), width, height);

      // Verify that moss mats and vines spread laterally beyond feet (x < 14 or x > 21)
      bool foundFloraOutside = false;
      for (int y = 12; y <= 18; y++) {
        for (int x = 5; x < 14; x++) {
          final idx = y * width + x;
          if (pixels[idx] == 0 && result[idx] != 0) {
            foundFloraOutside = true;
            break;
          }
        }
        if (foundFloraOutside) break;
      }
      expect(foundFloraOutside, isTrue, reason: 'Creeping vines and moss should spread laterally');
    });

    test('autumnFoliage palette produces warm crimson, amber, and gold leaf pixels', () {
      const width = 28;
      const height = 28;
      final pixels = Uint32List(width * height);

      for (int y = 8; y <= 14; y++) {
        for (int x = 11; x <= 16; x++) {
          pixels[y * width + x] = 0xFF333333;
        }
      }

      final effect = SproutingBrambleEffect({
        'growthSpread': 8.0,
        'brambleHeight': 5.0,
        'flowerDensity': 0.8,
        'naturePalette': 'autumnFoliage',
        'behindOnly': false,
      });

      final result = effect.apply(Uint32List.fromList(pixels), width, height);

      // Verify presence of warm autumn leaf / amber / crimson pixels (R high, B low)
      bool foundAutumn = false;
      for (int i = 0; i < width * height; i++) {
        if (pixels[i] == 0 && result[i] != 0) {
          final p = result[i];
          final r = (p >> 16) & 0xFF;
          final b = p & 0xFF;
          if (r > 160 && b < 100) {
            foundAutumn = true;
            break;
          }
        }
      }
      expect(foundAutumn, isTrue, reason: 'autumnFoliage should produce crimson/amber leaf pixels');
    });

    test('behindOnly preserves foreground sprite pixels without overwriting', () {
      const width = 24;
      const height = 24;
      final pixels = Uint32List(width * height);

      const spriteColor = 0xFF116633;
      for (int y = 8; y <= 14; y++) {
        for (int x = 9; x <= 14; x++) {
          pixels[y * width + x] = spriteColor;
        }
      }

      final effect = SproutingBrambleEffect({
        'growthSpread': 6.0,
        'brambleHeight': 4.0,
        'behindOnly': true,
      });

      final result = effect.apply(Uint32List.fromList(pixels), width, height);

      // Foreground sprite pixels must remain untouched
      for (int y = 8; y <= 14; y++) {
        for (int x = 9; x <= 14; x++) {
          expect(result[y * width + x], equals(spriteColor));
        }
      }
    });
  });
}
