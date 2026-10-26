import 'dart:ui';
import 'package:equatable/equatable.dart';

/// Named socket in bone-local coordinates (X along the bone, Y across it).
class RigAttachment with EquatableMixin {
  const RigAttachment(
      {required this.id, required this.boneId, required this.name, this.offset = Offset.zero, this.angle = 0});
  final String id, boneId, name;
  final Offset offset;
  final double angle;
  RigAttachment copyWith({String? name, Offset? offset, double? angle}) => RigAttachment(
      id: id, boneId: boneId, name: name ?? this.name, offset: offset ?? this.offset, angle: angle ?? this.angle);
  Map<String, dynamic> toJson() =>
      {'id': id, 'boneId': boneId, 'name': name, 'x': offset.dx, 'y': offset.dy, 'angle': angle};
  factory RigAttachment.fromJson(Map<String, dynamic> json) => RigAttachment(
      id: json['id'] as String,
      boneId: json['boneId'] as String,
      name: json['name'] as String,
      offset: Offset((json['x'] as num?)?.toDouble() ?? 0, (json['y'] as num?)?.toDouble() ?? 0),
      angle: (json['angle'] as num?)?.toDouble() ?? 0);
  @override
  List<Object?> get props => [id, boneId, name, offset, angle];
}
