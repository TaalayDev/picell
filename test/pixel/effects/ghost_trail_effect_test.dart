import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';
import 'package:picell/ui/widgets/fields/ui_field.dart';

void main() {
  group('GhostTrailEffect', () {
    test('instantiates with default parameters and isAnimation is true', () {
      final effect = GhostTrailEffect();
      expect(effect.type, equals(EffectType.ghostTrail));
      expect(effect.isAnimation, isTrue);
      expect(effect.parameters['ghostCount'], equals(3));
      expect(effect.parameters['spacing'], equals(6));
      expect(effect.parameters['direction'], equals(0.0));
      expect(effect.parameters['tintColor'], equals(0xFF00E5FF));
      expect(effect.parameters['preserveAlpha'], isTrue);

      final defaults = effect.getDefaultParameters();
      expect(defaults['ghostCount'], equals(3));

      final metadata = effect.getMetadata();
      expect(metadata.containsKey('ghostCount'), isTrue);
      expect(metadata.containsKey('spacing'), isTrue);
      expect(metadata.containsKey('tintColor'), isTrue);
    });

    test('getFields returns strongly-typed UIField descriptors', () {
      final effect = GhostTrailEffect();
      final fields = effect.getFields();

      expect(fields.length, equals(8));
      final keys = fields.map((f) => f.key).toList();
      expect(keys, containsAll([
        'ghostCount',
        'spacing',
        'direction',
        'tintColor',
        'tintStrength',
        'fade',
        'time',
        'preserveAlpha',
      ]));

      final countField = fields.firstWhere((f) => f.key == 'ghostCount') as SliderField;
      expect(countField.isInteger, isTrue);

      final colorField = fields.firstWhere((f) => f.key == 'tintColor');
      expect(colorField, isA<ColorField>());
    });

    test('EffectsManager creates and deserializes GhostTrailEffect', () {
      final effect = EffectsManager.createEffect(EffectType.ghostTrail, {
        'ghostCount': 4,
      });
      expect(effect, isA<GhostTrailEffect>());
      expect(effect.parameters['ghostCount'], equals(4));

      final fromJson = EffectsManager.effectFromJson({
        'type': 'ghostTrail',
        'parameters': {'ghostCount': 2},
      });
      expect(fromJson, isA<GhostTrailEffect>());
      expect(fromJson?.parameters['ghostCount'], equals(2));
    });

    test('horizontal dash (direction=0°) casts after-images behind (to the left of) the sprite', () {
      // 10x1 image: single white pixel at rightmost edge (x = 9): 0xFFFFFFFF
      const width = 10;
      const height = 1;
      final pixels = Uint32List(width * height);
      pixels[9] = 0xFFFFFFFF;

      final effect = GhostTrailEffect({
        'ghostCount': 2,
        'spacing': 3.0,
        'direction': 0.0, // Dashing right -> ghosts trail to the left
        'tintColor': 0xFF00E5FF, // Cyan tint
        'tintStrength': 1.0,
        'fade': 0.5,
        'time': 0.0,
        'preserveAlpha': true,
      });

      final out = effect.apply(pixels, width, height);

      // (9) should remain original foreground white pixel
      expect(out[9], equals(0xFFFFFFFF));

      // Ghost 1 at offset -3 (x = 6): should have tinted cyan color
      final pGhost1 = out[9 - (1 * 3 * 0.8).round()];
      final g1 = (pGhost1 >> 8) & 0xFF;
      final b1 = pGhost1 & 0xFF;
      expect(g1, greaterThan(150));
      expect(b1, greaterThan(150));

      // Far left (x = 0) remains transparent
      expect(out[0], equals(0));
    });

    test('preserves transparent background when preserveAlpha is true', () {
      const width = 5;
      const height = 1;
      final pixels = Uint32List(width * height);
      pixels[4] = 0xFFFFFFFF;

      final effect = GhostTrailEffect({'preserveAlpha': true});
      final out = effect.apply(pixels, width, height);

      expect(out[0], equals(0));
    });
  });
}
