import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/fields/ui_field.dart';

void main() {
  group('VoronoiShatterEffect', () {
    test('instantiates with default parameters and isAnimation is false', () {
      final effect = VoronoiShatterEffect();
      expect(effect.type, equals(EffectType.voronoiShatter));
      expect(effect.isAnimation, isFalse);
      expect(effect.parameters['impactCenterX'], equals(0.5));
      expect(effect.parameters['impactCenterY'], equals(0.5));
      expect(effect.parameters['shardCount'], equals(16.0));
      expect(effect.parameters['explosionForce'], equals(3.5));
      expect(effect.parameters['fractureGap'], equals(1.2));
      expect(effect.parameters['shardRotation'], equals(0.3));
      expect(effect.parameters['specularBevel'], equals(0.5));
      expect(effect.parameters['preserveAlpha'], isTrue);
    });

    test('getFields returns strongly-typed UIField descriptors', () {
      final effect = VoronoiShatterEffect();
      final fields = effect.getFields();

      expect(fields.any((f) => f.key == 'impactCenterX' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'impactCenterY' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'shardCount' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'explosionForce' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'fractureGap' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'shardRotation' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'specularBevel' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'preserveAlpha' && f is BoolField), isTrue);
    });

    test('EffectsManager creates and deserializes VoronoiShatterEffect', () {
      final effect = EffectsManager.createEffect(
        EffectType.voronoiShatter,
        {
          'shardCount': 24.0,
          'explosionForce': 6.0,
          'fractureGap': 2.0,
        },
      );
      expect(effect, isA<VoronoiShatterEffect>());
      expect(effect.parameters['shardCount'], equals(24.0));
      expect(effect.parameters['explosionForce'], equals(6.0));
      expect(effect.parameters['fractureGap'], equals(2.0));
    });

    test('fractures pixels into shards and creates transparent fracture gaps', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      // Solid color box
      for (int i = 0; i < pixels.length; i++) {
        pixels[i] = 0xFF336699;
      }

      final effect = VoronoiShatterEffect({
        'shardCount': 16.0,
        'explosionForce': 0.0,
        'fractureGap': 2.0,
        'preserveAlpha': true,
      });

      final out = effect.apply(pixels, width, height);

      // Fracture gaps must be transparent (0) while shard interiors are opaque
      int transparentGaps = 0;
      int solidShards = 0;
      for (int i = 0; i < pixels.length; i++) {
        if (out[i] == 0) {
          transparentGaps++;
        } else {
          solidShards++;
        }
      }
      expect(transparentGaps, greaterThan(0));
      expect(solidShards, greaterThan(0));
    });

    test('explosionForce displaces shards outward from impact center', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          pixels[y * width + x] = 0xFF000000 | ((x * 7) << 16) | ((y * 7) << 8) | 0x88;
        }
      }

      final effectZero = VoronoiShatterEffect({
        'explosionForce': 0.0,
        'fractureGap': 1.0,
        'shardRotation': 0.0,
      });
      final effectBlast = VoronoiShatterEffect({
        'explosionForce': 8.0,
        'fractureGap': 1.0,
        'shardRotation': 0.0,
      });

      final outZero = effectZero.apply(pixels, width, height);
      final outBlast = effectBlast.apply(pixels, width, height);

      int diffCount = 0;
      for (int i = 0; i < pixels.length; i++) {
        if (outZero[i] != outBlast[i]) diffCount++;
      }
      expect(diffCount, greaterThan(0));
    });

    test('preserveAlpha strictly confines shards to layer pixels and keeps empty space transparent', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      // Center 10x10 sprite
      for (int y = 11; y < 21; y++) {
        for (int x = 11; x < 21; x++) {
          pixels[y * width + x] = 0xFFDDAA44;
        }
      }

      final effect = VoronoiShatterEffect();

      final out = effect.apply(pixels, width, height);

      // Outer margin must not be filled with solid background
      expect(out[0], equals(0));
      expect(out[width - 1], equals(0));
      expect(out[(height - 1) * width], equals(0));
      expect(out[(height - 1) * width + width - 1], equals(0));
    });
  });
}
