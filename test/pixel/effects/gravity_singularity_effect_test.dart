import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/fields/ui_field.dart';

void main() {
  group('GravitySingularityEffect', () {
    test('instantiates with default parameters and isAnimation is false', () {
      final effect = GravitySingularityEffect();
      expect(effect.type, equals(EffectType.gravitySingularity));
      expect(effect.isAnimation, isFalse);
      expect(effect.isPremium, isFalse);
      expect(effect.parameters['singularityRadius'], equals(4.5));
      expect(effect.parameters['diskRadius'], equals(10.0));
      expect(effect.parameters['swirlTwist'], equals(2.5));
      expect(effect.parameters['singularityPalette'], equals('cosmicVoid'));
      expect(effect.parameters['distortionStrength'], equals(0.5));
      expect(effect.parameters['behindOnly'], isFalse);
    });

    test('getFields returns strongly-typed UIField descriptors', () {
      final effect = GravitySingularityEffect();
      final fields = effect.getFields();

      expect(fields.any((f) => f.key == 'singularityRadius' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'diskRadius' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'swirlTwist' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'singularityPalette' && f is SelectField), isTrue);
      expect(fields.any((f) => f.key == 'distortionStrength' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'behindOnly' && f is BoolField), isTrue);
    });

    test('EffectsManager creates and deserializes GravitySingularityEffect', () {
      final effect = EffectsManager.createEffect(
        EffectType.gravitySingularity,
        {
          'singularityRadius': 3.5,
          'diskRadius': 12.0,
          'singularityPalette': 'solarAccretion',
        },
      );
      expect(effect, isA<GravitySingularityEffect>());
      expect(effect.parameters['singularityRadius'], equals(3.5));
      expect(effect.parameters['diskRadius'], equals(12.0));
      expect(effect.parameters['singularityPalette'], equals('solarAccretion'));
    });

    test('renders event horizon core, photon ring, and swirling accretion disk', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      // Centered 10x10 block
      for (int y = 11; y <= 20; y++) {
        for (int x = 11; x <= 20; x++) {
          pixels[y * width + x] = 0xFF666666;
        }
      }

      final effect = GravitySingularityEffect({
        'singularityRadius': 4.0,
        'diskRadius': 11.0,
        'swirlTwist': 2.5,
        'singularityPalette': 'cosmicVoid',
        'distortionStrength': 0.5,
        'behindOnly': false,
      });

      final result = effect.apply(Uint32List.fromList(pixels), width, height);

      // 1. Center of mass (around 15, 15) should have event horizon void core
      const centerIdx = 15 * width + 15;
      expect((result[centerIdx] >> 24) & 0xFF, greaterThan(200));

      // 2. Accretion disk matter should project outside original 10x10 sprite block
      bool foundDiskPixelOutside = false;
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final idx = y * width + x;
          if (pixels[idx] == 0 && result[idx] != 0) {
            final a = (result[idx] >> 24) & 0xFF;
            if (a > 60) {
              foundDiskPixelOutside = true;
              break;
            }
          }
        }
        if (foundDiskPixelOutside) break;
      }
      expect(foundDiskPixelOutside, isTrue, reason: 'Accretion disk should swirl beyond sprite boundary');
    });

    test('solarAccretion palette produces gold and flame-orange accretion colors', () {
      const width = 28;
      const height = 28;
      final pixels = Uint32List(width * height);

      for (int y = 10; y <= 17; y++) {
        for (int x = 10; x <= 17; x++) {
          pixels[y * width + x] = 0xFF444444;
        }
      }

      final effect = GravitySingularityEffect({
        'singularityRadius': 3.5,
        'diskRadius': 10.0,
        'singularityPalette': 'solarAccretion',
        'distortionStrength': 0.0,
        'behindOnly': false,
      });

      final result = effect.apply(Uint32List.fromList(pixels), width, height);

      // Verify gold / orange accretion matter (R > 180, G > 80)
      bool foundGold = false;
      for (int i = 0; i < width * height; i++) {
        if (pixels[i] == 0 && result[i] != 0) {
          final p = result[i];
          final r = (p >> 16) & 0xFF;
          final g = (p >> 8) & 0xFF;
          if (r > 180 && g > 80) {
            foundGold = true;
            break;
          }
        }
      }
      expect(foundGold, isTrue, reason: 'solarAccretion palette should produce gold and orange matter');
    });

    test('behindOnly preserves foreground sprite pixels without overwriting', () {
      const width = 24;
      const height = 24;
      final pixels = Uint32List(width * height);

      const spriteColor = 0xFF336699;
      for (int y = 9; y <= 14; y++) {
        for (int x = 9; x <= 14; x++) {
          pixels[y * width + x] = spriteColor;
        }
      }

      final effect = GravitySingularityEffect({
        'singularityRadius': 3.0,
        'diskRadius': 8.0,
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
