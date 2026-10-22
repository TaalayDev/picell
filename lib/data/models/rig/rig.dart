import 'dart:convert';

import 'package:equatable/equatable.dart';

import 'bone.dart';
import 'bone_pose.dart';
import 'ik_chain.dart';
import 'rig_clip.dart';
import 'rig_part.dart';
import 'rig_pose.dart';

export 'bone.dart';
export 'bone_pose.dart';
export 'ik_chain.dart';
export 'rig_clip.dart';
export 'rig_part.dart';
export 'rig_pose.dart';

class RigSettings with EquatableMixin {
  /// Rotation is rounded to a multiple of this many degrees; 0 disables
  /// snapping. Snapping keeps rotated pixel art consistent between frames.
  final double snapAngleDegrees;

  /// Matches `PixelUtils.applyRotation`'s interpolation argument.
  final int interpolation;

  const RigSettings({this.snapAngleDegrees = 0, this.interpolation = 0});

  RigSettings copyWith({double? snapAngleDegrees, int? interpolation}) => RigSettings(
        snapAngleDegrees: snapAngleDegrees ?? this.snapAngleDegrees,
        interpolation: interpolation ?? this.interpolation,
      );

  Map<String, dynamic> toJson() => {'snapAngleDegrees': snapAngleDegrees, 'interpolation': interpolation};

  factory RigSettings.fromJson(Map<String, dynamic> json) => RigSettings(
        snapAngleDegrees: (json['snapAngleDegrees'] as num?)?.toDouble() ?? 0,
        interpolation: json['interpolation'] as int? ?? 0,
      );

  @override
  List<Object?> get props => [snapAngleDegrees, interpolation];
}

/// A skeleton, its bound parts and animation clips, linked to one animation
/// state of the project. The state's frames are the baked output.
class Rig with EquatableMixin {
  final String id;

  /// Database id of the animation state holding the rest pose: the rig is
  /// drawn against that state's first frame, which baking never touches.
  final int stateId;

  /// Which frame of that state is the rest pose, as a position in the state.
  /// A position, not a frame id, so it survives the project being imported.
  final int restFrameIndex;

  /// The animation state the baked frames live in; null until the first bake.
  final int? outputStateId;
  final String name;
  final List<Bone> bones;
  final List<RigPart> parts;
  final List<RigClip> clips;
  final List<IkChain> ikChains;

  /// Saved poses, for reuse across frames and clips.
  final List<RigPose> poses;
  final RigSettings settings;

  const Rig({
    required this.id,
    required this.stateId,
    this.restFrameIndex = 0,
    this.outputStateId,
    this.name = 'Rig',
    this.bones = const [],
    this.parts = const [],
    this.clips = const [],
    this.ikChains = const [],
    this.poses = const [],
    this.settings = const RigSettings(),
  });

  Rig copyWith({
    String? id,
    int? stateId,
    int? restFrameIndex,
    int? Function()? outputStateId,
    String? name,
    List<Bone>? bones,
    List<RigPart>? parts,
    List<RigClip>? clips,
    List<IkChain>? ikChains,
    List<RigPose>? poses,
    RigSettings? settings,
  }) {
    return Rig(
      id: id ?? this.id,
      stateId: stateId ?? this.stateId,
      restFrameIndex: restFrameIndex ?? this.restFrameIndex,
      outputStateId: outputStateId != null ? outputStateId() : this.outputStateId,
      name: name ?? this.name,
      bones: bones ?? this.bones,
      parts: parts ?? this.parts,
      clips: clips ?? this.clips,
      ikChains: ikChains ?? this.ikChains,
      poses: poses ?? this.poses,
      settings: settings ?? this.settings,
    );
  }

  /// How many bones an IK chain ending at [tipBoneId] can have: the tip and
  /// all its ancestors.
  int maxChainLength(String tipBoneId) => _ancestry(tipBoneId, 1 << 20).length;

