import 'dart:math' as math;
import 'dart:ui';

import '../../data/models/rig/rig.dart';
import 'affine2.dart';
import 'pose_interpolator.dart';

/// The outcome of solving a rig with IK: where every bone ended up, and the
/// poses that produce it (IK-driven bones have their rotations replaced).
class SolvedRig {
  const SolvedRig({required this.world, required this.poses});

  final Map<String, Affine2> world;
  final Map<String, BonePose> poses;
}

/// Turns per-bone poses into one transform per bone that maps rest-pose
/// canvas pixels to their posed positions: forward kinematics, plus an IK
/// pass that bends chains of bones to reach a target.
abstract final class RigSolver {
  /// Socket transform from socket-local coordinates to canvas coordinates.
  static Affine2 attachmentTransform(Rig rig, RigAttachment socket, Map<String, Affine2> world) {
    final bone = rig.bones.where((b) => b.id == socket.boneId).firstOrNull;
    if (bone == null) return Affine2.identity;
    final origin = Affine2.rotation(bone.restAngle).apply(socket.offset) + bone.head;
    return Affine2.rotation(bone.restAngle + socket.angle)
        .thenTranslate(origin.dx, origin.dy)
        .then(world[bone.id] ?? Affine2.identity);
  }

  static Offset? chainTipPoint(Rig rig, IkChain chain) {
    final tip = rig.bones.where((b) => b.id == chain.tipBoneId).firstOrNull;
    if (tip == null) return null;
    final socket = rig.attachments.where((a) => a.id == chain.tipSocketId && a.boneId == tip.id).firstOrNull;
    return socket == null ? tip.tail : attachmentTransform(rig, socket, const {}).apply(Offset.zero);
  }

  /// Shared evaluation for canvas, baking and GIFs. Frozen joints override
  /// inherited motion and IK; their descendants follow the held world pose.
  static SolvedRig solveClip(Rig rig, RigClip clip, double time) {
    final solved = solveIk(
        rig, PoseInterpolator.sample(clip, rig.bones, time), PoseInterpolator.sampleIk(clip, rig.ikChains, time));
    if (clip.freezes.isEmpty) return solved;
    final frame = (clip.loop && clip.length > 0
            ? ((time % clip.length) + clip.length) % clip.length
            : time.clamp(0.0, (clip.length - 1).toDouble()))
        .floor();
    final held = <String, Affine2>{};
    for (final freeze in clip.freezes.where((f) => f.time == frame)) {
      final m = freeze.matrix;
      held[freeze.boneId] = Affine2(m[0], m[1], m[2], m[3], m[4], m[5]);
    }
    if (held.isEmpty) return solved;
    final bones = {for (final b in rig.bones) b.id: b};
    final world = <String, Affine2>{};
    Affine2 resolve(Bone bone, Set<String> visiting) {
      if (world.containsKey(bone.id)) return world[bone.id]!;
      if (held.containsKey(bone.id)) return world[bone.id] = held[bone.id]!;
      final local = localTransform(bone, solved.poses[bone.id] ?? BonePose.rest, rig.settings.snapAngleDegrees);
      final parent = bones[bone.parentId];
      if (parent == null || !visiting.add(bone.id)) return world[bone.id] = local;
      final result = local.then(resolve(parent, visiting));
      visiting.remove(bone.id);
      return world[bone.id] = result;
    }

    for (final b in rig.bones) {
      resolve(b, {});
    }
    return SolvedRig(world: world, poses: solved.poses);
  }

  /// Iterations of the IK solver. Chains are short, so this is plenty; a
  /// chain that cannot reach its target stops as a straight line anyway.
  static const int _ikIterations = 32;

  /// Close enough to stop: a twentieth of a pixel.
  static const double _ikTolerance = 0.05;

