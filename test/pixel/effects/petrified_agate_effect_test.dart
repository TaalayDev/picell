import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/fields/ui_field.dart';

void main() {
  group('PetrifiedAgateEffect', () {
    test('instantiates with default parameters and isAnimation is false', () {
      final effect = PetrifiedAgateEffect();
      expect(effect.type, equals(EffectType.petrifiedAgate));
      expect(effect.isAnimation, isFalse);
      expect(effect.parameters['ringFrequency'], equals(6.0));
      expect(effect.parameters['agateBanding'], equals(0.75));
      expect(effect.parameters['druseCavityScale'], equals(0.4));
      expect(effect.parameters['mineralOxide'], equals(0.55));
      expect(effect.parameters['woodFiberGrain'], equals(0.5));
      expect(effect.parameters['agatePalette'], equals('arizonaRainbow'));
      expect(effect.parameters['preserveAlpha'], isTrue);
    });

    test('getFields returns strongly-typed UIField descriptors', () {
      final effect = PetrifiedAgateEffect();
      final fields = effect.getFields();

      expect(fields.any((f) => f.key == 'ringFrequency' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'agateBanding' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'druseCavityScale' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'mineralOxide' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'woodFiberGrain' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'agatePalette' && f is SelectField), isTrue);
      expect(fields.any((f) => f.key == 'preserveAlpha' && f is BoolField), isTrue);
    });

    test('EffectsManager creates and deserializes PetrifiedAgateEffect', () {
      final effect = EffectsManager.createEffect(
        EffectType.petrifiedAgate,
        {
          'ringFrequency': 8.0,
          'agatePalette': 'carnelianFire',
          'druseCavityScale': 0.6,
        },
      );
      expect(effect, isA<PetrifiedAgateEffect>());
      expect(effect.parameters['ringFrequency'], equals(8.0));
      expect(effect.parameters['agatePalette'], equals('carnelianFire'));
      expect(effect.parameters['druseCavityScale'], equals(0.6));
    });

    test('renders wood rings, chalcedony agate banding, and geode druse', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      // Solid color base on layer
      for (int i = 0; i < pixels.length; i++) {
        pixels[i] = 0xFF503020;
      }

      final effect = PetrifiedAgateEffect({
        'ringFrequency': 5.0,
        'agateBanding': 0.8,
        'druseCavityScale': 0.5,
        'agatePalette': 'carnelianFire',
        'preserveAlpha': true,
      });

      final out = effect.apply(pixels, width, height);

      int nonZeroCount = 0;
      for (int i = 0; i < pixels.length; i++) {
        if (out[i] != 0) nonZeroCount++;
      }
      expect(nonZeroCount, equals(width * height));
    });

    test('agatePalette variations produce distinct petrified fossil coloration', () {
      const width = 24;
      const height = 24;
      final pixels = Uint32List(width * height);
      for (int i = 0; i < pixels.length; i++) {
        pixels[i] = 0xFF404040;
      }

      final effectRainbow = PetrifiedAgateEffect({
        'agatePalette': 'arizonaRainbow',
        'preserveAlpha': true,
      });
      final effectCarnelian = PetrifiedAgateEffect({
        'agatePalette': 'carnelianFire',
        'preserveAlpha': true,
      });

      final outRainbow = effectRainbow.apply(pixels, width, height);
      final outCarnelian = effectCarnelian.apply(pixels, width, height);

      int diffCount = 0;
      for (int i = 0; i < pixels.length; i++) {
        if (outRainbow[i] != outCarnelian[i]) diffCount++;
      }
      expect(diffCount, greaterThan(0));
    });

    test('preserveAlpha restricts petrified agate texture strictly to existing layer pixels', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      // Center cross sprite on layer
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          if ((x >= 12 && x < 20) || (y >= 12 && y < 20)) {
            pixels[y * width + x] = 0xFF654321;
          }
        }
      }

      final effect = PetrifiedAgateEffect();

      final out = effect.apply(pixels, width, height);

      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final isInside = ((x >= 12 && x < 20) || (y >= 12 && y < 20));
          final a = (out[y * width + x] >> 24) & 0xFF;
          if (!isInside) {
            expect(a, equals(0), reason: 'Transparent pixels must remain transparent');
          } else {
            expect(a, equals(255), reason: 'Existing pixels must be textured');
          }
        }
      }
    });
  });
}
