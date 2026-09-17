import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/fields/ui_field.dart';

void main() {
  group('DropShadowEffect', () {
    test('instantiates with default parameters and metadata', () {
      final effect = DropShadowEffect();
      expect(effect.type, equals(EffectType.dropShadow));
      expect(effect.parameters['mode'], equals('drop'));
      expect(effect.parameters['shadowColor'], equals(0x99000000));
      expect(effect.parameters['offsetX'], equals(2));
      expect(effect.parameters['offsetY'], equals(3));
      expect(effect.parameters['isometricAngle'], equals(30.0));
      expect(effect.parameters['isometricScale'], equals(0.5));
      expect(effect.parameters['softness'], equals(0));
      expect(effect.parameters['shadowOnly'], isFalse);

      final defaults = effect.getDefaultParameters();
      expect(defaults['mode'], equals('drop'));

      final metadata = effect.getMetadata();
      expect(metadata.containsKey('mode'), isTrue);
      expect(metadata.containsKey('shadowColor'), isTrue);
      expect(metadata.containsKey('offsetX'), isTrue);
      expect(metadata.containsKey('offsetY'), isTrue);
      expect(metadata.containsKey('isometricAngle'), isTrue);
      expect(metadata.containsKey('shadowOnly'), isTrue);
    });

    test('getFields returns strongly-typed UIField descriptors', () {
      final effect = DropShadowEffect();
      final fields = effect.getFields();

      expect(fields.length, equals(8));
      final keys = fields.map((f) => f.key).toList();
      expect(keys, containsAll([
        'mode',
        'shadowColor',
        'offsetX',
        'offsetY',
        'isometricAngle',
        'isometricScale',
        'softness',
        'shadowOnly',
      ]));

      final modeField = fields.firstWhere((f) => f.key == 'mode') as SelectField;
      expect(modeField.options.containsKey('drop'), isTrue);
      expect(modeField.options.containsKey('isometric'), isTrue);

      final colorField = fields.firstWhere((f) => f.key == 'shadowColor');
      expect(colorField, isA<ColorField>());

      final xField = fields.firstWhere((f) => f.key == 'offsetX') as SliderField;
      expect(xField.isInteger, isTrue);

      final shadowOnlyField = fields.firstWhere((f) => f.key == 'shadowOnly');
      expect(shadowOnlyField, isA<BoolField>());
    });

    test('EffectsManager creates and deserializes DropShadowEffect', () {
      final effect = EffectsManager.createEffect(EffectType.dropShadow, {
        'offsetX': 5,
      });
      expect(effect, isA<DropShadowEffect>());
      expect(effect.parameters['offsetX'], equals(5));

      final fromJson = EffectsManager.effectFromJson({
        'type': 'dropShadow',
        'parameters': {'offsetX': 7},
      });
      expect(fromJson, isA<DropShadowEffect>());
      expect(fromJson?.parameters['offsetX'], equals(7));
    });

    test('renders 2D drop shadow at specified offset', () {
      const width = 4;
      const height = 4;
      final pixels = Uint32List(width * height);
      // Put a single red pixel at (0, 0): 0xFFFF0000
      pixels[0] = 0xFFFF0000;

      final effect = DropShadowEffect({
        'mode': 'drop',
        'shadowColor': 0xFF000000, // solid black shadow
        'offsetX': 1,
        'offsetY': 1,
        'softness': 0,
        'shadowOnly': false,
      });

      final out = effect.apply(pixels, width, height);

      // (0, 0) should remain the original red pixel
      expect(out[0], equals(0xFFFF0000));

      // (1, 1) should receive the offset shadow
      final shadowPixel = out[1 * width + 1];
      expect(shadowPixel, equals(0xFF000000));

      // (3, 3) should remain completely transparent
      expect(out[3 * width + 3], equals(0));
    });

    test('shadowOnly mode removes the original sprite and outputs only shadow', () {
      const width = 4;
      const height = 4;
      final pixels = Uint32List(width * height);
      // Red pixel at (0, 0)
      pixels[0] = 0xFFFF0000;

      final effect = DropShadowEffect({
        'mode': 'drop',
        'shadowColor': 0xFF000000,
        'offsetX': 2,
        'offsetY': 0,
        'softness': 0,
        'shadowOnly': true,
      });

      final out = effect.apply(pixels, width, height);

      // (0, 0) should be transparent because shadowOnly is true
      expect(out[0], equals(0));

      // (2, 0) should have the shadow
      expect(out[2], equals(0xFF000000));
    });
  });
}
