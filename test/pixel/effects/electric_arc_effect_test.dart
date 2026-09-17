import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/fields/ui_field.dart';

void main() {
  group('ElectricArcEffect', () {
    test('instantiates with default parameters and isAnimation is true', () {
      final effect = ElectricArcEffect();
      expect(effect.type, equals(EffectType.electricArc));
      expect(effect.isAnimation, isTrue);
      expect(effect.isPremium, isFalse);
      expect(effect.parameters['strikeMode'], equals('vertical'));
      expect(effect.parameters['arcColor'], equals(0xFF00E5FF));
      expect(effect.parameters['branching'], equals(0.6));
      expect(effect.parameters['jaggedness'], equals(0.8));
      expect(effect.parameters['glowRadius'], equals(2));
      expect(effect.parameters['flashIntensity'], equals(0.3));
      expect(effect.parameters['time'], equals(0.0));
      expect(effect.parameters['preserveAlpha'], isTrue);
    });

    test('getFields returns strongly-typed UIField descriptors', () {
      final effect = ElectricArcEffect();
      final fields = effect.getFields();

      expect(fields.any((f) => f.key == 'strikeMode' && f is SelectField), isTrue);
      expect(fields.any((f) => f.key == 'arcColor' && f is ColorField), isTrue);
      expect(fields.any((f) => f.key == 'branching' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'jaggedness' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'glowRadius' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'flashIntensity' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'time' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'preserveAlpha' && f is BoolField), isTrue);
    });

    test('EffectsManager creates and deserializes ElectricArcEffect', () {
      final effect = EffectsManager.createEffect(
        EffectType.electricArc,
        {
          'strikeMode': 'radial',
          'arcColor': 0xFFFFD700,
          'branching': 0.8,
        },
      );
      expect(effect, isA<ElectricArcEffect>());
      expect(effect.parameters['strikeMode'], equals('radial'));
      expect(effect.parameters['arcColor'], equals(0xFFFFD700));
      expect(effect.parameters['branching'], equals(0.8));
    });

    test('renders white core and plasma aura pixels', () {
      const width = 16;
      const height = 16;
      final pixels = Uint32List(width * height);

      final effect = ElectricArcEffect({
        'strikeMode': 'vertical',
        'arcColor': 0xFF00E5FF,
        'glowRadius': 2,
        'flashIntensity': 0.0,
        'time': 0.0,
        'preserveAlpha': true,
      });

      final out = effect.apply(pixels, width, height);

      // Must contain high-voltage white core
      final hasCore = out.any((p) => p == 0xFFFFFFFF);
      expect(hasCore, isTrue);

      // Must contain colored plasma aura (blue/cyan tint)
      final hasAura = out.any((p) {
        final a = (p >> 24) & 0xFF;
        final b = p & 0xFF;
        return a > 0 && b > 100 && p != 0xFFFFFFFF;
      });
      expect(hasAura, isTrue);
    });

    test('time parameter advances strike animation jitter and path', () {
      const width = 16;
      const height = 16;
      final pixels = Uint32List(width * height);

      final t0 = ElectricArcEffect({
        'strikeMode': 'vertical',
        'time': 0.0,
        'preserveAlpha': true,
      });

      final tNext = ElectricArcEffect({
        'strikeMode': 'vertical',
        'time': 0.4,
        'preserveAlpha': true,
      });

      final out0 = t0.apply(pixels, width, height);
      final outNext = tNext.apply(pixels, width, height);

      expect(outNext, isNot(equals(out0)));
    });

    test('radial strike mode bursts from center outward', () {
      const width = 16;
      const height = 16;
      final pixels = Uint32List(width * height);

      final effect = ElectricArcEffect({
        'strikeMode': 'radial',
        'flashIntensity': 0.0,
        'time': 0.0,
        'preserveAlpha': true,
      });

      final out = effect.apply(pixels, width, height);

      // Center pixel area should be energized
      const cx = 8;
      const cy = 8;
      final centerPixel = out[cy * width + cx];
      expect((centerPixel >> 24) & 0xFF, greaterThan(0));
    });

    test('preserveAlpha: false fills background with dark stormy sky', () {
      const width = 8;
      const height = 8;
      final pixels = Uint32List(width * height);

      final effect = ElectricArcEffect({
        'preserveAlpha': false,
      });

      final out = effect.apply(pixels, width, height);
      for (final p in out) {
        expect((p >> 24) & 0xFF, equals(255));
      }
    });
  });
}
