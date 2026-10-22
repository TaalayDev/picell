import 'dart:typed_data';

import '../../data/models/layer.dart';
import '../../data/models/rig/rig.dart';
import '../pixel_utils.dart';
import 'affine2.dart';
import 'part_rasterizer.dart';
import 'pose_interpolator.dart';
import 'rig_solver.dart';

/// Turns a [Rig] and one of its [RigClip]s into pixel frames.
///
/// Pure: reads the rest-pose [layers] and returns fresh buffers, so it can be
/// run on an isolate and never touches state that undo snapshots may alias.
class RigBaker {
  final Rig rig;
  final int width;
  final int height;

  /// Rest-pose layers carrying `Layer.stableKey`s that the parts refer to.
  final List<Layer> layers;

  final Map<String, Uint32List> _partCache = {};

  RigBaker({required this.rig, required this.width, required this.height, required this.layers});

  /// The composite of every layer at [time] of [clip]: parts moved by their
  /// bones, plus layers no bone drives, which stay where they are. Always a
  /// new buffer.
  Uint32List bakeFrame(RigClip clip, double time) {
    final poses = PoseInterpolator.sample(clip, rig.bones, time);
    final world = RigSolver.solveIk(rig, poses, PoseInterpolator.sampleIk(clip, rig.ikChains, time)).world;
    final bones = {for (final bone in rig.bones) bone.id: bone};
    final byKey = {
      for (final layer in layers)
        if (layer.stableKey != null) layer.stableKey!: layer,
    };
    final boundKeys = {for (final part in rig.parts) part.layerKey};

    // Everything to draw, with its stacking position. Parts carry the order
    // the editor gave them (their layer's position); still layers use their
    // own position, so both interleave exactly like the layer stack.
    final entries = <({int order, Layer layer, RigPart? part})>[
      for (final part in rig.parts)
        if (byKey[part.layerKey] != null) (order: part.drawOrder, layer: byKey[part.layerKey]!, part: part),
      for (final (index, layer) in layers.indexed)
        if (layer.stableKey == null || !boundKeys.contains(layer.stableKey)) (order: index, layer: layer, part: null),
    ];
    // Highest first: the first opaque pixel wins, which is the same rule
    // PixelUtils.mergeLayersPixels uses for layers.
    entries.sort((p, q) => q.order.compareTo(p.order));

    final out = Uint32List(width * height);
    for (final entry in entries) {
      final layer = entry.layer;
      if (!layer.isVisible || layer.opacity <= 0) continue;

      final Uint32List pixels;
      final part = entry.part;
      if (part == null) {
        pixels = layer.processedPixels(width, height);
      } else {
        final bone = bones[part.boneId];
        if (bone == null) continue;
        final pivot = part.pivotOverride ?? bone.head;
        final transform = (world[bone.id] ?? Affine2.identity).withIntegerDisplacementAt(pivot);
        pixels = _rasterize(part, layer, transform);
      }

      final opacity = layer.opacity;
      for (var i = 0; i < out.length; i++) {
        if (out[i] == 0) out[i] = PixelUtils.applyAlpha(pixels[i], opacity);
      }
    }
    return out;
  }

  /// One buffer per frame of [clip], times `0 .. length - 1`.
  List<Uint32List> bakeClip(RigClip clip) => [for (var t = 0; t < clip.length; t++) bakeFrame(clip, t.toDouble())];

  // Equal poses recur constantly (snapped angles, stepped easing, loops), so
  // a rasterized part is reused whenever its transform repeats. Cached
  // buffers are only read by bakeFrame, never handed out.
  Uint32List _rasterize(RigPart part, Layer layer, Affine2 transform) {
    final key = '${part.id}|${layer.id}|${transform.cacheKey}';
    return _partCache[key] ??= PartRasterizer.rasterize(
      layer.processedPixels(width, height),
      width,
      height,
      transform,
      mask: part.mask,
    );
  }
}
