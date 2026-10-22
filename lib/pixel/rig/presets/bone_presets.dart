import 'dart:math' as math;
import 'dart:ui';

import '../../../data/models/rig/rig.dart';

/// One bone of a [BonePreset], in a unit box: x and y run 0..1, y down, so a
/// preset can be stretched to any size and shape.
class PresetBone {
  final String name;

  /// Name of the parent bone in the same preset; null for a root.
  final String? parent;
  final Offset head;
  final Offset tail;

  const PresetBone(this.name, this.parent, this.head, this.tail);
}

/// An IK chain a preset can add: the bones that end at [tip].
class PresetIk {
  final String name;
  final String tip;
  final int boneCount;
  final int bend;

  const PresetIk(this.name, this.tip, {this.boneCount = 2, this.bend = 1});
}

/// A ready-made skeleton, laid out in the unit box. Bones are listed parents
/// first. Names are the ones animation presets look for.
class BonePreset {
  final String id;
  final String name;
  final String description;
  final List<PresetBone> bones;
  final List<PresetIk> ik;

  /// A part to add to a skeleton (a tail, a limb), not a whole figure: it
  /// attaches to the selected bone and starts small.
  final bool addOn;

  const BonePreset({
    required this.id,
    required this.name,
    required this.description,
    required this.bones,
    this.ik = const [],
    this.addOn = false,
  });

  /// The width to height of the shape the preset is drawn in, as a hint for
  /// a first placement.
  double get aspect {
    var minX = 1.0, maxX = 0.0, minY = 1.0, maxY = 0.0;
    for (final b in bones) {
      for (final p in [b.head, b.tail]) {
        minX = math.min(minX, p.dx);
        maxX = math.max(maxX, p.dx);
        minY = math.min(minY, p.dy);
        maxY = math.max(maxY, p.dy);
      }
    }
    return (maxX - minX) / math.max(0.0001, maxY - minY);
  }
}

Offset _mirror(Offset p) => Offset(1 - p.dx, p.dy);

/// The same bones on the other side of the body (`_l` becomes `_r`).
List<PresetBone> _mirrored(List<PresetBone> side) => [
      for (final b in side)
        PresetBone(
          _flipSide(b.name),
          b.parent == null ? null : _flipSide(b.parent!),
          _mirror(b.head),
          _mirror(b.tail),
        ),
    ];

String _flipSide(String name) => name.endsWith('_l') ? '${name.substring(0, name.length - 2)}_r' : name;

/// A chain of bones, each starting where the last ends, through [points].
List<PresetBone> _chain(String prefix, List<Offset> points, {String? parent, bool numbered = true}) {
  return [
    for (var i = 0; i < points.length - 1; i++)
      PresetBone(
        numbered ? '${prefix}_${i + 1}' : prefix,
        i == 0 ? parent : '${prefix}_$i',
        points[i],
        points[i + 1],
      ),
  ];
}

/// The skeletons that come with the editor.
abstract final class BonePresets {
  static final humanoid = BonePreset(
    id: 'humanoid',
    name: 'Humanoid',
    description: 'Hips, spine, neck, head, arms and legs with hands and feet. Seen from the front.',
    bones: [
      const PresetBone('hips', null, Offset(0.50, 0.58), Offset(0.50, 0.50)),
      const PresetBone('spine', 'hips', Offset(0.50, 0.50), Offset(0.50, 0.36)),
      const PresetBone('neck', 'spine', Offset(0.50, 0.36), Offset(0.50, 0.28)),
      const PresetBone('head', 'neck', Offset(0.50, 0.28), Offset(0.50, 0.06)),
      ..._side([
        const PresetBone('arm_l', 'spine', Offset(0.40, 0.36), Offset(0.30, 0.50)),
        const PresetBone('forearm_l', 'arm_l', Offset(0.30, 0.50), Offset(0.24, 0.63)),
        const PresetBone('hand_l', 'forearm_l', Offset(0.24, 0.63), Offset(0.21, 0.70)),
        const PresetBone('thigh_l', 'hips', Offset(0.45, 0.58), Offset(0.43, 0.78)),
        const PresetBone('shin_l', 'thigh_l', Offset(0.43, 0.78), Offset(0.42, 0.94)),
        const PresetBone('foot_l', 'shin_l', Offset(0.42, 0.94), Offset(0.34, 0.98)),
      ]),
    ],
    ik: const [
      PresetIk('arm_l_ik', 'forearm_l'),
      PresetIk('arm_r_ik', 'forearm_r'),
      PresetIk('leg_l_ik', 'shin_l'),
      PresetIk('leg_r_ik', 'shin_r'),
    ],
  );

