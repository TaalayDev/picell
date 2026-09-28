import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/fields/ui_field.dart';

void main() {
  group('DirectionalMotionBlurEffect', () {
    test('instantiates with default parameters and isAnimation is false', () {
      final effect = DirectionalMotionBlurEffect();
      expect(effect.type, equals(EffectType.directionalMotionBlur));
      expect(effect.isAnimation, isFalse);
      expect(effect.parameters['blurLength'], equals(6.0));
      expect(effect.parameters['angle'], equals(0.0));
      expect(effect.parameters['blurProfile'], equals('trailing'));
      expect(effect.parameters['intensity'], equals(0.75));
      expect(effect.parameters['preserveAlpha'], isTrue);
    });

    test('getFields returns strongly-typed UIField descriptors', () {
      final effect = DirectionalMotionBlurEffect();
      final fields = effect.getFields();

      expect(fields.any((f) => f.key == 'blurLength' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'angle' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'blurProfile' && f is SelectField), isTrue);
      expect(fields.any((f) => f.key == 'intensity' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'preserveAlpha' && f is BoolField), isTrue);
    });

    test('EffectsManager creates and deserializes DirectionalMotionBlurEffect', () {
      final effect = EffectsManager.createEffect(
        EffectType.directionalMotionBlur,
        {
          'blurLength': 12.0,
          'angle': 90.0,
          'blurProfile': 'symmetric',
        },
      );
      expect(effect, isA<DirectionalMotionBlurEffect>());
      expect(effect.parameters['blurLength'], equals(12.0));
      expect(effect.parameters['angle'], equals(90.0));
      expect(effect.parameters['blurProfile'], equals('symmetric'));
    });

    test('directional blur smears pixels along angle vector', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      // Single bright vertical line in center (x = 16)
      for (int y = 0; y < height; y++) {
        pixels[y * width + 16] = 0xFFFFFFFF;
      }

      final effect = DirectionalMotionBlurEffect({
        'blurLength': 8.0,
        'angle': 0.0, // horizontal blur
        'blurProfile': 'trailing',
        'intensity': 1.0,
        'preserveAlpha': false,
      });

      final result = effect.apply(Uint32List.fromList(pixels), width, height);

      // When moving rightward (angle 0), trailing samples backwards (-x),
      // so pixels at x > 16 should drag color from x = 16.
      bool foundStreak = false;
      for (int x = 17; x <= 24; x++) {
        final color = result[16 * width + x];
        if (((color >> 24) & 0xFF) > 0) {
          foundStreak = true;
          break;
        }
      }
      expect(foundStreak, isTrue, reason: 'Pixels to the right should receive velocity blur streak');
    });

    test('blur profiles trailing vs symmetric produce distinct streak distributions', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      // Single white pixel at (16, 16)
      pixels[16 * width + 16] = 0xFFFFFFFF;

      final trailingEffect = DirectionalMotionBlurEffect({
        'blurLength': 6.0,
        'angle': 0.0,
        'blurProfile': 'trailing',
        'intensity': 1.0,
        'preserveAlpha': false,
      });

      final symmetricEffect = DirectionalMotionBlurEffect({
        'blurLength': 6.0,
        'angle': 0.0,
        'blurProfile': 'symmetric',
        'intensity': 1.0,
        'preserveAlpha': false,
      });

      final outTrailing = trailingEffect.apply(Uint32List.fromList(pixels), width, height);
      final outSymmetric = symmetricEffect.apply(Uint32List.fromList(pixels), width, height);

      // For symmetric blur, pixels to the left (e.g. x = 14) receive blur.
      // For trailing blur with angle 0, pixels to the left (x = 14) do NOT sample from x = 16.
      final aSymLeft = (outSymmetric[16 * width + 14] >> 24) & 0xFF;
      final aTrailLeft = (outTrailing[16 * width + 14] >> 24) & 0xFF;

      expect(aSymLeft, greaterThan(0));
      expect(aTrailLeft, equals(0));
    });

    test('preserveAlpha strictly confines blur to layer pixels and keeps empty space transparent', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      // 4x4 block in center
      for (int y = 14; y < 18; y++) {
        for (int x = 14; x < 18; x++) {
          pixels[y * width + x] = 0xFF44AAFF;
        }
      }

      final effect = DirectionalMotionBlurEffect({
        'blurLength': 10.0,
        'angle': 45.0,
        'blurProfile': 'trailing',
        'intensity': 0.8,
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