  /// Solves [rig] for [poses], then bends each IK chain that has an entry in
  /// [targets] (canvas pixels) so the tail of its tip bone reaches it.
  ///
  /// The rotations of the chain's bones are replaced by the solution; their
  /// own keyframes only decide where the search starts. Translation and flip
  /// of those bones still apply. Chains are solved in the order the rig lists
  /// them, each seeing the result of the ones before.
  ///
  /// Rotation limits are respected, so a chain that cannot bend far enough
  /// falls short rather than breaking its limits. A target out of reach
  /// leaves the chain straight and pointing at it.
  static SolvedRig solveIk(Rig rig, Map<String, BonePose> poses, Map<String, Offset> targets) {
    var current = Map<String, BonePose>.of(poses);
    for (final chain in rig.ikChains) {
      final target = targets[chain.id];
      final bones = rig.chainBones(chain);
      if (target == null || bones.isEmpty) continue;
      current = _solveChain(rig, current, bones, chain.bend, target, chainTipPoint(rig, chain));
    }
    return SolvedRig(world: solve(rig, current), poses: current);
  }

  static Map<String, BonePose> _solveChain(
    Rig rig,
    Map<String, BonePose> start,
    List<Bone> bones,
    int bend,
    Offset target,
    Offset? endpoint,
  ) {
    // One and two bones have exact solutions (the two-bone one is the law of
    // cosines, and `bend` picks between its two mirror images). Longer chains
    // have many solutions and are searched for.
    if (bones.length == 1) return _aim(rig, start, bones.first, target, endpoint);
    if (bones.length == 2) {
      final solved = _solveTwoBones(rig, start, bones[0], bones[1], bend, target, endpoint);
      if (solved != null) return solved;
    }
    return _searchChain(rig, start, bones, bend, target, endpoint);
  }

  /// [angle] plus whole turns, whichever lands nearest [reference], so a
  /// solved rotation never makes a bone spin the long way round between
  /// frames.
  static double _nearest(double angle, double reference) {
    var a = angle;
    while (a - reference > 180) {
      a -= 360;
    }
    while (a - reference < -180) {
      a += 360;
    }
    return a;
  }

  static double _limit(Bone b, double r) {
    final lo = b.minAngle, hi = b.maxAngle;
    if (lo != null && r < lo) r = lo;
    if (hi != null && r > hi) r = hi;
    return r;
  }

  /// The world transform of [bone]'s parent under [poses], or identity.
  static Affine2 _parentWorld(Rig rig, Map<String, BonePose> poses, Bone bone) {
    final parent = bone.parentId;
    if (parent == null) return Affine2.identity;
    return solve(rig, poses)[parent] ?? Affine2.identity;
  }

  /// [v] in the bone's own frame after its pose's mirroring.
  static Offset _flipped(Offset v, BonePose pose) => Offset(pose.flipX ? -v.dx : v.dx, pose.flipY ? -v.dy : v.dy);

  static double _degrees(double radians) => radians * 180 / math.pi;

  /// One bone: turn it so its tail points at the target.
  static Map<String, BonePose> _aim(Rig rig, Map<String, BonePose> start, Bone bone, Offset target, Offset? endpoint) {
    final inverse = _parentWorld(rig, start, bone).invert();
    if (inverse == null) return start;
    final pose = start[bone.id] ?? BonePose.rest;

    final toTarget = inverse.apply(target) - bone.head - pose.translation;
    final tail = _flipped((endpoint ?? bone.tail) - bone.head, pose);
    if (toTarget.distance < 1e-9 || tail.distance < 1e-9) return start;

    final rotation = _limit(bone, _nearest(_degrees(toTarget.direction - tail.direction), pose.rotation));
    return {...start, bone.id: pose.copyWith(rotation: rotation)};
  }

