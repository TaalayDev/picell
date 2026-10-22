import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../../data/models/layer.dart';
import '../../data/models/rig/rig.dart';
import 'affine2.dart';
import 'presets/bone_presets.dart';
import 'presets/motion_presets.dart';
import 'presets/name_tokens.dart';
import 'pose_interpolator.dart';
import 'rig_solver.dart';

/// Setup builds the skeleton; animate poses it over time.
enum RigMode { setup, animate }

enum RigTool {
  /// Select bones. In setup, also drag a joint to move a bone and its tip to
  /// reshape it.
  select,

  /// Setup: drag out a new bone. Starting on another bone's tip makes it a
  /// child.
  createBone,

  /// Animate: drag to rotate the selected bone about its joint.
  rotate,

  /// Animate: drag to translate the selected bone (and its children).
  move,
}

/// A bone as currently shown: at its rest position in setup, posed in animate.
typedef DisplayBone = ({Bone bone, Offset head, Offset tail});

/// The parts of a placement box that can be grabbed.
enum PlacementHandle { move, left, right, top, bottom, topLeft, topRight, bottomLeft, bottomRight }

/// A skeleton preset on its way onto the canvas: where it will go, and how.
class PresetPlacement {
  const PresetPlacement({
    required this.preset,
    required this.box,
    this.flip = false,
    this.withIk = false,
    this.attach = false,
  });

  final BonePreset preset;

  /// The box, in canvas pixels, the preset is stretched to fill.
  final Rect box;
  final bool flip;
  final bool withIk;

  /// Whether its roots hang from the selected bone.
  final bool attach;

  PresetPlacement copyWith({Rect? box, bool? flip, bool? withIk, bool? attach}) => PresetPlacement(
        preset: preset,
        box: box ?? this.box,
        flip: flip ?? this.flip,
        withIk: withIk ?? this.withIk,
        attach: attach ?? this.attach,
      );
}

/// What adding a preset did.
class PlacedPreset {
  const PlacedPreset({required this.boneIds, required this.boundLayers});

  final List<String> boneIds;

  /// Layers that were bound to the new bones because their names matched.
  final int boundLayers;
}

enum RigHitPart {
  head,
  tail,
  body,

  /// The grab handle of an IK chain's target (animate mode).
  ikTarget,
}

class RigHit {
  final String boneId;
  final RigHitPart part;

  /// The chain whose target was hit, for [RigHitPart.ikTarget].
  final String? chainId;
  const RigHit(this.boneId, this.part, {this.chainId});

  @override
  bool operator ==(Object other) =>
      other is RigHit && other.boneId == boneId && other.part == part && other.chainId == chainId;

  @override
  int get hashCode => Object.hash(boneId, part, chainId);
}

/// State and edit operations of the rig editor's setup mode.
///
/// Keeps its own immutable-[Rig] undo history, independent from the pixel
/// editor's, so leaving the screen is one step for the editor no matter how
/// much was done here. Pure Dart: everything the screen does goes through
/// here, which is what the tests exercise.
///
/// Coordinates are canvas pixels.
class RigEditorController extends ChangeNotifier {
  RigEditorController({
    required Rig rig,
    required this.restLayers,
    required this.width,
    required this.height,
    String Function()? newId,
    int defaultFps = 12,
    String clipName = 'Animation',
  })  : _rig = rig,
        _initial = rig,
        _newId = newId ?? _defaultId,
        _draftClip = RigClip(id: 'main', name: clipName, fps: defaultFps);

  /// Rest-pose layers (bottom first, keyed with `Layer.stableKey`).
  final List<Layer> restLayers;
  final int width;
  final int height;
  final String Function() _newId;

  static var _counter = 0;
  static String _defaultId() => '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}-${_counter++}';

  Rig _rig;
  final Rig _initial;
  Rig get rig => _rig;

  final List<Rig> _undo = [];
  final List<Rig> _redo = [];
  Rig? _gestureBase;

  String? _selectedBoneId;
  String? get selectedBoneId => _selectedBoneId;
  Bone? get selectedBone => bone(_selectedBoneId);

  RigTool _tool = RigTool.select;
  RigTool get tool => _tool;
  set tool(RigTool value) {
    if (_tool == value) return;
    // Tools that make no sense in the current mode are ignored.
    final animating = _mode == RigMode.animate;
    if (animating && value == RigTool.createBone) return;
    if (!animating && (value == RigTool.rotate || value == RigTool.move)) return;
    _tool = value;
    notifyListeners();
  }

  RigMode _mode = RigMode.setup;
  RigMode get mode => _mode;
  set mode(RigMode value) {
    if (_mode == value) return;
    _mode = value;
    _activeLayerKey = null; // arming a layer is a setup gesture
    _placement = null; // and so is placing a preset
    // Posing is what animate mode is for, so start on the rotate tool.
    if (value == RigMode.animate && _tool == RigTool.select) {
      _tool = RigTool.rotate;
    } else if (!_toolFitsMode(_tool)) {
      _tool = RigTool.select;
    }
    notifyListeners();
  }

  bool _toolFitsMode(RigTool t) => _mode == RigMode.animate
      ? t != RigTool.createBone
      : (t != RigTool.rotate && t != RigTool.move);

  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;

  /// Whether the rig differs from what the screen opened with.
  bool get hasChanges => _rig != _initial;

  Bone? bone(String? id) {
    if (id == null) return null;
    for (final b in _rig.bones) {
      if (b.id == id) return b;
    }
    return null;
  }

  List<Bone> childrenOf(String id) => [
        for (final b in _rig.bones)
          if (b.parentId == id) b,
      ];

  /// Bone ids in tree order (parent before children) with their depth.
  List<({Bone bone, int depth})> get tree {
    final out = <({Bone bone, int depth})>[];
    final ids = {for (final b in _rig.bones) b.id};
    final visited = <String>{};

    void walk(Bone b, int depth) {
      if (!visited.add(b.id)) return;
      out.add((bone: b, depth: depth));
      for (final c in childrenOf(b.id)) {
        walk(c, depth + 1);
      }
    }

    for (final b in _rig.bones) {
      if (b.parentId == null || !ids.contains(b.parentId)) walk(b, 0);
    }
    return out;
  }

