import 'dart:typed_data';

import '../../data/models/layer.dart';
import '../pixel_utils.dart';
import 'effect_animation_renderer.dart';
import 'effects.dart';

/// How one animated effect treats several selected layers.
enum EffectMultiLayerMode {
  /// The layers are composited and transformed as if they were one layer.
  merged,

  /// Every layer is transformed on its own with the same parameters.
  perLayer,
}

/// One layer taking part in an animated effect.
class EffectTargetLayer {
  const EffectTargetLayer({
    required this.index,
    required this.layer,
    required this.effects,
    required this.animatedEffectIndex,
  });

  /// Position of the layer in its frame (stable, unlike `layerId` on copies).
  final int index;
  final Layer layer;

  /// Full ordered stack for this layer, including the animated effect.
  final List<Effect> effects;
  final int animatedEffectIndex;

  Effect get animatedEffect => effects[animatedEffectIndex];
}

/// The layers an animated effect is applied to, in frame order (last = top).
class EffectTarget {
  EffectTarget({required this.layers, this.mode = EffectMultiLayerMode.merged}) : assert(layers.isNotEmpty);

  final List<EffectTargetLayer> layers;
  final EffectMultiLayerMode mode;

  bool get isMultiLayer => layers.length > 1;
  List<int> get layerIds => [for (final item in layers) item.layer.layerId];

  /// Resolves what [mode] means for this target: a single layer has nothing
  /// to merge, so it always behaves like per-layer.
  EffectMultiLayerMode get effectiveMode => isMultiLayer ? mode : EffectMultiLayerMode.perLayer;

  /// Whether "merged" can keep the layers separate: the effect treats every
  /// pixel by its canvas position alone, so moving the layers with the same
  /// parameters is the same as moving their composite.
  bool get mergedKeepsLayers =>
      effectiveMode == EffectMultiLayerMode.merged &&
      EffectCatalog.isCanvasSpaceTransform(layers.first.animatedEffect.type);

  EffectTarget copyWith({EffectMultiLayerMode? mode}) => EffectTarget(layers: layers, mode: mode ?? this.mode);

  /// Builds a target from [indices] of [frameLayers].
  ///
  /// [primaryIndex] is the layer whose stack ([primaryEffects], with the
  /// animated effect at [primaryAnimatedIndex]) the user is editing. Every
  /// other layer keeps its own stack and gets the animated effect appended.
  factory EffectTarget.fromFrame({
    required List<Layer> frameLayers,
    required Iterable<int> indices,
    required int primaryIndex,
    required List<Effect> primaryEffects,
    required int primaryAnimatedIndex,
    EffectMultiLayerMode mode = EffectMultiLayerMode.merged,
  }) {
    final animated = primaryEffects[primaryAnimatedIndex];
    final ordered = {
      ...indices.where((i) => i >= 0 && i < frameLayers.length),
      primaryIndex,
    }.toList()
      ..sort();
    return EffectTarget(
      mode: mode,
      layers: [
        for (final index in ordered)
          if (index == primaryIndex)
            EffectTargetLayer(
              index: index,
              layer: frameLayers[index],
              effects: primaryEffects,
              animatedEffectIndex: primaryAnimatedIndex,
            )
          else
            EffectTargetLayer(
              index: index,
              layer: frameLayers[index],
              effects: [...frameLayers[index].effects, animated],
              animatedEffectIndex: frameLayers[index].effects.length,
            ),
      ],
    );
  }

  /// Layers selected in the panel, falling back to just the active layer when
  /// the selection is empty, stale, or does not include the active layer.
  static List<int> resolveSelection({
    required List<int> selected,
    required int activeIndex,
    required int layerCount,
  }) {
    final valid = selected.where((i) => i >= 0 && i < layerCount).toSet();
    if (valid.length < 2 || !valid.contains(activeIndex)) return [activeIndex];
    return valid.toList()..sort();
  }
}

/// Pixels produced for an [EffectTarget] at one point in time, aligned with
/// [EffectTarget.layers].
class EffectTargetFrame {
  const EffectTargetFrame(this.pixels, {this.flattened = false});

  final List<Uint32List> pixels;

  /// True when opacity was baked into the pixels (merged mode), so the layer
  /// receiving them must be shown at full opacity.
  final bool flattened;
}

/// What a finished generation produced, so it can be written back.
class EffectGenerationResult {
  const EffectGenerationResult({
    required this.layerIds,
    required this.activeLayerId,
    required this.flattened,
  });

  /// Source layer ids, in the order of each generated frame's layers.
  final List<int> layerIds;
  final int activeLayerId;
  final bool flattened;
}

/// Renders [EffectTarget]s one animation frame at a time.
abstract final class EffectTargetRenderer {
  static Future<EffectTargetFrame> renderFrame({
    required EffectTarget target,
    required int width,
    required int height,
    required double progress,
  }) async {
    if (target.effectiveMode == EffectMultiLayerMode.perLayer || target.mergedKeepsLayers) {
      final pixels = await Future.wait([
        for (final item in target.layers) _renderLayer(item, width, height, progress),
      ]);
      return EffectTargetFrame(pixels);
    }
    return _renderMerged(target, width, height, progress);
  }

  static Future<Uint32List> _renderLayer(
    EffectTargetLayer item,
    int width,
    int height,
    double progress,
  ) {
    return EffectAnimationRenderer.renderFrame(
      pixels: item.layer.pixels,
      width: width,
      height: height,
      effects: item.effects,
      animatedEffectIndex: item.animatedEffectIndex,
      progress: progress,
    );
  }

  /// Composites the layers (visibility, opacity and their non-animated
  /// effects respected), animates the composite, and returns it on the
  /// topmost visible target layer. The other target layers are emptied.
  static Future<EffectTargetFrame> _renderMerged(
    EffectTarget target,
    int width,
    int height,
    double progress,
  ) async {
    final composite = PixelUtils.mergeLayersPixels(
      width: width,
      height: height,
      layers: [
        for (final item in target.layers)
          item.layer.copyWith(
            effects: [
              for (final (i, effect) in item.effects.indexed)
                if (i != item.animatedEffectIndex) effect,
            ],
          ),
      ],
    );
    final animated = target.layers.first.animatedEffect;
    final rendered = await _renderLayer(
      EffectTargetLayer(
        index: 0,
        layer: target.layers.first.layer.copyWith(pixels: composite, effects: const []),
        effects: [animated],
        animatedEffectIndex: 0,
      ),
      width,
      height,
      progress,
    );

    var receiver = target.layers.length - 1;
    for (var i = target.layers.length - 1; i >= 0; i--) {
      if (target.layers[i].layer.isVisible) {
        receiver = i;
        break;
      }
    }
    return EffectTargetFrame(
      [
        for (var i = 0; i < target.layers.length; i++) i == receiver ? rendered : Uint32List(width * height),
      ],
      flattened: true,
    );
  }
}