  /// Two bones, exactly. Works in the space the chain's root hangs in, where
  /// the hand is `head1 + t1 + R(a1)·F1(u + R(a2)·F2(tail2 - head2))` with
  /// `u` the offset from the first joint to the second. Only the distance to
  /// the target depends on the second angle, so it comes from the law of
  /// cosines (two solutions: the bend); the first angle then just aims.
  ///
  /// Returns null when the geometry is degenerate (a zero-length bone).
  static Map<String, BonePose>? _solveTwoBones(
    Rig rig,
    Map<String, BonePose> start,
    Bone upper,
    Bone lower,
    int bend,
    Offset target,
    Offset? endpoint,
  ) {
    final inverse = _parentWorld(rig, start, upper).invert();
    if (inverse == null) return null;
    final p1 = start[upper.id] ?? BonePose.rest;
    final p2 = start[lower.id] ?? BonePose.rest;

    final u = lower.head + p2.translation - upper.head;
    final b = _flipped((endpoint ?? lower.tail) - lower.head, p2);
    final v = inverse.apply(target) - upper.head - p1.translation;
    final lu = u.distance, lb = b.distance;
    if (lu < 1e-9 || lb < 1e-9) return null;

    final distance = v.distance;
    final cosine = ((distance * distance - lu * lu - lb * lb) / (2 * lu * lb)).clamp(-1.0, 1.0);
    final spread = math.acos(cosine);
    final baseAngle = u.direction - b.direction;

    // The preferred fold, unless its angle is outside the bone's limits and
    // the mirror image is not.
    double lowerRotation(int sign) => _nearest(_degrees(baseAngle + sign * spread), p2.rotation);
    var second = lowerRotation(bend);
    if (_limit(lower, second) != second) {
      final other = lowerRotation(-bend);
      if (_limit(lower, other) == other) second = other;
    }
    second = _limit(lower, second);

    // With the second angle fixed, the first one aims the whole limb.
    final reach = u + _rotated(b, second);
    final f1 = _flipped(reach, p1);
    var first = p1.rotation;
    if (distance > 1e-9 && f1.distance > 1e-9) {
      first = _limit(upper, _nearest(_degrees(v.direction - f1.direction), p1.rotation));
    }

    return {
      ...start,
      upper.id: p1.copyWith(rotation: first),
      lower.id: p2.copyWith(rotation: second),
    };
  }

  static Offset _rotated(Offset v, double degrees) {
    final r = degrees * math.pi / 180;
    final c = math.cos(r), s = math.sin(r);
    return Offset(c * v.dx - s * v.dy, s * v.dx + c * v.dy);
  }

  /// Longer chains: cyclic coordinate descent from the tip to the root.
  static Map<String, BonePose> _searchChain(
    Rig rig,
    Map<String, BonePose> start,
    List<Bone> bones,
    int bend,
    Offset target,
    Offset? endpoint,
  ) {
    final poses = Map<String, BonePose>.of(start);
    final tip = bones.last;

    BonePose pose(Bone b) => poses[b.id] ?? BonePose.rest;
    double clamp(Bone b, double r) {
      final lo = b.minAngle, hi = b.maxAngle;
      if (lo != null && r < lo) r = lo;
      if (hi != null && r > hi) r = hi;
      return r;
    }

    void setRotation(Bone b, double r) {
      final p = pose(b);
      poses[b.id] = p.copyWith(rotation: clamp(b, r));
    }

    // A straight chain can fold either way and the search would pick by
    // rounding noise; a small nudge makes it fold the way `bend` asks.
    // The nudge goes on every bone but the root of the chain, which is the
    // one that swings the whole limb.
    if (bones.length > 1 && _isNearlyStraight(rig, poses, bones)) {
      for (final b in bones.skip(1)) {
        setRotation(b, pose(b).rotation + bend * 8);
      }
    }

    for (var i = 0; i < _ikIterations; i++) {
      var moved = false;
      // Tip first: the bones nearest the target make the finest corrections.
      for (var j = bones.length - 1; j >= 0; j--) {
        final world = solve(rig, poses);
        final reach = world[tip.id]!.apply(endpoint ?? tip.tail);
        if ((reach - target).distance < _ikTolerance) return poses;

        final bone = bones[j];
        final head = world[bone.id]!.apply(bone.head);
        final toReach = reach - head, toTarget = target - head;
        if (toReach.distance < 1e-9 || toTarget.distance < 1e-9) continue;

        var turn = (toTarget.direction - toReach.direction) * 180 / math.pi;
        while (turn > 180) {
          turn -= 360;
        }
        while (turn < -180) {
          turn += 360;
        }

        // A mirrored parent turns the bone the other way on screen.
        final parent = bone.parentId == null ? null : world[bone.parentId];
        final sign = parent != null && parent.determinant < 0 ? -1.0 : 1.0;

        final before = pose(bone).rotation;
        setRotation(bone, before + sign * turn);
        if ((pose(bone).rotation - before).abs() > 1e-6) moved = true;
      }
      // Every bone is at a limit or already aimed: nothing more to gain.
      if (!moved) break;
    }
    return poses;
  }

