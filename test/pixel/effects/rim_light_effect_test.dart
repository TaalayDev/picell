import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/fields/ui_field.dart';

void main() {
  group('RimLightEffect', () {
    test('instantiates with default parameters and metadata', () {
      final effect = RimLightEffect();
      expect(effect.type, equals(EffectType.rimLight));
      expect(effect.parameters['lightColor'], equals(0xFFFFE082));
      expect(effect.parameters['lightAngle'], equals(45.0));
      expect(effect.parameters['brightness'], equals(1.0));
      expect(effect.parameters['thickness'], equals(1));
      expect(effect.parameters['wrap'], equals(0.2));
      expect(effect.parameters['preserveAlpha'], isTrue);

      final defaults = effect.getDefaultParameters();
      expect(defaults['lightAngle'], equals(45.0));

      final metadata = effect.getMetadata();
      expect(metadata.containsKey('lightColor'), isTrue);
      expect(metadata.containsKey('lightAngle'), isTrue);
      expect(metadata.containsKey('brightness'), isTrue);
      expect(metadata.containsKey('thickness'), isTrue);
      expect(metadata.containsKey('wrap'), isTrue);
    });

    test('getFields returns strongly-typed UIField descriptors', () {
      final effect = RimLightEffect();
      final fields = effect.getFields();

      expect(fields.length, equals(6));
      final keys = fields.map((f) => f.key).toList();
      expect(keys, containsAll([
        'lightColor',
        'lightAngle',
        'brightness',
        'thickness',
        'wrap',
        'preserveAlpha',
      ]));

      final colorField = fields.firstWhere((f) => f.key == 'lightColor');
      expect(colorField, isA<ColorField>());

      final angleField = fields.firstWhere((f) => f.key == 'lightAngle') as SliderField;
      expect(angleField.max, equals(360.0));

      final thicknessField = fields.firstWhere((f) => f.key == 'thickness') as SliderField;
      expect(thicknessField.isInteger, isTrue);
    });

    test('EffectsManager creates and deserializes RimLightEffect', () {
      final effect = EffectsManager.createEffect(EffectType.rimLight, {
        'lightAngle': 90.0,
      });
      expect(effect, isA<RimLightEffect>());
      expect(effect.parameters['lightAngle'], equals(90.0));

      final fromJson = EffectsManager.effectFromJson({
        'type': 'rimLight',
        'parameters': {'lightAngle': 180.0},
      });
      expect(fromJson, isA<RimLightEffect>());
      expect(fromJson?.parameters['lightAngle'], equals(180.0));
    });

    test('light from 0° (Right) brightens right-side edge more than left-side edge', () {
      // 5x1 image: 0 (trans), Solid Blue (left), Solid Blue (mid), Solid Blue (right), 0 (trans)
      const width = 5;
      const height = 1;
      final pixels = Uint32List.fromList([
        0x00000000,
        0xFF000080, // left edge (facing left)
        0xFF000080, // center
        0xFF000080, // right edge (facing right)
        0x00000000,
      ]);

      final effect = RimLightEffect({
        'lightColor': 0xFFFFFF00, // Yellow light
        'lightAngle': 0.0, // Light from the Right
        'brightness': 1.0,
        'thickness': 1,
        'wrap': 0.0, // Strict directional illumination
        'preserveAlpha': true,
      });

      final out = effect.apply(pixels, width, height);

      // Right edge pixel (at index 3) faces right towards the light -> should receive strong rim highlight
      final pRight = out[3];
      final rRight = (pRight >> 16) & 0xFF;

      // Left edge pixel (at index 1) faces away from light -> should receive zero/minimal light
      final pLeft = out[1];
      final rLeft = (pLeft >> 16) & 0xFF;

      expect(rRight, greaterThan(100));
      expect(rLeft, equals(0));
    });

    test('preserves transparent background when preserveAlpha is true', () {
      const width = 3;
      const height = 1;
      final pixels = Uint32List.fromList([
        0x00000000,
        0xFF0000FF,
        0x00000000,
      ]);

      final effect = RimLightEffect({'preserveAlpha': true});
      final out = effect.apply(pixels, width, height);

      expect(out[0], equals(0));
      expect(out[2], equals(0));
      expect((out[1] >> 24) & 0xFF, equals(255));
    });
  });
}