  static final humanoidSimple = BonePreset(
    id: 'humanoid_simple',
    name: 'Humanoid (simple)',
    description: 'A lighter figure: hips, spine, head and two bones per limb.',
    bones: [
      const PresetBone('hips', null, Offset(0.50, 0.55), Offset(0.50, 0.45)),
      const PresetBone('spine', 'hips', Offset(0.50, 0.45), Offset(0.50, 0.25)),
      const PresetBone('head', 'spine', Offset(0.50, 0.25), Offset(0.50, 0.05)),
      ..._side([
        const PresetBone('arm_l', 'spine', Offset(0.42, 0.28), Offset(0.28, 0.45)),
        const PresetBone('forearm_l', 'arm_l', Offset(0.28, 0.45), Offset(0.20, 0.62)),
        const PresetBone('thigh_l', 'hips', Offset(0.46, 0.55), Offset(0.42, 0.77)),
        const PresetBone('shin_l', 'thigh_l', Offset(0.42, 0.77), Offset(0.40, 0.97)),
      ]),
    ],
    ik: const [
      PresetIk('arm_l_ik', 'forearm_l'),
      PresetIk('arm_r_ik', 'forearm_r'),
      PresetIk('leg_l_ik', 'shin_l'),
      PresetIk('leg_r_ik', 'shin_r'),
    ],
  );

  static final quadruped = BonePreset(
    id: 'quadruped',
    name: 'Quadruped',
    description: 'A four-legged animal seen from the side, facing left, with a three-bone tail.',
    bones: [
      const PresetBone('hips', null, Offset(0.70, 0.42), Offset(0.52, 0.40)),
      const PresetBone('spine', 'hips', Offset(0.52, 0.40), Offset(0.34, 0.38)),
      const PresetBone('neck', 'spine', Offset(0.34, 0.38), Offset(0.24, 0.26)),
      const PresetBone('head', 'neck', Offset(0.24, 0.26), Offset(0.08, 0.32)),
      ..._chain('tail', const [Offset(0.70, 0.42), Offset(0.82, 0.34), Offset(0.91, 0.27), Offset(0.97, 0.20)],
          parent: 'hips'),
      const PresetBone('fl_upper', 'spine', Offset(0.36, 0.44), Offset(0.35, 0.68)),
      const PresetBone('fl_lower', 'fl_upper', Offset(0.35, 0.68), Offset(0.34, 0.95)),
      const PresetBone('fr_upper', 'spine', Offset(0.30, 0.44), Offset(0.29, 0.68)),
      const PresetBone('fr_lower', 'fr_upper', Offset(0.29, 0.68), Offset(0.28, 0.95)),
      const PresetBone('bl_upper', 'hips', Offset(0.66, 0.46), Offset(0.70, 0.68)),
      const PresetBone('bl_lower', 'bl_upper', Offset(0.70, 0.68), Offset(0.68, 0.95)),
      const PresetBone('br_upper', 'hips', Offset(0.60, 0.46), Offset(0.64, 0.68)),
      const PresetBone('br_lower', 'br_upper', Offset(0.64, 0.68), Offset(0.62, 0.95)),
    ],
    ik: const [
      PresetIk('fl_ik', 'fl_lower'),
      PresetIk('fr_ik', 'fr_lower'),
      PresetIk('bl_ik', 'bl_lower'),
      PresetIk('br_ik', 'br_lower'),
    ],
  );

  static const bird = BonePreset(
    id: 'bird',
    name: 'Bird',
    description: 'A bird seen from the side, facing left: body, neck, head, tail, a two-bone wing and a leg.',
    bones: [
      PresetBone('hips', null, Offset(0.56, 0.52), Offset(0.42, 0.46)),
      PresetBone('neck', 'hips', Offset(0.42, 0.46), Offset(0.30, 0.30)),
      PresetBone('head', 'neck', Offset(0.30, 0.30), Offset(0.14, 0.28)),
      PresetBone('tail', 'hips', Offset(0.56, 0.52), Offset(0.92, 0.64)),
      PresetBone('wing_1', 'hips', Offset(0.48, 0.44), Offset(0.62, 0.24)),
      PresetBone('wing_2', 'wing_1', Offset(0.62, 0.24), Offset(0.80, 0.10)),
      PresetBone('leg_upper', 'hips', Offset(0.52, 0.54), Offset(0.52, 0.72)),
      PresetBone('leg_lower', 'leg_upper', Offset(0.52, 0.72), Offset(0.54, 0.90)),
    ],
    ik: [PresetIk('leg_ik', 'leg_lower')],
  );

  static final fish = BonePreset(
    id: 'fish',
    name: 'Fish',
    description: 'A body made of five bones in a row, for swimming with a wave down the spine. Faces left.',
    bones: _chain(
      'fish',
      const [Offset(0.02, 0.5), Offset(0.24, 0.5), Offset(0.46, 0.5), Offset(0.68, 0.5), Offset(0.84, 0.5), Offset(0.98, 0.5)],
    ),
  );

  static final tail = BonePreset(
    id: 'tail',
    name: 'Tail',
    description: 'Four bones in a row. Add it to a selected bone to give a character a tail, or use it for a rope or hair.',
    bones: _chain(
      'tail',
      const [Offset(0.0, 0.5), Offset(0.25, 0.5), Offset(0.5, 0.5), Offset(0.75, 0.5), Offset(1.0, 0.5)],
    ),
    addOn: true,
  );