  // ── Selection ────────────────────────────────────────────────────────────

  void selectBone(String? id) {
    if (id != null && bone(id) == null) id = null;
    if (_selectedBoneId == id && _selectedIkChainId == null) return;
    _selectedBoneId = id;
    _selectedIkChainId = null;
    notifyListeners();
  }

  /// The bone part under [point], or null. Joints win over tips, tips over
  /// bodies, so overlapping handles stay reachable.
  RigHit? hitTest(Offset point, double tolerance) {
    // IK target handles sit on top of everything else.
    if (_mode == RigMode.animate) {
      for (final chain in _rig.ikChains.reversed) {
        final handle = ikHandle(chain);
        if (handle != null && (point - handle).distance <= tolerance) {
          return RigHit(chain.tipBoneId, RigHitPart.ikTarget, chainId: chain.id);
        }
      }
    }

    RigHit? best;
    var bestScore = double.infinity;

    // Later bones are drawn on top, so they win ties.
    for (final d in displayBones.reversed) {
      final b = d.bone;
      final candidates = <(RigHitPart, double)>[
        (RigHitPart.head, (point - d.head).distance),
        (RigHitPart.tail, (point - d.tail).distance),
        (RigHitPart.body, _distanceToSegment(point, d.head, d.tail)),
      ];
      for (final (part, dist) in candidates) {
        if (dist > tolerance) continue;
        // Prefer handles by weighting body hits as farther away.
        final score = dist + (part == RigHitPart.body ? tolerance : 0);
        if (score < bestScore) {
          bestScore = score;
          best = RigHit(b.id, part);
        }
      }
    }
    return best;
  }

  static double _distanceToSegment(Offset p, Offset a, Offset b) {
    final ab = b - a;
    final len2 = ab.dx * ab.dx + ab.dy * ab.dy;
    if (len2 == 0) return (p - a).distance;
    final t = (((p - a).dx * ab.dx + (p - a).dy * ab.dy) / len2).clamp(0.0, 1.0);
    return (p - (a + ab * t)).distance;
  }

  /// Snaps [point] to the centre of the pixel it falls in, clamped to the
  /// canvas. Joints sit on pixels so quarter turns stay on the pixel grid.
  Offset snapToPixel(Offset point) => Offset(
        (point.dx.floorToDouble() + 0.5).clamp(0.5, width - 0.5),
        (point.dy.floorToDouble() + 0.5).clamp(0.5, height - 0.5),
      );

  // ── Gestures / undo ──────────────────────────────────────────────────────

  /// Starts a drag. Edits until [endGesture] collapse into one undo step.
  void beginGesture() {
    _gestureBase ??= _rig;
  }

  void endGesture() {
    final base = _gestureBase;
    _gestureBase = null;
    if (base != null && base != _rig) {
      _pushUndo(base);
    }
  }

  void _pushUndo(Rig previous) {
    _undo.add(previous);
    _redo.clear();
  }

  void _commit(Rig next) {
    if (next == _rig) return;
    if (_gestureBase == null) _pushUndo(_rig);
    _rig = next;
    notifyListeners();
  }

  void undo() {
    if (_undo.isEmpty) return;
    _redo.add(_rig);
    _rig = _undo.removeLast();
    _afterHistoryJump();
  }

  void redo() {
    if (_redo.isEmpty) return;
    _undo.add(_rig);
    _rig = _redo.removeLast();
    _afterHistoryJump();
  }

  void _afterHistoryJump() {
    if (bone(_selectedBoneId) == null) _selectedBoneId = null;
    notifyListeners();
  }

  // ── Bones ────────────────────────────────────────────────────────────────

  /// Where a new bone that starts at [point] should attach: on any part of an
  /// existing bone (within [tolerance]) it becomes that bone's child, joined
  /// at the joint, tip or - along the body - the nearest pixel of the line.
  /// Away from every bone it is a free root starting at [point]'s pixel.
  ({String? parentId, Offset head}) attachPoint(Offset point, double tolerance) {
    final hit = hitTest(point, tolerance);
    final d = hit == null ? null : displayBone(hit.boneId);
    if (hit == null || d == null) return (parentId: null, head: snapToPixel(point));

    switch (hit.part) {
      case RigHitPart.head:
        return (parentId: hit.boneId, head: d.head);
      case RigHitPart.tail:
        return (parentId: hit.boneId, head: d.tail);
      case RigHitPart.body:
        return (parentId: hit.boneId, head: snapToPixel(_nearestOnSegment(point, d.head, d.tail)));
      case RigHitPart.ikTarget:
        // Only offered while animating, when bones cannot be drawn.
        return (parentId: null, head: snapToPixel(point));
    }
  }

  static Offset _nearestOnSegment(Offset p, Offset a, Offset b) {
    final ab = b - a;
    final len2 = ab.dx * ab.dx + ab.dy * ab.dy;
    if (len2 == 0) return a;
    final t = (((p - a).dx * ab.dx + (p - a).dy * ab.dy) / len2).clamp(0.0, 1.0);
    return a + ab * t;
  }

  /// Adds a bone from [head] to [tail] (both snapped to pixels) and selects
  /// it. Returns its id, or null when it would be shorter than one pixel.
  ///
  /// If a layer is armed ([selectLayer]) the new bone is bound to it, in the
  /// same undo step, and the layer is disarmed.
  String? addBone({required Offset head, required Offset tail, String? parentId, String? name}) {
    head = snapToPixel(head);
    tail = snapToPixel(tail);
    final delta = tail - head;
    if (delta.distance < 1) return null;
    if (parentId != null && bone(parentId) == null) parentId = null;

    final id = _newId();
    final created = Bone(
      id: id,
      name: name ?? _uniqueName('bone'),
      parentId: parentId,
      head: head,
      length: delta.distance,
      restAngle: _degrees(delta),
    );

    final armed = _activeLayerKey;
    _commit(_rig.copyWith(
      bones: [..._rig.bones, created],
      parts: armed == null ? null : _partsBinding(armed, id) ?? _rig.parts,
    ));
    _activeLayerKey = null;
    _selectedBoneId = id;
    notifyListeners();
    return id;
  }

