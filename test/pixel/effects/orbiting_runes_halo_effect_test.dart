import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/fields/ui_field.dart';

void main() {
  group('OrbitingRunesHaloEffect', () {
    test('instantiates with default parameters and isAnimation is false', () {
      final effect = OrbitingRunesHaloEffect();
      expect(effect.type, equals(EffectType.orbitingRunesHalo));
      expect(effect.isAnimation, isFalse);
      expect(effect.parameters['orbitRadiusX'], equals(14.0));
      expect(effect.parameters['orbitRadiusY'], equals(6.0));
      expect(effect.parameters['runeCount'], equals(5.0));
      expect(effect.parameters['haloStyle'], equals('elderRunes'));
      expect(effect.parameters['runePalette'], equals('celestialGold'));
      expect(effect.parameters['heightAboveSprite'], equals(6.0));
    });

    test('getFields returns strongly-typed UIField descriptors', () {
      final effect = OrbitingRunesHaloEffect();
      final fields = effect.getFields();

      expect(fields.any((f) => f.key == 'orbitRadiusX' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'orbitRadiusY' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'runeCount' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'haloStyle' && f is SelectField), isTrue);
      expect(fields.any((f) => f.key == 'runePalette' && f is SelectField), isTrue);
      expect(fields.any((f) => f.key == 'heightAboveSprite' && f is SliderField), isTrue);
    });

    test('EffectsManager creates and deserializes OrbitingRunesHaloEffect', () {
      final effect = EffectsManager.createEffect(
        EffectType.orbitingRunesHalo,
        {
          'orbitRadiusX': 16.0,
          'haloStyle': 'angelicRing',
          'runePalette': 'arcaneAmethyst',
        },
      );
      expect(effect, isA<OrbitingRunesHaloEffect>());
      expect(effect.parameters['orbitRadiusX'], equals(16.0));
      expect(effect.parameters['haloStyle'], equals('angelicRing'));
      expect(effect.parameters['runePalette'], equals('arcaneAmethyst'));
    });

    test('renders continuous glowing angelic ring hovering overhead', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      // Character body at (12..19, 14..26)
      for (int y = 14; y <= 26; y++) {
        for (int x = 12; x <= 19; x++) {
          pixels[y * width + x] = 0xFF444444;
        }
      }

      final effect = OrbitingRunesHaloEffect({
        'orbitRadiusX': 10.0,
        'orbitRadiusY': 4.0,
        'haloStyle': 'angelicRing',
        'runePalette': 'celestialGold',
        'heightAboveSprite': 6.0, // orbit center around y = 14 - 6 = 8
      });

      final result = effect.apply(Uint32List.fromList(pixels), width, height);

      // Verify angelic halo ring is drawn around y = 8 (e.g. y in 4..12, x in 5..26)
      bool foundHaloPixels = false;
      for (int y = 4; y <= 12; y++) {
        for (int x = 5; x <= 26; x++) {
          final idx = y * width + x;
          if (pixels[idx] == 0 && result[idx] != 0) {
            final a = (result[idx] >> 24) & 0xFF;
            if (a > 100) {
              foundHaloPixels = true;
              break;
            }
          }
        }
        if (foundHaloPixels) break;
      }
      expect(foundHaloPixels, isTrue, reason: 'Angelic ring halo should hover above character head');
    });

    test('elderRunes renders discrete runic glyph nodes with depth sorting', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      // Character block at (13..18, 12..24)
      for (int y = 12; y <= 24; y++) {
        for (int x = 13; x <= 18; x++) {
          pixels[y * width + x] = 0xFF555555;
        }
      }

      final effect = OrbitingRunesHaloEffect({
        'orbitRadiusX': 12.0,
        'orbitRadiusY': 4.0,
        'runeCount': 4.0,
        'haloStyle': 'elderRunes',
        'runePalette': 'arcaneAmethyst',
        'heightAboveSprite': 4.0,
      });

      final result = effect.apply(Uint32List.fromList(pixels), width, height);

      // In elderRunes mode, discrete runic glyphs should be placed on orbit perimeter
      // Specifically at lateral extremes x ~ 15 - 12 = 3 and x ~ 15 + 12 = 27
      bool foundLeftRune = false;
      bool foundRightRune = false;

      for (int y = 5; y <= 12; y++) {
        for (int x = 1; x <= 5; x++) {
          if (((result[y * width + x] >> 24) & 0xFF) > 0) {
            foundLeftRune = true;
            break;
          }
        }
        for (int x = 25; x <= 30; x++) {
          if (((result[y * width + x] >> 24) & 0xFF) > 0) {
            foundRightRune = true;
            break;
          }
        }
      }

      expect(foundLeftRune, isTrue, reason: 'Left orbital rune should be rendered');
      expect(foundRightRune, isTrue, reason: 'Right orbital rune should be rendered');
    });

    test('arcaneAmethyst palette applies magenta and purple glyph colors', () {
      const width = 24;
      const height = 24;
      final pixels = Uint32List(width * height);

      // Small 4x4 sprite at (10..13, 14..17)
      for (int y = 14; y <= 17; y++) {
        for (int x = 10; x <= 13; x++) {
          pixels[y * width + x] = 0xFF333333;
        }
      }

      final effect = OrbitingRunesHaloEffect({
        'orbitRadiusX': 8.0,
        'orbitRadiusY': 3.0,
        'runeCount': 3.0,
        'haloStyle': 'magusOrbs',
        'runePalette': 'arcaneAmethyst',
        'heightAboveSprite': 5.0,
      });

      final result = effect.apply(Uint32List.fromList(pixels), width, height);

      // In arcaneAmethyst, Red and Blue are both high (magenta/purple) while Green is low
      bool foundAmethystColor = false;
      for (int y = 3; y <= 12; y++) {
        for (int x = 2; x <= 20; x++) {
          final idx = y * width + x;
          if (pixels[idx] == 0 && result[idx] != 0) {
            final p = result[idx];
            final r = (p >> 16) & 0xFF;
            final g = (p >> 8) & 0xFF;
            final b = p & 0xFF;
            if (r > 150 && b > 180 && g < 100) {
              foundAmethystColor = true;
              break;
            }
          }
        }
        if (foundAmethystColor) break;
      }
      expect(foundAmethystColor, isTrue, reason: 'arcaneAmethyst palette should yield magenta/purple glow');
    });
  });
}
