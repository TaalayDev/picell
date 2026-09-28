import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/fields/ui_field.dart';

void main() {
  group('TacticalReticleEffect', () {
    test('instantiates with default parameters and isAnimation is false', () {
      final effect = TacticalReticleEffect();
      expect(effect.type, equals(EffectType.tacticalReticle));
      expect(effect.isAnimation, isFalse);
      expect(effect.parameters['bracketPadding'], equals(3.0));
      expect(effect.parameters['bracketLength'], equals(6.0));
      expect(effect.parameters['showCrosshairs'], isTrue);
      expect(effect.parameters['deadzoneRadius'], equals(6.0));
      expect(effect.parameters['showTelemetry'], isTrue);
      expect(effect.parameters['reticlePalette'], equals('cyberCyan'));
      expect(effect.parameters['behindOnly'], isFalse);
    });

    test('getFields returns strongly-typed UIField descriptors', () {
      final effect = TacticalReticleEffect();
      final fields = effect.getFields();

      expect(fields.any((f) => f.key == 'bracketPadding' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'bracketLength' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'showCrosshairs' && f is BoolField), isTrue);
      expect(fields.any((f) => f.key == 'deadzoneRadius' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'showTelemetry' && f is BoolField), isTrue);
      expect(fields.any((f) => f.key == 'reticlePalette' && f is SelectField), isTrue);
      expect(fields.any((f) => f.key == 'behindOnly' && f is BoolField), isTrue);
    });

    test('EffectsManager creates and deserializes TacticalReticleEffect', () {
      final effect = EffectsManager.createEffect(
        EffectType.tacticalReticle,
        {
          'bracketPadding': 4.0,
          'bracketLength': 8.0,
          'reticlePalette': 'targetingRed',
        },
      );
      expect(effect, isA<TacticalReticleEffect>());
      expect(effect.parameters['bracketPadding'], equals(4.0));
      expect(effect.parameters['bracketLength'], equals(8.0));
      expect(effect.parameters['reticlePalette'], equals('targetingRed'));
    });

    test('renders corner framing brackets, crosshairs, and telemetry around sprite', () {
      const width = 36;
      const height = 36;
      final pixels = Uint32List(width * height);

      // 10x10 character square at center (13..22, 13..22)
      for (int y = 13; y <= 22; y++) {
        for (int x = 13; x <= 22; x++) {
          pixels[y * width + x] = 0xFF555555;
        }
      }

      final effect = TacticalReticleEffect({
        'bracketPadding': 3.0,
        'bracketLength': 6.0,
        'showCrosshairs': true,
        'deadzoneRadius': 4.0,
        'showTelemetry': true,
        'reticlePalette': 'cyberCyan',
        'behindOnly': false,
      });

      final result = effect.apply(Uint32List.fromList(pixels), width, height);

      // Check that pixels outside the original 10x10 square now contain reticle elements
      int reticlePixelCount = 0;
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final isInsideSprite = (x >= 13 && x <= 22 && y >= 13 && y <= 22);
          final resA = (result[y * width + x] >> 24) & 0xFF;
          if (!isInsideSprite && resA > 0) {
            reticlePixelCount++;
          }
        }
      }

      expect(reticlePixelCount, greaterThan(20));
    });

    test('reticlePalette themes produce distinctive HUD colors', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      for (int y = 12; y <= 19; y++) {
        for (int x = 12; x <= 19; x++) {
          pixels[y * width + x] = 0xFF444444;
        }
      }

      final redEffect = TacticalReticleEffect({
        'bracketPadding': 2.0,
        'bracketLength': 5.0,
        'reticlePalette': 'targetingRed',
      });
      final greenEffect = TacticalReticleEffect({
        'bracketPadding': 2.0,
        'bracketLength': 5.0,
        'reticlePalette': 'matrixGreen',
      });

      final redResult = redEffect.apply(Uint32List.fromList(pixels), width, height);
      final greenResult = greenEffect.apply(Uint32List.fromList(pixels), width, height);

      int redDom = 0;
      int greenDom = 0;

      for (int i = 0; i < width * height; i++) {
        final rR = (redResult[i] >> 16) & 0xFF;
        final rG = (redResult[i] >> 8) & 0xFF;
        if (rR > 180 && rG < 80) redDom++;

        final gG = (greenResult[i] >> 8) & 0xFF;
        final gR = (greenResult[i] >> 16) & 0xFF;
        if (gG > 180 && gR < 80) greenDom++;
      }

      expect(redDom, greaterThan(5));
      expect(greenDom, greaterThan(5));
    });

    test('behindOnly preserves foreground sprite pixels without overwriting', () {
      const width = 30;
      const height = 30;
      final pixels = Uint32List(width * height);

      // Character block
      for (int y = 10; y <= 20; y++) {
        for (int x = 10; x <= 20; x++) {
          pixels[y * width + x] = 0xFF112233;
        }
      }

      final effect = TacticalReticleEffect({
        'bracketPadding': 1.0,
        'showCrosshairs': true,
        'deadzoneRadius': 2.0,
        'behindOnly': true,
      });

      final result = effect.apply(Uint32List.fromList(pixels), width, height);

      // Center character pixel should remain completely unchanged
      expect(result[15 * width + 15], equals(0xFF112233));
    });
  });
}