  String _uniqueName(String base) {
    final names = {for (final b in _rig.bones) b.name};
    for (var i = _rig.bones.length + 1;; i++) {
      final candidate = '${base}_$i';
      if (!names.contains(candidate)) return candidate;
    }
  }

  static double _degrees(Offset v) => math.atan2(v.dy, v.dx) * 180 / math.pi;

  /// Moves [id] and everything below it by [delta] (snapped to whole pixels).
  void moveBone(String id, Offset delta) {
    if (bone(id) == null) return;
    delta = Offset(delta.dx.roundToDouble(), delta.dy.roundToDouble());
    if (delta == Offset.zero) return;
    final moving = {id, ..._descendants(id)};
    _commit(_rig.copyWith(bones: [
      for (final b in _rig.bones) moving.contains(b.id) ? b.copyWith(head: b.head + delta) : b,
    ]));
  }

  /// Points the bone at [tail] (snapped), keeping its head. Ignored when it
  /// would collapse the bone.
  void setBoneTail(String id, Offset tail) {
    final b = bone(id);
    if (b == null) return;
    final newTail = snapToPixel(tail);
    final delta = newTail - b.head;
    if (delta.distance < 1) return;

    // Children attached at this bone's tip stay attached: they, and
    // everything below them, travel with the tip.
    final oldTail = b.tail;
    final shift = <String, Offset>{};
    for (final c in _rig.bones) {
      if (c.parentId == id && (c.head - oldTail).distance < 0.51) {
        final move = newTail - c.head;
        shift[c.id] = move;
        for (final d in _descendants(c.id)) {
          shift[d] = move;
        }
      }
    }

    _commit(_rig.copyWith(bones: [
      for (final x in _rig.bones)
        if (x.id == id)
          x.copyWith(length: delta.distance, restAngle: _degrees(delta))
        else if (shift.containsKey(x.id))
          x.copyWith(head: x.head + shift[x.id]!)
        else
          x,
    ]));
  }

  void renameBone(String id, String name) {
    name = name.trim();
    if (name.isEmpty || bone(id) == null) return;
    _commit(_rig.copyWith(bones: [
      for (final b in _rig.bones) b.id == id ? b.copyWith(name: name) : b,
    ]));
  }

  /// Rotation limits in degrees relative to the rest angle; null clears one.
  void setBoneLimits(String id, {double? min, double? max}) {
    if (bone(id) == null) return;
    if (min != null && max != null && min > max) (min, max) = (max, min);
    _commit(_rig.copyWith(bones: [
      for (final b in _rig.bones) b.id == id ? b.copyWith(minAngle: () => min, maxAngle: () => max) : b,
    ]));
  }

  /// Makes [parentId] the parent of [id] (null = root). Returns false, and
  /// changes nothing, if that would make a bone its own ancestor.
  bool reparent(String id, String? parentId) {
    if (bone(id) == null) return false;
    if (parentId != null) {
      if (bone(parentId) == null) return false;
      if (parentId == id || _descendants(id).contains(parentId)) return false;
    }
    _commit(_rig.copyWith(bones: [
      for (final b in _rig.bones) b.id == id ? b.copyWith(parentId: () => parentId) : b,
    ]));
    return true;
  }

  /// Deletes [id]. Its children move up to its parent; parts bound to it are
  /// unbound; keyframes of the bone are dropped.
  void deleteBone(String id) {
    final target = bone(id);
    if (target == null) return;
    // A chain ending at the deleted bone has nothing left to reach with.
    final gone = {
      for (final c in _rig.ikChains)
        if (c.tipBoneId == id) c.id,
    };
    _commit(_rig.copyWith(
      bones: [
        for (final b in _rig.bones)
          if (b.id != id) b.parentId == id ? b.copyWith(parentId: () => target.parentId) : b,
      ],
      parts: [
        for (final p in _rig.parts)
          if (p.boneId != id) p,
      ],
      ikChains: [
        for (final c in _rig.ikChains)
          if (!gone.contains(c.id)) c,
      ],
      poses: [
        for (final p in _rig.poses)
          p.copyWith(
            bones: {
              for (final e in p.bones.entries)
                if (e.key != id) e.key: e.value,
            },
            ik: {
              for (final e in p.ik.entries)
                if (!gone.contains(e.key)) e.key: e.value,
            },
          ),
      ],
      clips: [
        for (final c in _rig.clips)
          c.copyWith(
            keyframes: [for (final k in c.keyframes) if (k.boneId != id) k],
            ikKeyframes: [for (final k in c.ikKeyframes) if (!gone.contains(k.chainId)) k],
          ),
      ],
    ));
    if (_selectedIkChainId != null && ikChain(_selectedIkChainId) == null) _selectedIkChainId = null;
    if (_selectedBoneId == id) {
      _selectedBoneId = null;
      notifyListeners();
    }
  }

  Set<String> _descendants(String id) {
    final out = <String>{};
    void walk(String parent) {
      for (final b in _rig.bones) {
        if (b.parentId == parent && out.add(b.id)) walk(b.id);
      }
    }

    walk(id);
    return out;
  }

  // ── Animation ────────────────────────────────────────────────────────────

  final RigClip _draftClip;
  int _time = 0;
  Map<String, BonePose>? _clipboard;
  Map<String, Offset> _ikClipboard = const {};

  /// The clip being edited. A rig starts without one; the first keyframe
  /// stores this draft in the rig, so merely looking at animate mode leaves
  /// the rig untouched.
  RigClip get activeClip => _rig.clips.isNotEmpty ? _rig.clips.first : _draftClip;

  /// The frame being viewed and edited.
  int get time => _time.clamp(0, activeClip.length - 1);

  void setTime(int frame) {
    frame = frame.clamp(0, activeClip.length - 1);
    if (frame == _time) return;
    _time = frame;
    notifyListeners();
  }