  /// The bones of [chain], root of the chain first, tip last. Shorter than
  /// `chain.boneCount` if the tip has fewer ancestors; empty if the tip bone
  /// is gone.
  List<Bone> chainBones(IkChain chain) => _ancestry(chain.tipBoneId, chain.boneCount).reversed.toList();

  /// [id] and its parents, tip first, at most [limit] bones.
  List<Bone> _ancestry(String id, int limit) {
    final byId = {for (final b in bones) b.id: b};
    final out = <Bone>[];
    final seen = <String>{};
    var current = byId[id];
    while (current != null && out.length < limit && seen.add(current.id)) {
      out.add(current);
      final parent = current.parentId;
      current = parent == null ? null : byId[parent];
    }
    return out;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'stateId': stateId,
        'restFrameIndex': restFrameIndex,
        if (outputStateId != null) 'outputStateId': outputStateId,
        'name': name,
        'bones': bones.map((b) => b.toJson()).toList(),
        'parts': parts.map((p) => p.toJson()).toList(),
        'clips': clips.map((c) => c.toJson()).toList(),
        if (ikChains.isNotEmpty) 'ikChains': ikChains.map((c) => c.toJson()).toList(),
        if (poses.isNotEmpty) 'poses': poses.map((p) => p.toJson()).toList(),
        'settings': settings.toJson(),
      };

  factory Rig.fromJson(Map<String, dynamic> json) {
    List<T> list<T>(String key, T Function(Map<String, dynamic>) parse) =>
        ((json[key] as List?) ?? const []).map((e) => parse(e as Map<String, dynamic>)).toList();

    return Rig(
      id: json['id'] as String,
      stateId: json['stateId'] as int,
      restFrameIndex: json['restFrameIndex'] as int? ?? 0,
      outputStateId: json['outputStateId'] as int?,
      name: json['name'] as String? ?? 'Rig',
      bones: list('bones', Bone.fromJson),
      parts: list('parts', RigPart.fromJson),
      clips: list('clips', RigClip.fromJson),
      ikChains: list('ikChains', IkChain.fromJson),
      poses: list('poses', RigPose.fromJson),
      settings: json['settings'] == null
          ? const RigSettings()
          : RigSettings.fromJson(json['settings'] as Map<String, dynamic>),
    );
  }

  @override
  List<Object?> get props => [id, stateId, restFrameIndex, outputStateId, name, bones, parts, clips, ikChains, poses, settings];
}

/// The rigs of a project as stored in `Project.rigData`: a versioned JSON
/// document, one [Rig] per animation state at most.
class RigDocument {
  static const int version = 1;

  const RigDocument._();

  static List<Rig> decode(String? data) {
    if (data == null || data.isEmpty) return const [];
    try {
      final json = jsonDecode(data) as Map<String, dynamic>;
      return ((json['rigs'] as List?) ?? const []).map((r) => Rig.fromJson(r as Map<String, dynamic>)).toList();
    } catch (_) {
      // A corrupt or newer-format rig must not stop the project from opening.
      return const [];
    }
  }

  static String? encode(List<Rig> rigs) {
    if (rigs.isEmpty) return null;
    return jsonEncode({'version': version, 'rigs': rigs.map((r) => r.toJson()).toList()});
  }

  /// Rewrites each rig's state ids through [stateIds] (old -> new). Needed
  /// when a project is inserted and its states get new database ids. Rigs
  /// whose rest-pose state is unmapped are dropped; an unmapped output state
  /// just means the rig has not been baked yet.
  static String? remapStateIds(String? data, Map<int, int> stateIds) {
    final rigs = [
      for (final rig in decode(data))
        if (stateIds.containsKey(rig.stateId))
          rig.copyWith(
            stateId: stateIds[rig.stateId],
            outputStateId: () => stateIds[rig.outputStateId],
          ),
    ];
    return encode(rigs);
  }
}
