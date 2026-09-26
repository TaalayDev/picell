import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/fields/ui_field.dart';

void main() {
  group('HangingIciclesEffect', () {
    test('instantiates with default parameters and isAnimation is false', () {
      final effect = HangingIciclesEffect();
      expect(effect.type, equals(EffectType.hangingIcicles));
      expect(effect.isAnimation, isFalse);
      expect(effect.isPremium, isFalse);
      expect(effect.parameters['frostCoverage'], equals(0.6));
      expect(effect.parameters['icicleLength'], equals(10.0));
      expect(effect.parameters['iceOpacity'], equals(0.85));
      expect(effect.parameters['crystalPalette'], equals('arcticCyan'));
      expect(effect.parameters['drippingDrops'], isTrue);
      expect(effect.parameters['glintSparkles'], isTrue);
    });

    test('getFields returns strongly-typed UIField descriptors', () {
      final effect = HangingIciclesEffect();
      final fields = effect.getFields();

      expect(fields.any((f) => f.key == 'frostCoverage' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'icicleLength' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'iceOpacity' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'crystalPalette' && f is SelectField), isTrue);
      expect(fields.any((f) => f.key == 'drippingDrops' && f is BoolField), isTrue);
      expect(fields.any((f) => f.key == 'glintSparkles' && f is BoolField), isTrue);
    });

    test('EffectsManager creates and deserializes HangingIciclesEffect', () {
      final effect = EffectsManager.createEffect(
        EffectType.hangingIcicles,
        {
          'frostCoverage': 0.8,
          'icicleLength': 14.0,
          'crystalPalette': 'frozenLilac',
        },
      );
      expect(effect, isA<HangingIciclesEffect>());
      expect(effect.parameters['frostCoverage'], equals(0.8));
      expect(effect.parameters['icicleLength'], equals(14.0));
      expect(effect.parameters['crystalPalette'], equals('frozenLilac'));
    });

    test('grows downward hanging icicle spikes beneath lower overhang edges', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);

      // Horizontal overhang ledge across the middle (x: 8..24, y: 10..14)
      for (int y = 10; y <= 14; y++) {
        for (int x = 8; x <= 24; x++) {
          pixels[y * width + x] = 0xFF444444; // rock ledge
        }
      }

      final effect = HangingIciclesEffect({
        'frostCoverage': 0.0, // disable top frost to test overhang icicles independently
        'icicleLength': 8.0,
        'iceOpacity': 1.0,
        'crystalPalette': 'arcticCyan',
        'drippingDrops': false,
        'glintSparkles': false,
      });

      final result = effect.apply(Uint32List.fromList(pixels), width, height);

      // Verify that beneath the ledge (y in 15..22, x in 8..24) icicles hang downward
      bool foundHangingIcicle = false;
      for (int y = 15; y <= 22; y++) {
        for (int x = 8; x <= 24; x++) {
          final p = result[y * width + x];
          if (((p >> 24) & 0xFF) > 0) {
            foundHangingIcicle = true;
            break;
          }
        }
        if (foundHangingIcicle) break;
      }
      expect(foundHangingIcicle, isTrue, reason: 'Downward icicle spikes should hang beneath overhang ledge');
    });

    test('top frost coverage applies crystalline frost crust above upward-facing surface', () {
      const width = 24;
      const height = 24;
      final pixels = Uint32List(width * height);

      // 6x6 block at (8..13, 12..17)
      for (int y = 12; y <= 17; y++) {
        for (int x = 8; x <= 13; x++) {
          pixels[y * width + x] = 0xFF555555;
        }
      }

      final effect = HangingIciclesEffect({
        'frostCoverage': 1.0, // full coverage
        'icicleLength': 4.0,
        'iceOpacity': 0.9,
      });

      final result = effect.apply(Uint32List.fromList(pixels), width, height);

      // The pixel right above the top surface (y = 11, x in 8..13) should have frost crust
      bool foundFrostCap = false;
      for (int x = 8; x <= 13; x++) {
        final p = result[11 * width + x];
        if (((p >> 24) & 0xFF) > 0) {
          foundFrostCap = true;
          break;
        }
      }
      expect(foundFrostCap, isTrue, reason: 'Crystalline frost crust should form above top-facing surfaces');
    });

    test('frozenLilac palette applies purple and lilac rime colors', () {
      const width = 24;
      const height = 24;
      final pixels = Uint32List(width * height);

      // Ledge at y in 8..11, x in 6..18
      for (int y = 8; y <= 11; y++) {
        for (int x = 6; x <= 18; x++) {
          pixels[y * width + x] = 0xFF333333;
        }
      }

      final effect = HangingIciclesEffect({
        'frostCoverage': 0.0,
        'icicleLength': 6.0,
        'iceOpacity': 1.0,
        'crystalPalette': 'frozenLilac',
        'glintSparkles': false,
        'drippingDrops': false,
      });

      final result = effect.apply(Uint32List.fromList(pixels), width, height);

      // In frozenLilac, core/shadow has prominent red/blue components (lilac/purple)
      bool foundLilacTint = false;
      for (int y = 12; y <= 16; y++) {
        for (int x = 6; x <= 18; x++) {
          final p = result[y * width + x];
          final a = (p >> 24) & 0xFF;
          if (a > 50) {
            final r = (p >> 16) & 0xFF;
            final b = p & 0xFF;
            if (r > 60 && b > 100) {
              foundLilacTint = true;
              break;
            }
          }
        }
        if (foundLilacTint) break;
      }
      expect(foundLilacTint, isTrue, reason: 'frozenLilac palette should yield purple/lilac tinted icicle spikes');
    });
  });
}
