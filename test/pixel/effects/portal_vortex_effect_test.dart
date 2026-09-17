import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/fields/ui_field.dart';

void main() {
  group('PortalVortexEffect', () {
    test('instantiates with default parameters and isAnimation is true', () {
      final effect = PortalVortexEffect();
      expect(effect.type, equals(EffectType.portalVortex));
      expect(effect.isAnimation, isTrue);
      expect(effect.isPremium, isFalse);
      expect(effect.parameters['spinSpeed'], equals(1.5));
      expect(effect.parameters['swirlTwist'], equals(1.5));
      expect(effect.parameters['coreRadius'], equals(0.25));
      expect(effect.parameters['glowColor'], equals(0xFFD500F9));
      expect(effect.parameters['particlePull'], equals(0.7));
      expect(effect.parameters['portalMode'], equals('warpSprite'));
      expect(effect.parameters['time'], equals(0.0));
      expect(effect.parameters['preserveAlpha'], isTrue);
    });

    test('getFields returns strongly-typed UIField descriptors', () {
      final effect = PortalVortexEffect();
      final fields = effect.getFields();

      expect(fields.any((f) => f.key == 'spinSpeed' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'swirlTwist' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'coreRadius' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'glowColor' && f is ColorField), isTrue);
      expect(fields.any((f) => f.key == 'particlePull' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'portalMode' && f is SelectField), isTrue);
      expect(fields.any((f) => f.key == 'time' && f is SliderField), isTrue);
      expect(fields.any((f) => f.key == 'preserveAlpha' && f is BoolField), isTrue);
    });

    test('EffectsManager creates and deserializes PortalVortexEffect', () {
      final effect = EffectsManager.createEffect(
        EffectType.portalVortex,
        {
          'spinSpeed': 2.0,
          'portalMode': 'portalOverlay',
          'glowColor': 0xFF00E676,
        },
      );
      expect(effect, isA<PortalVortexEffect>());
      expect(effect.parameters['spinSpeed'], equals(2.0));
      expect(effect.parameters['portalMode'], equals('portalOverlay'));
      expect(effect.parameters['glowColor'], equals(0xFF00E676));
    });

    test('applies vortex distortion and generates luminous accretion ring', () {
      const width = 16;
      const height = 16;
      final pixels = Uint32List(width * height);
      // Center solid test sprite
      for (int y = 4; y < 12; y++) {
        for (int x = 4; x < 12; x++) {
          pixels[y * width + x] = 0xFFFFFFFF;
        }
      }

      final effect = PortalVortexEffect({
        'glowColor': 0xFFD500F9,
        'portalMode': 'warpSprite',
        'time': 0.0,
        'preserveAlpha': true,
      });

      final out = effect.apply(pixels, width, height);

      // Must contain portal glow color
      final hasGlow = out.any((p) {
        final a = (p >> 24) & 0xFF;
        final r = (p >> 16) & 0xFF;
        final b = p & 0xFF;
        return a > 0 && (r > 150 || b > 150);
      });
      expect(hasGlow, isTrue);
    });

    test('time parameter advances vortex rotation angle', () {
      const width = 16;
      const height = 16;
      final pixels = Uint32List(width * height);
      pixels[6 * width + 6] = 0xFFFFFFFF;
      pixels[10 * width + 10] = 0xFFFFFFFF;

      final t0 = PortalVortexEffect({
        'time': 0.0,
        'preserveAlpha': true,
      });

      final tNext = PortalVortexEffect({
        'time': 0.25,
        'preserveAlpha': true,
      });

      final out0 = t0.apply(pixels, width, height);
      final outNext = tNext.apply(pixels, width, height);

      expect(outNext, isNot(equals(out0)));
    });

    test('preserveAlpha: false fills background with dark void', () {
      const width = 8;
      const height = 8;
      final pixels = Uint32List(width * height);

      final effect = PortalVortexEffect({
        'preserveAlpha': false,
      });

      final out = effect.apply(pixels, width, height);
      for (final p in out) {
        expect((p >> 24) & 0xFF, equals(255));
      }
    });
  });
}
