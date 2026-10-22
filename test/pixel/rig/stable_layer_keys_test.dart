import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:picell/data.dart';
import 'package:picell/pixel/rig/stable_layer_keys.dart';

void main() {
  Layer layer(String id, {String? key}) =>
      Layer(layerId: 0, id: id, name: id, pixels: Uint32List(4), stableKey: key);

  AnimationFrame frame(int id, int stateId, List<Layer> layers) => AnimationFrame(
        id: id,
        name: 'f$id',
        stateId: stateId,
        duration: 100,
        layers: layers,
        createdAt: DateTime(2026),
        editedAt: DateTime(2026),
      );

  test('layers at the same position share a key across frames of the state', () {
    final frames = [
      frame(1, 1, [layer('a1'), layer('b1')]),
      frame(2, 1, [layer('a2'), layer('b2')]),
    ];
    final out = StableLayerKeys.ensure(frames, 1);

    // Keys come from the first frame's layer ids.
    expect(out[0].layers.map((l) => l.stableKey), ['a1', 'b1']);
    expect(out[1].layers.map((l) => l.stableKey), ['a1', 'b1']);
    expect(StableLayerKeys.find(out[1], 'b1')!.id, 'b2');
    expect(StableLayerKeys.find(out[1], 'nope'), isNull);
  });

  test('existing keys are kept and untouched frames are the same instance', () {
    final keyed = frame(1, 1, [layer('a', key: 'x')]);
    final other = frame(2, 2, [layer('b')]);
    final out = StableLayerKeys.ensure([keyed, other], 1);

    expect(identical(out[0], keyed), isTrue);
    expect(identical(out[1], other), isTrue, reason: 'other states must not be keyed');
  });

  test('a partly keyed frame only gains keys where missing', () {
    final out = StableLayerKeys.ensure(
      [frame(1, 1, [layer('a', key: 'x'), layer('b')])],
      1,
      keyFor: (l) => 'k-${l.id}',
    );
    expect(out.single.layers.map((l) => l.stableKey), ['x', 'k-b']);
  });

  test('stamping is repeatable, so keys survive an undo to unstamped frames', () {
    final original = [
      frame(1, 1, [layer('a1'), layer('b1')]),
      frame(2, 1, [layer('a2'), layer('b2')]),
    ];
    final first = StableLayerKeys.ensure(original, 1);
    final again = StableLayerKeys.ensure(original, 1);
    expect(again[1].layers.map((l) => l.stableKey), first[1].layers.map((l) => l.stableKey));
  });
}
