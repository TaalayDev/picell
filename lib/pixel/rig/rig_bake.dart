import 'dart:typed_data';

import 'package:uuid/uuid.dart';

import '../../data.dart';
import 'rig_baker.dart';

/// `Layer.stableKey`s that mark the layers a bake manages.
abstract final class RigLayerKeys {
  /// The layer a bake overwrites with the posed pixels.
  static const output = 'rig:output';

  /// An empty layer above it, left alone by baking, for hand touch-ups.
  static const cleanup = 'rig:cleanup';
}

/// What a bake changes in the output animation, before anything is written.
class RigBakePlan {
  const RigBakePlan({required this.updated, required this.added, required this.removed});

  /// Existing frames, with their rig layer replaced.
  final List<AnimationFrame> updated;

  /// New frames (id 0, layers not yet stored).
  final List<AnimationFrame> added;

  /// Existing frames past the end of the clip.
  final List<AnimationFrame> removed;
}

/// Decides how baked buffers map onto an output animation's frames. Pure.
///
/// Frame `i` of the clip becomes frame `i` of the animation. Only the rig
/// layer of a frame is rewritten, so cleanup layers and anything else the
/// user added survive a re-bake.
abstract final class RigBakePlanner {
  static bool isRigFrame(AnimationFrame frame) => frame.layers.any((l) => l.stableKey == RigLayerKeys.output);

  static bool _hasPixels(Layer layer) => layer.pixels.any((p) => p != 0);

  /// Whether [frame] holds anything a bake does not produce: pixels on any
  /// layer other than the rig layer.
  static bool hasHandEdits(AnimationFrame frame) =>
      frame.layers.any((l) => l.stableKey != RigLayerKeys.output && _hasPixels(l));

  /// Frames a bake of [rig] would delete that hold hand edits.
  static List<AnimationFrame> removalsWithEdits({required Rig rig, required List<AnimationFrame> frames}) {
    final clip = rig.clips.isEmpty ? null : rig.clips.first;
    final outputId = rig.outputStateId;
    if (clip == null || outputId == null) return const [];
    final existing = frames.where((f) => f.stateId == outputId).toList();
    return [
      for (final f in existing.skip(clip.length))
        if (hasHandEdits(f)) f,
    ];
  }

  static RigBakePlan plan({
    required List<AnimationFrame> existing,
    required List<Uint32List> baked,
    required int stateId,
    required int durationMs,
    required int firstNewOrder,
    required int width,
    required int height,
    String Function()? newId,
  }) {
    final makeId = newId ?? () => const Uuid().v4();
    final updated = <AnimationFrame>[];
    final added = <AnimationFrame>[];

    for (var i = 0; i < baked.length; i++) {
      final pixels = Uint32List.fromList(baked[i]);

      if (i < existing.length) {
        final frame = existing[i];
        final at = frame.layers.indexWhere((l) => l.stableKey == RigLayerKeys.output);
        final List<Layer> layers;
        if (at >= 0) {
          layers = [
            for (final (index, l) in frame.layers.indexed) index == at ? l.copyWith(pixels: pixels) : l,
          ];
        } else {
          // The user deleted the rig layer: put a fresh one at the bottom.
          layers = [
            Layer(
              layerId: 0,
              id: makeId(),
              name: 'Rig',
              pixels: pixels,
              isLocked: true,
              stableKey: RigLayerKeys.output,
            ),
            ...frame.layers,
          ];
        }
        updated.add(frame.copyWith(
          duration: durationMs,
          layers: [for (final (index, l) in layers.indexed) l.order == index ? l : l.copyWith(order: index)],
        ));
      } else {
        added.add(AnimationFrame(
          id: 0,
          stateId: stateId,
          name: 'Frame ${i + 1}',
          duration: durationMs,
          order: firstNewOrder + added.length,
          layers: [
            Layer(
              layerId: 0,
              id: makeId(),
              name: 'Rig',
              pixels: pixels,
              isLocked: true,
              order: 0,
              stableKey: RigLayerKeys.output,
            ),
            Layer(
              layerId: 0,
              id: makeId(),
              name: 'Cleanup',
              pixels: Uint32List(width * height),
              order: 1,
              stableKey: RigLayerKeys.cleanup,
            ),
          ],
        ));
      }
    }

    return RigBakePlan(updated: updated, added: added, removed: existing.skip(baked.length).toList());
  }
}

