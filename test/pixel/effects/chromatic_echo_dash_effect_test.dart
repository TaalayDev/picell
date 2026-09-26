import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/fields/ui_field.dart';

void main() {
  group('ChromaticEchoDashEffect', () {
    test('instantiates with default parameters and isAnimation is false', () {
      final effect = ChromaticEchoDashEffect();
      expect(effect.type, equals(EffectType.chromaticEchoDash));
      expect(effect.isAnimation, isFalse);
      expect(effect.isPremium, isFalse);
      expect(effect.parameters['motionAngle'], equals(0.0));
      expect(effect.parameters['echoCount'], equals(3.0));
      expect(effect.parameters['trailDistance'], equals(12.0));
      expect(effect.parameters['colorMode'], equals('chromaticRGB'));
      expect(effect.parameters['glowColor'], equals(0xFF00E5FF));
      expect(effect.parameters['ditherFade'], isTrue);
      expect(effect.parameters['behindOnly'], isTrue);
    });

    test('getFields returns strongly-typed UIField descriptors', () {
      final effect = ChromaticEchoDashEffect();
      final fields = effect.getFields();

      expect(fields.any((f) => f.key == 'motionAngle' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'echoCount' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'trailDistance' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'colorMode' && f is SelectField), isTrue);
      expect(fields.any((f) => f.key == 'glowColor' && f is ColorField), isTrue);
      expect(fields.any((f) => f.key == 'ditherFade' && f is BoolField), isTrue);
      expect(fields.any((f) => f.key == 'behindOnly' && f is BoolField), isTrue);
    });

    test('EffectsManager creates and deserializes ChromaticEchoDashEffect', () {
      final effect = EffectsManager.createEffect(
        EffectType.chromaticEchoDash,
        {
          'motionAngle': 90.0,
          'echoCount': 4.0,
          'colorMode': 'spectralGlow',
          'glowColor': 0xFFE040FB,
        },
      );
      expect(effect, isA<ChromaticEchoDashEffect>());
      expect(effect.parameters['motionAngle'], equals(90.0));
      expect(effect.parameters['echoCount'], equals(4.0));
      expect(effect.parameters['colorMode'], equals('spectralGlow'));
      expect(effect.parameters['glowColor'], equals(0xFFE040FB));
    });

    test('generates stepped ghost afterimages displaced behind the sprite', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      // Centered 4x4 sprite at (16..19, 14..17)
      for (int y = 14; y <= 17; y++) {
        for (int x = 16; x <= 19; x++) {
          pixels[y * width + x] = 0xFFFFFFFF;
        }
      }

      // Motion angle = 0 (moving rightward), so echoes appear at x < 16
      final effect = ChromaticEchoDashEffect({
        'motionAngle': 0.0,
        'echoCount': 3.0,
        'trailDistance': 12.0,
        'colorMode': 'sourceAlpha',
        'ditherFade': false,
        'behindOnly': true,
      });

      final result = effect.apply(Uint32List.fromList(pixels), width, height);

      // Echo 1: shift = 4px left -> x in 12..15
      // Echo 2: shift = 8px left -> x in 8..11
      // Echo 3: shift = 12px left -> x in 4..7
      bool foundEcho1 = false;
      bool foundEcho3 = false;

      for (int x = 12; x <= 15; x++) {
        if (((result[15 * width + x] >> 24) & 0xFF) > 0) {
          foundEcho1 = true;
          break;
        }
      }
      for (int x = 4; x <= 7; x++) {
        if (((result[15 * width + x] >> 24) & 0xFF) > 0) {
          foundEcho3 = true;
          break;
        }
      }

      expect(foundEcho1, isTrue, reason: 'Echo 1 should appear near the sprite');
      expect(foundEcho3, isTrue, reason: 'Echo 3 should appear farther behind the sprite');
    });

    test('chromaticRGB mode tints echoes with distinct RGB chromatic shifts', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      // 4x4 white box at (20..23, 10..13)
      for (int y = 10; y <= 13; y++) {
        for (int x = 20; x <= 23; x++) {
          pixels[y * width + x] = 0xFFFFFFFF;
        }
      }

      final effect = ChromaticEchoDashEffect({
        'motionAngle': 0.0,
        'echoCount': 3.0,
        'trailDistance': 15.0,
        'colorMode': 'chromaticRGB',
        'ditherFade': false,
        'behindOnly': true,
      });

      final result = effect.apply(Uint32List.fromList(pixels), width, height);

      // Check echo 1 (Cyan tint: higher Green & Blue than Red)
      // Shift ~ 5px left: x ~ 15..18
      bool foundCyanEcho = false;
      for (int x = 15; x <= 18; x++) {
        final p = result[11 * width + x];
        final a = (p >> 24) & 0xFF;
        if (a > 30) {
          final r = (p >> 16) & 0xFF;
          final g = (p >> 8) & 0xFF;
          final b = p & 0xFF;
          if (b > r && g > r) {
            foundCyanEcho = true;
            break;
          }
        }
      }
      expect(foundCyanEcho, isTrue, reason: 'Echo 1 in chromaticRGB mode should feature cyan chromatic tint');
    });

    test('behindOnly preserves original foreground sprite pixels', () {
      const width = 24;
      const height = 24;
      final pixels = Uint32List(width * height);

      const spriteColor = 0xFF33CC33; // Green
      for (int y = 8; y <= 12; y++) {
        for (int x = 14; x <= 18; x++) {
          pixels[y * width + x] = spriteColor;
        }
      }

      final effect = ChromaticEchoDashEffect({
        'motionAngle': 0.0,
        'echoCount': 3.0,
        'trailDistance': 12.0,
        'behindOnly': true,
      });

      final result = effect.apply(Uint32List.fromList(pixels), width, height);

      for (int y = 8; y <= 12; y++) {
        for (int x = 14; x <= 18; x++) {
          expect(result[y * width + x], equals(spriteColor));
        }
      }
    });
  });
}
