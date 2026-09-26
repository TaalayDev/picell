import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/fields/ui_field.dart';

void main() {
  group('StompDustImpactEffect', () {
    test('instantiates with default parameters and isAnimation is false', () {
      final effect = StompDustImpactEffect();
      expect(effect.type, equals(EffectType.stompDustImpact));
      expect(effect.isAnimation, isFalse);
      expect(effect.isPremium, isFalse);
      expect(effect.parameters['plumeWidth'], equals(12.0));
      expect(effect.parameters['plumeHeight'], equals(6.0));
      expect(effect.parameters['dustDensity'], equals(0.7));
      expect(effect.parameters['groundCracks'], isTrue);
      expect(effect.parameters['dustPalette'], equals('desertSand'));
      expect(effect.parameters['behindOnly'], isFalse);
    });

    test('getFields returns strongly-typed UIField descriptors', () {
      final effect = StompDustImpactEffect();
      final fields = effect.getFields();

      expect(fields.any((f) => f.key == 'plumeWidth' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'plumeHeight' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'dustDensity' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'groundCracks' && f is BoolField), isTrue);
      expect(fields.any((f) => f.key == 'dustPalette' && f is SelectField), isTrue);
      expect(fields.any((f) => f.key == 'behindOnly' && f is BoolField), isTrue);
    });

    test('EffectsManager creates and deserializes StompDustImpactEffect', () {
      final effect = EffectsManager.createEffect(
        EffectType.stompDustImpact,
        {
          'plumeWidth': 16.0,
          'plumeHeight': 8.0,
          'dustPalette': 'volcanicAsh',
        },
      );
      expect(effect, isA<StompDustImpactEffect>());
      expect(effect.parameters['plumeWidth'], equals(16.0));
      expect(effect.parameters['plumeHeight'], equals(8.0));
      expect(effect.parameters['dustPalette'], equals('volcanicAsh'));
    });

    test('projects kicking dust plumes and ground cracks from bottom contact points', () {
      const width = 36;
      const height = 36;
      final pixels = Uint32List(width * height);

      // 8x8 character sprite centered at (14..21, 10..17)
      for (int y = 10; y <= 17; y++) {
        for (int x = 14; x <= 21; x++) {
          pixels[y * width + x] = 0xFF555555;
        }
      }

      final effect = StompDustImpactEffect({
        'plumeWidth': 12.0,
        'plumeHeight': 6.0,
        'dustDensity': 0.8,
        'groundCracks': true,
        'dustPalette': 'desertSand',
        'behindOnly': false,
      });

      final result = effect.apply(Uint32List.fromList(pixels), width, height);

      // Verify presence of dust puff pixels to the left and right of sprite base (y = 14..18, x < 14 or x > 21)
      bool foundLeftDust = false;
      bool foundRightDust = false;

      for (int y = 13; y <= 19; y++) {
        for (int x = 4; x < 14; x++) {
          final idx = y * width + x;
          if (pixels[idx] == 0 && result[idx] != 0) {
            foundLeftDust = true;
            break;
          }
        }
        for (int x = 22; x < 32; x++) {
          final idx = y * width + x;
          if (pixels[idx] == 0 && result[idx] != 0) {
            foundRightDust = true;
            break;
          }
        }
      }

      expect(foundLeftDust, isTrue, reason: 'Left plume should project dust to the left');
      expect(foundRightDust, isTrue, reason: 'Right plume should project dust to the right');
    });

    test('volcanicAsh palette produces dark gray and orange ember pixels', () {
      const width = 28;
      const height = 28;
      final pixels = Uint32List(width * height);

      for (int y = 8; y <= 14; y++) {
        for (int x = 11; x <= 16; x++) {
          pixels[y * width + x] = 0xFF444444;
        }
      }

      final effect = StompDustImpactEffect({
        'plumeWidth': 10.0,
        'plumeHeight': 5.0,
        'dustPalette': 'volcanicAsh',
        'groundCracks': true,
        'behindOnly': false,
      });

      final result = effect.apply(Uint32List.fromList(pixels), width, height);

      // Verify presence of ash / ember pixels
      bool foundAshOrEmber = false;
      for (int i = 0; i < width * height; i++) {
        if (pixels[i] == 0 && result[i] != 0) {
          final p = result[i];
          final r = (p >> 16) & 0xFF;
          final g = (p >> 8) & 0xFF;
          final b = p & 0xFF;
          // Either ember orange (R high, B low) or ash gray
          if ((r > 200 && g < 150 && b < 80) || (r > 80 && (r - g).abs() < 20 && (g - b).abs() < 20)) {
            foundAshOrEmber = true;
            break;
          }
        }
      }
      expect(foundAshOrEmber, isTrue, reason: 'volcanicAsh should generate ash gray or ember sparks');
    });

    test('behindOnly preserves foreground sprite pixels without overwriting', () {
      const width = 24;
      const height = 24;
      final pixels = Uint32List(width * height);

      const spriteColor = 0xFF227744;
      for (int y = 8; y <= 14; y++) {
        for (int x = 9; x <= 14; x++) {
          pixels[y * width + x] = spriteColor;
        }
      }

      final effect = StompDustImpactEffect({
        'plumeWidth': 8.0,
        'plumeHeight': 4.0,
        'behindOnly': true,
      });

      final result = effect.apply(Uint32List.fromList(pixels), width, height);

      // Foreground sprite pixels must be untouched
      for (int y = 8; y <= 14; y++) {
        for (int x = 9; x <= 14; x++) {
          expect(result[y * width + x], equals(spriteColor));
        }
      }
    });
  });
}