class RigBakeResult {
  const RigBakeResult({
    required this.states,
    required this.frames,
    required this.rig,
    required this.outputState,
  });

  final List<AnimationStateModel> states;
  final List<AnimationFrame> frames;

  /// The rig, now pointing at its output animation.
  final Rig rig;
  final AnimationStateModel outputState;
}

/// Bakes a rig's clip into frames and stores them.
///
/// Non-destructive: the rest pose (frame `rig.restFrameIndex` of
/// `rig.stateId`) is only read. The result goes into the rig's output animation, created on the
/// first bake and refreshed after that.
class RigBakeService {
  RigBakeService(this._repo);

  final ProjectRepo _repo;

  /// Whether [rig] has anything to bake: a clip with at least one keyframe,
  /// of a bone or of an IK target.
  static bool canBake(Rig rig) =>
      rig.clips.isNotEmpty && (rig.clips.first.keyframes.isNotEmpty || rig.clips.first.ikKeyframes.isNotEmpty);

  Future<RigBakeResult> bake({
    required int projectId,
    required Rig rig,
    required List<AnimationStateModel> states,
    required List<AnimationFrame> frames,
    required int width,
    required int height,
  }) async {
    if (!canBake(rig)) throw StateError('The rig has no keyframes to bake.');
    final clip = rig.clips.first;

    final source = states.where((s) => s.id == rig.stateId).firstOrNull;
    final sourceFrames = frames.where((f) => f.stateId == rig.stateId).toList();
    final restFrame = sourceFrames.isEmpty ? null : sourceFrames[rig.restFrameIndex.clamp(0, sourceFrames.length - 1)];
    if (source == null || restFrame == null) throw StateError('The rig\'s rest-pose animation no longer exists.');

    final baked = RigBaker(rig: rig, width: width, height: height, layers: restFrame.layers).bakeClip(clip);

    // Find or create the output animation.
    var outputState = states.where((s) => s.id == rig.outputStateId && s.id != rig.stateId).firstOrNull;
    var allStates = states;
    if (outputState == null) {
      outputState = await _repo.createState(
        projectId,
        AnimationStateModel(id: 0, name: '${source.name} (rig)', frameRate: clip.fps),
      );
      allStates = [...states, outputState];
    } else if (outputState.frameRate != clip.fps) {
      final changed = outputState.copyWith(frameRate: clip.fps);
      await _repo.updateState(projectId, changed);
      allStates = [for (final s in states) s.id == changed.id ? changed : s];
      outputState = changed;
    }

    final existing = frames.where((f) => f.stateId == outputState!.id).toList();
    final nextOrder = frames.isEmpty ? 0 : frames.map((f) => f.order).reduce((a, b) => a > b ? a : b) + 1;
    final plan = RigBakePlanner.plan(
      existing: existing,
      baked: baked,
      stateId: outputState.id,
      durationMs: (1000 / clip.fps).round().clamp(1, 1 << 30),
      firstNewOrder: nextOrder,
      width: width,
      height: height,
    );

    // Store. Layers that have no database id yet are created first so the
    // frame write below only ever updates rows it knows.
    final updatedById = <int, AnimationFrame>{};
    for (var frame in plan.updated) {
      final layers = <Layer>[];
      for (final layer in frame.layers) {
        layers.add(layer.layerId == 0 ? await _repo.createLayer(projectId, frame.id, layer) : layer);
      }
      frame = frame.copyWith(layers: layers);
      await _repo.updateFrame(projectId, frame);
      updatedById[frame.id] = frame;
    }
    final created = <AnimationFrame>[];
    for (final frame in plan.added) {
      created.add(await _repo.createFrame(projectId, frame));
    }
    for (final frame in plan.removed) {
      await _repo.deleteFrame(frame.id);
    }

    final removedIds = {for (final f in plan.removed) f.id};
    final newFrames = [
      for (final f in frames)
        if (!removedIds.contains(f.id)) updatedById[f.id] ?? f,
      ...created,
    ];

    return RigBakeResult(
      states: allStates,
      frames: newFrames,
      rig: rig.copyWith(outputStateId: () => outputState!.id),
      outputState: outputState,
    );
  }
}
