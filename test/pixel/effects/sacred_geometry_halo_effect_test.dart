import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/fields/ui_field.dart';

void main() {
  group('SacredGeometryHaloEffect', () {
    test('instantiates with default parameters and isAnimation is false', () {
      final effect = SacredGeometryHaloEffect();
      expect(effect.type, equals(EffectType.sacredGeometryHalo));
      expect(effect.isAnimation, isFalse);
      expect(effect.isPremium, isFalse);
      expect(effect.parameters['geometryType'], equals('metatronCube'));
      expect(effect.parameters['haloRadius'], equals(13.0));
      expect(effect.parameters['showNodes'], isTrue);
      expect(effect.parameters['isometricLines'], isTrue);
      expect(effect.parameters['sacredPalette'], equals('divineGold'));
      expect(effect.parameters['behindOnly'], isFalse);
    });

    test('getFields returns strongly-typed UIField descriptors', () {
      final effect = SacredGeometryHaloEffect();
      final fields = effect.getFields();

      expect(fields.any((f) => f.key == 'geometryType' && f is SelectField), isTrue);
      expect(fields.any((f) => f.key == 'haloRadius' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'showNodes' && f is BoolField), isTrue);
      expect(fields.any((f) => f.key == 'isometricLines' && f is BoolField), isTrue);
      expect(fields.any((f) => f.key == 'sacredPalette' && f is SelectField), isTrue);
      expect(fields.any((f) => f.key == 'behindOnly' && f is BoolField), isTrue);
    });

    test('EffectsManager creates and deserializes SacredGeometryHaloEffect', () {
      final effect = EffectsManager.createEffect(
        EffectType.sacredGeometryHalo,
        {
          'geometryType': 'flowerOfLife',
          'haloRadius': 15.0,
          'sacredPalette': 'cosmicPlatonic',
        },
      );
      expect(effect, isA<SacredGeometryHaloEffect>());
      expect(effect.parameters['geometryType'], equals('flowerOfLife'));
      expect(effect.parameters['haloRadius'], equals(15.0));
      expect(effect.parameters['sacredPalette'], equals('cosmicPlatonic'));
    });

    test('renders Metatron Cube and sacred geometry nodal vectors', () {
      const width = 36;
      const height = 36;
      final pixels = Uint32List(width * height);

      // Character body at (14..21, 14..21)
      for (int y = 14; y <= 21; y++) {
        for (int x = 14; x <= 21; x++) {
          pixels[y * width + x] = 0xFF333333;
        }
      }

      final effect = SacredGeometryHaloEffect({
        'geometryType': 'metatronCube',
        'haloRadius': 13.0,
        'showNodes': true,
        'isometricLines': true,
        'sacredPalette': 'divineGold',
        'behindOnly': false,
      });

      final result = effect.apply(Uint32List.fromList(pixels), width, height);

      // Verify that halo and nodes render outside the 8x8 character square
      int haloPixelCount = 0;
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final isInside = (x >= 14 && x <= 21 && y >= 14 && y <= 21);
          final resA = (result[y * width + x] >> 24) & 0xFF;
          if (!isInside && resA > 0) {
            haloPixelCount++;
          }
        }
      }

      expect(haloPixelCount, greaterThan(35));
    });

    test('sacredPalette variations produce distinctive gold and azure halos', () {
      const width = 30;
      const height = 30;
      final pixels = Uint32List(width * height);

      for (int y = 10; y <= 18; y++) {
        for (int x = 10; x <= 18; x++) {
          pixels[y * width + x] = 0xFF222222;
        }
      }

      final goldEffect = SacredGeometryHaloEffect({
        'haloRadius': 10.0,
        'sacredPalette': 'divineGold',
      });
      final azureEffect = SacredGeometryHaloEffect({
        'haloRadius': 10.0,
        'sacredPalette': 'cosmicPlatonic',
      });

      final goldResult = goldEffect.apply(Uint32List.fromList(pixels), width, height);
      final azureResult = azureEffect.apply(Uint32List.fromList(pixels), width, height);

      int goldCount = 0;
      int azureCount = 0;

      for (int i = 0; i < width * height; i++) {
        final gR = (goldResult[i] >> 16) & 0xFF;
        final gG = (goldResult[i] >> 8) & 0xFF;
        final gB = goldResult[i] & 0xFF;
        if (gR > 200 && gG > 180 && gB < 100) goldCount++;

        final aR = (azureResult[i] >> 16) & 0xFF;
        final aG = (azureResult[i] >> 8) & 0xFF;
        final aB = azureResult[i] & 0xFF;
        if (aB > 200 && aG > 160 && aR < 100) azureCount++;
      }

      expect(goldCount, greaterThan(15));
      expect(azureCount, greaterThan(15));
    });

    test('behindOnly preserves foreground sprite pixels without overwriting', () {
      const width = 30;
      const height = 30;
      final pixels = Uint32List(width * height);

      for (int y = 10; y <= 20; y++) {
        for (int x = 10; x <= 20; x++) {
          pixels[y * width + x] = 0xFF774422;
        }
      }

      final effect = SacredGeometryHaloEffect({
        'haloRadius': 9.0,
        'behindOnly': true,
      });

      final result = effect.apply(Uint32List.fromList(pixels), width, height);

      for (int y = 10; y <= 20; y++) {
        for (int x = 10; x <= 20; x++) {
          expect(result[y * width + x], equals(0xFF774422));
        }
      }
    });
  });
}