  /// Poses of every bone at [time]; empty (all at rest) in setup mode.
  Map<String, BonePose> get poses =>
      _mode == RigMode.animate ? PoseInterpolator.sample(activeClip, _rig.bones, time.toDouble()) : const {};

  BonePose poseOf(String boneId) => poses[boneId] ?? BonePose.rest;

  /// Where each IK chain's target is on the current frame (animate mode);
  /// chains without keys are absent.
  Map<String, Offset> get _ikTargets =>
      _mode == RigMode.animate ? PoseInterpolator.sampleIk(activeClip, _rig.ikChains, time.toDouble()) : const {};

  SolvedRig get _solved => RigSolver.solveIk(_rig, poses, _ikTargets);

  Map<String, Affine2> get _world => _solved.world;

  /// A bone's pose as the rig really shows it: its own keys, except that
  /// bones driven by an active IK chain have the rotation the solver chose.
  BonePose shownPoseOf(String boneId) => _solved.poses[boneId] ?? BonePose.rest;

  /// Bones as drawn: rest positions in setup, posed (with the same
  /// whole-pixel joint snapping the baked pixels get) in animate.
  List<DisplayBone> get displayBones {
    if (_mode == RigMode.setup) {
      return [for (final b in _rig.bones) (bone: b, head: b.head, tail: b.tail)];
    }
    final world = _world;
    return [
      for (final b in _rig.bones)
        () {
          final t = (world[b.id] ?? Affine2.identity).withIntegerDisplacementAt(b.head);
          return (bone: b, head: t.apply(b.head), tail: t.apply(b.tail));
        }(),
    ];
  }

  DisplayBone? displayBone(String id) {
    for (final d in displayBones) {
      if (d.bone.id == id) return d;
    }
    return null;
  }

  Affine2 _parentWorld(String boneId) {
    final parentId = bone(boneId)?.parentId;
    return (parentId == null ? null : _world[parentId]) ?? Affine2.identity;
  }

  /// +1, or -1 when the bone's parent chain mirrors it, so a drag that turns
  /// clockwise on screen turns the bone the way the pointer went.
  double rotationSign(String boneId) => _parentWorld(boneId).determinant < 0 ? -1 : 1;

  /// A screen-space [delta] expressed in the bone's own (rest-pose) frame.
  Offset toLocalDelta(String boneId, Offset delta) =>
      _parentWorld(boneId).invert()?.applyVector(delta) ?? delta;

  RigKeyframe? keyAt(String boneId, int frame) {
    for (final k in activeClip.keyframes) {
      if (k.boneId == boneId && k.time == frame) return k;
    }
    return null;
  }

  /// Keyed frames of [boneId], for the timeline.
  Set<int> keyTimes(String boneId) => {
        for (final k in activeClip.keyframes)
          if (k.boneId == boneId) k.time,
      };

  void _updateClip(RigClip Function(RigClip) change) {
    final next = change(activeClip);
    _commit(_rig.copyWith(clips: [next, ..._rig.clips.skip(1)]));
  }

  RigClip _withKeys(RigClip clip, Iterable<RigKeyframe> keys) {
    final replaced = {for (final k in keys) (k.boneId, k.time)};
    return clip.copyWith(keyframes: [
      for (final k in clip.keyframes)
        if (!replaced.contains((k.boneId, k.time))) k,
      ...keys,
    ]);
  }

  RigKeyframe _keyFor(Bone bone, BonePose base, {double? rotation, Offset? translation, bool? flipX}) {
    var r = rotation ?? base.rotation;
    final lo = bone.minAngle, hi = bone.maxAngle;
    if (lo != null && r < lo) r = lo;
    if (hi != null && r > hi) r = hi;
    return RigKeyframe(
      time: time,
      boneId: bone.id,
      rotation: r,
      translation: translation ?? base.translation,
      flipX: flipX ?? base.flipX,
      easing: keyAt(bone.id, time)?.easing ?? RigEasing.linear,
    );
  }

  /// Poses [boneId] at the current frame, keying it there (auto-key). Values
  /// left null keep what the bone does at this frame now.
  void setPose(String boneId, {double? rotation, Offset? translation, bool? flipX}) {
    final b = bone(boneId);
    if (b == null) return;
    final key = _keyFor(b, poseOf(boneId), rotation: rotation, translation: translation, flipX: flipX);
    if (keyAt(boneId, time) == key) return;
    _updateClip((clip) => _withKeys(clip, [key]));
  }

  /// Keys [boneId] at the current frame exactly as it is posed now.
  void keyBone(String boneId) {
    final b = bone(boneId);
    if (b == null || keyAt(boneId, time) != null) return;
    _updateClip((clip) => _withKeys(clip, [_keyFor(b, poseOf(boneId))]));
  }

  void deleteKey(String boneId, int frame) {
    if (keyAt(boneId, frame) == null) return;
    _updateClip((clip) => clip.copyWith(keyframes: [
          for (final k in clip.keyframes)
            if (!(k.boneId == boneId && k.time == frame)) k,
        ]));
  }

  /// Sets how the bone eases from the key at [frame] to its next key.
  void setKeyEasing(String boneId, int frame, RigEasing easing) {
    final key = keyAt(boneId, frame);
    if (key == null || key.easing == easing) return;
    _updateClip((clip) => _withKeys(clip, [key.copyWith(easing: easing)]));
  }

  bool get canPastePose => _clipboard != null;

  /// Remembers every bone's pose at the current frame.
  void copyPose() {
    _clipboard = Map.of(poses);
    _ikClipboard = Map.of(_ikTargets);
    notifyListeners();
  }

  /// Keys every copied bone at the current frame with the copied pose.
  void pastePose() {
    final clipboard = _clipboard;
    if (clipboard == null) return;
    _applyPose(clipboard, _ikClipboard);
  }

