import 'dart:math' as math;
import 'dart:ui';

import '../../../data/models/rig/rig.dart';
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
class Wave {
  final double amplitude;
  final double cycles;

  /// Shift in cycles (0.25 is a quarter of a cycle later).
  final double phase;
  final double bias;
  final WaveShape shape;

  const Wave({this.amplitude = 0, this.cycles = 1, this.phase = 0, this.bias = 0, this.shape = WaveShape.sine});

  double at(double t, {double phaseShift = 0, double amplitudeScale = 1}) {
    final s = math.sin(2 * math.pi * (cycles * t + phase + phaseShift));
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
    return (matched: found.values.map((b) => b.id).toSet().length, total: roles.length);
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

    for (final a in assignments) {
      if (a.track.keys.isNotEmpty) {
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
