import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/fields/ui_field.dart';

void main() {
  group('ZodiacConstellationEffect', () {
    test('instantiates with default parameters and isAnimation is false', () {
      final effect = ZodiacConstellationEffect();
      expect(effect.type, equals(EffectType.zodiacConstellation));
      expect(effect.isAnimation, isFalse);
      expect(effect.isPremium, isFalse);
      expect(effect.parameters['starScale'], equals(14.0));
      expect(effect.parameters['constellationPattern'], equals('orionHunter'));
      expect(effect.parameters['crossGlints'], isTrue);
      expect(effect.parameters['dustDensity'], equals(8.0));
      expect(effect.parameters['starPalette'], equals('polarWhite'));
      expect(effect.parameters['behindOnly'], isFalse);
    });

    test('getFields returns strongly-typed UIField descriptors', () {
      final effect = ZodiacConstellationEffect();
      final fields = effect.getFields();

      expect(fields.any((f) => f.key == 'starScale' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'constellationPattern' && f is SelectField), isTrue);
      expect(fields.any((f) => f.key == 'crossGlints' && f is BoolField), isTrue);
      expect(fields.any((f) => f.key == 'dustDensity' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'starPalette' && f is SelectField), isTrue);
      expect(fields.any((f) => f.key == 'behindOnly' && f is BoolField), isTrue);
    });

    test('EffectsManager creates and deserializes ZodiacConstellationEffect', () {
      final effect = EffectsManager.createEffect(
        EffectType.zodiacConstellation,
        {
          'starScale': 16.0,
          'constellationPattern': 'cassiopeiaCrown',
          'starPalette': 'celestialGold',
        },
      );
      expect(effect, isA<ZodiacConstellationEffect>());
      expect(effect.parameters['starScale'], equals(16.0));
      expect(effect.parameters['constellationPattern'], equals('cassiopeiaCrown'));
      expect(effect.parameters['starPalette'], equals('celestialGold'));
    });

    test('renders constellation star vertices, asterism chords, and cross glints', () {
      const width = 36;
      const height = 36;
      final pixels = Uint32List(width * height);

      // 8x8 character square at center (14..21, 14..21)
      for (int y = 14; y <= 21; y++) {
        for (int x = 14; x <= 21; x++) {
          pixels[y * width + x] = 0xFF555555;
        }
      }

      final effect = ZodiacConstellationEffect({
        'starScale': 14.0,
        'constellationPattern': 'orionHunter',
        'crossGlints': true,
        'dustDensity': 10.0,
        'starPalette': 'polarWhite',
        'behindOnly': false,
      });

      final result = effect.apply(Uint32List.fromList(pixels), width, height);

      int starPixelCount = 0;
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final isInside = (x >= 14 && x <= 21 && y >= 14 && y <= 21);
          final resA = (result[y * width + x] >> 24) & 0xFF;
          if (!isInside && resA > 0) {
            starPixelCount++;
          }
        }
      }

      expect(starPixelCount, greaterThan(35));
    });

    test('starPalette variations produce distinctive white and azure colors', () {
      const width = 30;
      const height = 30;
      final pixels = Uint32List(width * height);

      for (int y = 11; y <= 18; y++) {
        for (int x = 11; x <= 18; x++) {
          pixels[y * width + x] = 0xFF111111;
        }
      }

      final whiteEffect = ZodiacConstellationEffect({
        'starPalette': 'polarWhite',
        'dustDensity': 0.0,
      });
      final azureEffect = ZodiacConstellationEffect({
        'starPalette': 'nebulaAzure',
        'dustDensity': 0.0,
      });

      final whiteResult = whiteEffect.apply(Uint32List.fromList(pixels), width, height);
      final azureResult = azureEffect.apply(Uint32List.fromList(pixels), width, height);

      int whiteSilverCount = 0;
      int azureCoolCount = 0;

      for (int i = 0; i < width * height; i++) {
        final wR = (whiteResult[i] >> 16) & 0xFF;
        final wG = (whiteResult[i] >> 8) & 0xFF;
        final wB = whiteResult[i] & 0xFF;
        if (wR > 180 && wG > 180 && wB > 180) whiteSilverCount++;

        final aR = (azureResult[i] >> 16) & 0xFF;
        final aG = (azureResult[i] >> 8) & 0xFF;
        final aB = azureResult[i] & 0xFF;
        if (aB > 200 && aG > 140 && aR < 180) azureCoolCount++;
      }

      expect(whiteSilverCount, greaterThan(5));
      expect(azureCoolCount, greaterThan(5));
    });

    test('behindOnly preserves foreground sprite pixels without overwriting', () {
      const width = 30;
      const height = 30;
      final pixels = Uint32List(width * height);

      for (int y = 10; y <= 20; y++) {
        for (int x = 10; x <= 20; x++) {
          pixels[y * width + x] = 0xFF884422;
        }
      }

      final effect = ZodiacConstellationEffect({
        'starScale': 8.0,
        'behindOnly': true,
      });

      final result = effect.apply(Uint32List.fromList(pixels), width, height);

      for (int y = 10; y <= 20; y++) {
        for (int x = 10; x <= 20; x++) {
          expect(result[y * width + x], equals(0xFF884422));
        }
      }
    });
  });
}