  /// Keys the given bone poses and IK targets at the current frame, as one
  /// edit. Bones and chains that no longer exist are skipped.
  void _applyPose(Map<String, BonePose> bones, Map<String, Offset> ik) {
    final keys = [
      for (final e in bones.entries)
        if (bone(e.key) != null)
          _keyFor(bone(e.key)!, e.value, rotation: e.value.rotation, translation: e.value.translation, flipX: e.value.flipX),
    ];
    final ikKeys = [
      for (final e in ik.entries)
        if (ikChain(e.key) != null) IkKeyframe(time: time, chainId: e.key, target: e.value),
    ];
    if (keys.isEmpty && ikKeys.isEmpty) return;
    _updateClip((clip) => _withIkKeys(_withKeys(clip, keys), ikKeys));
  }

  // ── Pose library ─────────────────────────────────────────────────────────

  List<RigPose> get savedPoses => _rig.poses;

  RigPose? savedPose(String id) {
    for (final p in _rig.poses) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// Saves how the rig is posed on the current frame under [name] (blank
  /// names become "Pose N"; a taken name gets a number). Returns the id.
  /// Keys are saved as they are, not as the IK solver bent them, so applying
  /// the pose later reproduces the same edit.
  String? savePose(String name) {
    if (_mode != RigMode.animate || _rig.bones.isEmpty) return null;
    final taken = {for (final p in _rig.poses) p.name};
    var base = name.trim();
    if (base.isEmpty) base = 'Pose ${_rig.poses.length + 1}';
    var unique = base;
    for (var i = 2; taken.contains(unique); i++) {
      unique = '$base $i';
    }

    final id = _newId();
    _commit(_rig.copyWith(poses: [
      ..._rig.poses,
      RigPose(id: id, name: unique, bones: Map.of(poses), ik: Map.of(_ikTargets)),
    ]));
    return id;
  }

  /// Puts a saved pose on the current frame: every bone and IK target it
  /// mentions is keyed here. One undo step.
  void applyPose(String id) {
    final pose = savedPose(id);
    if (pose == null || _mode != RigMode.animate) return;
    _applyPose(pose.bones, pose.ik);
  }

  void renamePose(String id, String name) {
    name = name.trim();
    final pose = savedPose(id);
    if (pose == null || name.isEmpty || pose.name == name) return;
    _commit(_rig.copyWith(poses: [for (final p in _rig.poses) p.id == id ? p.copyWith(name: name) : p]));
  }

  void deletePose(String id) {
    if (savedPose(id) == null) return;
    _commit(_rig.copyWith(poses: [
      for (final p in _rig.poses)
        if (p.id != id) p,
    ]));
  }

  /// Length in frames, 1..240. Keys beyond the new end are dropped.
  void setClipLength(int frames) {
    frames = frames.clamp(1, 240);
    if (frames == activeClip.length) return;
    _updateClip((clip) => clip.copyWith(
          length: frames,
          keyframes: [
            for (final k in clip.keyframes)
              if (k.time < frames) k,
          ],
          ikKeyframes: [
            for (final k in clip.ikKeyframes)
              if (k.time < frames) k,
          ],
        ));
    _time = _time.clamp(0, frames - 1);
  }

  void setFps(int fps) {
    fps = fps.clamp(1, 60);
    if (fps == activeClip.fps) return;
    _updateClip((clip) => clip.copyWith(fps: fps));
  }

  void setLoop(bool loop) {
    if (loop == activeClip.loop) return;
    _updateClip((clip) => clip.copyWith(loop: loop));
  }

  // ── Inverse kinematics ───────────────────────────────────────────────────

  String? _selectedIkChainId;

  IkChain? ikChain(String? id) {
    if (id == null) return null;
    for (final c in _rig.ikChains) {
      if (c.id == id) return c;
    }
    return null;
  }

  /// The chain being edited: the one picked on the canvas or timeline, or
  /// else the one whose tip is the selected bone.
  IkChain? get selectedIkChain => ikChain(_selectedIkChainId) ?? ikChainWithTip(_selectedBoneId);

  IkChain? ikChainWithTip(String? boneId) {
    if (boneId == null) return null;
    for (final c in _rig.ikChains) {
      if (c.tipBoneId == boneId) return c;
    }
    return null;
  }

  /// Chains the bone takes part in, as tip or as one of the bones behind it.
  List<IkChain> ikChainsOf(String boneId) => [
        for (final c in _rig.ikChains)
          if (_rig.chainBones(c).any((b) => b.id == boneId)) c,
      ];

  /// Whether an IK chain is steering the bone on this frame: the chain has
  /// target keys, so its bones' own rotation keys are only a starting guess.
  bool isIkDriven(String boneId) => ikChainsOf(boneId).any((c) => _hasIkKeys(c.id));

  bool _hasIkKeys(String chainId) => activeClip.ikKeyframes.any((k) => k.chainId == chainId);

  /// Picks [chainId] (null to drop the pick) and its tip bone.
  void selectIkChain(String? chainId) {
    final chain = ikChain(chainId);
    _selectedIkChainId = chain?.id;
    if (chain != null) _selectedBoneId = chain.tipBoneId;
    notifyListeners();
  }

  /// Makes the bones from [tipBoneId] up [boneCount] parents an IK chain
  /// (default 2, as many as the bone has ancestors at most). Returns its id,
  /// or null if the bone is unknown or already ends a chain.
  String? addIkChain({required String tipBoneId, int? boneCount, int bend = 1, String? name}) {
    final tip = bone(tipBoneId);
    if (tip == null || ikChainWithTip(tipBoneId) != null) return null;
    final most = _rig.maxChainLength(tipBoneId);
    final count = (boneCount ?? 2).clamp(1, most);

    final names = {for (final c in _rig.ikChains) c.name};
    var chainName = name ?? '${tip.name}_ik';
    for (var i = 2; names.contains(chainName); i++) {
      chainName = '${name ?? '${tip.name}_ik'}_$i';
    }

    final id = _newId();
    _commit(_rig.copyWith(ikChains: [
      ..._rig.ikChains,
      IkChain(id: id, name: chainName, tipBoneId: tipBoneId, boneCount: count, bend: bend < 0 ? -1 : 1),
    ]));
    _selectedIkChainId = id;
    notifyListeners();
    return id;
  }

  /// Removes the chain and its target keys; its bones keep their own keys.
  void removeIkChain(String chainId) {
    if (ikChain(chainId) == null) return;
    _commit(_rig.copyWith(
      ikChains: [
        for (final c in _rig.ikChains)
          if (c.id != chainId) c,
      ],
      poses: [
        for (final p in _rig.poses)
          p.copyWith(ik: {
            for (final e in p.ik.entries)
              if (e.key != chainId) e.key: e.value,
          }),
      ],
      clips: [
        for (final c in _rig.clips)
          c.copyWith(ikKeyframes: [for (final k in c.ikKeyframes) if (k.chainId != chainId) k]),
      ],
    ));
    if (_selectedIkChainId == chainId) _selectedIkChainId = null;
    notifyListeners();
  }

  /// Changes how many bones the chain spans (1 up to the tip's ancestors) or
  /// which way it folds.
  void setIkChain(String chainId, {int? boneCount, int? bend}) {
    final chain = ikChain(chainId);
    if (chain == null) return;
    final next = chain.copyWith(
      boneCount: boneCount?.clamp(1, _rig.maxChainLength(chain.tipBoneId)),
      bend: bend == null ? null : (bend < 0 ? -1 : 1),
    );
    if (next == chain) return;
    _commit(_rig.copyWith(ikChains: [for (final c in _rig.ikChains) c.id == chainId ? next : c]));
  }

  /// Where [chainId]'s target is on this frame, or null if it has no keys.
  Offset? ikTarget(String chainId) => _ikTargets[chainId];

  /// Where to grab the chain on the canvas: its target if it has one, else
  /// the tip of its last bone. Null in setup mode or if the tip is gone.
  Offset? ikHandle(IkChain chain) {
    if (_mode != RigMode.animate) return null;
    return _ikTargets[chain.id] ?? displayBone(chain.tipBoneId)?.tail;
  }

  IkKeyframe? ikKeyAt(String chainId, int frame) {
    for (final k in activeClip.ikKeyframes) {
      if (k.chainId == chainId && k.time == frame) return k;
    }
    return null;
  }

  Set<int> ikKeyTimes(String chainId) => {
        for (final k in activeClip.ikKeyframes)
          if (k.chainId == chainId) k.time,
      };

  RigClip _withIkKeys(RigClip clip, Iterable<IkKeyframe> keys) {
    final replaced = {for (final k in keys) (k.chainId, k.time)};
    return clip.copyWith(ikKeyframes: [
      for (final k in clip.ikKeyframes)
        if (!replaced.contains((k.chainId, k.time))) k,
      ...keys,
    ]);
  }

  /// Puts the chain's target on [target] (snapped to a pixel) at the current
  /// frame, keying it there (auto-key). The first key switches the chain on.
  void setIkTarget(String chainId, Offset target) {
    if (ikChain(chainId) == null) return;
    final key = IkKeyframe(
      time: time,
      chainId: chainId,
      target: snapToPixel(target),
      easing: ikKeyAt(chainId, time)?.easing ?? RigEasing.linear,
    );
    if (ikKeyAt(chainId, time) == key) return;
    _updateClip((clip) => _withIkKeys(clip, [key]));
  }

  /// Keys the chain at the current frame where its target (or tip) is now.
  void keyIkChain(String chainId) {
    final chain = ikChain(chainId);
    final here = chain == null ? null : ikHandle(chain);
    if (here == null || ikKeyAt(chainId, time) != null) return;
    setIkTarget(chainId, here);
  }

  void deleteIkKey(String chainId, int frame) {
    if (ikKeyAt(chainId, frame) == null) return;
    _updateClip((clip) => clip.copyWith(ikKeyframes: [
          for (final k in clip.ikKeyframes)
            if (!(k.chainId == chainId && k.time == frame)) k,
        ]));
  }

  void setIkKeyEasing(String chainId, int frame, RigEasing easing) {
    final key = ikKeyAt(chainId, frame);
    if (key == null || key.easing == easing) return;
    _updateClip((clip) => _withIkKeys(clip, [key.copyWith(easing: easing)]));
  }

  // ── Skeleton presets ─────────────────────────────────────────────────────

  /// The smallest a placement box can be, in pixels.
  static const double minPlacementSize = 6;

  PresetPlacement? _placement;

  /// The preset being placed, if any. While there is one the canvas is
  /// showing a box to move and stretch.
  PresetPlacement? get placement => _placement;

  /// Whether the selected bone could be a placement's parent.
  bool get canAttachPlacement => selectedBone != null;

  /// Starts placing [preset] (setup mode). It begins fitted to the artwork,
  /// or, for an add-on such as a tail or a limb, small and at the end of the
  /// selected bone, attached to it.
  void beginPlacement(BonePreset preset) {
    if (_mode != RigMode.setup) return;
    final attach = preset.addOn && selectedBone != null;
    _placement = PresetPlacement(preset: preset, box: _suggestedBox(preset, attach), attach: attach);
    notifyListeners();
  }

  void cancelPlacement() {
    if (_placement == null) return;
    _placement = null;
    notifyListeners();
  }

  void setPlacementFlip(bool flip) => _updatePlacement((p) => p.copyWith(flip: flip));
  void setPlacementIk(bool withIk) => _updatePlacement((p) => p.copyWith(withIk: withIk));
  void setPlacementAttach(bool attach) {
    if (attach && selectedBone == null) return;
    _updatePlacement((p) => p.copyWith(attach: attach));
  }

  void _updatePlacement(PresetPlacement Function(PresetPlacement) change) {
    final current = _placement;
    if (current == null) return;
    final next = change(current);
    if (next.box == current.box && next.flip == current.flip && next.withIk == current.withIk && next.attach == current.attach) {
      return;
    }
    _placement = next;
    notifyListeners();
  }

  /// Moves the whole box by [delta], to whole pixels.
  void movePlacement(Offset delta) {
    final d = Offset(delta.dx.roundToDouble(), delta.dy.roundToDouble());
    if (d == Offset.zero) return;
    _updatePlacement((p) => p.copyWith(box: p.box.shift(d)));
  }

  /// Pulls the edge or corner [handle] to [pointer], to whole pixels. The box
  /// stops at [minPlacementSize]; it never turns inside out.
  void dragPlacementHandle(PlacementHandle handle, Offset pointer) {
    final p = _placement;
    if (p == null || handle == PlacementHandle.move) return;
    var l = p.box.left, t = p.box.top, r = p.box.right, b = p.box.bottom;
    final x = pointer.dx.roundToDouble(), y = pointer.dy.roundToDouble();

    final left = handle == PlacementHandle.left || handle == PlacementHandle.topLeft || handle == PlacementHandle.bottomLeft;
    final right = handle == PlacementHandle.right || handle == PlacementHandle.topRight || handle == PlacementHandle.bottomRight;
    final top = handle == PlacementHandle.top || handle == PlacementHandle.topLeft || handle == PlacementHandle.topRight;
    final bottom = handle == PlacementHandle.bottom || handle == PlacementHandle.bottomLeft || handle == PlacementHandle.bottomRight;

    if (left) l = math.min(x, r - minPlacementSize);
    if (right) r = math.max(x, l + minPlacementSize);
    if (top) t = math.min(y, b - minPlacementSize);
    if (bottom) b = math.max(y, t + minPlacementSize);
    _updatePlacement((p) => p.copyWith(box: Rect.fromLTRB(l, t, r, b)));
  }

  /// The part of the placement box at [point], or null. Corners first, then
  /// edges, then the inside (which moves the whole box).
  PlacementHandle? placementHandleAt(Offset point, double tolerance) {
    final box = _placement?.box;
    if (box == null) return null;
    bool near(double a, double b) => (a - b).abs() <= tolerance;
    final inX = point.dx >= box.left - tolerance && point.dx <= box.right + tolerance;
    final inY = point.dy >= box.top - tolerance && point.dy <= box.bottom + tolerance;

    if (near(point.dx, box.left) && near(point.dy, box.top)) return PlacementHandle.topLeft;
    if (near(point.dx, box.right) && near(point.dy, box.top)) return PlacementHandle.topRight;
    if (near(point.dx, box.left) && near(point.dy, box.bottom)) return PlacementHandle.bottomLeft;
    if (near(point.dx, box.right) && near(point.dy, box.bottom)) return PlacementHandle.bottomRight;
    if (near(point.dx, box.left) && inY) return PlacementHandle.left;
    if (near(point.dx, box.right) && inY) return PlacementHandle.right;
    if (near(point.dy, box.top) && inX) return PlacementHandle.top;
    if (near(point.dy, box.bottom) && inX) return PlacementHandle.bottom;
    if (box.contains(point)) return PlacementHandle.move;
    return null;
  }

  BuiltPreset _buildPlacement(PresetPlacement p, {required String Function() newId, required Set<String> takenNames}) {
    return BonePresetBuilder.build(
      p.preset,
      box: p.box,
      snap: snapToPixel,
      newId: newId,
      flip: p.flip,
      withIk: p.withIk,
      attachTo: p.attach ? _selectedBoneId : null,
      takenNames: takenNames,
    );
  }

  /// The bones of the placement as they would land, for drawing a preview.
  List<({Offset head, Offset tail})> get placementGhost {
    final p = _placement;
    if (p == null) return const [];
    var i = 0;
    final built = _buildPlacement(p, newId: () => '${i++}', takenNames: const {});
    return [for (final b in built.bones) (head: b.head, tail: b.tail)];
  }

  /// Adds the preset to the rig as one undo step, selects its first bone,
  /// and binds any layer that has no bone yet and is named like one of the
  /// new bones ("Head", "Left Arm"...). Does nothing without a placement.
  PlacedPreset? commitPlacement() {
    final p = _placement;
    if (p == null) return null;

    final taken = {for (final b in _rig.bones) b.name};
    final built = _buildPlacement(p, newId: _newId, takenNames: taken);

    // Layers waiting for a bone, matched to the new bones by name.
    final parts = [..._rig.parts];
    final boundKeys = {for (final part in parts) part.layerKey};
    final claimed = <String>{};
    var bound = 0;
    for (final (index, layer) in restLayers.indexed) {
      final key = layer.stableKey;
      if (key == null || boundKeys.contains(key)) continue;
      for (final b in built.bones) {
        if (claimed.contains(b.id) || !NameTokens.sameThing(layer.name, b.name)) continue;
        claimed.add(b.id);
        parts.add(RigPart(id: _newId(), boneId: b.id, layerKey: key, drawOrder: index));
        bound++;
        break;
      }
    }

    _placement = null;
    _commit(_rig.copyWith(
      bones: [..._rig.bones, ...built.bones],
      ikChains: [..._rig.ikChains, ...built.chains],
      parts: parts,
    ));
    _selectedBoneId = built.bones.isEmpty ? _selectedBoneId : built.bones.first.id;
    _selectedIkChainId = null;
    notifyListeners();
    return PlacedPreset(boneIds: [for (final b in built.bones) b.id], boundLayers: bound);
  }

  /// The box around what is drawn on the visible rest layers, if anything.
  Rect? _artBounds() {
    var minX = width, minY = height, maxX = -1, maxY = -1;
    for (final layer in restLayers) {
      if (!layer.isVisible || layer.opacity <= 0) continue;
      final px = layer.pixels;
      if (px.length != width * height) continue;
      for (var y = 0; y < height; y++) {
        for (var x = 0; x < width; x++) {
          if (px[y * width + x] >> 24 == 0) continue;
          if (x < minX) minX = x;
          if (x > maxX) maxX = x;
          if (y < minY) minY = y;
          if (y > maxY) maxY = y;
        }
      }
    }
    if (maxX < 0) return null;
    return Rect.fromLTRB(minX.toDouble(), minY.toDouble(), maxX + 1.0, maxY + 1.0);
  }

  Rect _suggestedBox(BonePreset preset, bool attach) {
    final canvas = Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble());
    final art = _artBounds() ?? canvas.deflate(math.min(width, height) * 0.1);

    Rect box;
    if (preset.addOn) {
      // A part, not a figure: about a third of the art, centred on the end of
      // the selected bone (or on the art).
      final longest = math.max(minPlacementSize, math.max(art.width, art.height) * 0.4);
      final aspect = preset.aspect;
      var w = aspect >= 1 ? longest : longest * aspect;
      var h = aspect >= 1 ? longest / aspect : longest;
      w = math.max(minPlacementSize, w);
      h = math.max(minPlacementSize, h);
      final anchor = (attach ? selectedBone?.tail : null) ?? art.center;
      box = Rect.fromCenter(center: anchor, width: w, height: h);
    } else {
      box = art;
    }

    // Whole pixels, no smaller than the minimum, and on the canvas.
    var l = box.left.floorToDouble(), t = box.top.floorToDouble();
    var r = box.right.ceilToDouble(), b = box.bottom.ceilToDouble();
    if (r - l < minPlacementSize) r = l + minPlacementSize;
    if (b - t < minPlacementSize) b = t + minPlacementSize;
    final shift = Offset(
      l < 0 ? -l : (r > width ? width - r : 0),
      t < 0 ? -t : (b > height ? height - b : 0),
    );
    return Rect.fromLTRB(l, t, r, b).shift(shift);
  }

