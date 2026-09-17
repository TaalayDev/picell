import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/fields/ui_field.dart';

void main() {
  group('LcdMatrixEffect', () {
    test('instantiates with default parameters and metadata', () {
      final effect = LcdMatrixEffect();
      expect(effect.type, equals(EffectType.lcdMatrix));
      expect(effect.parameters['palette'], equals('dmg_green'));
      expect(effect.parameters['ditherMode'], equals('bayer2x2'));
      expect(effect.parameters['pixelGrid'], equals(0.35));
      expect(effect.parameters['pixelSize'], equals(2));
      expect(effect.parameters['preserveAlpha'], isTrue);

      final defaults = effect.getDefaultParameters();
      expect(defaults['palette'], equals('dmg_green'));

      final metadata = effect.getMetadata();
      expect(metadata.containsKey('palette'), isTrue);
      expect(metadata.containsKey('ditherMode'), isTrue);
      expect(metadata.containsKey('pixelGrid'), isTrue);
      expect(metadata.containsKey('pixelSize'), isTrue);
      expect(metadata.containsKey('preserveAlpha'), isTrue);
    });

    test('getFields returns strongly-typed UIField descriptors', () {
      final effect = LcdMatrixEffect();
      final fields = effect.getFields();

      expect(fields.length, equals(7));
      final keys = fields.map((f) => f.key).toList();
      expect(keys, containsAll([
        'palette',
        'ditherMode',
        'pixelGrid',
        'pixelSize',
        'contrast',
        'brightness',
        'preserveAlpha',
      ]));

      final paletteField = fields.firstWhere((f) => f.key == 'palette') as SelectField;
      expect(paletteField.options.containsKey('dmg_green'), isTrue);
      expect(paletteField.options.containsKey('pocket_gray'), isTrue);
      expect(paletteField.options.containsKey('gb_light'), isTrue);
      expect(paletteField.options.containsKey('virtual_boy'), isTrue);
      expect(paletteField.options.containsKey('amber'), isTrue);

      final gridField = fields.firstWhere((f) => f.key == 'pixelGrid') as SliderField;
      expect(gridField.min, equals(0.0));
      expect(gridField.max, equals(1.0));

      final sizeField = fields.firstWhere((f) => f.key == 'pixelSize') as SliderField;
      expect(sizeField.isInteger, isTrue);
    });

    test('EffectsManager creates and deserializes LcdMatrixEffect', () {
      final effect = EffectsManager.createEffect(EffectType.lcdMatrix, {
        'palette': 'pocket_gray',
      });
      expect(effect, isA<LcdMatrixEffect>());
      expect(effect.parameters['palette'], equals('pocket_gray'));

      final fromJson = EffectsManager.effectFromJson({
        'type': 'lcdMatrix',
        'parameters': {'palette': 'virtual_boy'},
      });
      expect(fromJson, isA<LcdMatrixEffect>());
      expect(fromJson?.parameters['palette'], equals('virtual_boy'));
    });

    test('quantizes black and white pixels to darkest and lightest palette shades', () {
      const width = 2;
      const height = 1;
      // Pixel 0: pure black (0xFF000000), Pixel 1: pure white (0xFFFFFFFF)
      final pixels = Uint32List.fromList([0xFF000000, 0xFFFFFFFF]);

      final effect = LcdMatrixEffect({
        'palette': 'dmg_green',
        'ditherMode': 'none',
        'pixelGrid': 0.0,
        'pixelSize': 1,
        'contrast': 0.0,
        'brightness': 0.0,
        'preserveAlpha': true,
      });

      final out = effect.apply(pixels, width, height);
      final dmgPal = LcdMatrixEffect.palettes['dmg_green']!;

      // Pixel 0 should map to darkest DMG shade (0xFF0F380F)
      expect(out[0], equals(dmgPal[0]));

      // Pixel 1 should map to lightest DMG shade (0xFF9BBC0F)
      expect(out[1], equals(dmgPal[3]));
    });

    test('Bayer dithering creates pattern variance across flat midtone region', () {
      const width = 4;
      const height = 4;
      // Fill with uniform mid-gray: 0xFF808080
      final pixels = Uint32List(width * height)..fillRange(0, width * height, 0xFF808080);

      final noDither = LcdMatrixEffect({
        'palette': 'dmg_green',
        'ditherMode': 'none',
        'pixelGrid': 0.0,
        'pixelSize': 1,
        'contrast': 0.0,
        'brightness': 0.0,
      });
      final dithered = LcdMatrixEffect({
        'palette': 'dmg_green',
        'ditherMode': 'bayer2x2',
        'pixelGrid': 0.0,
        'pixelSize': 1,
        'contrast': 0.0,
        'brightness': 0.0,
      });

      final outNoDither = noDither.apply(pixels, width, height);
      final outDithered = dithered.apply(pixels, width, height);

      // Without dither, all pixels in flat gray region must be identical
      expect(outNoDither.toSet().length, equals(1));

      // With Bayer 2x2 dither, there should be multiple distinct shades forming the pattern
      expect(outDithered.toSet().length, greaterThan(1));
    });

    test('preserves transparent background when preserveAlpha is true', () {
      const width = 2;
      const height = 2;
      final pixels = Uint32List.fromList([
        0x00000000, 0xFFFFFFFF,
        0x00000000, 0xFF000000,
      ]);

      final effect = LcdMatrixEffect({
        'pixelSize': 1,
        'preserveAlpha': true,
      });

      final out = effect.apply(pixels, width, height);
      expect(out[0], equals(0));
      expect(out[2], equals(0));
      expect((out[1] >> 24) & 0xFF, equals(255));
      expect((out[3] >> 24) & 0xFF, equals(255));
    });
  });
}
