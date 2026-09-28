import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/fields/ui_field.dart';

void main() {
  group('WoodblockUkiyoeEffect', () {
    test('instantiates with default parameters and isAnimation is false', () {
      final effect = WoodblockUkiyoeEffect();
      expect(effect.type, equals(EffectType.woodblockUkiyoe));
      expect(effect.isAnimation, isFalse);
      expect(effect.parameters['keylineThickness'], equals(1.2));
      expect(effect.parameters['bokashiFade'], equals(0.5));
      expect(effect.parameters['paperGrainIntensity'], equals(0.35));
      expect(effect.parameters['pigmentPalette'], equals('traditionalEdo'));
      expect(effect.parameters['woodcutRelief'], equals(0.4));
      expect(effect.parameters['preserveAlpha'], isFalse);
    });

    test('getFields returns strongly-typed UIField descriptors', () {
      final effect = WoodblockUkiyoeEffect();
      final fields = effect.getFields();

      expect(fields.any((f) => f.key == 'keylineThickness' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'bokashiFade' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'paperGrainIntensity' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'pigmentPalette' && f is SelectField), isTrue);
      expect(fields.any((f) => f.key == 'woodcutRelief' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'preserveAlpha' && f is BoolField), isTrue);
    });

    test('EffectsManager creates and deserializes WoodblockUkiyoeEffect', () {
      final effect = EffectsManager.createEffect(
        EffectType.woodblockUkiyoe,
        {
          'keylineThickness': 1.8,
          'pigmentPalette': 'greatWaveIndigo',
        },
      );
      expect(effect, isA<WoodblockUkiyoeEffect>());
      expect(effect.parameters['keylineThickness'], equals(1.8));
      expect(effect.parameters['pigmentPalette'], equals('greatWaveIndigo'));
    });

    test('renders woodblock print keylines and pigment blocks on canvas', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      // Create high-contrast shapes
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          if (x < 16) {
            pixels[y * width + x] = 0xFF2196F3; // Blue
          } else {
            pixels[y * width + x] = 0xFFFF5722; // Orange
          }
        }
      }

      final effect = WoodblockUkiyoeEffect({
        'keylineThickness': 1.2,
        'preserveAlpha': false,
      });

      final out = effect.apply(pixels, width, height);

      int nonZeroPixels = 0;
      for (int i = 0; i < pixels.length; i++) {
        if (out[i] != 0) nonZeroPixels++;
      }
      expect(nonZeroPixels, equals(width * height));
    });

    test('different pigmentPalette options produce distinctive traditional ink tones', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);
      for (int i = 0; i < pixels.length; i++) {
        pixels[i] = 0xFF3F51B5;
      }

      final edo = WoodblockUkiyoeEffect({
        'pigmentPalette': 'traditionalEdo',
        'preserveAlpha': false,
      }).apply(pixels, width, height);

      final sunset = WoodblockUkiyoeEffect({
        'pigmentPalette': 'vermilionSunset',
        'preserveAlpha': false,
      }).apply(pixels, width, height);

      final sumi = WoodblockUkiyoeEffect({
        'pigmentPalette': 'sumiMonochrome',
        'preserveAlpha': false,
      }).apply(pixels, width, height);

      bool diffEdoSunset = false;
      bool diffEdoSumi = false;
      for (int i = 0; i < pixels.length; i++) {
        if (edo[i] != sunset[i]) diffEdoSunset = true;
        if (edo[i] != sumi[i]) diffEdoSumi = true;
      }
      expect(diffEdoSunset, isTrue);
      expect(diffEdoSumi, isTrue);
    });

    test('preserveAlpha restricts woodblock print within sprite boundary', () {
      const width = 16;
      const height = 16;
      final pixels = Uint32List(width * height);

      // Create a 6x6 square in center
      for (int y = 5; y < 11; y++) {
        for (int x = 5; x < 11; x++) {
          pixels[y * width + x] = 0xFF00FF00;
        }
      }

      final effect = WoodblockUkiyoeEffect({
        'preserveAlpha': true,
      });

      final out = effect.apply(pixels, width, height);

      // Pixels outside 6x6 must remain 0
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          if (x < 5 || x >= 11 || y < 5 || y >= 11) {
            expect(out[y * width + x], equals(0));
          }
        }
      }

      int nonZeroInside = 0;
      for (int y = 5; y < 11; y++) {
        for (int x = 5; x < 11; x++) {
          if (out[y * width + x] != 0) nonZeroInside++;
        }
      }
      expect(nonZeroInside, greaterThan(0));
    });
  });
}
