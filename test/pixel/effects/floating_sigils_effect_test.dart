import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/fields/ui_field.dart';

void main() {
  group('FloatingSigilsEffect', () {
    test('instantiates with default parameters and isAnimation is false', () {
      final effect = FloatingSigilsEffect();
      expect(effect.type, equals(EffectType.floatingSigils));
      expect(effect.isAnimation, isFalse);
      expect(effect.parameters['sigilCount'], equals(6.0));
      expect(effect.parameters['orbitRadius'], equals(11.0));
      expect(effect.parameters['runeStyle'], equals('elderFuthark'));
      expect(effect.parameters['linkThreads'], isTrue);
      expect(effect.parameters['sigilPalette'], equals('elderGold'));
      expect(effect.parameters['behindOnly'], isFalse);
    });

    test('getFields returns strongly-typed UIField descriptors', () {
      final effect = FloatingSigilsEffect();
      final fields = effect.getFields();

      expect(fields.any((f) => f.key == 'sigilCount' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'orbitRadius' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'runeStyle' && f is SelectField), isTrue);
      expect(fields.any((f) => f.key == 'linkThreads' && f is BoolField), isTrue);
      expect(fields.any((f) => f.key == 'sigilPalette' && f is SelectField), isTrue);
      expect(fields.any((f) => f.key == 'behindOnly' && f is BoolField), isTrue);
    });

    test('EffectsManager creates and deserializes FloatingSigilsEffect', () {
      final effect = EffectsManager.createEffect(
        EffectType.floatingSigils,
        {
          'sigilCount': 4.0,
          'orbitRadius': 9.0,
          'runeStyle': 'celestialSigil',
          'sigilPalette': 'valkyrieCyan',
        },
      );
      expect(effect, isA<FloatingSigilsEffect>());
      expect(effect.parameters['sigilCount'], equals(4.0));
      expect(effect.parameters['orbitRadius'], equals(9.0));
      expect(effect.parameters['runeStyle'], equals('celestialSigil'));
      expect(effect.parameters['sigilPalette'], equals('valkyrieCyan'));
    });

    test('renders floating rune glyphs and connecting ether threads', () {
      const width = 36;
      const height = 36;
      final pixels = Uint32List(width * height);

      // Character center square (14..21, 14..21)
      for (int y = 14; y <= 21; y++) {
        for (int x = 14; x <= 21; x++) {
          pixels[y * width + x] = 0xFF444444;
        }
      }

      final effect = FloatingSigilsEffect({
        'sigilCount': 6.0,
        'orbitRadius': 12.0,
        'runeStyle': 'elderFuthark',
        'linkThreads': true,
        'sigilPalette': 'elderGold',
        'behindOnly': false,
      });

      final result = effect.apply(Uint32List.fromList(pixels), width, height);

      // Verify that outer orbit contains rune glyph pixels
      int glyphPixelCount = 0;
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final isInside = (x >= 14 && x <= 21 && y >= 14 && y <= 21);
          final resA = (result[y * width + x] >> 24) & 0xFF;
          if (!isInside && resA > 0) {
            glyphPixelCount++;
          }
        }
      }

      expect(glyphPixelCount, greaterThan(30));
    });

    test('sigilPalette variations produce distinctive cyan and crimson colors', () {
      const width = 30;
      const height = 30;
      final pixels = Uint32List(width * height);

      for (int y = 11; y <= 18; y++) {
        for (int x = 11; x <= 18; x++) {
          pixels[y * width + x] = 0xFF222222;
        }
      }

      final cyanEffect = FloatingSigilsEffect({
        'sigilPalette': 'valkyrieCyan',
      });
      final crimsonEffect = FloatingSigilsEffect({
        'sigilPalette': 'infernalCrimson',
      });

      final cyanResult = cyanEffect.apply(Uint32List.fromList(pixels), width, height);
      final crimsonResult = crimsonEffect.apply(Uint32List.fromList(pixels), width, height);

      int cyanCount = 0;
      int crimsonCount = 0;

      for (int i = 0; i < width * height; i++) {
        final cG = (cyanResult[i] >> 8) & 0xFF;
        final cB = cyanResult[i] & 0xFF;
        final cR = (cyanResult[i] >> 16) & 0xFF;
        if (cB > 200 && cG > 200 && cR < 80) cyanCount++;

        final irR = (crimsonResult[i] >> 16) & 0xFF;
        final irG = (crimsonResult[i] >> 8) & 0xFF;
        final irB = crimsonResult[i] & 0xFF;
        if (irR > 200 && irG < 70 && irB < 100) crimsonCount++;
      }

      expect(cyanCount, greaterThan(10));
      expect(crimsonCount, greaterThan(10));
    });

    test('behindOnly preserves foreground sprite pixels without overwriting', () {
      const width = 30;
      const height = 30;
      final pixels = Uint32List(width * height);

      for (int y = 10; y <= 20; y++) {
        for (int x = 10; x <= 20; x++) {
          pixels[y * width + x] = 0xFF553311;
        }
      }

      final effect = FloatingSigilsEffect({
        'sigilCount': 8.0,
        'orbitRadius': 6.0,
        'behindOnly': true,
      });

      final result = effect.apply(Uint32List.fromList(pixels), width, height);

      for (int y = 10; y <= 20; y++) {
        for (int x = 10; x <= 20; x++) {
          expect(result[y * width + x], equals(0xFF553311));
        }
      }
    });
  });
}
