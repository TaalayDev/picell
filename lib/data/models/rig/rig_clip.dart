import 'dart:ui';

import 'package:equatable/equatable.dart';

enum RigEasing { linear, easeIn, easeOut, easeInOut, stepped }

/// A bone's pose at one point of a clip. Missing channels keep the value of
/// the previous keyframe (or the rest pose before the first one).
class RigKeyframe with EquatableMixin {
  /// Frame index within the clip.
  final int time;
  final String boneId;

  /// Degrees, added to the bone's rest angle.
  final double rotation;
  final Offset translation;
  final bool flipX;

  /// Easing used to reach the next keyframe of the same bone.
  final RigEasing easing;

  const RigKeyframe({
    required this.time,
    required this.boneId,
    this.rotation = 0,
    this.translation = Offset.zero,
    this.flipX = false,
    this.easing = RigEasing.linear,
  });

  RigKeyframe copyWith({
    int? time,
    String? boneId,
    double? rotation,
    Offset? translation,
    bool? flipX,
    RigEasing? easing,
  }) {
    return RigKeyframe(
      time: time ?? this.time,
      boneId: boneId ?? this.boneId,
      rotation: rotation ?? this.rotation,
      translation: translation ?? this.translation,
      flipX: flipX ?? this.flipX,
      easing: easing ?? this.easing,
    );
  }

  Map<String, dynamic> toJson() => {
        'time': time,
        'boneId': boneId,
        'rotation': rotation,
        'translation': {'dx': translation.dx, 'dy': translation.dy},
        'flipX': flipX,
        'easing': easing.name,
      };

  factory RigKeyframe.fromJson(Map<String, dynamic> json) {
    final t = json['translation'] as Map<String, dynamic>?;
    return RigKeyframe(
      time: json['time'] as int,
      boneId: json['boneId'] as String,
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0,
      translation: t == null ? Offset.zero : Offset((t['dx'] as num).toDouble(), (t['dy'] as num).toDouble()),
      flipX: json['flipX'] as bool? ?? false,
      easing: RigEasing.values.firstWhere(
        (e) => e.name == json['easing'],
        orElse: () => RigEasing.linear,
      ),
    );
  }

  @override
  List<Object?> get props => [time, boneId, rotation, translation, flipX, easing];
}

/// Where an [IkChain]'s target is on one frame, in canvas pixels. Between
/// keys the target travels in a straight line.
class IkKeyframe with EquatableMixin {
  final int time;
  final String chainId;
  final Offset target;

  /// Easing used to reach the next keyframe of the same chain.
  final RigEasing easing;

  /// A contact holds only this frame, unlike an interpolated IK target.
  final bool planted;

  const IkKeyframe({
    required this.time,
    required this.chainId,
    required this.target,
    this.easing = RigEasing.linear,
    this.planted = false,
  });

  IkKeyframe copyWith({int? time, String? chainId, Offset? target, RigEasing? easing, bool? planted}) {
    return IkKeyframe(
      time: time ?? this.time,
      chainId: chainId ?? this.chainId,
      target: target ?? this.target,
      easing: easing ?? this.easing,
      planted: planted ?? this.planted,
    );
  }

  Map<String, dynamic> toJson() => {
        'time': time,
        if (planted) 'planted': true,
        'chainId': chainId,
        'target': {'dx': target.dx, 'dy': target.dy},
        'easing': easing.name,
      };

  factory IkKeyframe.fromJson(Map<String, dynamic> json) {
    final t = json['target'] as Map<String, dynamic>;
    return IkKeyframe(
      time: json['time'] as int,
      chainId: json['chainId'] as String,
      planted: json['planted'] == true,
      target: Offset((t['dx'] as num).toDouble(), (t['dy'] as num).toDouble()),
      easing: RigEasing.values.firstWhere(
        (e) => e.name == json['easing'],
        orElse: () => RigEasing.linear,
      ),
    );
  }

