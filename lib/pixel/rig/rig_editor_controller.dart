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

part 'rig_workflow.dart';

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

  final Set<String> _selectedBoneIds = {};
  bool multiSelectEnabled = false;
  bool groupActivePivot = false;
  bool snappingEnabled = true;
  bool moveConnectedChain = true;
  void _notifyWorkflow() => notifyListeners();
  bool ghostSkeleton = false, ghostArtwork = false, ghostsSuppressed = false;
  double ghostOpacity = .25;
  int ghostSpacing = 1;
  int? pinnedGhostFrame;
  bool timelineSelectedTracksOnly = false, rippleTimeline = false;
  RigClip? _keyClipboard;
  int _keyClipboardStart = 0, _keyClipboardLength = 1;
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

  bool _toolFitsMode(RigTool t) =>
      _mode == RigMode.animate ? t != RigTool.createBone : (t != RigTool.rotate && t != RigTool.move);

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
    if (multiSelectEnabled && id != null) {
      toggleBoneSelection(id);
      return;
    }
    if (_selectedBoneId == id && _selectedIkChainId == null && _selectedBoneIds.length <= 1) return;
    _selectedBoneId = id;
    _selectedBoneIds
      ..clear()
      ..addAll(id == null ? const [] : [id]);
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

  /// Half-pixel grid: both pixel centres (.5) and boundaries (integers).
  /// Canvas edges are valid joint positions as well.
  Offset snapToPixel(Offset point) => Offset(
        (point.dx * 2).roundToDouble().clamp(0, width * 2) / 2,
        (point.dy * 2).roundToDouble().clamp(0, height * 2) / 2,
      );

  static Offset snapDelta(Offset delta) => Offset(
        (delta.dx * 2).roundToDouble() / 2,
        (delta.dy * 2).roundToDouble() / 2,
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
    _selectedBoneIds.removeWhere((id) => bone(id) == null);
    if (bone(_selectedBoneId) == null) _selectedBoneId = _selectedBoneIds.firstOrNull;
    notifyListeners();
  }

  // ── Bones ────────────────────────────────────────────────────────────────

  /// Where a new bone that starts at [point] should attach: on any part of an
  /// existing bone (within [tolerance]) it becomes that bone's child, joined
  /// at the joint, tip or - along the body - the nearest pixel of the line.
  /// Away from every bone it is a free root starting at [point]'s pixel.
  ({String? parentId, Offset head}) attachPoint(Offset point, double tolerance, {bool bypass = false}) {
    final hit = snappingEnabled && !bypass ? hitTest(point, tolerance) : null;
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

  /// Adds a bone from [head] to [tail] (both snapped to half pixels) and selects
  /// it. Returns its id, or null when it would be shorter than half a pixel.
  ///
  /// If a layer is armed ([selectLayer]) the new bone is bound to it, in the
  /// same undo step, and the layer is disarmed.
  String? addBone({required Offset head, required Offset tail, String? parentId, String? name, bool connect = true}) {
    if (parentId != null && bone(parentId) == null) parentId = null;
    // Exact endpoints may be off-grid after rotating a connected chain.
    final parent = bone(parentId);
    if (parent != null && (head - parent.tail).distance < 1e-6) {
      head = parent.tail;
    } else if (parent != null && (head - parent.head).distance < 1e-6) {
      head = parent.head;
    } else {
      head = snapToPixel(head);
    }
    if (parentId == null && snappingEnabled && connect) {
      for (final candidate in _rig.bones.reversed) {
        if ((head - candidate.tail).distance < 1e-6 || (head - candidate.head).distance < 1e-6) {
          parentId = candidate.id;
          break;
        }
      }
    }
    tail = snapToPixel(tail);
    final delta = tail - head;
    if (delta.distance < .5) return null;
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
    _selectedBoneIds
      ..clear()
      ..add(id);
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

  /// Moves on a half-pixel grid. A shared head edits the existing joint,
  /// rather than silently tearing a connected child away from its parent.
  void moveBone(String id, Offset delta) {
    final target = bone(id);
    if (target == null) return;
    delta = snapDelta(delta);
    if (delta == Offset.zero) return;
    final parent = bone(target.parentId);
    if (parent != null && (target.head - parent.tail).distance < 1e-6) {
      setBoneTail(parent.id, parent.tail + delta);
      return;
    }
    if (parent != null && (target.head - parent.head).distance < 1e-6) {
      moveBone(parent.id, delta);
      return;
    }
    final moving = {id, ..._descendants(id)};
    _commit(_rig.copyWith(bones: [
      for (final b in _rig.bones) moving.contains(b.id) ? b.copyWith(head: b.head + delta) : b,
    ]));
  }

  /// Reshapes a bone and rotates attached subtrees with its new direction.
  /// Attachment positions along the bone scale with its new length.
  void setBoneTail(String id, Offset tail, {bool snap = true}) {
    final b = bone(id);
    if (b == null) return;
    final newTail = snap ? snapToPixel(tail) : tail;
    final delta = newTail - b.head;
    if (delta.distance < .5) return;
    final angle = _degrees(delta);
    final turn = (angle - b.restAngle) * math.pi / 180;
    Offset rotate(Offset v) =>
        Offset(v.dx * math.cos(turn) - v.dy * math.sin(turn), v.dx * math.sin(turn) + v.dy * math.cos(turn));
    final changed = <String, Bone>{};
    for (final child in _rig.bones.where((x) => x.parentId == id)) {
      final oldAxis = b.tail - b.head;
      final t = b.length == 0
          ? 0.0
          : (((child.head - b.head).dx * oldAxis.dx + (child.head - b.head).dy * oldAxis.dy) / (b.length * b.length))
              .clamp(0.0, 1.0);
      final onAxis = (child.head - (b.head + oldAxis * t)).distance < 1e-6;
      final newAnchor = onAxis ? b.head + delta * t : b.head + rotate(child.head - b.head);
      for (final childId in {child.id, ..._descendants(child.id)}) {
        final item = bone(childId)!;
        changed[childId] = item.copyWith(
          head: newAnchor + rotate(item.head - child.head),
          restAngle: item.restAngle + angle - b.restAngle,
        );
      }
    }
    _commit(_rig.copyWith(bones: [
      for (final item in _rig.bones)
        if (item.id == id) item.copyWith(length: delta.distance, restAngle: angle) else changed[item.id] ?? item,
    ]));
  }

  /// Snap a free bone's head onto an existing joint without allowing cycles.
  /// Called when a setup drag ends; the gesture remains one undo operation.
  ({String parentId, Offset point})? jointConnection(String id, {double tolerance = .25}) {
    final target = bone(id);
    if (target == null || target.parentId != null) return null;
    final blocked = {id, ..._descendants(id)};
    String? parent;
    Offset? anchor;
    var best = tolerance;
    for (final candidate in _rig.bones.reversed) {
      if (blocked.contains(candidate.id)) continue;
      for (final joint in [candidate.tail, candidate.head]) {
        final distance = (target.head - joint).distance;
        if (distance <= best) {
          best = distance;
          parent = candidate.id;
          anchor = joint;
        }
      }
    }
    return parent == null || anchor == null ? null : (parentId: parent, point: anchor);
  }

  bool connectJoint(String id, {double tolerance = .25}) {
    final connection = jointConnection(id, tolerance: tolerance);
    final target = bone(id);
    if (connection == null || target == null) return false;
    final anchor = connection.point;
    final move = anchor - target.head;
    final moving = {id, ..._descendants(id)};
    _commit(_rig.copyWith(bones: [
      for (final item in _rig.bones)
        if (item.id == id)
          item.copyWith(head: anchor, parentId: () => connection.parentId)
        else if (moving.contains(item.id))
          item.copyWith(head: item.head + move)
        else
          item,
    ]));
    return true;
  }

  /// Connect an existing bone to the nearest endpoint of another bone.
  /// The entire child subtree moves together, preserving its internal joints.
  bool connectToBone(String id, String parentId) {
    final child = bone(id), parent = bone(parentId);
    if (child == null || parent == null || id == parentId || _descendants(id).contains(parentId)) return false;
    final anchor =
        (child.head - parent.head).distance < (child.head - parent.tail).distance ? parent.head : parent.tail;
    final delta = anchor - child.head;
    final moving = {id, ..._descendants(id)};
    _commit(_rig.copyWith(bones: [
      for (final item in _rig.bones)
        if (item.id == id)
          item.copyWith(head: anchor, parentId: () => parentId)
        else if (moving.contains(item.id))
          item.copyWith(head: item.head + delta)
        else
          item,
    ]));
    return true;
  }

  /// Moving a posed shared joint translates its connected hierarchy together.
  String jointMoveBoneId(String id) {
    var current = bone(id);
    final seen = <String>{};
    while (current != null && seen.add(current.id)) {
      final parent = bone(current.parentId);
      if (parent == null ||
          ((current.head - parent.head).distance > 1e-6 && (current.head - parent.tail).distance > 1e-6)) {
        return current.id;
      }
      current = parent;
    }
    return id;
  }

  /// Numeric setup edits retain connected joints and form one undo step.
  bool setBoneGeometry(String id, {double? x, double? y, double? length, double? angle}) {
    final b = bone(id);
    if (b == null ||
        _mode != RigMode.setup ||
        [x, y, length, angle].whereType<double>().any((n) => !n.isFinite) ||
        (length != null && length < .5)) {
      return false;
    }
    if (!moveConnectedChain) {
      _commit(_rig.copyWith(bones: [
        for (final item in _rig.bones)
          item.id == id
              ? item.copyWith(
                  head: snapToPixel(Offset(x ?? b.head.dx, y ?? b.head.dy)),
                  length: length == null ? b.length : (length * 2).roundToDouble() / 2,
                  restAngle: angle)
              : item
      ]));
      return true;
    }
    final ownGesture = _gestureBase == null;
    if (ownGesture) beginGesture();
    try {
      final head = snapToPixel(Offset(x ?? b.head.dx, y ?? b.head.dy));
      moveBone(id, head - b.head);
      final current = bone(id)!;
      if (length != null || angle != null) {
        final size = length == null ? current.length : (length * 2).roundToDouble() / 2;
        final radians = (angle ?? current.restAngle) * math.pi / 180;
        setBoneTail(id, current.head + Offset(math.cos(radians), math.sin(radians)) * size, snap: false);
      }
    } finally {
      if (ownGesture) endGesture();
    }
    return true;
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
    _selectedBoneIds.remove(id);
    // A chain ending at the deleted bone has nothing left to reach with.
    final gone = {
      for (final c in _rig.ikChains)
        if (c.tipBoneId == id) c.id,
    };
    _commit(_rig.copyWith(
      attachments: [
        for (final a in _rig.attachments)
          if (a.boneId != id) a
      ],
      roleBindings: {
        for (final e in _rig.roleBindings.entries)
          if (e.value != id) e.key: e.value
      },
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
            freezes: [
              for (final f in c.freezes)
                if (f.boneId != id) f
            ],
            keyframes: [
              for (final k in c.keyframes)
                if (k.boneId != id) k
            ],
            ikKeyframes: [
              for (final k in c.ikKeyframes)
                if (!gone.contains(k.chainId)) k
            ],
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

  int? _rangeAnchor, _rangeEnd;
  bool rangeSelectionEnabled = false;
  bool get hasFrameSelection => _rangeAnchor != null;
  int get rangeStart => math.min(_rangeAnchor ?? time, _rangeEnd ?? time).clamp(0, activeClip.length - 1);
  int get rangeEnd => math.max(_rangeAnchor ?? time, _rangeEnd ?? time).clamp(0, activeClip.length - 1);
  bool frameInSelection(int frame) => hasFrameSelection && frame >= rangeStart && frame <= rangeEnd;

  void selectFrameRange(int start, int end) {
    _rangeAnchor = start.clamp(0, activeClip.length - 1);
    _rangeEnd = end.clamp(0, activeClip.length - 1);
    notifyListeners();
  }

  void toggleFrameSelection() {
    rangeSelectionEnabled = !rangeSelectionEnabled;
    if (rangeSelectionEnabled) {
      selectFrameRange(time, time);
    } else {
      _rangeAnchor = _rangeEnd = null;
      notifyListeners();
    }
  }

  void selectTimelineFrame(int frame, {bool extend = false}) {
    if (extend || rangeSelectionEnabled) {
      selectFrameRange(_rangeAnchor ?? time, frame);
    } else {
      _rangeAnchor = _rangeEnd = null;
    }
    setTime(frame);
    notifyListeners();
  }

  /// Move selected keys on every track. Destination keys are replaced.
  void moveFrameRange(int delta) {
    if (!hasFrameSelection) return;
    final start = rangeStart, end = rangeEnd;
    delta = delta.clamp(-start, 239 - end);
    if (delta == 0) return;
    final clip = activeClip;
    bool inside(int t) => t >= start && t <= end;
    final keys = [
      for (final k in clip.keyframes)
        if (inside(k.time)) k.copyWith(time: k.time + delta)
    ];
    final ik = [
      for (final k in clip.ikKeyframes)
        if (inside(k.time)) k.copyWith(time: k.time + delta)
    ];
    final movedFreezes = [
      for (final f in clip.freezes)
        if (inside(f.time)) f.copyWith(time: f.time + delta)
    ];
    final destinations = {for (final f in movedFreezes) (f.boneId, f.time)};
    final base = clip.copyWith(
      freezes: [
        for (final f in clip.freezes)
          if (!inside(f.time) && !destinations.contains((f.boneId, f.time))) f,
        ...movedFreezes
      ],
      length: math.max(clip.length, end + delta + 1),
      keyframes: [
        for (final k in clip.keyframes)
          if (!inside(k.time)) k
      ],
      ikKeyframes: [
        for (final k in clip.ikKeyframes)
          if (!inside(k.time)) k
      ],
    );
    _updateClip((_) => _withIkKeys(_withKeys(base, keys), ik));
    selectFrameRange(start + delta, end + delta);
    setTime(start + delta);
  }

  /// Insert a copy immediately after the range, preserving later frames.
  void duplicateFrameRange() {
    if (!hasFrameSelection) return;
    final start = rangeStart, end = rangeEnd, clip = activeClip;
    final count = end - start + 1;
    if (clip.length + count > 240) return;
    final at = end + 1;
    _updateClip((_) => clip.copyWith(
          length: clip.length + count,
          freezes: [
            for (final f in clip.freezes) f.time >= at ? f.copyWith(time: f.time + count) : f,
            for (final f in clip.freezes)
              if (f.time >= start && f.time <= end) f.copyWith(time: f.time + count)
          ],
          keyframes: [
            for (final k in clip.keyframes) k.time >= at ? k.copyWith(time: k.time + count) : k,
            for (final k in clip.keyframes)
              if (k.time >= start && k.time <= end) k.copyWith(time: k.time + count),
          ],
          ikKeyframes: [
            for (final k in clip.ikKeyframes) k.time >= at ? k.copyWith(time: k.time + count) : k,
            for (final k in clip.ikKeyframes)
              if (k.time >= start && k.time <= end) k.copyWith(time: k.time + count),
          ],
        ));
    selectFrameRange(at, at + count - 1);
    setTime(at);
  }

  /// Delete selected frames and close the gap on every bone and IK track.
  void deleteFrameRange() {
    if (!hasFrameSelection) return;
    final start = rangeStart, end = rangeEnd, clip = activeClip;
    final count = end - start + 1;
    _updateClip((_) => clip.copyWith(
          length: math.max(1, clip.length - count),
          freezes: [
            for (final f in clip.freezes)
              if (f.time < start || f.time > end) f.time > end ? f.copyWith(time: f.time - count) : f
          ],
          keyframes: [
            for (final k in clip.keyframes)
              if (k.time < start || k.time > end) k.time > end ? k.copyWith(time: k.time - count) : k
          ],
          ikKeyframes: [
            for (final k in clip.ikKeyframes)
              if (k.time < start || k.time > end) k.time > end ? k.copyWith(time: k.time - count) : k
          ],
        ));
    _rangeAnchor = _rangeEnd = null;
    _time = start.clamp(0, activeClip.length - 1);
    notifyListeners();
  }

  bool get canPlantFoot =>
      _mode == RigMode.animate && selectedBone != null && _rig.maxChainLength(selectedBoneId!) >= 2;

  /// Hold the selected foot's current contact point over the chosen range.
  /// Per-frame contacts never enable IK outside that range.
  void plantFoot() {
    if (!canPlantFoot) return;
    final tip = selectedBone!;
    final target = displayBone(tip.id)!.tail;
    final existing = ikChainWithTip(tip.id);
    final chain = existing ??
        IkChain(
            id: _newId(),
            name: '${tip.name} contact',
            tipBoneId: tip.id,
            boneCount: math.min(3, _rig.maxChainLength(tip.id)));
    final keys = [
      for (var i = rangeStart; i <= rangeEnd; i++)
        IkKeyframe(time: i, chainId: chain.id, target: target, planted: true, easing: RigEasing.stepped)
    ];
    final clip = _withIkKeys(activeClip, keys);
    _commit(_rig.copyWith(
      ikChains: [
        for (final c in _rig.ikChains)
          if (c.id != chain.id) c,
        chain
      ],
      clips: _clipsReplacing(clip),
    ));
  }

  bool get hasFootPlant {
    final chain = ikChainWithTip(_selectedBoneId);
    return chain != null &&
        activeClip.ikKeyframes
            .any((k) => k.chainId == chain.id && k.planted && k.time >= rangeStart && k.time <= rangeEnd);
  }

  void releaseFootPlant() {
    final chain = ikChainWithTip(_selectedBoneId);
    if (chain == null) return;
    _updateClip((clip) => clip.copyWith(ikKeyframes: [
          for (final k in clip.ikKeyframes)
            if (!(k.chainId == chain.id && k.planted && k.time >= rangeStart && k.time <= rangeEnd)) k
        ]));
  }

  List<RigClip> _clipsReplacing(RigClip clip) => _rig.clips.any((c) => c.id == clip.id)
      ? [for (final c in _rig.clips) c.id == clip.id ? clip : c]
      : [..._rig.clips, clip];

  void selectClip(String id) {
    if (!_rig.clips.any((c) => c.id == id) || activeClip.id == id) return;
    _rig = _rig.copyWith(activeClipId: () => id);
    _time = 0;
    pinnedGhostFrame = null;
    _rangeAnchor = _rangeEnd = null;
    notifyListeners();
  }

  String _clipName(String base) {
    base = base.trim().isEmpty ? 'Animation' : base.trim();
    final names = _rig.clips.map((c) => c.name).toSet();
    if (!names.contains(base)) return base;
    for (var i = 2;; i++) {
      if (!names.contains('$base $i')) return '$base $i';
    }
  }

  void createClip(String name) {
    final clip = RigClip(id: _newId(), name: _clipName(name), fps: activeClip.fps);
    _time = 0;
    pinnedGhostFrame = null;
    _rangeAnchor = _rangeEnd = null;
    _commit(_rig.copyWith(clips: [..._rig.clips, clip], activeClipId: () => clip.id));
  }

  void duplicateClip() {
    final source = activeClip;
    final clip = source.copyWith(id: _newId(), name: _clipName('${source.name} copy'));
    _time = 0;
    pinnedGhostFrame = null;
    _rangeAnchor = _rangeEnd = null;
    _commit(_rig.copyWith(clips: [..._rig.clips, clip], activeClipId: () => clip.id));
  }

  void renameClip(String name) {
    name = name.trim();
    if (name.isEmpty || name == activeClip.name) return;
    _updateClip((c) => c.copyWith(name: _clipName(name)));
  }

  void deleteClip() {
    if (_rig.clips.isEmpty) return;
    final clips = _rig.clips.where((c) => c.id != activeClip.id).toList();
    _time = 0;
    pinnedGhostFrame = null;
    _rangeAnchor = _rangeEnd = null;
    _commit(_rig.copyWith(clips: clips, activeClipId: () => clips.firstOrNull?.id));
  }

  bool jointFrozenAt(String id, int frame) => activeClip.freezes.any((f) => f.boneId == id && f.time == frame);
  bool hasJointFreeze(String id) => activeClip.freezes
      .any((f) => f.boneId == id && (!hasFrameSelection || (f.time >= rangeStart && f.time <= rangeEnd)));

  void freezeJoint(String id) {
    if (_mode != RigMode.animate || bone(id) == null) return;
    final t = _world[id] ?? Affine2.identity;
    final matrix = [t.a, t.b, t.c, t.d, t.tx, t.ty];
    final start = hasFrameSelection ? rangeStart : 0;
    final end = hasFrameSelection ? rangeEnd : activeClip.length - 1;
    _updateClip((clip) => clip.copyWith(freezes: [
          for (final f in clip.freezes)
            if (f.boneId != id || f.time < start || f.time > end) f,
          for (var i = start; i <= end; i++) JointFreeze(boneId: id, time: i, matrix: matrix),
        ]));
  }

  void unfreezeJoint(String id) {
    _updateClip((clip) => clip.copyWith(freezes: [
          for (final f in clip.freezes)
            if (!(f.boneId == id && (!hasFrameSelection || (f.time >= rangeStart && f.time <= rangeEnd)))) f
        ]));
  }

  /// Whether clearing would remove keys, extra frames, or additional clips.
  bool get canClearAnimations =>
      _rig.clips.length > 1 ||
      activeClip.length > 1 ||
      _rig.clips.any((clip) => clip.keyframes.isNotEmpty || clip.ikKeyframes.isNotEmpty || clip.freezes.isNotEmpty);

  /// Remove every animation and keyed frame, keeping one empty working frame.
  /// Skeleton, bindings, IK chains and saved poses remain available for reuse.
  /// The complete reset, including every clip, is one undo step.
  void clearAnimations() {
    if (!canClearAnimations) return;
    final empty = activeClip.copyWith(length: 1, keyframes: const [], ikKeyframes: const [], freezes: const []);
    _time = 0;
    _rangeAnchor = _rangeEnd = null;
    _commit(_rig.copyWith(clips: [empty]));
  }

  /// The clip being edited. A rig starts without one; the first keyframe
  /// stores this draft in the rig, so merely looking at animate mode leaves
  /// the rig untouched.
  RigClip get activeClip => _rig.activeClip ?? _draftClip;

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

  SolvedRig get _solved => _mode == RigMode.animate
      ? RigSolver.solveClip(_rig, activeClip, time.toDouble())
      : RigSolver.solveIk(_rig, const {}, const {});

  Map<String, Affine2> get _world => _solved.world;

  /// A bone's pose as the rig really shows it: its own keys, except that
  /// bones driven by an active IK chain have the rotation the solver chose.
  BonePose shownPoseOf(String boneId) => _solved.poses[boneId] ?? BonePose.rest;

  /// Exact solved joint positions, shared with the baker in animate mode.
  List<DisplayBone> get displayBones {
    if (_mode == RigMode.setup) {
      return [for (final b in _rig.bones) (bone: b, head: b.head, tail: b.tail)];
    }
    final world = _world;
    return [
      for (final b in _rig.bones)
        () {
          final t = (world[b.id] ?? Affine2.identity);
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
  Offset toLocalDelta(String boneId, Offset delta) => _parentWorld(boneId).invert()?.applyVector(delta) ?? delta;

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
    _commit(_rig.copyWith(clips: _clipsReplacing(next)));
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
    if (b == null || jointFrozenAt(boneId, time)) return;
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
          _keyFor(bone(e.key)!, e.value,
              rotation: e.value.rotation, translation: e.value.translation, flipX: e.value.flipX),
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
          freezes: [
            for (final f in clip.freezes)
              if (f.time < frames) f
          ],
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
  bool isIkDriven(String boneId) => ikChainsOf(boneId).any((c) => _ikTargets.containsKey(c.id));

  /// Picks [chainId] (null to drop the pick) and its tip bone.
  void selectIkChain(String? chainId) {
    final chain = ikChain(chainId);
    _selectedIkChainId = chain?.id;
    if (chain != null) {
      _selectedBoneIds
        ..clear()
        ..add(chain.tipBoneId);
      _selectedBoneId = chain.tipBoneId;
    }
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
          c.copyWith(ikKeyframes: [
            for (final k in c.ikKeyframes)
              if (k.chainId != chainId) k
          ]),
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
    final point = RigSolver.chainTipPoint(_rig, chain);
    return _ikTargets[chain.id] ?? (point == null ? null : (_world[chain.tipBoneId] ?? Affine2.identity).apply(point));
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
    if (next.box == current.box &&
        next.flip == current.flip &&
        next.withIk == current.withIk &&
        next.attach == current.attach) {
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

    final left =
        handle == PlacementHandle.left || handle == PlacementHandle.topLeft || handle == PlacementHandle.bottomLeft;
    final right =
        handle == PlacementHandle.right || handle == PlacementHandle.topRight || handle == PlacementHandle.bottomRight;
    final top =
        handle == PlacementHandle.top || handle == PlacementHandle.topLeft || handle == PlacementHandle.topRight;
    final bottom = handle == PlacementHandle.bottom ||
        handle == PlacementHandle.bottomLeft ||
        handle == PlacementHandle.bottomRight;

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
    if (built.bones.isNotEmpty) {
      _selectedBoneIds
        ..clear()
        ..add(built.bones.first.id);
    }
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
    if (preset.alignedCanvasSize == Size(width.toDouble(), height.toDouble())) return canvas;
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
      MotionBuilder.coverage(preset, _rig.bones,
          mirror: mirror, roleBindings: preset.roleBindings ?? _rig.roleBindings);

  /// Puts an animation preset on the clip (animate mode): the bones it finds
  /// get its keyframes, replacing their own; the clip takes the preset's
  /// length, speed and looping. Other bones keep their keys. One undo step.
  ///
  /// Returns what was matched; when nothing was (a missing selection, bones
  /// named something else) the clip is left alone.
  MotionResult applyMotion(MotionPreset preset, {double intensity = 1, bool mirror = false}) {
    final bindings = preset.roleBindings ?? _rig.roleBindings;
    final legRoles = RoleMatcher.match(['thigh_l', 'thigh_r', 'shin_l', 'shin_r', 'foot_l', 'foot_r'], _rig.bones);
    for (final role in legRoles.keys.toList()) {
      final explicit = bone(bindings[role]);
      if (explicit != null) legRoles[role] = explicit;
    }
    for (final role in bindings.keys) {
      final explicit = bone(bindings[role]);
      if (explicit != null) legRoles[role] = explicit;
    }
    Offset contact(Bone foot) {
      final socket = _rig.attachments.where((a) => a.boneId == foot.id && a.name == 'foot_contact').firstOrNull;
      return socket == null ? foot.tail : RigSolver.attachmentTransform(_rig, socket, const {}).apply(Offset.zero);
    }

    final feet = [
      for (final side in ['l', 'r']) legRoles['foot_$side'] ?? legRoles['shin_$side']
    ].whereType<Bone>().toList();
    final ground = feet.isEmpty ? null : feet.map((b) => contact(b).dy).reduce(math.max);
    var root = bone(bindings['hips']) ?? RoleMatcher.match(['hips'], _rig.bones)['hips'];
    final seen = <String>{};
    while (root?.parentId != null && seen.add(root!.id)) {
      root = bone(root.parentId) ?? root;
    }
    final origin = preset.keepPosition && root != null
        ? (_world[root.id] ?? Affine2.identity).apply(root.head) - root.head
        : Offset.zero;
    final shift = preset.groundY != null && ground != null ? preset.groundY! - ground : origin.dy;
    final legs = [
      for (final side in ['l', 'r'])
        [legRoles['thigh_$side'], legRoles['shin_$side'], legRoles['foot_$side']]
            .whereType<Bone>()
            .fold<double>(0, (v, b) => v + b.length)
    ].where((v) => v > 0).toList();
    final motionHeight =
        preset.proportionScale && legs.isNotEmpty ? legs.reduce((a, b) => a + b) / legs.length / .4 : height.toDouble();
    final result = MotionBuilder.build(
      preset,
      bones: _mode == RigMode.animate ? _rig.bones : const [],
      canvasHeight: motionHeight,
      roleBindings: bindings,
      intensity: intensity,
      mirror: mirror,
      selectedBoneId: _selectedBoneId,
    );
    if (result.isEmpty) return result;

    // Respect the bones' rotation limits, as every other pose edit does.
    final keys = [
      for (final k in result.keyframes)
        k.copyWith(
            rotation: _limited(bone(k.boneId), k.rotation),
            translation: k.translation + (bone(k.boneId)?.parentId == null ? Offset(origin.dx, shift) : Offset.zero)),
    ];
    final animated = {for (final k in keys) k.boneId};
    final affectedBones = {
      for (final id in animated) ...{id, ..._descendants(id)}
    };

    // Contact keys from the previous preset must not pin a new walk/jump.
    final affectedChains = {
      for (final chain in _rig.ikChains)
        if (_rig.chainBones(chain).any((b) => animated.contains(b.id))) chain.id
    };
    var clip = activeClip.copyWith(
      length: result.frames,
      freezes: [
        for (final f in activeClip.freezes)
          if (f.time < result.frames && (f.sourcePresetId == null || !affectedBones.contains(f.boneId))) f
      ],
      fps: result.fps,
      loop: result.loop,
      keyframes: [
        for (final k in activeClip.keyframes)
          if (!animated.contains(k.boneId) && k.time < result.frames) k,
        ...keys,
      ],
      ikKeyframes: [
        for (final k in activeClip.ikKeyframes)
          if (k.time < result.frames && !(k.planted && affectedChains.contains(k.chainId))) k,
      ],
    );
    final chains = List<IkChain>.of(_rig.ikChains);
    if (preset.plantFeet) {
      // Feet are optional so the simple skeleton can plant its shin tips.
      final roles = legRoles;
      for (final side in ['l', 'r']) {
        final foot = roles['foot_$side'] ?? roles['shin_$side'];
        if (foot == null || _rig.maxChainLength(foot.id) < 2) continue;
        final count = math.min(roles['foot_$side'] != null ? 3 : 2, _rig.maxChainLength(foot.id));
        final existing = ikChainWithTip(foot.id);
        final socket = _rig.attachments.where((a) => a.boneId == foot.id && a.name == 'foot_contact').firstOrNull;
        final chain = existing?.copyWith(boneCount: count, tipSocketId: () => socket?.id) ??
            IkChain(
                id: _newId(),
                name: '${foot.name} contact',
                tipBoneId: foot.id,
                boneCount: count,
                tipSocketId: socket?.id);
        final leg = {for (final b in _rig.chainBones(chain)) b.id};
        // Replace old targets on this leg; independent arm targets stay intact.
        final conflicting = {
          for (final c in chains)
            if (_rig.chainBones(c).any((b) => leg.contains(b.id))) c.id
        };
        clip = clip.copyWith(ikKeyframes: [
          for (final k in clip.ikKeyframes)
            if (!conflicting.contains(k.chainId)) k,
          for (var frame = 0; frame < result.frames; frame++)
            IkKeyframe(
                time: frame,
                chainId: chain.id,
                target: contact(foot) + Offset(origin.dx, shift),
                planted: true,
                easing: RigEasing.stepped),
        ]);
        chains.removeWhere((c) => c.id == chain.id);
        chains.add(chain);
      }
    }
    if (preset.lockedRoles.isNotEmpty) {
      final locked = <String, Bone>{
        for (final role in preset.lockedRoles)
          if ((bone(bindings[role]) ?? RoleMatcher.match([role], _rig.bones)[role]) case final Bone b) b.id: b
      }.values;
      final existing = {for (final f in clip.freezes) (f.boneId, f.time)};
      clip = clip.copyWith(freezes: [
        ...clip.freezes,
        for (final joint in locked)
          for (var frame = 0; frame < result.frames; frame++)
            if (!existing.contains((joint.id, frame)))
              JointFreeze(
                  boneId: joint.id, time: frame, matrix: [1, 0, 0, 1, origin.dx, shift], sourcePresetId: preset.id),
      ]);
    }
    // Preset keys, automatic contacts and locks share the same undo step.
    _commit(_rig.copyWith(ikChains: chains, roleBindings: bindings, clips: _clipsReplacing(clip)));
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
