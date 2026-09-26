import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/fields/ui_field.dart';

void main() {
  group('AlchemicalCircleEffect', () {
    test('instantiates with default parameters and isAnimation is false', () {
      final effect = AlchemicalCircleEffect();
      expect(effect.type, equals(EffectType.alchemicalCircle));
      expect(effect.isAnimation, isFalse);
      expect(effect.isPremium, isFalse);
      expect(effect.parameters['circleRadius'], equals(12.0));
      expect(effect.parameters['polygonSides'], equals('hexagram6'));
      expect(effect.parameters['spokeRays'], isTrue);
      expect(effect.parameters['outerRings'], isTrue);
      expect(effect.parameters['alchemyPalette'], equals('hermeticGold'));
      expect(effect.parameters['behindOnly'], isFalse);
    });

    test('getFields returns strongly-typed UIField descriptors', () {
      final effect = AlchemicalCircleEffect();
      final fields = effect.getFields();

      expect(fields.any((f) => f.key == 'circleRadius' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'polygonSides' && f is SelectField), isTrue);
      expect(fields.any((f) => f.key == 'spokeRays' && f is BoolField), isTrue);
      expect(fields.any((f) => f.key == 'outerRings' && f is BoolField), isTrue);
      expect(fields.any((f) => f.key == 'alchemyPalette' && f is SelectField), isTrue);
      expect(fields.any((f) => f.key == 'behindOnly' && f is BoolField), isTrue);
    });

    test('EffectsManager creates and deserializes AlchemicalCircleEffect', () {
      final effect = EffectsManager.createEffect(
        EffectType.alchemicalCircle,
        {
          'circleRadius': 14.0,
          'polygonSides': 'pentagram5',
          'alchemyPalette': 'bloodPhilosopher',
        },
      );
      expect(effect, isA<AlchemicalCircleEffect>());
      expect(effect.parameters['circleRadius'], equals(14.0));
      expect(effect.parameters['polygonSides'], equals('pentagram5'));
      expect(effect.parameters['alchemyPalette'], equals('bloodPhilosopher'));
    });

    test('renders concentric rings, star polygons, and spoke rays around sprite', () {
      const width = 36;
      const height = 36;
      final pixels = Uint32List(width * height);

      // 8x8 character square at center (14..21, 14..21)
      for (int y = 14; y <= 21; y++) {
        for (int x = 14; x <= 21; x++) {
          pixels[y * width + x] = 0xFF555555;
        }
      }

      final effect = AlchemicalCircleEffect({
        'circleRadius': 12.0,
        'polygonSides': 'hexagram6',
        'spokeRays': true,
        'outerRings': true,
        'alchemyPalette': 'hermeticGold',
        'behindOnly': false,
      });

      final result = effect.apply(Uint32List.fromList(pixels), width, height);

      // Check that pixels outside the 8x8 square received circle array graphics
      int circlePixels = 0;
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final isInside = (x >= 14 && x <= 21 && y >= 14 && y <= 21);
          final resA = (result[y * width + x] >> 24) & 0xFF;
          if (!isInside && resA > 0) {
            circlePixels++;
          }
        }
      }

      expect(circlePixels, greaterThan(40));
    });

    test('alchemyPalette variations produce distinctive gold and crimson hues', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      for (int y = 12; y <= 19; y++) {
        for (int x = 12; x <= 19; x++) {
          pixels[y * width + x] = 0xFF333333;
        }
      }

      final goldEffect = AlchemicalCircleEffect({
        'circleRadius': 10.0,
        'alchemyPalette': 'hermeticGold',
      });
      final bloodEffect = AlchemicalCircleEffect({
        'circleRadius': 10.0,
        'alchemyPalette': 'bloodPhilosopher',
      });

      final goldResult = goldEffect.apply(Uint32List.fromList(pixels), width, height);
      final bloodResult = bloodEffect.apply(Uint32List.fromList(pixels), width, height);

      int goldCount = 0;
      int bloodCount = 0;

      for (int i = 0; i < width * height; i++) {
        final gR = (goldResult[i] >> 16) & 0xFF;
        final gG = (goldResult[i] >> 8) & 0xFF;
        final gB = goldResult[i] & 0xFF;
        if (gR > 200 && gG > 180 && gB < 50) goldCount++;

        final bR = (bloodResult[i] >> 16) & 0xFF;
        final bG = (bloodResult[i] >> 8) & 0xFF;
        final bB = bloodResult[i] & 0xFF;
        if (bR > 200 && bG < 50 && bB < 80) bloodCount++;
      }

      expect(goldCount, greaterThan(15));
      expect(bloodCount, greaterThan(15));
    });

    test('behindOnly preserves foreground sprite pixels without overwriting', () {
      const width = 30;
      const height = 30;
      final pixels = Uint32List(width * height);

      for (int y = 10; y <= 20; y++) {
        for (int x = 10; x <= 20; x++) {
          pixels[y * width + x] = 0xFF445566;
        }
      }

      final effect = AlchemicalCircleEffect({
        'circleRadius': 8.0,
        'behindOnly': true,
      });

      final result = effect.apply(Uint32List.fromList(pixels), width, height);

      for (int y = 10; y <= 20; y++) {
        for (int x = 10; x <= 20; x++) {
          expect(result[y * width + x], equals(0xFF445566));
        }
      }
    });
  });
}
