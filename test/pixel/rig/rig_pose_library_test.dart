import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:picell/data/models/layer.dart';
import 'package:picell/data/models/rig/rig.dart';
import 'package:picell/pixel/rig/rig_editor_controller.dart';

void main() {
  Layer layer(String key) => Layer(layerId: 0, id: 'id-$key', name: key, pixels: Uint32List(256), stableKey: key);

  const upper = Bone(id: 'upper', name: 'upper', head: Offset(4.5, 8.5), length: 4);
  const lower = Bone(id: 'lower', name: 'lower', parentId: 'upper', head: Offset(8.5, 8.5), length: 4);

  late int n;
  late RigEditorController c;

  setUp(() {
    n = 0;
    c = RigEditorController(
      rig: const Rig(id: 'r', stateId: 1, bones: [upper, lower]),
      restLayers: [layer('body')],
      width: 16,
      height: 16,
      newId: () => 'id${n++}',
    )..mode = RigMode.animate;
    c.setClipLength(6);
  });

  void strike() {
    c.setPose('upper', rotation: 35, translation: const Offset(1, 0));
    c.setPose('lower', rotation: -50, flipX: true);
  }

  test('a saved pose remembers every bone on the frame, including bones at rest', () {
    strike();
    final id = c.savePose('Punch')!;
    final pose = c.savedPose(id)!;
    expect(pose.name, 'Punch');
    expect(pose.bones['upper'], const BonePose(rotation: 35, translation: Offset(1, 0)));
    expect(pose.bones['lower'], const BonePose(rotation: -50, flipX: true));
  });

  test('applying it on another frame keys every bone there, as one undo step', () {
    strike();
    final id = c.savePose('Punch')!;
    c.setTime(4);
    expect(c.keyAt('upper', 4), isNull);

    c.applyPose(id);

    expect(c.keyAt('upper', 4)!.rotation, 35);
    expect(c.keyAt('upper', 4)!.translation, const Offset(1, 0));
    expect(c.keyAt('lower', 4)!.rotation, -50);
    expect(c.keyAt('lower', 4)!.flipX, isTrue);
    expect(c.poseOf('upper').rotation, 35, reason: 'the frame now shows it');

    c.undo();
    expect(c.keyAt('upper', 4), isNull);
    expect(c.keyAt('lower', 4), isNull);
  });

  test('applying a pose replaces what was keyed on that frame, and keeps its easing', () {
    strike();
    final id = c.savePose('Punch')!;
    c.setTime(3);
    c.setPose('upper', rotation: 80);
    c.setKeyEasing('upper', 3, RigEasing.stepped);
    c.applyPose(id);
    expect(c.keyAt('upper', 3)!.rotation, 35);
    expect(c.keyAt('upper', 3)!.easing, RigEasing.stepped);
  });

  test('poses are respected within the bones rotation limits', () {
    const limited = Bone(id: 'lim', name: 'lim', head: Offset(2.5, 2.5), length: 3, minAngle: -10, maxAngle: 10);
    final lc = RigEditorController(
      rig: const Rig(id: 'r', stateId: 1, bones: [limited]),
      restLayers: [layer('body')],
      width: 16,
      height: 16,
      newId: () => 'x',
    )..mode = RigMode.animate;
    lc.savePose('Wide'); // rest
    final id = lc.savedPoses.single.id;
    // A pose saved before the limits were tightened still applies safely.
    lc.setBoneLimits('lim', min: 0, max: 5);
    lc.applyPose(id);
    expect(lc.keyAt('lim', 0)!.rotation, inInclusiveRange(0, 5));
  });

  test('IK targets are saved and re-applied with the pose', () {
    final chain = c.addIkChain(tipBoneId: 'lower')!;
    c.setIkTarget(chain, const Offset(9.5, 4.5));
    final id = c.savePose('Reach')!;
    expect(c.savedPose(id)!.ik[chain], const Offset(9.5, 4.5));

    c.setTime(5);
    c.applyPose(id);
    expect(c.ikKeyAt(chain, 5)!.target, const Offset(9.5, 4.5));
  });

  test('names: blank ones are numbered, taken ones get a number', () {
    final a = c.savePose('  ')!;
    final b = c.savePose('Idle')!;
    final d = c.savePose('Idle')!;
    expect([a, b, d].map((id) => c.savedPose(id)!.name), ['Pose 1', 'Idle', 'Idle 2']);
  });

  test('rename and delete', () {
    final id = c.savePose('Idle')!;
    c.renamePose(id, '  Stand ');
    expect(c.savedPose(id)!.name, 'Stand');
    c.renamePose(id, '   ');
    expect(c.savedPose(id)!.name, 'Stand');
    c.deletePose(id);
    expect(c.savedPoses, isEmpty);
    c.undo();
    expect(c.savedPoses, hasLength(1));
  });

  test('saving is an animate-mode action, and needs bones', () {
    c.mode = RigMode.setup;
    expect(c.savePose('x'), isNull);
    final empty = RigEditorController(
      rig: const Rig(id: 'r', stateId: 1),
      restLayers: [layer('body')],
      width: 16,
      height: 16,
    )..mode = RigMode.animate;
    expect(empty.savePose('x'), isNull);
    c.mode = RigMode.animate;
    final id = c.savePose('ok')!;
    c.mode = RigMode.setup;
    c.applyPose(id);
    expect(c.rig.clips.single.keyframes, isEmpty, reason: 'poses are applied while animating');
  });

  test('deleting a bone or a chain scrubs it from saved poses', () {
    strike();
    final chain = c.addIkChain(tipBoneId: 'lower')!;
    c.setIkTarget(chain, const Offset(9.5, 4.5));
    final id = c.savePose('Both')!;

    c.removeIkChain(chain);
    expect(c.savedPose(id)!.ik, isEmpty);

    c.deleteBone('lower');
    expect(c.savedPose(id)!.bones.keys, ['upper']);
    // And what is left still applies.
    c.setTime(2);
    c.applyPose(id);
    expect(c.keyAt('upper', 2)!.rotation, 35);
  });

  test('applying skips bones that are gone instead of failing', () {
    final id = c.savePose('x')!;
    final other = RigEditorController(
      rig: const Rig(id: 'r', stateId: 1, bones: [upper]),
      restLayers: [layer('body')],
      width: 16,
      height: 16,
    )..mode = RigMode.animate;
    other.applyPose(id); // not in this controller's library: ignored
    expect(other.rig.clips, isEmpty);
    c.deleteBone('lower');
    c.applyPose(id);
    expect(c.keyAt('lower', 0), isNull);
    expect(c.keyAt('upper', 0), isNotNull);
  });

  test('a pose survives the rig being saved and loaded', () {
    strike();
    c.savePose('Punch');
    final back = Rig.fromJson(c.rig.toJson());
    expect(back.poses, c.rig.poses);
  });
}
