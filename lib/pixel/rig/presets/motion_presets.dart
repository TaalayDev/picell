import 'dart:math' as math;
import 'dart:ui';

import '../../../data/models/rig/rig.dart';
import '../pose_interpolator.dart';
import 'name_tokens.dart';

/// How a repeating motion rises and falls over one cycle.
enum WaveShape {
  /// A smooth swing either side of the bias.
  sine,

  /// Only the positive half of the swing: a foot that lifts and comes down.
  lift,

  /// The swing folded over, so it peaks twice a cycle: a body bouncing on
  /// each step.
  bounce,
}

/// A repeating value: `bias + amplitude * shape(sin(2π (cycles·t + phase)))`
/// over a clip, where `t` runs 0..1.
///
/// An [overtone] adds a second swing at twice the speed (as a fraction of
/// the first), shifted by [overtonePhase] of its own cycle. It skews the
/// plain sine so one half of a swing is quicker than the other: a leg that
/// whips forward and pushes back slowly, a wing that beats down hard.
class Wave {
  final double amplitude;
  final double cycles;

  /// Shift in cycles (0.25 is a quarter of a cycle later).
  final double phase;
  final double bias;
  final WaveShape shape;
  final double overtone;
  final double overtonePhase;

  const Wave({
    this.amplitude = 0,
    this.cycles = 1,
    this.phase = 0,
    this.bias = 0,
    this.shape = WaveShape.sine,
    this.overtone = 0,
    this.overtonePhase = 0,
  });

  double at(double t, {double phaseShift = 0, double amplitudeScale = 1}) {
    final turn = cycles * t + phase + phaseShift;
    var s = math.sin(2 * math.pi * turn);
    if (overtone != 0) s += overtone * math.sin(2 * math.pi * (2 * turn + overtonePhase));
    final shaped = switch (shape) {
      WaveShape.sine => s,
      WaveShape.lift => math.max(0.0, s),
      WaveShape.bounce => s.abs(),
    };
    return bias + amplitude * amplitudeScale * shaped;
  }
}

/// A pose at one moment of a keyed motion. [t] runs 0..1 over the clip;
/// rotation is in degrees and the shifts are fractions of the canvas height.
class MotionKey {
  final double t;
  final double rotation;
  final double tx;
  final double ty;

  const MotionKey(this.t, {this.rotation = 0, this.tx = 0, this.ty = 0});
}

/// What one bone does in a motion, found by [role] (a name such as
/// "thigh_l"; `*` means whichever bones the animation is applied to).
///
/// Either waves (sampled on every frame) or [keys] (poses, eased between).
/// Shifts are fractions of the canvas height, so a motion suits any size.
class MotionTrack {
  final String role;
  final Wave? rotation;
  final Wave? tx;
  final Wave? ty;
  final List<MotionKey> keys;
  final RigEasing easing;

  const MotionTrack(
    this.role, {
    this.rotation,
    this.tx,
    this.ty,
    this.keys = const [],
    this.easing = RigEasing.easeInOut,
  });
}

/// Where an animation preset finds its bones.
enum MotionTarget {
  /// By name: the bone presets' names (head, arm_l, thigh_r...) or anything
  /// that reads the same.
  roles,

  /// The selected bone alone.
  selectedBone,

  /// The selected bone and everything below it, each a little later and
  /// further along than the one before: a tail, hair, a rope.
  selectedChain,
}

/// A ready-made animation.
class MotionPreset {
  final String id;
  final String name;
  final String description;
  final String category;
  final int frames;
  final int fps;
  final bool loop;
  final Map<String, String>? roleBindings;
  final bool proportionScale;
  final bool keepPosition;
  final double? groundY;

  /// Automatically hold both available foot contacts for the full clip.
  final bool plantFeet;

  /// Show optional grounding controls even when the preset starts without them.
  final bool legControls;
  static const legJointRoles = ['thigh_l', 'thigh_r', 'shin_l', 'shin_r', 'foot_l', 'foot_r'];

  /// Roles held at their rest-world pose throughout this clip.
  final List<String> lockedRoles;
  final MotionTarget target;
  final List<MotionTrack> tracks;

  /// For [MotionTarget.selectedChain]: how much later (in cycles) and how much
  /// larger (as a fraction) the motion gets at each bone further down.
  final double lag;
  final double growth;

  const MotionPreset({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.frames,
    required this.fps,
    required this.tracks,
    this.loop = true,
    this.roleBindings,
    this.proportionScale = false,
    this.keepPosition = false,
    this.groundY,
    this.plantFeet = false,
    this.legControls = false,
    this.lockedRoles = const [],
    this.target = MotionTarget.roles,
    this.lag = 0,
    this.growth = 0,
  });

