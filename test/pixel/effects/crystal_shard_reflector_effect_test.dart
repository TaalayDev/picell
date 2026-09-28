import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/fields/ui_field.dart';

void main() {
  group('CrystalShardReflectorEffect', () {
    test('instantiates with default parameters and isAnimation is false', () {
      final effect = CrystalShardReflectorEffect();
      expect(effect.type, equals(EffectType.crystalShardReflector));
      expect(effect.isAnimation, isFalse);
      expect(effect.parameters['shardCount'], equals(7));
      expect(effect.parameters['orbitDistance'], equals(4.0));
      expect(effect.parameters['shardSize'], equals(4.0));
      expect(effect.parameters['crystalPalette'], equals('prismaticDiamond'));
      expect(effect.parameters['sparkleGlints'], isTrue);
      expect(effect.parameters['behindOnly'], isFalse);
    });

    test('getFields returns strongly-typed UIField descriptors', () {
      final effect = CrystalShardReflectorEffect();
      final fields = effect.getFields();

      expect(fields.any((f) => f.key == 'shardCount' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'orbitDistance' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'shardSize' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'crystalPalette' && f is SelectField), isTrue);
      expect(fields.any((f) => f.key == 'sparkleGlints' && f is BoolField), isTrue);
      expect(fields.any((f) => f.key == 'behindOnly' && f is BoolField), isTrue);
    });

    test('EffectsManager creates and deserializes CrystalShardReflectorEffect', () {
      final effect = EffectsManager.createEffect(
        EffectType.crystalShardReflector,
        {
          'shardCount': 5,
          'crystalPalette': 'bloodRuby',
          'shardSize': 5.0,
        },
      );
      expect(effect, isA<CrystalShardReflectorEffect>());
      expect(effect.parameters['shardCount'], equals(5));
      expect(effect.parameters['crystalPalette'], equals('bloodRuby'));
      expect(effect.parameters['shardSize'], equals(5.0));
    });

    test('renders floating faceted crystal shards around sprite boundary', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      // 8x8 square centered at (12..19, 12..19)
      for (int y = 12; y <= 19; y++) {
        for (int x = 12; x <= 19; x++) {
          pixels[y * width + x] = 0xFF555555;
        }
      }

      final effect = CrystalShardReflectorEffect({
        'shardCount': 6,
        'orbitDistance': 3.5,
        'shardSize': 3.5,
        'crystalPalette': 'prismaticDiamond',
        'sparkleGlints': true,
        'behindOnly': false,
      });

      final result = effect.apply(Uint32List.fromList(pixels), width, height);

      // Verify that crystal shards and sparkle motes are drawn outside the sprite
      int drawnShardsCount = 0;
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final idx = y * width + x;
          if (pixels[idx] == 0 && result[idx] != 0) {
            final a = (result[idx] >> 24) & 0xFF;
            if (a > 100) {
              drawnShardsCount++;
            }
          }
        }
      }
      expect(drawnShardsCount, greaterThan(20), reason: 'Diamond shards and glints should be drawn');
    });

    test('bloodRuby palette generates crimson and ruby colored facet pixels', () {
      const width = 28;
      const height = 28;
      final pixels = Uint32List(width * height);

      // 6x6 square at center
      for (int y = 11; y <= 16; y++) {
        for (int x = 11; x <= 16; x++) {
          pixels[y * width + x] = 0xFF333333;
        }
      }

      final effect = CrystalShardReflectorEffect({
        'shardCount': 6,
        'orbitDistance': 3.0,
        'shardSize': 4.0,
        'crystalPalette': 'bloodRuby',
        'sparkleGlints': false,
        'behindOnly': false,
      });

      final result = effect.apply(Uint32List.fromList(pixels), width, height);

      // Verify ruby crimson pixels (R high, B and G lower)
      bool foundRuby = false;
      for (int i = 0; i < width * height; i++) {
        if (pixels[i] == 0 && result[i] != 0) {
          final p = result[i];
          final r = (p >> 16) & 0xFF;
          final g = (p >> 8) & 0xFF;
          final b = p & 0xFF;
          if (r > 180 && g < 100 && b < 120) {
            foundRuby = true;
            break;
          }
        }
      }
      expect(foundRuby, isTrue, reason: 'bloodRuby palette should generate red/crimson pixels');
    });

    test('behindOnly preserves foreground sprite pixels without overwriting', () {
      const width = 24;
      const height = 24;
      final pixels = Uint32List(width * height);

      const spriteColor = 0xFF119955;
      for (int y = 9; y <= 14; y++) {
        for (int x = 9; x <= 14; x++) {
          pixels[y * width + x] = spriteColor;
        }
      }

      final effect = CrystalShardReflectorEffect({
        'shardCount': 8,
        'orbitDistance': 2.0,
        'behindOnly': true,
      });

      final result = effect.apply(Uint32List.fromList(pixels), width, height);

      // Foreground sprite pixels must remain untouched
      for (int y = 9; y <= 14; y++) {
        for (int x = 9; x <= 14; x++) {
          expect(result[y * width + x], equals(spriteColor));
        }
      }
    });
  });
}
