import 'dart:math' as math;
import 'dart:ui';

import 'package:equatable/equatable.dart';

/// Implicit links inherit motion only; explicit links also share layer influence.
enum BoneConnection { implicit, explicit }

/// One joint of a [Rig]. Positions are in rest-pose canvas pixels; angles are
/// in degrees, measured clockwise (screen space, y down).
class Bone with EquatableMixin {
  final String id;
  final String name;

  /// Null for a root bone.
  final String? parentId;
  final BoneConnection connection;

  /// Joint position in the rest pose.
  final Offset head;
  final double length;
  final double restAngle;

  /// Optional rotation limits, relative to [restAngle].
  final double? minAngle;
  final double? maxAngle;

  /// Rotation of this bone is rounded to a multiple of this many degrees.
  /// Null follows the rig's setting; 0 turns snapping off for this bone.
  final double? snapAngle;

  const Bone({
    required this.id,
    required this.name,
    this.parentId,
    this.connection = BoneConnection.explicit,
    this.head = Offset.zero,
    this.length = 0,
    this.restAngle = 0,
    this.minAngle,
    this.maxAngle,
    this.snapAngle,
  });

  /// Far end of the bone in the rest pose: [length] pixels from [head] along
  /// [restAngle] (0 = right, 90 = down).
  Offset get tail {
    final r = restAngle * math.pi / 180;
    final point = head + Offset(math.cos(r), math.sin(r)) * length;
    // Remove trigonometric roundoff at exact half-pixel joints.
    double clean(double value) {
      final half = (value * 2).roundToDouble() / 2;
      return (value - half).abs() < 1e-10 ? half : value;
    }

    return Offset(clean(point.dx), clean(point.dy));
  }

  Bone copyWith({
    String? id,
    String? name,
    String? Function()? parentId,
    BoneConnection? connection,
    Offset? head,
    double? length,
    double? restAngle,
    double? Function()? minAngle,
    double? Function()? maxAngle,
    double? Function()? snapAngle,
  }) {
    return Bone(
      id: id ?? this.id,
      name: name ?? this.name,
      parentId: parentId != null ? parentId() : this.parentId,
      connection: connection ?? this.connection,
      head: head ?? this.head,
      length: length ?? this.length,
      restAngle: restAngle ?? this.restAngle,
      minAngle: minAngle != null ? minAngle() : this.minAngle,
      maxAngle: maxAngle != null ? maxAngle() : this.maxAngle,
      snapAngle: snapAngle != null ? snapAngle() : this.snapAngle,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (parentId != null) 'parentId': parentId,
        'connection': connection.name,
        'head': {'dx': head.dx, 'dy': head.dy},
        'length': length,
        'restAngle': restAngle,
        if (minAngle != null) 'minAngle': minAngle,
        if (maxAngle != null) 'maxAngle': maxAngle,
        if (snapAngle != null) 'snapAngle': snapAngle,
      };

  factory Bone.fromJson(Map<String, dynamic> json) {
    final head = json['head'] as Map<String, dynamic>?;
    return Bone(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      parentId: json['parentId'] as String?,
      connection: json['connection'] == 'implicit' ? BoneConnection.implicit : BoneConnection.explicit,
      head: head == null ? Offset.zero : Offset((head['dx'] as num).toDouble(), (head['dy'] as num).toDouble()),
      length: (json['length'] as num?)?.toDouble() ?? 0,
      restAngle: (json['restAngle'] as num?)?.toDouble() ?? 0,
      minAngle: (json['minAngle'] as num?)?.toDouble(),
      maxAngle: (json['maxAngle'] as num?)?.toDouble(),
      snapAngle: (json['snapAngle'] as num?)?.toDouble(),
    );
  }

  @override
  List<Object?> get props => [id, name, parentId, connection, head, length, restAngle, minAngle, maxAngle, snapAngle];
}
