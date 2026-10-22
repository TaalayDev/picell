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

  const IkKeyframe({
    required this.time,
    required this.chainId,
    required this.target,
    this.easing = RigEasing.linear,
  });

  IkKeyframe copyWith({int? time, String? chainId, Offset? target, RigEasing? easing}) {
    return IkKeyframe(
      time: time ?? this.time,
      chainId: chainId ?? this.chainId,
      target: target ?? this.target,
      easing: easing ?? this.easing,
    );
  }

  Map<String, dynamic> toJson() => {
        'time': time,
        'chainId': chainId,
        'target': {'dx': target.dx, 'dy': target.dy},
        'easing': easing.name,
      };

  factory IkKeyframe.fromJson(Map<String, dynamic> json) {
    final t = json['target'] as Map<String, dynamic>;
    return IkKeyframe(
      time: json['time'] as int,
      chainId: json['chainId'] as String,
      target: Offset((t['dx'] as num).toDouble(), (t['dy'] as num).toDouble()),
      easing: RigEasing.values.firstWhere(
        (e) => e.name == json['easing'],
        orElse: () => RigEasing.linear,
      ),
    );
  }

  @override
  List<Object?> get props => [time, chainId, target, easing];
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

  const RigClip({
    required this.id,
    required this.name,
    this.fps = 12,
    this.length = 8,
    this.loop = true,
    this.keyframes = const [],
    this.ikKeyframes = const [],
  });

  RigClip copyWith({
    String? id,
    String? name,
    int? fps,
    int? length,
    bool? loop,
    List<RigKeyframe>? keyframes,
    List<IkKeyframe>? ikKeyframes,
  }) {
    return RigClip(
      id: id ?? this.id,
      name: name ?? this.name,
      fps: fps ?? this.fps,
      length: length ?? this.length,
      loop: loop ?? this.loop,
      keyframes: keyframes ?? this.keyframes,
      ikKeyframes: ikKeyframes ?? this.ikKeyframes,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'fps': fps,
        'length': length,
        'loop': loop,
        'keyframes': keyframes.map((k) => k.toJson()).toList(),
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
      ikKeyframes: ((json['ikKeyframes'] as List?) ?? const [])
          .map((k) => IkKeyframe.fromJson(k as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [id, name, fps, length, loop, keyframes, ikKeyframes];
}