  @override
  List<Object?> get props => [time, chainId, target, easing, planted];
}

/// A world-space bone pose held for one frame of one clip.
/// Matrix entries map rest-canvas coordinates to the frozen pose.
class JointFreeze with EquatableMixin {
  const JointFreeze({required this.boneId, required this.time, required this.matrix, this.sourcePresetId});
  final String boneId;
  final int time;
  final List<double> matrix;

  /// Preset-created locks can be released when another preset animates the leg.
  /// Null identifies a lock placed manually by the user.
  final String? sourcePresetId;
  JointFreeze copyWith({int? time}) =>
      JointFreeze(boneId: boneId, time: time ?? this.time, matrix: matrix, sourcePresetId: sourcePresetId);
  Map<String, dynamic> toJson() => {
        'boneId': boneId,
        'time': time,
        'matrix': matrix,
        if (sourcePresetId != null) 'sourcePresetId': sourcePresetId,
      };
  factory JointFreeze.fromJson(Map<String, dynamic> json) {
    final values = (json['matrix'] as List).map((n) => (n as num).toDouble()).toList();
    if (values.length != 6 || values.any((n) => !n.isFinite)) {
      throw const FormatException('Invalid frozen joint matrix');
    }
    return JointFreeze(
        boneId: json['boneId'] as String,
        time: json['time'] as int,
        matrix: values,
        sourcePresetId: json['sourcePresetId'] as String?);
  }
  @override
  List<Object?> get props => [boneId, time, matrix, sourcePresetId];
}

/// A keyed animation of a rig. Baked into the linked animation state's frames.
class RigClip with EquatableMixin {
  final String id;
  final String name;
  final int fps;

  /// Number of frames the clip produces.
  final int length;
  final bool loop;
  final List<RigKeyframe> keyframes;

  /// Target positions of the rig's IK chains over time.
  final List<IkKeyframe> ikKeyframes;
  final List<JointFreeze> freezes;

  const RigClip({
    required this.id,
    required this.name,
    this.fps = 12,
    this.length = 8,
    this.loop = true,
    this.keyframes = const [],
    this.ikKeyframes = const [],
    this.freezes = const [],
  });

  RigClip copyWith({
    String? id,
    String? name,
    int? fps,
    int? length,
    bool? loop,
    List<RigKeyframe>? keyframes,
    List<IkKeyframe>? ikKeyframes,
    List<JointFreeze>? freezes,
  }) {
    return RigClip(
      id: id ?? this.id,
      name: name ?? this.name,
      fps: fps ?? this.fps,
      length: length ?? this.length,
      loop: loop ?? this.loop,
      keyframes: keyframes ?? this.keyframes,
      ikKeyframes: ikKeyframes ?? this.ikKeyframes,
      freezes: freezes ?? this.freezes,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'fps': fps,
        'length': length,
        'loop': loop,
        'keyframes': keyframes.map((k) => k.toJson()).toList(),
        if (freezes.isNotEmpty) 'freezes': freezes.map((f) => f.toJson()).toList(),
        if (ikKeyframes.isNotEmpty) 'ikKeyframes': ikKeyframes.map((k) => k.toJson()).toList(),
      };

  factory RigClip.fromJson(Map<String, dynamic> json) {
    return RigClip(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      fps: json['fps'] as int? ?? 12,
      length: json['length'] as int? ?? 8,
      loop: json['loop'] as bool? ?? true,
      keyframes: ((json['keyframes'] as List?) ?? const [])
          .map((k) => RigKeyframe.fromJson(k as Map<String, dynamic>))
          .toList(),
      freezes:
          ((json['freezes'] as List?) ?? const []).map((f) => JointFreeze.fromJson(f as Map<String, dynamic>)).toList(),
      ikKeyframes: ((json['ikKeyframes'] as List?) ?? const [])
          .map((k) => IkKeyframe.fromJson(k as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [id, name, fps, length, loop, keyframes, ikKeyframes, freezes];
}