  // ── Animation presets ────────────────────────────────────────────────────

  /// How many of [preset]'s bones this rig has, for showing before applying.
  ({int matched, int total}) motionCoverage(MotionPreset preset, {bool mirror = false}) =>
      MotionBuilder.coverage(preset, _rig.bones, mirror: mirror);

  /// Puts an animation preset on the clip (animate mode): the bones it finds
  /// get its keyframes, replacing their own; the clip takes the preset's
  /// length, speed and looping. Other bones keep their keys. One undo step.
  ///
  /// Returns what was matched; when nothing was (a missing selection, bones
  /// named something else) the clip is left alone.
  MotionResult applyMotion(MotionPreset preset, {double intensity = 1, bool mirror = false}) {
    final result = MotionBuilder.build(
      preset,
      bones: _mode == RigMode.animate ? _rig.bones : const [],
      canvasHeight: height.toDouble(),
      intensity: intensity,
      mirror: mirror,
      selectedBoneId: _selectedBoneId,
    );
    if (result.isEmpty) return result;

    // Respect the bones' rotation limits, as every other pose edit does.
    final keys = [
      for (final k in result.keyframes)
        k.copyWith(rotation: _limited(bone(k.boneId), k.rotation)),
    ];
    final animated = {for (final k in keys) k.boneId};

    _updateClip((clip) => clip.copyWith(
          length: result.frames,
          fps: result.fps,
          loop: result.loop,
          keyframes: [
            for (final k in clip.keyframes)
              if (!animated.contains(k.boneId) && k.time < result.frames) k,
            ...keys,
          ],
          ikKeyframes: [
            for (final k in clip.ikKeyframes)
              if (k.time < result.frames) k,
          ],
        ));
    _time = _time.clamp(0, result.frames - 1);
    notifyListeners();
    return result;
  }

