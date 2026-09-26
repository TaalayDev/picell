import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/fields/ui_field.dart';

void main() {
  group('CrownSoulFireEffect', () {
    test('instantiates with default parameters and isAnimation is false', () {
      final effect = CrownSoulFireEffect();
      expect(effect.type, equals(EffectType.crownSoulFire));
      expect(effect.isAnimation, isFalse);
      expect(effect.isPremium, isFalse);
      expect(effect.parameters['fireHeight'], equals(12.0));
      expect(effect.parameters['flameTurbulence'], equals(0.5));
      expect(effect.parameters['firePalette'], equals('hellfireCrimson'));
      expect(effect.parameters['emberRate'], equals(0.4));
      expect(effect.parameters['anchorMode'], equals('topEdgesOnly'));
      expect(effect.parameters['behindOnly'], isFalse);
    });

    test('getFields returns strongly-typed UIField descriptors', () {
      final effect = CrownSoulFireEffect();
      final fields = effect.getFields();

      expect(fields.any((f) => f.key == 'fireHeight' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'flameTurbulence' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'firePalette' && f is SelectField), isTrue);
      expect(fields.any((f) => f.key == 'emberRate' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'anchorMode' && f is SelectField), isTrue);
      expect(fields.any((f) => f.key == 'behindOnly' && f is BoolField), isTrue);
    });

    test('EffectsManager creates and deserializes CrownSoulFireEffect', () {
      final effect = EffectsManager.createEffect(
        EffectType.crownSoulFire,
        {
          'fireHeight': 16.0,
          'firePalette': 'soulBlue',
          'anchorMode': 'fullSilhouette',
        },
      );
      expect(effect, isA<CrownSoulFireEffect>());
      expect(effect.parameters['fireHeight'], equals(16.0));
      expect(effect.parameters['firePalette'], equals('soulBlue'));
      expect(effect.parameters['anchorMode'], equals('fullSilhouette'));
    });

    test('sprouts flame tongues upward from top-facing sprite contours', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      // 8x8 block in lower center (x: 12..19, y: 16..23)
      for (int y = 16; y <= 23; y++) {
        for (int x = 12; x <= 19; x++) {
          pixels[y * width + x] = 0xFF555555; // solid grey sprite
        }
      }

      final effect = CrownSoulFireEffect({
        'fireHeight': 10.0,
        'flameTurbulence': 0.0,
        'firePalette': 'hellfireCrimson',
        'emberRate': 0.0,
        'anchorMode': 'topEdgesOnly',
        'behindOnly': false,
      });

      final result = effect.apply(Uint32List.fromList(pixels), width, height);

      // Upward flame tongues sprout above top edge (y < 16, x in 12..19)
      bool foundFireAbove = false;
      for (int y = 8; y < 16; y++) {
        for (int x = 12; x <= 19; x++) {
          final p = result[y * width + x];
          if (((p >> 24) & 0xFF) > 0) {
            foundFireAbove = true;
            break;
          }
        }
        if (foundFireAbove) break;
      }
      expect(foundFireAbove, isTrue, reason: 'Flame tongues should sprout upward from top-facing edges');

      // Beneath the sprite (y > 23), topEdgesOnly should NOT sprout downward flames
      bool foundFireBelow = false;
      for (int y = 24; y < height; y++) {
        for (int x = 12; x <= 19; x++) {
          if (((result[y * width + x] >> 24) & 0xFF) > 0) {
            foundFireBelow = true;
            break;
          }
        }
      }
      expect(foundFireBelow, isFalse, reason: 'topEdgesOnly mode should not sprout flames beneath the sprite');
    });

    test('soulBlue palette yields cyan and blue flame tongue colors', () {
      const width = 24;
      const height = 24;
      final pixels = Uint32List(width * height);

      // 4x4 square at (10..13, 14..17)
      for (int y = 14; y <= 17; y++) {
        for (int x = 10; x <= 13; x++) {
          pixels[y * width + x] = 0xFF888888;
        }
      }

      final effect = CrownSoulFireEffect({
        'fireHeight': 8.0,
        'flameTurbulence': 0.0,
        'firePalette': 'soulBlue',
        'emberRate': 0.0,
        'anchorMode': 'topEdgesOnly',
      });

      final result = effect.apply(Uint32List.fromList(pixels), width, height);

      // Verify soul flame colors in y in [10..13], x in [10..13]
      bool foundSoulCyan = false;
      for (int y = 10; y < 14; y++) {
        final p = result[y * width + 11];
        final a = (p >> 24) & 0xFF;
        if (a > 30) {
          final r = (p >> 16) & 0xFF;
          final b = p & 0xFF;
          // In soulBlue, Blue is dominant over Red in mid/upper flame
          if (b > r) {
            foundSoulCyan = true;
            break;
          }
        }
      }
      expect(foundSoulCyan, isTrue, reason: 'soulBlue palette should render prominent cyan/blue flame licks');
    });

    test('behindOnly preserves foreground sprite pixels without blending over', () {
      const width = 24;
      const height = 24;
      final pixels = Uint32List(width * height);

      const spriteColor = 0xFF22AA22; // Green
      for (int y = 12; y <= 16; y++) {
        for (int x = 10; x <= 14; x++) {
          pixels[y * width + x] = spriteColor;
        }
      }

      final effect = CrownSoulFireEffect({
        'fireHeight': 8.0,
        'anchorMode': 'fullSilhouette',
        'behindOnly': true,
      });

      final result = effect.apply(Uint32List.fromList(pixels), width, height);

      for (int y = 12; y <= 16; y++) {
        for (int x = 10; x <= 14; x++) {
          expect(result[y * width + x], equals(spriteColor),
              reason: 'Foreground sprite pixel should remain unchanged when behindOnly is true');
        }
      }
    });
  });
}
