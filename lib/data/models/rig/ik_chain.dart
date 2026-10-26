import 'package:equatable/equatable.dart';

/// An inverse-kinematics chain: instead of posing each bone, the animator
/// moves a target and the bones from [tipBoneId] up its parents bend to
/// reach it (a hand or a foot at the end of an arm or a leg).
///
/// The chain is the [boneCount] bones that end at the tip bone, so it needs
/// no list of its own and follows the bones if they are reparented. The
/// point that reaches for the target is the far end (tail) of the tip bone.
/// Targets are keyed in the clip (`IkKeyframe`); a chain without keys is not
/// solved and its bones are posed by their own keyframes.
class IkChain with EquatableMixin {
  final String id;
  final String name;
  final String tipBoneId;

  /// Optional named contact socket, otherwise the bone tail is used.
  final String? tipSocketId;

  /// How many bones, counting the tip, take part. At least 1.
  final int boneCount;

  /// Which way a bent chain folds: 1 or -1. It only decides between the two
  /// mirror-image solutions (knee forward or backward).
  final int bend;

  const IkChain({
    required this.id,
    required this.tipBoneId,
    this.tipSocketId,
    this.name = 'IK',
    this.boneCount = 2,
    this.bend = 1,
  });

  IkChain copyWith(
      {String? id, String? name, String? tipBoneId, int? boneCount, int? bend, String? Function()? tipSocketId}) {
    return IkChain(
      id: id ?? this.id,
      name: name ?? this.name,
      tipBoneId: tipBoneId ?? this.tipBoneId,
      tipSocketId: tipSocketId != null ? tipSocketId() : this.tipSocketId,
      boneCount: boneCount ?? this.boneCount,
      bend: bend ?? this.bend,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'tipBoneId': tipBoneId,
        if (tipSocketId != null) 'tipSocketId': tipSocketId,
        'boneCount': boneCount,
        'bend': bend,
      };

  factory IkChain.fromJson(Map<String, dynamic> json) {
    return IkChain(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'IK',
      tipBoneId: json['tipBoneId'] as String,
      tipSocketId: json['tipSocketId'] as String?,
      boneCount: (json['boneCount'] as int? ?? 2).clamp(1, 64),
      bend: (json['bend'] as int? ?? 1) < 0 ? -1 : 1,
    );
  }

  @override
  List<Object?> get props => [id, name, tipBoneId, tipSocketId, boneCount, bend];
}
