import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/fields/ui_field.dart';

void main() {
  group('LinocutStampEffect', () {
    test('instantiates with default parameters and isAnimation is false', () {
      final effect = LinocutStampEffect();
      expect(effect.type, equals(EffectType.linocutStamp));
      expect(effect.isAnimation, isFalse);
      expect(effect.isPremium, isFalse);
      expect(effect.parameters['chiselGougeAngle'], equals(45.0));
      expect(effect.parameters['inkPressure'], equals(1.0));
      expect(effect.parameters['chatterNoise'], equals(0.4));
      expect(effect.parameters['inkColor'], equals('carbonBlack'));
      expect(effect.parameters['paperColor'], equals('warmWhite'));
      expect(effect.parameters['preserveAlpha'], isFalse);
    });

    test('getFields returns strongly-typed UIField descriptors', () {
      final effect = LinocutStampEffect();
      final fields = effect.getFields();

      expect(fields.any((f) => f.key == 'chiselGougeAngle' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'inkPressure' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'chatterNoise' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'inkColor' && f is SelectField), isTrue);
      expect(fields.any((f) => f.key == 'paperColor' && f is SelectField), isTrue);
      expect(fields.any((f) => f.key == 'preserveAlpha' && f is BoolField), isTrue);
    });

    test('EffectsManager creates and deserializes LinocutStampEffect', () {
      final effect = EffectsManager.createEffect(
        EffectType.linocutStamp,
        {
          'chiselGougeAngle': 60.0,
          'inkColor': 'vermilionRed',
          'paperColor': 'kraftPaper',
        },
      );
      expect(effect, isA<LinocutStampEffect>());
      expect(effect.parameters['chiselGougeAngle'], equals(60.0));
      expect(effect.parameters['inkColor'], equals('vermilionRed'));
      expect(effect.parameters['paperColor'], equals('kraftPaper'));
    });

    test('renders high-contrast linocut relief and gouge chatter on canvas', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      // Create half dark, half light image
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          pixels[y * width + x] = (x < 16) ? 0xFF101010 : 0xFFE0E0E0;
        }
      }

      final effect = LinocutStampEffect({
        'inkPressure': 1.0,
        'chatterNoise': 0.5,
        'preserveAlpha': false,
      });

      final out = effect.apply(pixels, width, height);

      int nonZeroPixels = 0;
      for (int i = 0; i < pixels.length; i++) {
        if (out[i] != 0) nonZeroPixels++;
      }
      expect(nonZeroPixels, equals(width * height));
    });

    test('inkColor and paperColor options alter output palettes', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);
      for (int i = 0; i < pixels.length; i++) {
        pixels[i] = 0xFF202020; // Inked relief
      }

      final black = LinocutStampEffect({
        'inkColor': 'carbonBlack',
        'paperColor': 'warmWhite',
        'preserveAlpha': false,
      }).apply(pixels, width, height);

      final red = LinocutStampEffect({
        'inkColor': 'vermilionRed',
        'paperColor': 'warmWhite',
        'preserveAlpha': false,
      }).apply(pixels, width, height);

      final kraft = LinocutStampEffect({
        'inkColor': 'carbonBlack',
        'paperColor': 'kraftPaper',
        'preserveAlpha': false,
      }).apply(pixels, width, height);

      bool diffBlackRed = false;
      bool diffBlackKraft = false;
      for (int i = 0; i < pixels.length; i++) {
        if (black[i] != red[i]) diffBlackRed = true;
        if (black[i] != kraft[i]) diffBlackKraft = true;
      }
      expect(diffBlackRed, isTrue);
      expect(diffBlackKraft, isTrue);
    });

    test('preserveAlpha restricts relief stamp within sprite silhouette', () {
      const width = 16;
      const height = 16;
      final pixels = Uint32List(width * height);

      // Create a 6x6 square in center
      for (int y = 5; y < 11; y++) {
        for (int x = 5; x < 11; x++) {
          pixels[y * width + x] = 0xFF202020;
        }
      }

      final effect = LinocutStampEffect({
        'preserveAlpha': true,
      });

      final out = effect.apply(pixels, width, height);

      // Pixels outside 6x6 must remain 0
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          if (x < 5 || x >= 11 || y < 5 || y >= 11) {
            expect(out[y * width + x], equals(0));
          }
        }
      }

      int nonZeroInside = 0;
      for (int y = 5; y < 11; y++) {
        for (int x = 5; x < 11; x++) {
          if (out[y * width + x] != 0) nonZeroInside++;
        }
      }
      expect(nonZeroInside, greaterThan(0));
    });
  });
}