  static final tentacle = BonePreset(
    id: 'tentacle',
    name: 'Tentacle',
    description: 'Six bones hanging down: tentacles, vines, a banner or a scarf.',
    bones: _chain(
      'tentacle',
      [for (var i = 0; i <= 6; i++) Offset(0.5, i / 6)],
    ),
    addOn: true,
  );

  static const arm = BonePreset(
    id: 'arm',
    name: 'Arm',
    description: 'Arm, forearm and hand hanging down. Add it to a selected bone to build a limb.',
    bones: [
      PresetBone('arm', null, Offset(0.5, 0.0), Offset(0.5, 0.36)),
      PresetBone('forearm', 'arm', Offset(0.5, 0.36), Offset(0.5, 0.72)),
      PresetBone('hand', 'forearm', Offset(0.5, 0.72), Offset(0.5, 1.0)),
    ],
    ik: [PresetIk('arm_ik', 'forearm')],
    addOn: true,
  );

  static const leg = BonePreset(
    id: 'leg',
    name: 'Leg',
    description: 'Thigh, shin and foot. Add it to a selected bone to build a limb.',
    bones: [
      PresetBone('thigh', null, Offset(0.5, 0.0), Offset(0.5, 0.45)),
      PresetBone('shin', 'thigh', Offset(0.5, 0.45), Offset(0.5, 0.88)),
      PresetBone('foot', 'shin', Offset(0.5, 0.88), Offset(0.9, 1.0)),
    ],
    ik: [PresetIk('leg_ik', 'shin')],
    addOn: true,
  );

  /// Everything on offer, characters first.
  static final all = <BonePreset>[humanoid, humanoidSimple, quadruped, bird, fish, tail, tentacle, arm, leg];

  static BonePreset? byId(String id) {
    for (final p in all) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// [left] plus its mirror image.
  static List<PresetBone> _side(List<PresetBone> left) => [...left, ..._mirrored(left)];
}

/// What [BonePresetBuilder.build] produces: real bones and chains, ready to
/// add to a rig.
class BuiltPreset {
  const BuiltPreset({required this.bones, required this.chains, required this.idsByName});

  final List<Bone> bones;
  final List<IkChain> chains;

  /// The id given to each preset bone, by its name in the preset.
  final Map<String, String> idsByName;
}

/// Fits a [BonePreset] into a box on the canvas.
abstract final class BonePresetBuilder {
  /// Places [preset] in [box] (canvas pixels), stretched to fill it, mirrored
  /// left to right when [flip] is set. Joints are put on pixel centres with
  /// [snap], so bones that meet in the preset meet on the canvas too.
  ///
  /// Roots hang from [attachTo] when it is given. Names that clash with
  /// [takenNames] get a `_2` (or `_3`...) after them, all together, so the
  /// bones of one preset keep matching each other. Chains are made only when
  /// [withIk] is set.
  static BuiltPreset build(
    BonePreset preset, {
    required Rect box,
    required Offset Function(Offset) snap,
    required String Function() newId,
    bool flip = false,
    bool withIk = false,
    String? attachTo,
    Set<String> takenNames = const {},
  }) {
    final suffix = _suffixFor(preset, takenNames);
    final ids = <String, String>{};
    final bones = <Bone>[];

    Offset place(Offset unit) {
      final u = flip ? Offset(1 - unit.dx, unit.dy) : unit;
      return snap(Offset(box.left + u.dx * box.width, box.top + u.dy * box.height));
    }

    for (final pb in preset.bones) {
      final head = place(pb.head);
      var tail = place(pb.tail);
      var delta = tail - head;
      if (delta.distance < 1) {
        // A bone squeezed to under a pixel keeps one pixel of length, along
        // the way it points.
        final raw = flip ? Offset(pb.head.dx - pb.tail.dx, pb.tail.dy - pb.head.dy) : pb.tail - pb.head;
        delta = raw.dx.abs() >= raw.dy.abs()
            ? Offset(raw.dx < 0 ? -1 : 1, 0)
            : Offset(0, raw.dy < 0 ? -1 : 1);
        tail = head + delta;
      }

      final id = newId();
      ids[pb.name] = id;
      bones.add(Bone(
        id: id,
        name: '${pb.name}$suffix',
        parentId: pb.parent == null ? attachTo : ids[pb.parent!],
        head: head,
        length: delta.distance,
        restAngle: math.atan2(delta.dy, delta.dx) * 180 / math.pi,
      ));
    }

    final chains = <IkChain>[
      if (withIk)
        for (final ik in preset.ik)
          if (ids[ik.tip] != null)
            IkChain(
              id: newId(),
              name: '${ik.name}$suffix',
              tipBoneId: ids[ik.tip]!,
              boneCount: ik.boneCount,
              bend: flip ? -ik.bend : ik.bend,
            ),
    ];
    return BuiltPreset(bones: bones, chains: chains, idsByName: ids);
  }

  static String _suffixFor(BonePreset preset, Set<String> taken) {
    bool clashes(String suffix) => preset.bones.any((b) => taken.contains('${b.name}$suffix'));
    if (!clashes('')) return '';
    for (var n = 2;; n++) {
      if (!clashes('_$n')) return '_$n';
    }
  }
}