  /// Settings used for both the preview and the applied animation.
  MotionPreset copyWith(
          {int? frames,
          int? fps,
          bool? loop,
          bool? plantFeet,
          List<String>? lockedRoles,
          Map<String, String>? roleBindings,
          bool? proportionScale,
          bool? keepPosition,
          double? Function()? groundY}) =>
      MotionPreset(
        id: id,
        roleBindings: roleBindings ?? this.roleBindings,
        proportionScale: proportionScale ?? this.proportionScale,
        keepPosition: keepPosition ?? this.keepPosition,
        groundY: groundY != null ? groundY() : this.groundY,
        name: name,
        description: description,
        category: category,
        frames: frames ?? this.frames,
        fps: fps ?? this.fps,
        loop: loop ?? this.loop,
        plantFeet: plantFeet ?? this.plantFeet,
        legControls: legControls,
        lockedRoles: lockedRoles ?? this.lockedRoles,
        tracks: tracks,
        target: target,
        lag: lag,
        growth: growth,
      );

  /// The roles the preset is written for, in track order.
  List<String> get roles => [for (final t in tracks) t.role];
}

/// The result of fitting a [MotionPreset] to a rig.
class MotionResult {
  const MotionResult({
    required this.keyframes,
    required this.matched,
    required this.missing,
    required this.frames,
    required this.fps,
    required this.loop,
  });

  /// Keys for every bone that was found, one per frame (or per keyed pose).
  final List<RigKeyframe> keyframes;

  /// The bones found, by role.
  final Map<String, Bone> matched;

  /// Roles that no bone matched.
  final List<String> missing;
  final int frames;
  final int fps;
  final bool loop;

  bool get isEmpty => keyframes.isEmpty;
}

/// Turns a [MotionPreset] into keyframes for a rig's bones.
abstract final class MotionBuilder {
  /// How many of [preset]'s roles [bones] can supply, without building.
  static ({int matched, int total}) coverage(MotionPreset preset, Iterable<Bone> bones,
      {bool mirror = false, Map<String, String> roleBindings = const {}}) {
    if (preset.target != MotionTarget.roles) return (matched: 0, total: 0);
    final roles = preset.roles;
    final found = RoleMatcher.match([for (final r in roles) mirror ? _swapSide(r) : r], bones);
    for (final role in roles.map((r) => mirror ? _swapSide(r) : r)) {
      final explicit = bones.where((b) => b.id == roleBindings[role]).firstOrNull;
      if (explicit != null) found[role] = explicit;
    }
    // Parts the rig lacks but whose motion folds into a bone it has (a
    // one-bone leg takes the knee bend) need no bone of their own.
    final present = {
      for (final r in roles)
        if (found[mirror ? _swapSide(r) : r] != null) r
    };
    final folded = roles.where((r) => !present.contains(r) && _foldInto(r, present).isNotEmpty).length;
    return (matched: found.values.map((b) => b.id).toSet().length, total: roles.length - folded);
  }

  /// Where a part's rotation goes when the rig has no bone for it, as
  /// (role, share). Simple rigs draw a limb as one bone: half the knee or
  /// elbow bend turns that bone so the hand or foot ends up about where the
  /// two-bone limb would put it. A missing spine leans the body from the hips
  /// and turns the legs back the other way, so they stay where they were.
  static const _folds = <String, List<(String, double)>>{
    'forearm_l': [('arm_l', .5)],
    'forearm_r': [('arm_r', .5)],
    'hand_l': [('forearm_l', .5)],
    'hand_r': [('forearm_r', .5)],
    'shin_l': [('thigh_l', .5)],
    'shin_r': [('thigh_r', .5)],
    'foot_l': [('shin_l', .5)],
    'foot_r': [('shin_r', .5)],
    'neck': [('head', 1)],
    'spine': [('hips', 1), ('thigh_l', -1), ('thigh_r', -1)],
  };

  /// The present roles [role]'s rotation lands on, with their shares,
  /// following the chain past other missing parts (hand -> forearm -> arm).
  static List<(String, double)> _foldInto(String role, Set<String> present, [double share = 1, int depth = 0]) {
    final targets = _folds[role];
    if (targets == null || depth > 3) return const [];
    // The spine's counter-turn of the legs only makes sense when the body
    // itself can lean.
    if (role == 'spine' && !present.contains('hips')) return const [];
    return [
      for (final (target, s) in targets)
        if (present.contains(target)) (target, share * s) else ..._foldInto(target, present, share * s, depth + 1),
    ];
  }