  double _limited(Bone? bone, double rotation) {
    final lo = bone?.minAngle, hi = bone?.maxAngle;
    if (lo != null && rotation < lo) return lo;
    if (hi != null && rotation > hi) return hi;
    return rotation;
  }

  // ── Parts (layer assignment) ─────────────────────────────────────────────

  RigPart? partOfLayer(String layerKey) {
    for (final p in _rig.parts) {
      if (p.layerKey == layerKey) return p;
    }
    return null;
  }

  Bone? boneOfLayer(String layerKey) => bone(partOfLayer(layerKey)?.boneId);

  /// The parts list with [layerKey] bound to [boneId], or null if the layer
  /// is unknown. Draw order follows the layer's position, so the layer stack's
  /// overlap order is kept. Does not check [boneId]: a bone being created is
  /// not in the rig yet, so callers vouch for it.
  List<RigPart>? _partsBinding(String layerKey, String boneId) {
    final layerIndex = restLayers.indexWhere((l) => l.stableKey == layerKey);
    if (layerIndex < 0) return null;
    final existing = partOfLayer(layerKey);
    return [
      for (final p in _rig.parts)
        if (p.layerKey != layerKey) p,
      RigPart(
        id: existing?.id ?? _newId(),
        boneId: boneId,
        layerKey: layerKey,
        drawOrder: layerIndex,
      ),
    ];
  }

