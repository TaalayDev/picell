import 'dart:ui';

import 'package:equatable/equatable.dart';

enum RigEasing { linear, easeIn, easeOut, easeInOut, stepped }

/// A cubic Bézier easing curve, as in CSS `cubic-bezier(x1, y1, x2, y2)`: the
/// curve runs from (0, 0) to (1, 1) with these two control points. The x
/// values stay in 0..1 (time never runs backwards); the y values may leave
/// 0..1 to overshoot the target or pull back before moving.
class EasingCurve with EquatableMixin {
  final double x1, y1, x2, y2;

  /// Control points are clamped to what the editor offers.
  static const double minY = -1, maxY = 2;

  EasingCurve(double x1, double y1, double x2, double y2)
      : x1 = x1.clamp(0.0, 1.0),
        y1 = y1.clamp(minY, maxY),
        x2 = x2.clamp(0.0, 1.0),
        y2 = y2.clamp(minY, maxY);

  static final linear = EasingCurve(0, 0, 1, 1);
  static final easeIn = EasingCurve(.42, 0, 1, 1);
  static final easeOut = EasingCurve(0, 0, .58, 1);
  static final easeInOut = EasingCurve(.42, 0, .58, 1);

  /// Eased progress for linear progress [t] (0..1). The result may leave 0..1
  /// when the curve overshoots.
  double transform(double t) {
    t = t.clamp(0.0, 1.0);
    if (t == 0 || t == 1) return t;
    // Solve x(s) = t for the curve parameter s by bisection: x is monotonic
    // for control x values in 0..1.
    var lo = 0.0, hi = 1.0, s = t;
    for (var i = 0; i < 40; i++) {
      s = (lo + hi) / 2;
      final x = _bezier(s, x1, x2);
      if ((x - t).abs() < 1e-9) break;
      if (x < t) {
        lo = s;
      } else {
        hi = s;
      }
    }
    return _bezier(s, y1, y2);
  }

  static double _bezier(double s, double p1, double p2) {
    final u = 1 - s;
    return 3 * u * u * s * p1 + 3 * u * s * s * p2 + s * s * s;
  }

  EasingCurve copyWith({double? x1, double? y1, double? x2, double? y2}) =>
      EasingCurve(x1 ?? this.x1, y1 ?? this.y1, x2 ?? this.x2, y2 ?? this.y2);

  List<double> toJson() => [x1, y1, x2, y2];

  /// Null for anything that is not four numbers.
  static EasingCurve? fromJson(Object? json) {
    if (json is! List || json.length != 4 || json.any((v) => v is! num || !v.isFinite)) return null;
    final v = [for (final n in json) (n as num).toDouble()];
    return EasingCurve(v[0], v[1], v[2], v[3]);
  }

  @override
  List<Object?> get props => [x1, y1, x2, y2];
}

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

  /// A custom curve for the same segment; when set it is used instead of
  /// [easing].
  final EasingCurve? curve;

  const RigKeyframe({
    required this.time,
    required this.boneId,
    this.rotation = 0,
    this.translation = Offset.zero,
    this.flipX = false,
    this.easing = RigEasing.linear,
    this.curve,
  });

  RigKeyframe copyWith({
    int? time,
    String? boneId,
    double? rotation,
    Offset? translation,
    bool? flipX,
    RigEasing? easing,
    EasingCurve? Function()? curve,
  }) {
    return RigKeyframe(
      time: time ?? this.time,
      boneId: boneId ?? this.boneId,
      rotation: rotation ?? this.rotation,
      translation: translation ?? this.translation,
      flipX: flipX ?? this.flipX,
      easing: easing ?? this.easing,
      curve: curve != null ? curve() : this.curve,
    );
  }

  Map<String, dynamic> toJson() => {
        'time': time,
        'boneId': boneId,
        'rotation': rotation,
        'translation': {'dx': translation.dx, 'dy': translation.dy},
        'flipX': flipX,
        'easing': easing.name,
        if (curve != null) 'curve': curve!.toJson(),
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
      curve: EasingCurve.fromJson(json['curve']),
    );
  }

  @override
  List<Object?> get props => [time, boneId, rotation, translation, flipX, easing, curve];
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

  /// A custom curve for the same segment; used instead of [easing] when set.
  final EasingCurve? curve;

  const IkKeyframe({
    required this.time,
    required this.chainId,
    required this.target,
    this.easing = RigEasing.linear,
    this.planted = false,
    this.curve,
  });

  IkKeyframe copyWith({
    int? time,
    String? chainId,
    Offset? target,
    RigEasing? easing,
    bool? planted,
    EasingCurve? Function()? curve,
  }) {
    return IkKeyframe(
      time: time ?? this.time,
      chainId: chainId ?? this.chainId,
      target: target ?? this.target,
      easing: easing ?? this.easing,
      planted: planted ?? this.planted,
      curve: curve != null ? curve() : this.curve,
    );
  }

  Map<String, dynamic> toJson() => {
        'time': time,
        if (planted) 'planted': true,
        'chainId': chainId,
        'target': {'dx': target.dx, 'dy': target.dy},
        'easing': easing.name,
        if (curve != null) 'curve': curve!.toJson(),
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
      curve: EasingCurve.fromJson(json['curve']),
    );
  }

  @override
  List<Object?> get props => [time, chainId, target, easing, planted, curve];
}

/// Moves a bone's artwork in the stacking order from one frame on, until its
/// next order key. Never blended: the bone steps to the new place.
class DrawOrderKeyframe with EquatableMixin {
  final int time;
  final String boneId;

  /// Layers to move forward (positive) or back (negative) from where the
  /// bone's layer normally sits. Zero is the normal place.
  final int offset;

  const DrawOrderKeyframe({required this.time, required this.boneId, this.offset = 0});

  DrawOrderKeyframe copyWith({int? time, String? boneId, int? offset}) => DrawOrderKeyframe(
        time: time ?? this.time,
        boneId: boneId ?? this.boneId,
        offset: offset ?? this.offset,
      );

  Map<String, dynamic> toJson() => {'time': time, 'boneId': boneId, 'offset': offset};

  factory DrawOrderKeyframe.fromJson(Map<String, dynamic> json) => DrawOrderKeyframe(
        time: json['time'] as int,
        boneId: json['boneId'] as String,
        offset: json['offset'] as int? ?? 0,
      );

  @override
  List<Object?> get props => [time, boneId, offset];
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

  /// Changes of the stacking order of bones' artwork over time.
  final List<DrawOrderKeyframe> orderKeyframes;

  const RigClip({
    required this.id,
    required this.name,
    this.fps = 12,
    this.length = 8,
    this.loop = true,
    this.keyframes = const [],
    this.ikKeyframes = const [],
    this.freezes = const [],
    this.orderKeyframes = const [],
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
    List<DrawOrderKeyframe>? orderKeyframes,
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
      orderKeyframes: orderKeyframes ?? this.orderKeyframes,
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
        if (orderKeyframes.isNotEmpty) 'orderKeyframes': orderKeyframes.map((k) => k.toJson()).toList(),
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
      orderKeyframes: ((json['orderKeyframes'] as List?) ?? const [])
          .map((k) => DrawOrderKeyframe.fromJson(k as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [id, name, fps, length, loop, keyframes, ikKeyframes, freezes, orderKeyframes];
}
