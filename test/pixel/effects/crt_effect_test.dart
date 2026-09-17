import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/fields/ui_field.dart';

void main() {
  group('CrtEffect', () {
    test('instantiates with default parameters and metadata', () {
      final effect = CrtEffect();
      expect(effect.type, equals(EffectType.crt));
      expect(effect.parameters['scanlineIntensity'], equals(0.35));
      expect(effect.parameters['scanlineSpacing'], equals(2));
      expect(effect.parameters['rgbSubpixel'], equals(0.25));
      expect(effect.parameters['curvature'], equals(0.12));
      expect(effect.parameters['vignette'], equals(0.3));
      expect(effect.parameters['brightnessBoost'], equals(0.15));
      expect(effect.parameters['preserveAlpha'], isTrue);

      final defaults = effect.getDefaultParameters();
      expect(defaults['scanlineIntensity'], equals(0.35));

      final metadata = effect.getMetadata();
      expect(metadata.containsKey('scanlineIntensity'), isTrue);
      expect(metadata.containsKey('rgbSubpixel'), isTrue);
      expect(metadata.containsKey('curvature'), isTrue);
      expect(metadata.containsKey('vignette'), isTrue);
      expect(metadata.containsKey('brightnessBoost'), isTrue);
      expect(metadata.containsKey('preserveAlpha'), isTrue);
    });

    test('getFields returns complete strongly-typed UIField list', () {
      final effect = CrtEffect();
      final fields = effect.getFields();

      expect(fields.length, equals(7));
      final keys = fields.map((f) => f.key).toList();
      expect(keys, containsAll([
        'scanlineIntensity',
        'scanlineSpacing',
        'rgbSubpixel',
        'curvature',
        'vignette',
        'brightnessBoost',
        'preserveAlpha',
      ]));

      final intensityField = fields.firstWhere((f) => f.key == 'scanlineIntensity') as SliderField;
      expect(intensityField.min, equals(0.0));
      expect(intensityField.max, equals(1.0));

      final spacingField = fields.firstWhere((f) => f.key == 'scanlineSpacing') as SliderField;
      expect(spacingField.isInteger, isTrue);

      final alphaField = fields.firstWhere((f) => f.key == 'preserveAlpha');
      expect(alphaField, isA<BoolField>());
    });

    test('EffectsManager creates and deserializes CrtEffect', () {
      final effect = EffectsManager.createEffect(EffectType.crt, {
        'scanlineIntensity': 0.5,
      });
      expect(effect, isA<CrtEffect>());
      expect(effect.parameters['scanlineIntensity'], equals(0.5));

      final fromJson = EffectsManager.effectFromJson({
        'type': 'crt',
        'parameters': {'scanlineIntensity': 0.8},
      });
      expect(fromJson, isA<CrtEffect>());
      expect(fromJson?.parameters['scanlineIntensity'], equals(0.8));
    });

    test('applies horizontal scanlines correctly', () {
      // 4x4 image with solid white pixels: 0xFFFFFFFF
      const width = 4;
      const height = 4;
      final pixels = Uint32List(width * height)..fillRange(0, width * height, 0xFFFFFFFF);

      // Scanline only effect (no curvature, no vignette, no boost, no rgb mask)
      final crt = CrtEffect({
        'scanlineIntensity': 0.5,
        'scanlineSpacing': 2,
        'rgbSubpixel': 0.0,
        'curvature': 0.0,
        'vignette': 0.0,
        'brightnessBoost': 0.0,
        'preserveAlpha': true,
      });

      final out = crt.apply(pixels, width, height);
      expect(out.length, equals(16));

      // Row 0: y % 2 == 0, not scanline row -> should remain full white
      final pRow0 = out[0 * width + 0];
      final r0 = (pRow0 >> 16) & 0xFF;
      expect(r0, equals(255));

      // Row 1: y % 2 == 1 -> scanline row -> darkened by 1 - 0.5 * 0.5 = 0.75
      final pRow1 = out[1 * width + 0];
      final r1 = (pRow1 >> 16) & 0xFF;
      expect(r1, closeTo((255 * 0.75).round(), 1));
    });

    test('preserves transparent background when preserveAlpha is true', () {
      const width = 4;
      const height = 4;
      final pixels = Uint32List(width * height); // All transparent: 0x00000000
      // Make center 2 pixels solid red: 0xFFFF0000
      pixels[1 * width + 1] = 0xFFFF0000;
      pixels[1 * width + 2] = 0xFFFF0000;

      final crt = CrtEffect({
        'scanlineIntensity': 0.3,
        'scanlineSpacing': 2,
        'rgbSubpixel': 0.0,
        'curvature': 0.0,
        'vignette': 0.0,
        'brightnessBoost': 0.0,
        'preserveAlpha': true,
      });

      final out = crt.apply(pixels, width, height);

      // Transparent pixel at (0,0) stays transparent
      expect(out[0], equals(0));

      // Pixel at (1,1) has non-zero alpha and color
      final centerPixel = out[1 * width + 1];
      final a = (centerPixel >> 24) & 0xFF;
      expect(a, equals(255));
    });

    test('RGB phosphor mask modulates color channels based on column', () {
      const width = 3;
      const height = 1;
      final pixels = Uint32List(width * height)..fillRange(0, 3, 0xFF808080); // mid-grey

      final crt = CrtEffect({
        'scanlineIntensity': 0.0,
        'scanlineSpacing': 2,
        'rgbSubpixel': 0.5,
        'curvature': 0.0,
        'vignette': 0.0,
        'brightnessBoost': 0.0,
        'preserveAlpha': true,
      });

      final out = crt.apply(pixels, width, height);

      // Col 0: Red phosphor column -> R boosted, G & B dimmed
      final p0 = out[0];
      final r0 = (p0 >> 16) & 0xFF;
      final g0 = (p0 >> 8) & 0xFF;
      final b0 = p0 & 0xFF;
      expect(r0, greaterThan(g0));
      expect(r0, greaterThan(b0));

      // Col 1: Green phosphor column -> G boosted, R & B dimmed
      final p1 = out[1];
      final r1 = (p1 >> 16) & 0xFF;
      final g1 = (p1 >> 8) & 0xFF;
      final b1 = p1 & 0xFF;
      expect(g1, greaterThan(r1));
      expect(g1, greaterThan(b1));

      // Col 2: Blue phosphor column -> B boosted, R & G dimmed
      final p2 = out[2];
      final r2 = (p2 >> 16) & 0xFF;
      final g2 = (p2 >> 8) & 0xFF;
      final b2 = p2 & 0xFF;
      expect(b2, greaterThan(r2));
      expect(b2, greaterThan(g2));
    });

    test('barrel distortion curvature maps outside edges to transparent bezel when preserveAlpha is true', () {
      const width = 16;
      const height = 16;
      final pixels = Uint32List(width * height)..fillRange(0, width * height, 0xFFFFFFFF);

      final crt = CrtEffect({
        'scanlineIntensity': 0.0,
        'scanlineSpacing': 2,
        'rgbSubpixel': 0.0,
        'curvature': 0.5, // strong curvature
        'vignette': 0.0,
        'brightnessBoost': 0.0,
        'preserveAlpha': true,
      });

      final out = crt.apply(pixels, width, height);

      // Corner (0,0) with high curvature will sample out of bounds and be transparent
      final cornerPixel = out[0];
      expect((cornerPixel >> 24) & 0xFF, equals(0));

      // Center pixel (8,8) is undistorted and remains visible
      final centerPixel = out[8 * width + 8];
      expect((centerPixel >> 24) & 0xFF, equals(255));
    });
  });
}