  /// Binds the whole layer with [layerKey] to [boneId], or unbinds it when
  /// [boneId] is null. Ignores unknown layers and bones.
  void assignLayer(String layerKey, String? boneId) {
    if (restLayers.indexWhere((l) => l.stableKey == layerKey) < 0) return;
    if (boneId == null) {
      _commit(_rig.copyWith(parts: [
        for (final p in _rig.parts)
          if (p.layerKey != layerKey) p,
      ]));
      return;
    }
    if (bone(boneId) == null) return;
    final parts = _partsBinding(layerKey, boneId);
    if (parts != null) _commit(_rig.copyWith(parts: parts));
  }

  String? _activeLayerKey;

  /// The layer the next bone drawn will be bound to, if one is armed.
  String? get activeLayerKey => _activeLayerKey;

  /// Arms [layerKey] so the next bone drawn is bound to that layer; selecting
  /// the armed layer again, or null, disarms it. Unknown layers are ignored.
  void selectLayer(String? layerKey) {
    if (layerKey != null && restLayers.indexWhere((l) => l.stableKey == layerKey) < 0) return;
    final next = layerKey == _activeLayerKey ? null : layerKey;
    if (next == _activeLayerKey) return;
    _activeLayerKey = next;
    notifyListeners();
  }

  /// Layers that no bone drives; they stay put when the rig is posed.
  List<Layer> get unassignedLayers => [
        for (final l in restLayers)
          if (l.stableKey != null && partOfLayer(l.stableKey!) == null) l,
      ];
}
