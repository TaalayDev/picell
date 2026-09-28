import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/fields/ui_field.dart';

void main() {
  group('AbyssalTendrilMiasmaEffect', () {
    test('instantiates with default parameters and isAnimation is false', () {
      final effect = AbyssalTendrilMiasmaEffect();
      expect(effect.type, equals(EffectType.abyssalTendrilMiasma));
      expect(effect.isAnimation, isFalse);
      expect(effect.parameters['tendrilCount'], equals(6));
      expect(effect.parameters['reachLength'], equals(10.0));
      expect(effect.parameters['curlTwist'], equals(1.5));
      expect(effect.parameters['bubbleMotes'], isTrue);
      expect(effect.parameters['inkPalette'], equals('voidBlack'));
      expect(effect.parameters['behindOnly'], isFalse);
    });

    test('getFields returns strongly-typed UIField descriptors', () {
      final effect = AbyssalTendrilMiasmaEffect();
      final fields = effect.getFields();

      expect(fields.any((f) => f.key == 'tendrilCount' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'reachLength' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'curlTwist' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'bubbleMotes' && f is BoolField), isTrue);
      expect(fields.any((f) => f.key == 'inkPalette' && f is SelectField), isTrue);
      expect(fields.any((f) => f.key == 'behindOnly' && f is BoolField), isTrue);
    });

    test('EffectsManager creates and deserializes AbyssalTendrilMiasmaEffect', () {
      final effect = EffectsManager.createEffect(
        EffectType.abyssalTendrilMiasma,
        {
          'tendrilCount': 8,
          'reachLength': 14.0,
          'inkPalette': 'vampireBlood',
        },
      );
      expect(effect, isA<AbyssalTendrilMiasmaEffect>());
      expect(effect.parameters['tendrilCount'], equals(8));
      expect(effect.parameters['reachLength'], equals(14.0));
      expect(effect.parameters['inkPalette'], equals('vampireBlood'));
    });

    test('projects creeping serpentine tendrils outward from sprite contour', () {
      const width = 36;
      const height = 36;
      final pixels = Uint32List(width * height);

      // 8x8 character square at (14..21, 14..21)
      for (int y = 14; y <= 21; y++) {
        for (int x = 14; x <= 21; x++) {
          pixels[y * width + x] = 0xFF555555;
        }
      }

      final effect = AbyssalTendrilMiasmaEffect({
        'tendrilCount': 6,
        'reachLength': 10.0,
        'curlTwist': 1.5,
        'bubbleMotes': true,
        'inkPalette': 'voidBlack',
        'behindOnly': false,
      });

      final result = effect.apply(Uint32List.fromList(pixels), width, height);

      // Verify that dark tendril pixels are projected outward into empty space
      int tendrilPixelsFound = 0;
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final idx = y * width + x;
          if (pixels[idx] == 0 && result[idx] != 0) {
            final a = (result[idx] >> 24) & 0xFF;
            if (a > 60) {
              tendrilPixelsFound++;
            }
          }
        }
      }

      expect(tendrilPixelsFound, greaterThan(25), reason: 'Tendril stalks should extend outward');
    });

    test('vampireBlood palette produces dark crimson core and blood red glow', () {
      const width = 28;
      const height = 28;
      final pixels = Uint32List(width * height);

      for (int y = 10; y <= 16; y++) {
        for (int x = 10; x <= 16; x++) {
          pixels[y * width + x] = 0xFF444444;
        }
      }

      final effect = AbyssalTendrilMiasmaEffect({
        'tendrilCount': 6,
        'reachLength': 8.0,
        'inkPalette': 'vampireBlood',
        'behindOnly': false,
      });

      final result = effect.apply(Uint32List.fromList(pixels), width, height);

      // Verify red / crimson hue on tendril pixels (R high, B and G low)
      bool foundBlood = false;
      for (int i = 0; i < width * height; i++) {
        if (pixels[i] == 0 && result[i] != 0) {
          final p = result[i];
          final r = (p >> 16) & 0xFF;
          final g = (p >> 8) & 0xFF;
          final b = p & 0xFF;
          if (r > 150 && g < 50 && b < 50) {
            foundBlood = true;
            break;
          }
        }
      }
      expect(foundBlood, isTrue, reason: 'vampireBlood should generate crimson/red tendril pixels');
    });

    test('behindOnly preserves foreground sprite pixels without overwriting', () {
      const width = 24;
      const height = 24;
      final pixels = Uint32List(width * height);

      const spriteColor = 0xFF338855;
      for (int y = 9; y <= 14; y++) {
        for (int x = 9; x <= 14; x++) {
          pixels[y * width + x] = spriteColor;
        }
      }

      final effect = AbyssalTendrilMiasmaEffect({
        'tendrilCount': 6,
        'reachLength': 6.0,
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
