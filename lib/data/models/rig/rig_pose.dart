import 'dart:ui';

import 'package:equatable/equatable.dart';

import 'bone_pose.dart';

/// A saved pose: how every bone was posed, and where every IK target was, on
/// one frame. Kept with the rig so a pose (a stance, a punch, a jump) can be
/// put on any frame of any clip.
class RigPose with EquatableMixin {
  final String id;
  final String name;

  /// Pose of each bone, by bone id. Bones missing here are left alone when
  /// the pose is applied.
  final Map<String, BonePose> bones;

  /// Target of each IK chain that was active, by chain id.
  final Map<String, Offset> ik;

  const RigPose({
    required this.id,
    required this.name,
    this.bones = const {},
    this.ik = const {},
  });

  RigPose copyWith({String? id, String? name, Map<String, BonePose>? bones, Map<String, Offset>? ik}) {
    return RigPose(
      id: id ?? this.id,
      name: name ?? this.name,
      bones: bones ?? this.bones,
      ik: ik ?? this.ik,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'bones': [
          for (final e in bones.entries) {'boneId': e.key, ...e.value.toJson()},
        ],
        if (ik.isNotEmpty)
          'ik': [
            for (final e in ik.entries) {'chainId': e.key, 'dx': e.value.dx, 'dy': e.value.dy},
          ],
      };

  factory RigPose.fromJson(Map<String, dynamic> json) {
    return RigPose(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Pose',
      bones: {
        for (final b in (json['bones'] as List? ?? const []))
          (b as Map<String, dynamic>)['boneId'] as String: BonePose.fromJson(b),
      },
      ik: {
        for (final k in (json['ik'] as List? ?? const []))
          (k as Map<String, dynamic>)['chainId'] as String:
              Offset((k['dx'] as num).toDouble(), (k['dy'] as num).toDouble()),
      },
    );
  }

  @override
  List<Object?> get props => [id, name, bones, ik];
}
