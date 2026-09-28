import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/fields/ui_field.dart';

void main() {
  group('SupernovaCoronaEffect', () {
    test('instantiates with default parameters and isAnimation is false', () {
      final effect = SupernovaCoronaEffect();
      expect(effect.type, equals(EffectType.supernovaCorona));
      expect(effect.isAnimation, isFalse);
      expect(effect.parameters['coronaRadius'], equals(10.0));
      expect(effect.parameters['spikeLength'], equals(16.0));
      expect(effect.parameters['spikePattern'], equals('cross4'));
      expect(effect.parameters['prominences'], isTrue);
      expect(effect.parameters['coronaPalette'], equals('solarWhite'));
      expect(effect.parameters['behindOnly'], isFalse);
    });

    test('getFields returns strongly-typed UIField descriptors', () {
      final effect = SupernovaCoronaEffect();
      final fields = effect.getFields();

      expect(fields.any((f) => f.key == 'coronaRadius' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'spikeLength' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'spikePattern' && f is SelectField), isTrue);
      expect(fields.any((f) => f.key == 'prominences' && f is BoolField), isTrue);
      expect(fields.any((f) => f.key == 'coronaPalette' && f is SelectField), isTrue);
      expect(fields.any((f) => f.key == 'behindOnly' && f is BoolField), isTrue);
    });

    test('EffectsManager creates and deserializes SupernovaCoronaEffect', () {
      final effect = EffectsManager.createEffect(
        EffectType.supernovaCorona,
        {
          'coronaRadius': 12.0,
          'spikeLength': 20.0,
          'spikePattern': 'star8',
          'coronaPalette': 'hypernovaBlue',
        },
      );
      expect(effect, isA<SupernovaCoronaEffect>());
      expect(effect.parameters['coronaRadius'], equals(12.0));
      expect(effect.parameters['spikeLength'], equals(20.0));
      expect(effect.parameters['spikePattern'], equals('star8'));
      expect(effect.parameters['coronaPalette'], equals('hypernovaBlue'));
    });

    test('renders solar corona, diffraction spikes, and prominences', () {
      const width = 36;
      const height = 36;
      final pixels = Uint32List(width * height);

      // 8x8 character square at center (14..21, 14..21)
      for (int y = 14; y <= 21; y++) {
        for (int x = 14; x <= 21; x++) {
          pixels[y * width + x] = 0xFF555555;
        }
      }

      final effect = SupernovaCoronaEffect({
        'coronaRadius': 10.0,
        'spikeLength': 16.0,
        'spikePattern': 'cross4',
        'prominences': true,
        'coronaPalette': 'solarWhite',
        'behindOnly': false,
      });

      final result = effect.apply(Uint32List.fromList(pixels), width, height);

      // Verify that starlight elements render into surrounding space
      int flarePixelCount = 0;
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final isInside = (x >= 14 && x <= 21 && y >= 14 && y <= 21);
          final resA = (result[y * width + x] >> 24) & 0xFF;
          if (!isInside && resA > 0) {
            flarePixelCount++;
          }
        }
      }

      expect(flarePixelCount, greaterThan(40));
    });

    test('coronaPalette variations produce distinctive white and blue spectral colors', () {
      const width = 30;
      const height = 30;
      final pixels = Uint32List(width * height);

      for (int y = 11; y <= 18; y++) {
        for (int x = 11; x <= 18; x++) {
          pixels[y * width + x] = 0xFF333333;
        }
      }

      final solarEffect = SupernovaCoronaEffect({
        'coronaRadius': 8.0,
        'spikeLength': 12.0,
        'coronaPalette': 'solarWhite',
      });
      final blueEffect = SupernovaCoronaEffect({
        'coronaRadius': 8.0,
        'spikeLength': 12.0,
        'coronaPalette': 'hypernovaBlue',
      });

      final solarResult = solarEffect.apply(Uint32List.fromList(pixels), width, height);
      final blueResult = blueEffect.apply(Uint32List.fromList(pixels), width, height);

      int solarWarmCount = 0;
      int blueCoolCount = 0;

      for (int i = 0; i < width * height; i++) {
        final sR = (solarResult[i] >> 16) & 0xFF;
        final sG = (solarResult[i] >> 8) & 0xFF;
        final sB = solarResult[i] & 0xFF;
        if (sR > 200 && sG > 180 && sB < 150) solarWarmCount++;

        final bR = (blueResult[i] >> 16) & 0xFF;
        final bG = (blueResult[i] >> 8) & 0xFF;
        final bB = blueResult[i] & 0xFF;
        if (bB > 200 && bG > 150 && bR < 180) blueCoolCount++;
      }

      expect(solarWarmCount, greaterThan(10));
      expect(blueCoolCount, greaterThan(10));
    });

    test('behindOnly preserves foreground sprite pixels without overwriting', () {
      const width = 30;
      const height = 30;
      final pixels = Uint32List(width * height);

      for (int y = 10; y <= 20; y++) {
        for (int x = 10; x <= 20; x++) {
          pixels[y * width + x] = 0xFF223344;
        }
      }

      final effect = SupernovaCoronaEffect({
        'coronaRadius': 8.0,
        'behindOnly': true,
      });

      final result = effect.apply(Uint32List.fromList(pixels), width, height);

      for (int y = 10; y <= 20; y++) {
        for (int x = 10; x <= 20; x++) {
          expect(result[y * width + x], equals(0xFF223344));
        }
      }
    });
  });
}
