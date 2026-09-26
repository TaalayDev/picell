import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/fields/ui_field.dart';

void main() {
  group('DangerAlarmEffect', () {
    test('instantiates with default parameters and isAnimation is true', () {
      final effect = DangerAlarmEffect();
      expect(effect.type, equals(EffectType.dangerAlarm));
      expect(effect.isAnimation, isTrue);
      expect(effect.isPremium, isFalse);
      expect(effect.parameters['pulseBPM'], equals(120.0));
      expect(effect.parameters['vignetteThickness'], equals(0.45));
      expect(effect.parameters['alarmColor'], equals(0xFFFF1744));
      expect(effect.parameters['monochromeDepth'], equals(0.5));
      expect(effect.parameters['doublePulse'], isTrue);
      expect(effect.parameters['time'], equals(0.0));
      expect(effect.parameters['preserveAlpha'], isTrue);
    });

    test('getFields returns strongly-typed UIField descriptors', () {
      final effect = DangerAlarmEffect();
      final fields = effect.getFields();

      expect(fields.any((f) => f.key == 'pulseBPM' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'vignetteThickness' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'alarmColor' && f is ColorField), isTrue);
      expect(fields.any((f) => f.key == 'monochromeDepth' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'doublePulse' && f is BoolField), isTrue);
      expect(fields.any((f) => f.key == 'time' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'preserveAlpha' && f is BoolField), isTrue);
    });

    test('EffectsManager creates and deserializes DangerAlarmEffect', () {
      final effect = EffectsManager.createEffect(
        EffectType.dangerAlarm,
        {
          'pulseBPM': 140.0,
          'vignetteThickness': 0.6,
          'alarmColor': 0xFFFF9100,
        },
      );
      expect(effect, isA<DangerAlarmEffect>());
      expect(effect.parameters['pulseBPM'], equals(140.0));
      expect(effect.parameters['vignetteThickness'], equals(0.6));
      expect(effect.parameters['alarmColor'], equals(0xFFFF9100));
    });

    test('applies pulsing danger vignette and monochrome desaturation', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);
      for (int i = 0; i < pixels.length; i++) {
        // High saturation green
        pixels[i] = 0xFF00FF00;
      }

      final effect = DangerAlarmEffect({
        'pulseBPM': 120.0,
        'vignetteThickness': 0.5,
        'monochromeDepth': 0.8,
        'time': 0.05, // Peak systolic beat
        'preserveAlpha': true,
      });

      final out = effect.apply(pixels, width, height);

      int changedPixels = 0;
      for (int i = 0; i < pixels.length; i++) {
        if (out[i] != 0xFF00FF00) {
          changedPixels++;
        }
      }
      expect(changedPixels, greaterThan(0));
    });

    test('cardiac time cycle modulates pulse peak and trough', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height);
      for (int i = 0; i < pixels.length; i++) {
        pixels[i] = 0xFF00FF00;
      }

      // time = 0.02 (systolic peak) vs time = 0.20 (trough between beats)
      final effectPeak = DangerAlarmEffect({'time': 0.02, 'pulseBPM': 60.0, 'preserveAlpha': false});
      final effectTrough = DangerAlarmEffect({'time': 0.35, 'pulseBPM': 60.0, 'preserveAlpha': false});

      final outPeak = effectPeak.apply(pixels, width, height);
      final outTrough = effectTrough.apply(pixels, width, height);

      bool differenceDetected = false;
      for (int i = 0; i < pixels.length; i++) {
        if (outPeak[i] != outTrough[i]) {
          differenceDetected = true;
          break;
        }
      }
      expect(differenceDetected, isTrue);
    });

    test('respects preserveAlpha and does not affect transparent pixels', () {
      const width = 32;
      const height = 32;
      final pixels = Uint32List(width * height); // All transparent

      final effect = DangerAlarmEffect({
        'time': 0.05,
        'preserveAlpha': true,
      });

      final out = effect.apply(pixels, width, height);
      for (int i = 0; i < pixels.length; i++) {
        expect((out[i] >> 24) & 0xFF, equals(0));
      }
    });
  });
}