  /// Fits [preset] to [bones].
  ///
  /// [canvasHeight] turns the preset's shifts into pixels (a shift of less
  /// than a pixel but more than a quarter is rounded up to one, so a motion
  /// does not vanish on a small sprite). [intensity] scales every rotation
  /// and shift. [mirror] swaps the left and right sides and flips rotations
  /// and sideways shifts, to face the other way. [selectedBoneId] is the bone
  /// that selection-based presets work from.
  static MotionResult build(
    MotionPreset preset, {
    required List<Bone> bones,
    required double canvasHeight,
    double intensity = 1,
    bool mirror = false,
    String? selectedBoneId,
    Map<String, String> roleBindings = const {},
  }) {
    final sign = mirror ? -1.0 : 1.0;
    final keys = <RigKeyframe>[];
    final matched = <String, Bone>{};
    final missing = <String>[];

    // Which bone gets which track, and how far down a chain it is.
    final assignments = <({MotionTrack track, Bone bone, int depth})>[];
    if (preset.target == MotionTarget.roles) {
      final roleFor = {for (final t in preset.tracks) t.role: mirror ? _swapSide(t.role) : t.role};
      final found = RoleMatcher.match(roleFor.values, bones);
      for (final role in roleFor.values) {
        final explicit = bones.where((b) => b.id == roleBindings[role]).firstOrNull;
        if (explicit != null) found[role] = explicit;
      }
      final used = <String>{};
      for (final track in preset.tracks) {
        final bone = found[roleFor[track.role]];
        if (bone == null || !used.add(bone.id)) {
          missing.add(track.role);
        } else {
          matched[track.role] = bone;
          assignments.add((track: track, bone: bone, depth: 0));
        }
      }
    } else {
      final selected = bones.where((b) => b.id == selectedBoneId).firstOrNull;
      if (selected != null && preset.tracks.isNotEmpty) {
        final track = preset.tracks.first;
        final bonesDown = preset.target == MotionTarget.selectedChain ? _descendants(selected, bones) : [(selected, 0)];
        for (final (bone, depth) in bonesDown) {
          matched['${track.role}:${bone.id}'] = bone;
          assignments.add((track: track, bone: bone, depth: depth));
        }
      }
    }

    // Motion of parts the rig lacks, gathered onto the bones that stand in.
    final extras = <String, List<(MotionTrack, double)>>{};
    if (preset.target == MotionTarget.roles) {
      final present = {for (final a in assignments) a.track.role};
      final tracksByRole = {for (final t in preset.tracks) t.role: t};
      for (final role in missing) {
        final track = tracksByRole[role];
        if (track == null) continue;
        for (final (target, share) in _foldInto(role, present)) {
          extras.putIfAbsent(target, () => []).add((track, share));
        }
      }
    }

    for (final a in assignments) {
      final folded = extras[a.track.role];
      if (folded != null) {
        keys.addAll(_combinedFrames(preset, a.track, folded, a.bone, canvasHeight, intensity, sign));
      } else if (a.track.keys.isNotEmpty) {
        keys.addAll(_keyedFrames(preset, a.track, a.bone, canvasHeight, intensity, sign));
      } else {
        keys.addAll(_sampledFrames(preset, a.track, a.bone, a.depth, canvasHeight, intensity, sign));
      }
    }

    return MotionResult(
      keyframes: keys,
      matched: matched,
      missing: missing,
      frames: preset.frames,
      fps: preset.fps,
      loop: preset.loop,
    );
  }

  static List<RigKeyframe> _sampledFrames(
    MotionPreset preset,
    MotionTrack track,
    Bone bone,
    int depth,
    double canvasHeight,
    double intensity,
    double sign,
  ) {
    final shift = -preset.lag * depth;
    final scale = 1 + preset.growth * depth;
    return [
      for (var i = 0; i < preset.frames; i++)
        () {
          final t = i / preset.frames;
          return RigKeyframe(
            time: i,
            boneId: bone.id,
            rotation: (track.rotation?.at(t, phaseShift: shift, amplitudeScale: scale) ?? 0) * intensity * sign,
            translation: Offset(
              _pixels(
                  (track.tx?.at(t, phaseShift: shift, amplitudeScale: scale) ?? 0) * intensity * sign, canvasHeight),
              _pixels((track.ty?.at(t, phaseShift: shift, amplitudeScale: scale) ?? 0) * intensity, canvasHeight),
            ),
          );
        }(),
    ];
  }

