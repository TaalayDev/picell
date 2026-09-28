import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/fields/ui_field.dart';

void main() {
  group('KiFlareAuraEffect', () {
    test('instantiates with default parameters and isAnimation is false', () {
      final effect = KiFlareAuraEffect();
      expect(effect.type, equals(EffectType.kiFlareAura));
      expect(effect.isAnimation, isFalse);
      expect(effect.parameters['auraRadius'], equals(6.0));
      expect(effect.parameters['flameSway'], equals(0.6));
      expect(effect.parameters['auraPalette'], equals('superSaiyanGold'));
      expect(effect.parameters['innerRimIllumination'], equals(0.5));
      expect(effect.parameters['energyMotes'], isTrue);
      expect(effect.parameters['behindOnly'], isFalse);
    });

    test('getFields returns strongly-typed UIField descriptors', () {
      final effect = KiFlareAuraEffect();
      final fields = effect.getFields();

      expect(fields.any((f) => f.key == 'auraRadius' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'flameSway' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'auraPalette' && f is SelectField), isTrue);
      expect(fields.any((f) => f.key == 'innerRimIllumination' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'energyMotes' && f is BoolField), isTrue);
      expect(fields.any((f) => f.key == 'behindOnly' && f is BoolField), isTrue);
    });

    test('EffectsManager creates and deserializes KiFlareAuraEffect', () {
      final effect = EffectsManager.createEffect(
        EffectType.kiFlareAura,
        {
          'auraRadius': 8.0,
          'auraPalette': 'dragonRageRed',
          'flameSway': 0.8,
        },
      );
      expect(effect, isA<KiFlareAuraEffect>());
      expect(effect.parameters['auraRadius'], equals(8.0));
      expect(effect.parameters['auraPalette'], equals('dragonRageRed'));
      expect(effect.parameters['flameSway'], equals(0.8));
    });

    test('expands exterior energy aura flames around sprite silhouette', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      // 6x6 block in center (x: 13..18, y: 13..18)
      for (int y = 13; y <= 18; y++) {
        for (int x = 13; x <= 18; x++) {
          pixels[y * width + x] = 0xFF444444;
        }
      }

      final effect = KiFlareAuraEffect({
        'auraRadius': 6.0,
        'flameSway': 0.0,
        'auraPalette': 'superSaiyanGold',
        'innerRimIllumination': 0.0,
      });

      final result = effect.apply(Uint32List.fromList(pixels), width, height);

      // Verify aura flames extend 2-5px outside the sprite block (e.g. x in 8..11, y in 13..18)
      bool foundExteriorAura = false;
      for (int x = 8; x <= 11; x++) {
        final p = result[15 * width + x];
        if (((p >> 24) & 0xFF) > 0) {
          foundExteriorAura = true;
          break;
        }
      }
      expect(foundExteriorAura, isTrue, reason: 'Exterior Ki aura should radiate outward from sprite');
    });

    test('innerRimIllumination casts radiant aura tint onto character contours', () {
      const width = 24;
      const height = 24;
      final pixels = Uint32List(width * height);

      const darkSpriteColor = 0xFF222222; // very dark grey
      for (int y = 8; y <= 15; y++) {
        for (int x = 8; x <= 15; x++) {
          pixels[y * width + x] = darkSpriteColor;
        }
      }

      final effect = KiFlareAuraEffect({
        'auraRadius': 4.0,
        'auraPalette': 'superSaiyanGold',
        'innerRimIllumination': 1.0, // full rim illumination
        'behindOnly': false,
      });

      final result = effect.apply(Uint32List.fromList(pixels), width, height);

      // Character contour pixel at (8, 8) should be illuminated by gold light
      final illuminatedP = result[8 * width + 8];
      expect(illuminatedP, isNot(equals(darkSpriteColor)));

      final r = (illuminatedP >> 16) & 0xFF;
      final g = (illuminatedP >> 8) & 0xFF;
      expect(r, greaterThan(100), reason: 'Rim illumination should cast warm golden light on character edge');
      expect(g, greaterThan(80));
    });

    test('dragonRageRed palette produces crimson and red energy aura', () {
      const width = 24;
      const height = 24;
      final pixels = Uint32List(width * height);

      for (int y = 10; y <= 14; y++) {
        for (int x = 10; x <= 14; x++) {
          pixels[y * width + x] = 0xFF000000;
        }
      }

      final effect = KiFlareAuraEffect({
        'auraRadius': 4.0,
        'auraPalette': 'dragonRageRed',
        'innerRimIllumination': 0.0,
      });

      final result = effect.apply(Uint32List.fromList(pixels), width, height);

      // In dragonRageRed, Red component is strong in exterior aura
      bool foundCrimsonAura = false;
      for (int y = 8; y <= 16; y++) {
        for (int x = 6; x <= 9; x++) {
          final p = result[y * width + x];
          final a = (p >> 24) & 0xFF;
          if (a > 50) {
            final r = (p >> 16) & 0xFF;
            final b = p & 0xFF;
            if (r > 150 && r > b) {
              foundCrimsonAura = true;
              break;
            }
          }
        }
        if (foundCrimsonAura) break;
      }
      expect(foundCrimsonAura, isTrue, reason: 'dragonRageRed palette should produce prominent red/crimson flare');
    });
  });
}
