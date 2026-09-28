import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/fields/ui_field.dart';

void main() {
  group('TidalRockPoolEffect', () {
    test('instantiates with default parameters and isAnimation is true', () {
      final effect = TidalRockPoolEffect();
      expect(effect.type, equals(EffectType.tidalRockPool));
      expect(effect.isAnimation, isTrue);
      expect(effect.parameters['poolDepth'], equals(0.65));
      expect(effect.parameters['causticShimmer'], equals(0.7));
      expect(effect.parameters['kelpWaveSpeed'], equals(1.4));
      expect(effect.parameters['biomassColor'], equals('anemonePink'));
      expect(effect.parameters['saltRimCrust'], equals(0.45));
      expect(effect.parameters['waterClarity'], equals(0.8));
      expect(effect.parameters['time'], equals(0.0));
      expect(effect.parameters['preserveAlpha'], isFalse);
    });

    test('getFields returns strongly-typed UIField descriptors', () {
      final effect = TidalRockPoolEffect();
      final fields = effect.getFields();

      expect(fields.any((f) => f.key == 'poolDepth' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'causticShimmer' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'kelpWaveSpeed' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'biomassColor' && f is SelectField), isTrue);
      expect(fields.any((f) => f.key == 'saltRimCrust' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'waterClarity' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'time' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'preserveAlpha' && f is BoolField), isTrue);
    });

    test('EffectsManager creates and deserializes TidalRockPoolEffect', () {
      final effect = EffectsManager.createEffect(
        EffectType.tidalRockPool,
        {
          'poolDepth': 0.8,
          'biomassColor': 'seaEmerald',
          'causticShimmer': 0.9,
        },
      );
      expect(effect, isA<TidalRockPoolEffect>());
      expect(effect.parameters['poolDepth'], equals(0.8));
      expect(effect.parameters['biomassColor'], equals('seaEmerald'));
      expect(effect.parameters['causticShimmer'], equals(0.9));
    });

    test('renders rock pool basin with dancing caustics and marine flora', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      final effect = TidalRockPoolEffect({
        'poolDepth': 0.7,
        'causticShimmer': 0.85,
        'biomassColor': 'anemonePink',
        'preserveAlpha': false,
      });

      final out = effect.apply(pixels, width, height);

      int poolPixelsCount = 0;
      for (int i = 0; i < pixels.length; i++) {
        final b = out[i] & 0xFF;
        final g = (out[i] >> 8) & 0xFF;
        if (b > 100 || g > 100) poolPixelsCount++;
      }
      expect(poolPixelsCount, greaterThan(0));
    });

    test('time animation drives dynamic water caustics and kelp swaying', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      final effectT0 = TidalRockPoolEffect({'time': 0.0, 'preserveAlpha': false});
      final effectT1 = TidalRockPoolEffect({'time': 0.5, 'preserveAlpha': false});

      final out0 = effectT0.apply(pixels, width, height);
      final out1 = effectT1.apply(pixels, width, height);

      int diffCount = 0;
      for (int i = 0; i < pixels.length; i++) {
        if (out0[i] != out1[i]) diffCount++;
      }
      expect(diffCount, greaterThan(0));
    });

    test('preserveAlpha restricts tide pool water to sprite silhouette', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      // Center 8x8 block is opaque character sprite
      for (int y = 12; y < 20; y++) {
        for (int x = 12; x < 20; x++) {
          pixels[y * width + x] = 0xFF2A4050;
        }
      }

      final effect = TidalRockPoolEffect({
        'preserveAlpha': true,
      });

      final out = effect.apply(pixels, width, height);

      // Pixels outside central 8x8 block must remain 0
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final isInside = (x >= 12 && x < 20 && y >= 12 && y < 20);
          final a = (out[y * width + x] >> 24) & 0xFF;
          if (!isInside) {
            expect(a, equals(0));
          } else {
            expect(a, equals(255));
          }
        }
      }
    });
  });
}
