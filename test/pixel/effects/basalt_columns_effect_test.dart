import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/fields/ui_field.dart';

void main() {
  group('BasaltColumnsEffect', () {
    test('instantiates with default parameters and isAnimation is true', () {
      final effect = BasaltColumnsEffect();
      expect(effect.type, equals(EffectType.basaltColumns));
      expect(effect.isAnimation, isTrue);
      expect(effect.isPremium, isFalse);
      expect(effect.parameters['columnScale'], equals(8));
      expect(effect.parameters['heightVariation'], equals(0.5));
      expect(effect.parameters['hexBevel'], equals(0.6));
      expect(effect.parameters['lavaSeepage'], isTrue);
      expect(effect.parameters['columnTexture'], equals('volcanicBasalt'));
      expect(effect.parameters['time'], equals(0.0));
      expect(effect.parameters['preserveAlpha'], isFalse);
    });

    test('getFields returns strongly-typed UIField descriptors', () {
      final effect = BasaltColumnsEffect();
      final fields = effect.getFields();

      expect(fields.any((f) => f.key == 'columnScale' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'heightVariation' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'hexBevel' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'lavaSeepage' && f is BoolField), isTrue);
      expect(fields.any((f) => f.key == 'columnTexture' && f is SelectField), isTrue);
      expect(fields.any((f) => f.key == 'time' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'preserveAlpha' && f is BoolField), isTrue);
    });

    test('EffectsManager creates and deserializes BasaltColumnsEffect', () {
      final effect = EffectsManager.createEffect(
        EffectType.basaltColumns,
        {
          'columnScale': 10,
          'columnTexture': 'obsidianGlass',
          'hexBevel': 0.8,
        },
      );
      expect(effect, isA<BasaltColumnsEffect>());
      expect(effect.parameters['columnScale'], equals(10));
      expect(effect.parameters['columnTexture'], equals('obsidianGlass'));
      expect(effect.parameters['hexBevel'], equals(0.8));
    });

    test('renders interlocking hexagonal basalt columns and bevels on canvas', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      final effect = BasaltColumnsEffect({
        'columnScale': 8,
        'heightVariation': 0.5,
        'hexBevel': 0.6,
        'lavaSeepage': true,
        'preserveAlpha': false,
      });

      final out = effect.apply(pixels, width, height);

      int nonZeroPixels = 0;
      for (int i = 0; i < pixels.length; i++) {
        if (out[i] != 0) {
          nonZeroPixels++;
        }
      }
      expect(nonZeroPixels, greaterThan(0));
    });

    test('renders different stone textures (volcanicBasalt vs ancientMoss)', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      final effectBasalt = BasaltColumnsEffect({
        'columnTexture': 'volcanicBasalt',
        'preserveAlpha': false,
      });
      final effectMoss = BasaltColumnsEffect({
        'columnTexture': 'ancientMoss',
        'preserveAlpha': false,
      });

      final outBasalt = effectBasalt.apply(pixels, width, height);
      final outMoss = effectMoss.apply(pixels, width, height);

      bool differenceDetected = false;
      for (int i = 0; i < pixels.length; i++) {
        if (outBasalt[i] != outMoss[i]) {
          differenceDetected = true;
          break;
        }
      }
      expect(differenceDetected, isTrue);
    });

    test('time animation drives thermal magma seepage pulsation', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      final effect1 = BasaltColumnsEffect({
        'lavaSeepage': true,
        'time': 0.1,
        'preserveAlpha': false,
      });
      final effect2 = BasaltColumnsEffect({
        'lavaSeepage': true,
        'time': 0.6,
        'preserveAlpha': false,
      });

      final out1 = effect1.apply(pixels, width, height);
      final out2 = effect2.apply(pixels, width, height);

      bool differenceDetected = false;
      for (int i = 0; i < pixels.length; i++) {
        if (out1[i] != out2[i]) {
          differenceDetected = true;
          break;
        }
      }
      expect(differenceDetected, isTrue);
    });
  });
}