  static List<RigKeyframe> _keyedFrames(
    MotionPreset preset,
    MotionTrack track,
    Bone bone,
    double canvasHeight,
    double intensity,
    double sign,
  ) {
    final byFrame = <int, RigKeyframe>{};
    for (final k in track.keys) {
      // A looping clip repeats, so its last frame is not its first; a one-shot
      // clip may reach its last frame.
      final frame = preset.loop
          ? (k.t * preset.frames).round() % preset.frames
          : (k.t * (preset.frames - 1)).round().clamp(0, preset.frames - 1);
      byFrame[frame] = RigKeyframe(
        time: frame,
        boneId: bone.id,
        rotation: k.rotation * intensity * sign,
        translation: Offset(
          _pixels(k.tx * intensity * sign, canvasHeight),
          _pixels(k.ty * intensity, canvasHeight),
        ),
        easing: track.easing,
      );
    }
    return byFrame.values.toList();
  }

  /// One key per frame for a bone that also carries the rotation of parts
  /// the rig lacks: its own track plus each folded track times its share.
  static List<RigKeyframe> _combinedFrames(
    MotionPreset preset,
    MotionTrack track,
    List<(MotionTrack, double)> folded,
    Bone bone,
    double canvasHeight,
    double intensity,
    double sign,
  ) {
    return [
      for (var i = 0; i < preset.frames; i++)
        () {
          var rotation = _valueAt(preset, track, i, (k) => k.rotation, (w) => w.rotation);
          for (final (other, share) in folded) {
            rotation += share * _valueAt(preset, other, i, (k) => k.rotation, (w) => w.rotation);
          }
          return RigKeyframe(
            time: i,
            boneId: bone.id,
            rotation: rotation * intensity * sign,
            translation: Offset(
              _pixels(_valueAt(preset, track, i, (k) => k.tx, (w) => w.tx) * intensity * sign, canvasHeight),
              _pixels(_valueAt(preset, track, i, (k) => k.ty, (w) => w.ty) * intensity, canvasHeight),
            ),
          );
        }(),
    ];
  }

  /// [track]'s value at [frame], the way playback would show it: a wave
  /// sampled, or keyed poses eased between as the clip's keyframes would be.
  static double _valueAt(
    MotionPreset preset,
    MotionTrack track,
    int frame,
    double Function(MotionKey) keyValue,
    Wave? Function(MotionTrack) wave,
  ) {
    if (track.keys.isEmpty) return wave(track)?.at(frame / preset.frames) ?? 0;
    final n = preset.frames;
    // Key positions in frames, as [_keyedFrames] places them; a looping clip
    // runs on from its last key back round to its first.
    final byFrame = <int, double>{};
    for (final k in track.keys) {
      final f = preset.loop ? (k.t * n).round() % n : (k.t * (n - 1)).round().clamp(0, n - 1);
      byFrame[f] = keyValue(k);
    }
    final frames = byFrame.keys.toList()..sort();
    if (byFrame.containsKey(frame)) return byFrame[frame]!;
    var before = frames.lastWhere((f) => f < frame, orElse: () => -1);
    var after = frames.firstWhere((f) => f > frame, orElse: () => -1);
    if (preset.loop) {
      if (before < 0) before = frames.last - n;
      if (after < 0) after = frames.first + n;
    } else {
      if (before < 0) return byFrame[after]!;
      if (after < 0) return byFrame[before]!;
    }
    final from = byFrame[(before % n + n) % n]!, to = byFrame[after % n]!;
    final progress = PoseInterpolator.ease(track.easing, (frame - before) / (after - before));
    return from + (to - from) * progress;
  }

  /// A shift in pixels. Shifts between a quarter and a whole pixel become a
  /// whole one: on a small sprite a motion should step, not disappear.
  static double _pixels(double fraction, double canvasHeight) {
    final px = fraction * canvasHeight;
    if (px.abs() > 0.25 && px.abs() < 1) return px.sign;
    return px;
  }

  /// [bone] and everything under it, nearest first, with how far down each is.
  static List<(Bone, int)> _descendants(Bone bone, List<Bone> all) {
    final out = <(Bone, int)>[(bone, 0)];
    final seen = {bone.id};
    for (var i = 0; i < out.length; i++) {
      for (final child in all) {
        if (child.parentId == out[i].$1.id && seen.add(child.id)) out.add((child, out[i].$2 + 1));
      }
    }
    return out;
  }

  /// "arm_l" -> "arm_r" and back; other roles are unchanged.
  static String _swapSide(String role) {
    if (role.endsWith('_l')) return '${role.substring(0, role.length - 2)}_r';
    if (role.endsWith('_r')) return '${role.substring(0, role.length - 2)}_l';
    return role;
  }
}
