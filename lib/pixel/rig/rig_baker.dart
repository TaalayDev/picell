import 'dart:isolate';
import 'dart:typed_data';

import '../../data/models/layer.dart';
import '../../data/models/rig/rig.dart';
import '../pixel_utils.dart';
import 'affine2.dart';
import 'part_rasterizer.dart';
import 'pose_interpolator.dart';
import 'rig_solver.dart';
import 'rotsprite.dart';
import 'rig_layer_influences.dart';

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
  final Map<String, RotSpriteSource> _sprites = {};
  late final _parts = RigLayerInfluences.resolve(rig, width, height);

  RigBaker({required this.rig, required this.width, required this.height, required this.layers});

  /// The composite of every layer at [time] of [clip]: parts moved by their
  /// bones, plus layers no bone drives, which stay where they are. Always a
  /// new buffer.
  Uint32List bakeFrame(RigClip clip, double time) {
    final world = RigSolver.solveClip(rig, clip, time).world;
    final bones = {for (final bone in rig.bones) bone.id: bone};
    final byKey = {
      for (final layer in layers)
        if (layer.stableKey != null) layer.stableKey!: layer,
    };
    final boundKeys = {for (final part in _parts) part.layerKey};
    final orderOffsets = PoseInterpolator.sampleOrder(clip, time);

    // Everything to draw, with its stacking position. Parts carry the order
    // the editor gave them (their layer's position); still layers use their
    // own position, so both interleave exactly like the layer stack.
    // A moved part sits half a step past the layer it lands on, so it never
    // ties with that layer.
    double orderOf(RigPart part) {
      final offset = orderOffsets[part.boneId] ?? 0;
      return part.drawOrder + offset + (offset == 0 ? 0 : (offset > 0 ? .5 : -.5));
    }

    final entries = <({double order, Layer layer, RigPart? part})>[
      for (final part in _parts)
        if (byKey[part.layerKey] != null) (order: orderOf(part), layer: byKey[part.layerKey]!, part: part),
      for (final (index, layer) in layers.indexed)
        if (layer.stableKey == null || !boundKeys.contains(layer.stableKey)) (order: index.toDouble(), layer: layer, part: null),
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
        // Keep the exact shared joint transform; nearest-neighbour rasterization
        // still preserves the source palette without independently moving joints.
        var transform = world[bone.id] ?? Affine2.identity;
        final socket = rig.attachments.where((a) => a.id == part.attachmentId).firstOrNull;
        if (socket != null) {
          final pivot = part.pivotOverride ?? bone.head;
          transform = Affine2.translation(-pivot.dx, -pivot.dy).then(RigSolver.attachmentTransform(rig, socket, world));
        }
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

  /// Below this many canvas pixels times frames a clip bakes in a moment,
  /// so it stays on the calling isolate; above it the UI would stall.
  static const backgroundThreshold = 128 * 128 * 24;

  /// [bakeClip] for [rig]'s [clip] without blocking the UI: big jobs run on
  /// a background isolate, which sends the frames back one by one and
  /// reports [onProgress] (0..1) as it goes. Small jobs bake right here.
  static Future<List<Uint32List>> bakeClipInBackground({
    required Rig rig,
    required RigClip clip,
    required int width,
    required int height,
    required List<Layer> layers,
    void Function(double progress)? onProgress,
  }) async {
    if (width * height * clip.length <= backgroundThreshold) {
      final frames = RigBaker(rig: rig, width: width, height: height, layers: layers).bakeClip(clip);
      onProgress?.call(1);
      return frames;
    }

    // The rig with this clip active, and the layers, travel as JSON.
    final job = (
      rig: rig.copyWith(clips: [clip], activeClipId: () => clip.id).toJson(),
      layers: [for (final layer in layers) layer.toJson()],
      width: width,
      height: height,
    );
    final port = ReceivePort();
    final frames = <Uint32List>[];
    try {
      await Isolate.spawn(_bakeOnIsolate, (port.sendPort, job), onError: port.sendPort, onExit: port.sendPort);
      await for (final message in port) {
        switch (message) {
          case TransferableTypedData():
            frames.add(message.materialize().asUint32List());
            onProgress?.call(frames.length / clip.length);
          case [final Object? error, final Object? stack]:
            throw RemoteError('$error', '$stack');
          case null:
            break; // the isolate exited
        }
        if (message == null || frames.length == clip.length) break;
      }
    } finally {
      port.close();
    }
    if (frames.length != clip.length) {
      throw StateError('Baking stopped after ${frames.length} of ${clip.length} frames.');
    }
    return frames;
  }

  static void _bakeOnIsolate(
    (SendPort, ({Map<String, dynamic> rig, List<Map<String, dynamic>> layers, int width, int height})) request,
  ) {
    final (port, job) = request;
    final rig = Rig.fromJson(job.rig);
    final clip = rig.activeClip!;
    final baker = RigBaker(
      rig: rig,
      width: job.width,
      height: job.height,
      layers: [for (final json in job.layers) Layer.fromJson(json)],
    );
    for (var t = 0; t < clip.length; t++) {
      port.send(TransferableTypedData.fromList([baker.bakeFrame(clip, t.toDouble())]));
    }
  }

  // Equal poses recur constantly (snapped angles, stepped easing, loops), so
  // a rasterized part is reused whenever its transform repeats. Cached
  // buffers are only read by bakeFrame, never handed out.
  Uint32List _rasterize(RigPart part, Layer layer, Affine2 transform) {
    final key = '${part.id}|${layer.id}|${transform.cacheKey}';
    if (rig.settings.rotationModeFor(part.layerKey) == RigRotationMode.rotsprite) {
      // The enlarged image is built once per part; poses only sample it.
      final sprite = _sprites[part.id] ??=
          RotSpriteSource(layer.processedPixels(width, height), width, height, mask: part.mask);
      return _partCache[key] ??= sprite.rasterize(transform);
    }
    return _partCache[key] ??= PartRasterizer.rasterize(
      layer.processedPixels(width, height),
      width,
      height,
      transform,
      mask: part.mask,
    );
  }
}
