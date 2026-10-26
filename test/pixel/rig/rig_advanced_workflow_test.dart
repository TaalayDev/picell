import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/data/models/layer.dart';
import 'package:picell/data/models/rig/rig.dart';
import 'package:picell/pixel/rig/rig_editor_controller.dart';
import 'package:picell/pixel/rig/rig_solver.dart';
import 'package:picell/pixel/rig/rig_baker.dart';
import 'package:picell/pixel/rig/presets/bone_presets.dart';
import 'package:picell/pixel/rig/presets/motion_catalog.dart';

void main() {
  const bones = [
    Bone(id: 'root', name: 'Root', head: Offset(2, 2), length: 2),
    Bone(id: 'arm', name: 'Arm', parentId: 'root', head: Offset(4, 2), length: 2),
    Bone(id: 'hand', name: 'Hand', parentId: 'arm', head: Offset(6, 2), length: 1),
    Bone(id: 'other', name: 'Other', head: Offset(2, 8), length: 2),
  ];
  RigEditorController make({Rig? rig, List<Layer> layers = const [], int height = 16}) {
    var id = 0;
    final c = RigEditorController(
        rig: rig ?? const Rig(id: 'r', stateId: 1, bones: bones),
        restLayers: layers,
        width: 16,
        height: height,
        newId: () => 'new-${id++}');
    addTearDown(c.dispose);
    return c;
  }

  test('named sockets and artwork pivots persist alongside legacy projects', () {
    final c = make();
    final id = c.addAttachment('arm', 'grip')!;
    c.updateAttachment(id, x: 1.5, y: .5, angle: 30);
    final saved = Rig.fromJson(c.rig.toJson());
    expect(saved, c.rig);
    expect(saved.attachments.single.offset, const Offset(1.5, .5));
    final legacy = Rig.fromJson({'id': 'old', 'stateId': 1});
    expect(legacy.attachments, isEmpty);
    expect(legacy.roleBindings, isEmpty);
    c.undo();
    expect(c.rig.attachments.single.offset, const Offset(2, 0));
  });
  test('socket world position follows its bone rotation and mirrors', () {
    final c = make();
    final id = c.addAttachment('root', 'grip')!;
    c.mode = RigMode.animate;
    c.setPose('root', rotation: 90);
    expect((c.attachmentPosition(c.rig.attachments.single) - const Offset(2, 4)).distance, lessThan(1e-8));
    c.setPose('root', rotation: 0, flipX: true);
    expect(c.attachmentPosition(c.rig.attachments.single), const Offset(0, 2));
    expect(c.rig.attachments.single.id, id);
    expect(RigSolver.chainTipPoint(c.rig, const IkChain(id: 'chain', tipBoneId: 'root')), bones.first.tail);
  });
  test('socket binding bakes artwork using its source pivot and cleans up safely', () {
    final pixels = Uint32List(16 * 16);
    pixels[2 * 16 + 2] = 0xffff0000;
    final layer = Layer(layerId: 0, id: 'art', name: 'Sword', stableKey: 'sword', pixels: pixels);
    final c = make(layers: [layer]);
    final id = c.addAttachment('root', 'grip')!;
    c.attachLayerToSocket('sword', id, artworkPivot: const Offset(2, 2));
    c.mode = RigMode.animate;
    c.setPose('root', rotation: 90);
    final baked = RigBaker(rig: c.rig, width: 16, height: 16, layers: [layer]).bakeFrame(c.activeClip, 0);
    expect(baked[4 * 16 + 1], 0xffff0000);
    expect(baked.where((p) => p != 0), hasLength(1));
    c.mode = RigMode.setup;
    final before = c.rig;
    c.deleteAttachment(id);
    expect(c.rig.parts.single.attachmentId, isNull);
    c.undo();
    expect(c.rig, before);
    c.deleteBone('root');
    expect(c.rig.attachments, isEmpty);
    expect(c.rig.parts, isEmpty);
  });
  test('IK plants a named socket instead of assuming the bone tail', () {
    const rig = Rig(id: 'contact', stateId: 1, bones: bones, attachments: [
      RigAttachment(id: 'contact', boneId: 'arm', name: 'foot_contact', offset: Offset(1, 0))
    ], ikChains: [
      IkChain(id: 'chain', tipBoneId: 'arm', tipSocketId: 'contact')
    ], clips: [
      RigClip(id: 'clip', name: 'Contact', ikKeyframes: [IkKeyframe(time: 0, chainId: 'chain', target: Offset(3, 4))])
    ]);
    final solved = RigSolver.solveClip(rig, rig.activeClip!, 0);
    final point = RigSolver.attachmentTransform(rig, rig.attachments.single, solved.world).apply(Offset.zero);
    expect((point - const Offset(3, 4)).distance, lessThan(1e-6));
    expect((solved.world['arm']!.apply(bones[1].tail) - point).distance, closeTo(1, 1e-6));
    final c = make(rig: rig);
    c.deleteAttachment('contact');
    expect(c.rig.ikChains.single.tipSocketId, isNull);
    c.undo();
    expect(c.rig, rig);
  });

  test('group setup transforms selected ancestors and descendants only once', () {
    final c = make();
    c.selectBone('root');
    c.toggleBoneSelection('arm');
    c.transformSelection(translation: const Offset(1, .5));
    expect(c.bone('root')!.head, const Offset(3, 2.5));
    expect(c.bone('arm')!.head, const Offset(5, 2.5));
    expect(c.bone('hand')!.head, const Offset(7, 2.5));
    expect(c.bone('other')!.head, bones.last.head);
    c.undo();
    expect(c.rig.bones, bones);
    c.transformSelection(rotation: 90, activePivot: true);
    expect(c.bone('arm')!.head, bones[1].head);
    c.undo();
    expect(c.rig.bones, bones);
  });
  test('group drags share one undo step and frozen descendants hold their world pose', () {
    final c = make()..mode = RigMode.animate;
    c.freezeJoint('hand');
    final before = c.rig;
    c.selectBone('root');
    c.toggleBoneSelection('arm');
    c.beginGesture();
    c.transformSelection(translation: const Offset(1, 0));
    c.transformSelection(translation: const Offset(1, 0));
    c.endGesture();
    expect(c.displayBone('root')!.head, const Offset(4, 2));
    expect(c.displayBone('arm')!.head, const Offset(6, 2));
    expect(c.displayBone('hand')!.head, bones[2].head);
    c.undo();
    expect(c.rig, before);
    c.redo();
    expect(c.displayBone('root')!.head, const Offset(4, 2));
  });
  test('box and descendant selection retain an active bone and ignore deleted bones', () {
    final c = make();
    c.selectBox(const Rect.fromLTWH(1, 1, 4, 2));
    expect(c.selectedBoneIds, {'root', 'arm'});
    c.selectDescendants();
    expect(c.selectedBoneIds, {'root', 'arm', 'hand'});
    c.deleteBone('arm');
    expect(c.selectedBoneIds.contains('arm'), isFalse);
  });
  test('isolated numeric edits leave connected parents and children in place', () {
    final c = make();
    c.setConnectedGeometry(false);
    c.setBoneGeometry('arm', x: 5, y: 3);
    expect(c.bone('arm')!.head, const Offset(5, 3));
    expect(c.bone('root'), bones.first);
    expect(c.bone('hand'), bones[2]);
    c.setBoneEndpoint('arm', const Offset(5, 5));
    expect(c.bone('arm')!.tail, const Offset(5, 5));
    c.undo();
    c.undo();
    expect(c.rig.bones, bones);
  });
  test('snapping can be bypassed without changing grid precision', () {
    final c = make();
    c.setSnapping(false);
    expect(c.attachPoint(const Offset(4, 2), 1).parentId, isNull);
    final id = c.addBone(head: const Offset(4, 2), tail: const Offset(4, 4));
    expect(c.bone(id)!.parentId, 'root');
    expect(c.bone(id)!.connection, BoneConnection.implicit);
    c.setSnapping(true);
    expect(c.attachPoint(const Offset(4, 2), 1, bypass: true).parentId, isNull);
    expect(c.attachPoint(const Offset(2, 2), .1).parentId, 'root');
  });
  test('ghost frames wrap only looping clips and never alter saved or baked data', () {
    final c = make()..mode = RigMode.animate;
    c.setPose('root', rotation: 20);
    final before = c.rig;
    c.updateGhosts(skeleton: true, artwork: true);
    expect(c.ghostFrames.toSet(), {1, 7});
    c.setLoop(false);
    c.setTime(0);
    expect(c.ghostFrames, [1]);
    c.setTime(4);
    c.updateGhosts(pin: true);
    c.setTime(2);
    expect(c.ghostFrames.toSet(), {1, 3, 4});
    c.setGhostPlayback(true);
    expect(c.ghostFrames, isEmpty);
    c.setGhostPlayback(false);
    expect(c.ghostFrames, hasLength(3));
    c.undo();
    expect(c.rig, before);
    expect(Rig.fromJson(c.rig.toJson()), before);
  });
  test('selected-track key edits preserve other tracks and move locks with keys', () {
    final c = make()..mode = RigMode.animate;
    c.setTime(1);
    c.setPose('root', rotation: 10);
    c.setPose('arm', rotation: 20);
    c.selectFrameRange(1, 1);
    c.freezeJoint('arm');
    c.selectBone('arm');
    c.setTimelineScope(selectedOnly: true);
    c.copyTimelineKeys();
    c.editTimelineKeys(delta: 2);
    expect(c.keyAt('arm', 1), isNull);
    expect(c.keyAt('arm', 3)!.rotation, 20);
    expect(c.jointFrozenAt('arm', 3), isTrue);
    expect(c.keyAt('root', 1), isNotNull);
    c.setTime(5);
    c.pasteTimelineKeys();
    expect(c.keyAt('arm', 5)!.rotation, 20);
    expect(c.jointFrozenAt('arm', 5), isTrue);
    c.selectFrameRange(5, 5);
    c.editTimelineKeys(delete: true);
    expect(c.keyAt('arm', 5), isNull);
    expect(c.jointFrozenAt('arm', 5), isFalse);
    expect(c.activeClip.length, 8);
  });
  test('ripple paste inserts frames on all tracks and remains one undo step', () {
    final c = make()..mode = RigMode.animate;
    c.setTime(1);
    c.setPose('root', rotation: 10);
    c.setTime(4);
    c.setPose('other', rotation: 40);
    c.selectFrameRange(1, 2);
    c.copyTimelineKeys();
    c.setTime(3);
    c.setTimelineScope(ripple: true);
    final before = c.rig;
    c.pasteTimelineKeys();
    expect(c.activeClip.length, 10);
    expect(c.keyAt('root', 3), isNotNull);
    expect(c.keyAt('other', 6), isNotNull);
    c.undo();
    expect(c.rig, before);
  });
  test('explicit preset roles ground a renamed character and survive saving', () {
    final c = make();
    c.beginPlacement(BonePresets.humanoid);
    c.commitPlacement();
    final roles = {for (final b in c.rig.bones) b.name: b.id};
    for (final b in c.rig.bones) {
      c.renameBone(b.id, 'custom-${b.id}');
    }
    c.mode = RigMode.animate;
    final foot = c.bone(roles['foot_l'])!;
    final otherFoot = c.bone(roles['foot_r'])!;
    final ground = foot.tail.dy > otherFoot.tail.dy ? foot.tail.dy : otherFoot.tail.dy;
    final preset = MotionPresets.frontIdle.copyWith(roleBindings: roles, groundY: () => ground + 1);
    final result = c.applyMotion(preset);
    expect(result.missing, isEmpty);
    expect(c.rig.roleBindings, roles);
    for (var f = 0; f < c.activeClip.length; f++) {
      c.setTime(f);
      expect(c.displayBone(foot.id)!.tail.dy, closeTo(foot.tail.dy + 1, 1e-8));
    }
    expect(Rig.fromJson(c.rig.toJson()), c.rig);
    c.mode = RigMode.setup;
    c.deleteBone(foot.id);
    expect(c.rig.roleBindings.values.contains(foot.id), isFalse);
  });
  test('keeping preset placement preserves a translated character origin', () {
    final c = make();
    c.beginPlacement(BonePresets.humanoid);
    c.commitPlacement();
    c.mode = RigMode.animate;
    final hips = c.rig.bones.firstWhere((b) => b.name == 'hips');
    final foot = c.rig.bones.firstWhere((b) => b.name == 'foot_l');
    c.setPose(hips.id, translation: const Offset(2, 1));
    c.applyMotion(MotionPresets.frontIdle.copyWith(keepPosition: true));
    for (var frame = 0; frame < c.activeClip.length; frame++) {
      c.setTime(frame);
      expect((c.displayBone(foot.id)!.tail - (foot.tail + const Offset(2, 1))).distance, lessThan(1e-8));
    }
  });
  test('group rotation preserves exact connected joints at non-grid angles', () {
    final c = make();
    c.selectBone('root');
    c.toggleBoneSelection('arm');
    c.transformSelection(rotation: 37);
    expect((c.bone('root')!.tail - c.bone('arm')!.head).distance, lessThan(1e-8));
    expect((c.bone('arm')!.tail - c.bone('hand')!.head).distance, lessThan(1e-8));
  });

  test('proportion-scaled motion depends on leg lengths rather than canvas padding', () {
    final c = make();
    c.beginPlacement(BonePresets.humanoid);
    c.commitPlacement();
    final a = make(rig: c.rig, height: 32)..mode = RigMode.animate;
    final b = make(rig: c.rig, height: 128)..mode = RigMode.animate;
    final p = MotionPresets.frontWalk.copyWith(proportionScale: true);
    a.applyMotion(p);
    b.applyMotion(p);
    expect(a.activeClip.keyframes, b.activeClip.keyframes);
  });
}
