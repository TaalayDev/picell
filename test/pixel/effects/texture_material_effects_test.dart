import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/effects/effects.dart';

void main() {
  final source = Uint32List.fromList(List<int>.generate(
    64,
    (i) => i == 0 ? 0 : 0xff607080 + (i & 0x0f),
  ));

  group('procedural material effects', () {
    final cases = <EffectType, Effect>{
      EffectType.rustCorrosion: RustCorrosionEffect(),
      EffectType.wornFabric: WornFabricEffect(),
      EffectType.crackedCeramic: CrackedCeramicEffect(),
      EffectType.mossLichen: MossLichenEffect(),
      EffectType.paintPeeling: PaintPeelingEffect(),
    };

    for (final entry in cases.entries) {
      test('${entry.key.name} is deterministic and preserves alpha', () {
        final first = entry.value.apply(source, 8, 8);
        final second = entry.value.apply(source, 8, 8);

        expect(first, orderedEquals(second));
        expect(first, hasLength(source.length));
        expect(first.first, 0);
        expect(first.skip(1), isNot(orderedEquals(source.skip(1))));
      });

      test('${entry.key.name} is created and deserialized by the manager', () {
        expect(EffectsManager.createEffect(entry.key).type, entry.key);
        final restored = EffectsManager.effectFromJson({
          'type': entry.key.name,
          'parameters': entry.value.getDefaultParameters(),
        });
        expect(restored?.runtimeType, entry.value.runtimeType);
      });
    }

    test('zero rust and moss coverage leave opaque pixels unchanged', () {
      final rust = RustCorrosionEffect({
        ...RustCorrosionEffect().getDefaultParameters(),
        'amount': 0.0,
      });
      final moss = MossLichenEffect({
        ...MossLichenEffect().getDefaultParameters(),
        'coverage': 0.0,
      });

      expect(rust.apply(source, 8, 8), orderedEquals(source));
      expect(moss.apply(source, 8, 8), orderedEquals(source));
    });

    test('paint coverage extremes reveal source or coat it', () {
      final bare = PaintPeelingEffect({
        ...PaintPeelingEffect().getDefaultParameters(),
        'paintCoverage': 0.0,
        'edgeWear': 0.0,
      }).apply(source, 8, 8);
      final painted = PaintPeelingEffect({
        ...PaintPeelingEffect().getDefaultParameters(),
        'paintCoverage': 1.0,
        'edgeWear': 0.0,
      }).apply(source, 8, 8);

      expect(bare, orderedEquals(source));
      expect(painted.skip(1), isNot(orderedEquals(source.skip(1))));
    });

    test('moss and peeling can be stacked over rust', () {
      final output = EffectsManager.applyMultipleEffects(source, 8, 8, [
        RustCorrosionEffect(),
        MossLichenEffect(),
        PaintPeelingEffect(),
      ]);

      expect(output, hasLength(source.length));
      expect(output.first, 0);
      expect(output.skip(1), isNot(orderedEquals(source.skip(1))));
    });
  });
}
