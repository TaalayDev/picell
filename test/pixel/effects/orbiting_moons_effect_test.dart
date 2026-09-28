import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/fields/ui_field.dart';

void main() {
  group('OrbitingMoonsEffect', () {
    test('instantiates with default parameters and isAnimation is false', () {
      final effect = OrbitingMoonsEffect();
      expect(effect.type, equals(EffectType.orbitingMoons));
      expect(effect.isAnimation, isFalse);
      expect(effect.parameters['moonCount'], equals(3.0));
      expect(effect.parameters['orbitRadius'], equals(13.0));
      expect(effect.parameters['orbitTilt'], equals(15.0));
      expect(effect.parameters['showTracks'], isTrue);
      expect(effect.parameters['celestialPalette'], equals('terrestrialMoons'));
      expect(effect.parameters['behindOnly'], isFalse);
    });

    test('getFields returns strongly-typed UIField descriptors', () {
      final effect = OrbitingMoonsEffect();
      final fields = effect.getFields();

      expect(fields.any((f) => f.key == 'moonCount' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'orbitRadius' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'orbitTilt' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'showTracks' && f is BoolField), isTrue);
      expect(fields.any((f) => f.key == 'celestialPalette' && f is SelectField), isTrue);
      expect(fields.any((f) => f.key == 'behindOnly' && f is BoolField), isTrue);
    });

    test('EffectsManager creates and deserializes OrbitingMoonsEffect', () {
      final effect = EffectsManager.createEffect(
        EffectType.orbitingMoons,
        {
          'moonCount': 4.0,
          'orbitRadius': 16.0,
          'celestialPalette': 'gasGiantSatellites',
        },
      );
      expect(effect, isA<OrbitingMoonsEffect>());
      expect(effect.parameters['moonCount'], equals(4.0));
      expect(effect.parameters['orbitRadius'], equals(16.0));
      expect(effect.parameters['celestialPalette'], equals('gasGiantSatellites'));
    });

    test('renders spherical shaded moons and orbital guide tracks', () {
      const width = 36;
      const height = 36;
      final pixels = Uint32List(width * height);

      // 8x8 character square at center (14..21, 14..21)
      for (int y = 14; y <= 21; y++) {
        for (int x = 14; x <= 21; x++) {
          pixels[y * width + x] = 0xFF444444;
        }
      }

      final effect = OrbitingMoonsEffect({
        'moonCount': 3.0,
        'orbitRadius': 13.0,
        'orbitTilt': 15.0,
        'showTracks': true,
        'celestialPalette': 'terrestrialMoons',
        'behindOnly': false,
      });

      final result = effect.apply(Uint32List.fromList(pixels), width, height);

      int moonTrackPixelCount = 0;
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final isInside = (x >= 14 && x <= 21 && y >= 14 && y <= 21);
          final resA = (result[y * width + x] >> 24) & 0xFF;
          if (!isInside && resA > 0) {
            moonTrackPixelCount++;
          }
        }
      }

      expect(moonTrackPixelCount, greaterThan(30));
    });

    test('celestialPalette variations produce distinctive lunar and Jovian colors', () {
      const width = 30;
      const height = 30;
      final pixels = Uint32List(width * height);

      for (int y = 11; y <= 18; y++) {
        for (int x = 11; x <= 18; x++) {
          pixels[y * width + x] = 0xFF222222;
        }
      }

      final terrestrialEffect = OrbitingMoonsEffect({
        'celestialPalette': 'terrestrialMoons',
        'showTracks': false,
      });
      final jovianEffect = OrbitingMoonsEffect({
        'celestialPalette': 'gasGiantSatellites',
        'showTracks': false,
      });

      final terrResult = terrestrialEffect.apply(Uint32List.fromList(pixels), width, height);
      final jovResult = jovianEffect.apply(Uint32List.fromList(pixels), width, height);

      int terrSilverCount = 0;
      int jovGoldCount = 0;

      for (int i = 0; i < width * height; i++) {
        final tR = (terrResult[i] >> 16) & 0xFF;
        final tG = (terrResult[i] >> 8) & 0xFF;
        final tB = terrResult[i] & 0xFF;
        if (tR > 160 && tG > 160 && tB > 160) terrSilverCount++;

        final jR = (jovResult[i] >> 16) & 0xFF;
        final jG = (jovResult[i] >> 8) & 0xFF;
        final jB = jovResult[i] & 0xFF;
        if (jR > 200 && jG > 160 && jB < 100) jovGoldCount++;
      }

      expect(terrSilverCount, greaterThan(5));
      expect(jovGoldCount, greaterThan(5));
    });

    test('behindOnly preserves foreground sprite pixels without overwriting', () {
      const width = 30;
      const height = 30;
      final pixels = Uint32List(width * height);

      for (int y = 10; y <= 20; y++) {
        for (int x = 10; x <= 20; x++) {
          pixels[y * width + x] = 0xFF335577;
        }
      }

      final effect = OrbitingMoonsEffect({
        'orbitRadius': 8.0,
        'behindOnly': true,
      });

      final result = effect.apply(Uint32List.fromList(pixels), width, height);

      for (int y = 10; y <= 20; y++) {
        for (int x = 10; x <= 20; x++) {
          expect(result[y * width + x], equals(0xFF335577));
        }
      }
    });
  });
}