  static bool _isNearlyStraight(Rig rig, Map<String, BonePose> poses, List<Bone> bones) {
    final world = solve(rig, poses);
    final tip = bones.last;
    final root = world[bones.first.id]!.apply(bones.first.head);
    final end = world[tip.id]!.apply(tip.tail);
    final reach = (end - root).distance;
    var length = 0.0;
    for (final b in bones) {
      length += b.length;
    }
    return length > 0 && reach / length > 0.995;
  }

  /// World transform of every bone in [rig] for [poses] (missing bones sit at
  /// rest).
  ///
  /// A bone's own pose rotates/flips/moves it about its rest `head`; the
  /// result is then carried along by its parent's world transform, so a child
  /// follows its parent. Rotation is clamped to the bone's limits, then
  /// snapped to `rig.settings.snapAngleDegrees`.
  ///
  /// Parent links that are missing or cyclic are treated as "no parent"
  /// rather than looping forever.
  static Map<String, Affine2> solve(Rig rig, Map<String, BonePose> poses) {
    final bones = {for (final bone in rig.bones) bone.id: bone};
    final world = <String, Affine2>{};

    Affine2 resolve(Bone bone, Set<String> visiting) {
      final cached = world[bone.id];
      if (cached != null) return cached;

      Affine2? parentWorld;
      final parent = bone.parentId == null ? null : bones[bone.parentId];
      if (parent != null && visiting.add(bone.id)) {
        parentWorld = resolve(parent, visiting);
        visiting.remove(bone.id);
      }

      final local = localTransform(bone, poses[bone.id] ?? BonePose.rest, rig.settings.snapAngleDegrees);
      final result = parentWorld == null ? local : local.then(parentWorld);
      return world[bone.id] = result;
    }

    for (final bone in rig.bones) {
      resolve(bone, {});
    }
    return world;
  }

  /// A bone's own pose as a transform about its head, ignoring its parent.
  static Affine2 localTransform(Bone bone, BonePose pose, double snapDegrees) {
    var rotation = pose.rotation;
    final lo = bone.minAngle, hi = bone.maxAngle;
    if (lo != null && rotation < lo) rotation = lo;
    if (hi != null && rotation > hi) rotation = hi;
    // A bone's own setting wins over the rig's; 0 means no snapping.
    final snap = bone.snapAngle ?? snapDegrees;
    if (snap > 0) {
      rotation = (rotation / snap).roundToDouble() * snap;
      // Snapping must not carry the bone past its limits.
      if (lo != null && rotation < lo) rotation = lo;
      if (hi != null && rotation > hi) rotation = hi;
    }

    final head = bone.head;
    var t = Affine2.identity;
    // Scale first, in the bone's rest direction, so stretching follows the
    // bone however it is then flipped or turned.
    if (pose.isScaled) {
      t = Affine2.scaleAlong(
        math.max(BonePose.minScale, pose.scaleX),
        math.max(BonePose.minScale, pose.scaleY),
        bone.restAngle,
        head,
      );
    }
    if (pose.flipX) t = t.then(Affine2.flipX(head.dx));
    if (pose.flipY) t = t.then(Affine2.flipY(head.dy));
    t = t.then(Affine2.rotationAbout(rotation, head));
    return t.thenTranslate(pose.translation.dx, pose.translation.dy);
  }
}
