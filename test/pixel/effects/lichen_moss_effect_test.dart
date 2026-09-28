import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/fields/ui_field.dart';

void main() {
  group('LichenMossEffect', () {
    test('instantiates with default parameters and isAnimation is true', () {
      final effect = LichenMossEffect();
      expect(effect.type, equals(EffectType.lichenMoss));
      expect(effect.isAnimation, isTrue);
      expect(effect.parameters['lichenCoverage'], equals(0.5));
      expect(effect.parameters['growthPattern'], equals('crustoseRings'));
      expect(effect.parameters['sporePustules'], equals(0.4));
      expect(effect.parameters['lichenPalette'], equals('arcticOrange'));
      expect(effect.parameters['edgeCreepDepth'], equals(3.5));
      expect(effect.parameters['time'], equals(0.0));
      expect(effect.parameters['preserveAlpha'], isFalse);
    });

    test('getFields returns strongly-typed UIField descriptors', () {
      final effect = LichenMossEffect();
      final fields = effect.getFields();

      expect(fields.any((f) => f.key == 'lichenCoverage' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'growthPattern' && f is SelectField), isTrue);
      expect(fields.any((f) => f.key == 'sporePustules' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'lichenPalette' && f is SelectField), isTrue);
      expect(fields.any((f) => f.key == 'edgeCreepDepth' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'time' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'preserveAlpha' && f is BoolField), isTrue);
    });

    test('EffectsManager creates and deserializes LichenMossEffect', () {
      final effect = EffectsManager.createEffect(
        EffectType.lichenMoss,
        {
          'growthPattern': 'velvetPatches',
          'lichenPalette': 'deepForestEmerald',
          'lichenCoverage': 0.7,
        },
      );
      expect(effect, isA<LichenMossEffect>());
      expect(effect.parameters['growthPattern'], equals('velvetPatches'));
      expect(effect.parameters['lichenPalette'], equals('deepForestEmerald'));
      expect(effect.parameters['lichenCoverage'], equals(0.7));
    });

    test('renders lichen crust and rock moss on stone canvas', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      // Stone background
      for (int i = 0; i < pixels.length; i++) {
        pixels[i] = 0xFF505050;
      }

      final effect = LichenMossEffect({
        'lichenCoverage': 0.6,
        'growthPattern': 'crustoseRings',
        'preserveAlpha': false,
      });

      final out = effect.apply(pixels, width, height);

      int nonStoneCount = 0;
      for (int i = 0; i < pixels.length; i++) {
        if (out[i] != 0xFF505050) nonStoneCount++;
      }
      expect(nonStoneCount, greaterThan(0));
    });

    test('different growth patterns produce distinct morphological colonies', () {
      const width = 24;
      const height = 24;
      final pixels = Uint32List(width * height);
      for (int i = 0; i < pixels.length; i++) {
        pixels[i] = 0xFF444444;
      }

      final ringEffect = LichenMossEffect({
        'growthPattern': 'crustoseRings',
        'lichenCoverage': 0.5,
        'preserveAlpha': false,
      });
      final tendrilEffect = LichenMossEffect({
        'growthPattern': 'creepingMoss',
        'lichenCoverage': 0.5,
        'preserveAlpha': false,
      });

      final outRings = ringEffect.apply(pixels, width, height);
      final outTendrils = tendrilEffect.apply(pixels, width, height);

      int diffCount = 0;
      for (int i = 0; i < pixels.length; i++) {
        if (outRings[i] != outTendrils[i]) diffCount++;
      }
      expect(diffCount, greaterThan(0));
    });

    test('preserveAlpha restricts lichen growth to sprite silhouette', () {
      const width = 24;
      const height = 24;
      final pixels = Uint32List(width * height);

      for (int y = 6; y < 18; y++) {
        for (int x = 6; x < 18; x++) {
          pixels[y * width + x] = 0xFF666666;
        }
      }

      final effect = LichenMossEffect({
        'preserveAlpha': true,
        'lichenCoverage': 0.8,
      });

      final out = effect.apply(pixels, width, height);

      expect(out[0], equals(0));
      expect(out[10 * width + 10], isNot(equals(0)));
    });
  });
}
