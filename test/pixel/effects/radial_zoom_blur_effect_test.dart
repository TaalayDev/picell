import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/fields/ui_field.dart';

void main() {
  group('RadialZoomBlurEffect', () {
    test('instantiates with default parameters and isAnimation is false', () {
      final effect = RadialZoomBlurEffect();
      expect(effect.type, equals(EffectType.radialZoomBlur));
      expect(effect.isAnimation, isFalse);
      expect(effect.parameters['focalCenterX'], equals(0.5));
      expect(effect.parameters['focalCenterY'], equals(0.5));
      expect(effect.parameters['zoomStrength'], equals(0.45));
      expect(effect.parameters['deadzoneRadius'], equals(0.15));
      expect(effect.parameters['blurDirection'], equals('zoomOut'));
      expect(effect.parameters['sampleCount'], equals(10.0));
      expect(effect.parameters['preserveAlpha'], isTrue);
    });

    test('getFields returns strongly-typed UIField descriptors', () {
      final effect = RadialZoomBlurEffect();
      final fields = effect.getFields();

      expect(fields.any((f) => f.key == 'focalCenterX' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'focalCenterY' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'zoomStrength' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'deadzoneRadius' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'blurDirection' && f is SelectField), isTrue);
      expect(fields.any((f) => f.key == 'sampleCount' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'preserveAlpha' && f is BoolField), isTrue);
    });

    test('EffectsManager creates and deserializes RadialZoomBlurEffect', () {
      final effect = EffectsManager.createEffect(
        EffectType.radialZoomBlur,
        {
          'focalCenterX': 0.25,
          'zoomStrength': 0.8,
          'deadzoneRadius': 0.1,
          'blurDirection': 'zoomIn',
        },
      );
      expect(effect, isA<RadialZoomBlurEffect>());
      expect(effect.parameters['focalCenterX'], equals(0.25));
      expect(effect.parameters['zoomStrength'], equals(0.8));
      expect(effect.parameters['deadzoneRadius'], equals(0.1));
      expect(effect.parameters['blurDirection'], equals('zoomIn'));
    });

    test('deadzone preserves inner pixels 100% crisp without modification', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      // Gradient pattern across entire canvas
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          pixels[y * width + x] = 0xFF000000 | (x << 16) | (y << 8) | 0x88;
        }
      }

      final effect = RadialZoomBlurEffect({
        'focalCenterX': 0.5, // (16, 16)
        'focalCenterY': 0.5,
        'zoomStrength': 0.8,
        'deadzoneRadius': 0.25, // deadzone radius around center
        'blurDirection': 'zoomOut',
        'sampleCount': 12.0,
        'preserveAlpha': false,
      });

      final result = effect.apply(Uint32List.fromList(pixels), width, height);

      // Pixels immediately adjacent to center (16, 16) inside deadzone must match original exactly
      expect(result[16 * width + 16], equals(pixels[16 * width + 16]));
      expect(result[16 * width + 17], equals(pixels[16 * width + 17]));
      expect(result[15 * width + 16], equals(pixels[15 * width + 16]));
    });

    test('outer pixels outside deadzone receive radial zoom streak', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      // High-contrast concentric stripes
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final int dist = ((x - 16) * (x - 16) + (y - 16) * (y - 16));
          pixels[y * width + x] = (dist % 16 < 8) ? 0xFFFFFFFF : 0xFF112233;
        }
      }

      final effect = RadialZoomBlurEffect({
        'focalCenterX': 0.5,
        'focalCenterY': 0.5,
        'zoomStrength': 0.8,
        'deadzoneRadius': 0.05,
        'blurDirection': 'zoomOut',
        'sampleCount': 10.0,
        'preserveAlpha': false,
      });

      final result = effect.apply(Uint32List.fromList(pixels), width, height);

      // Check differences at outer perimeter
      int diffCount = 0;
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          if (x < 6 || x > 26 || y < 6 || y > 26) {
            if (result[y * width + x] != pixels[y * width + x]) {
              diffCount++;
            }
          }
        }
      }
      expect(diffCount, greaterThan(0), reason: 'Outer pixels should be radially blurred');
    });

    test('preserveAlpha strictly confines blur to layer pixels and keeps empty space transparent', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      // Center 6x6 sprite
      for (int y = 13; y < 19; y++) {
        for (int x = 13; x < 19; x++) {
          pixels[y * width + x] = 0xFFFF5533;
        }
      }

      final effect = RadialZoomBlurEffect({
        'focalCenterX': 0.5,
        'focalCenterY': 0.5,
        'zoomStrength': 0.9,
        'deadzoneRadius': 0.05,
        'blurDirection': 'zoomOut',
        'sampleCount': 14.0,
        'preserveAlpha': true,
      });

      final result = effect.apply(Uint32List.fromList(pixels), width, height);

      // Every transparent pixel in original must remain transparent
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final orig = pixels[y * width + x];
          final origA = (orig >> 24) & 0xFF;
          final resA = (result[y * width + x] >> 24) & 0xFF;

          if (origA == 0) {
            expect(resA, equals(0), reason: 'Transparent canvas background at ($x, $y) must not be filled');
          }
        }
      }
    });
  });
}
