import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:picell/data/models/layer.dart';
import 'package:picell/pixel/effects/effect_animation_renderer.dart';
import 'package:picell/pixel/effects/effect_target.dart';
import 'package:picell/pixel/pixel_utils.dart';
import 'package:picell/pixel/effects/effects.dart';

Layer layer(int id, List<int> pixels, {bool visible = true, double opacity = 1}) => Layer(
      layerId: id,
      id: 'l$id',
      name: 'L$id',
      pixels: Uint32List.fromList(pixels),
      isVisible: visible,
      opacity: opacity,
    );

void main() {
  const w = 2, h = 2;
  final a = layer(1, [0xff112233, 0, 0, 0]);
  final b = layer(2, [0, 0xff445566, 0, 0xff778899]);

  EffectTarget target(EffectMultiLayerMode mode, {List<int> indices = const [0, 1]}) => EffectTarget.fromFrame(
        frameLayers: [a, b],
        indices: indices,
        primaryIndex: 0,
        primaryEffects: [InvertEffect()],
        primaryAnimatedIndex: 0,
        mode: mode,
      );

  test('resolveSelection falls back to the active layer', () {
    int one(List<int> s, int active) =>
        EffectTarget.resolveSelection(selected: s, activeIndex: active, layerCount: 3).length;
    expect(one(const [], 1), 1);
    expect(one(const [0, 2], 1), 1); // active not included
    expect(one(const [0, 1, 7], 1), 2); // stale index dropped
    expect(EffectTarget.resolveSelection(selected: const [2, 0, 1], activeIndex: 1, layerCount: 3), [0, 1, 2]);
  });

  test('other layers keep their stack and get the animated effect appended', () {
    final t = target(EffectMultiLayerMode.perLayer);
    expect(t.layers.map((l) => l.index), [0, 1]);
    expect(t.layers[1].effects.last, same(t.layers[0].animatedEffect));
    expect(t.layers[1].animatedEffectIndex, 0);
  });

  test('per-layer output equals rendering each layer alone', () async {
    final t = target(EffectMultiLayerMode.perLayer);
    final frame = await EffectTargetRenderer.renderFrame(target: t, width: w, height: h, progress: 0.5);
    final alone = await EffectTargetRenderer.renderFrame(
      target: target(EffectMultiLayerMode.perLayer, indices: const [0]),
      width: w,
      height: h,
      progress: 0.5,
    );
    expect(frame.flattened, isFalse);
    expect(frame.pixels[0], alone.pixels[0]);
    expect(frame.pixels, hasLength(2));
  });

  test('merged output matches a manual composite on the top visible layer', () async {
    final frame = await EffectTargetRenderer.renderFrame(
      target: target(EffectMultiLayerMode.merged),
      width: w,
      height: h,
      progress: 0,
    );
    expect(frame.flattened, isTrue);
    expect(frame.pixels[0].every((p) => p == 0), isTrue);
    // Composite of a (bottom) and b (top) is non-empty everywhere either has a pixel.
    final lit = frame.pixels[1].where((p) => p != 0).length;
    expect(lit, 3);
  });

  test('merged mode skips hidden layers when picking the receiver', () async {
    final hiddenTop = EffectTarget.fromFrame(
      frameLayers: [
        a,
        layer(2, [0xff445566, 0, 0, 0], visible: false)
      ],
      indices: const [0, 1],
      primaryIndex: 0,
      primaryEffects: [InvertEffect()],
      primaryAnimatedIndex: 0,
    );
    final frame = await EffectTargetRenderer.renderFrame(target: hiddenTop, width: w, height: h, progress: 0);
    expect(frame.pixels[0].any((p) => p != 0), isTrue);
    expect(frame.pixels[1].every((p) => p == 0), isTrue);
  });

  test('a single layer behaves like per-layer even when merged is requested', () async {
    final t = target(EffectMultiLayerMode.merged, indices: const [0]);
    expect(t.effectiveMode, EffectMultiLayerMode.perLayer);
    final frame = await EffectTargetRenderer.renderFrame(target: t, width: w, height: h, progress: 0);
    expect(frame.flattened, isFalse);
    expect(frame.pixels, hasLength(1));
  });

  group('canvas-space transforms', () {
    Uint32List content(int seed) => Uint32List.fromList([
          for (var y = 0; y < 32; y++)
            for (var x = 0; x < 32; x++)
              ((x * 31 + y * 17 + seed * 13) % 7 < 3 && x > 3 + seed && x < 28 - seed && y > 4 && y < 27)
                  ? 0xff000000 | ((x * 7 + seed * 50) & 255) << 16 | ((y * 9) & 255) << 8 | (0x30 + seed * 60)
                  : 0
        ]);

    for (final type in EffectCatalog.canvasSpaceTransforms) {
      test('${type.name}: moving layers apart equals moving their composite', () async {
        for (final seed in [0, 1, 2]) {
          for (final progress in [0.2, 0.63]) {
            final base = EffectsManager.createEffect(type, null);
            // Nearest sampling makes rotation exact; others have no sampling choice.
            final effect = type == EffectType.rotate
                ? EffectsManager.createEffect(type, {...base.parameters, 'interpolation': 0})
                : base;
            final layers = [layer(1, content(seed)), layer(2, content(seed + 1))];

            final together = await EffectTargetRenderer.renderFrame(
              target: EffectTarget.fromFrame(
                frameLayers: [layers[0], layers[1]],
                indices: const [0, 1],
                primaryIndex: 1,
                primaryEffects: [effect],
                primaryAnimatedIndex: 0,
              ).copyWith(mode: EffectMultiLayerMode.perLayer),
              width: 32,
              height: 32,
              progress: progress,
            );
            final apart = PixelUtils.mergeLayersPixels(width: 32, height: 32, layers: [
              for (final (i, l) in layers.indexed) l.copyWith(pixels: together.pixels[i]),
            ]);
            // Reference: animate the flattened composite directly.
            final reference = await EffectAnimationRenderer.renderFrame(
              pixels: PixelUtils.mergeLayersPixels(width: 32, height: 32, layers: layers),
              width: 32,
              height: 32,
              effects: [effect],
              animatedEffectIndex: 0,
              progress: progress,
            );
            expect(apart, reference, reason: '${type.name} seed=$seed progress=$progress');
          }
        }
      });
    }

    test('merged mode keeps the layers separate for them, and flattens otherwise', () async {
      Future<EffectTargetFrame> merged(Effect effect) => EffectTargetRenderer.renderFrame(
            target: EffectTarget.fromFrame(
              frameLayers: [a, b],
              indices: const [0, 1],
              primaryIndex: 0,
              primaryEffects: [effect],
              primaryAnimatedIndex: 0,
            ),
            width: w,
            height: h,
            progress: 0.5,
          );
      final kept = await merged(EffectsManager.createEffect(EffectType.shake, null));
      expect(kept.flattened, isFalse);
      expect(kept.pixels[0].any((p) => p != 0), isTrue);
      expect(kept.pixels[1].any((p) => p != 0), isTrue);
      expect((await merged(EffectsManager.createEffect(EffectType.breathing, null))).flattened, isTrue);
    });
  });
}
