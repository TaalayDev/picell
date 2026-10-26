import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/data/models/layer.dart';
import 'package:picell/data/models/rig/rig.dart';
import 'package:picell/pixel/rig/rig_bake.dart';
import 'package:picell/pixel/rig/rig_baker.dart';
import 'package:picell/pixel/rig/rig_editor_controller.dart';
import 'package:picell/pixel/rig/rig_gif.dart';
import 'package:picell/pixel/rig/rig_solver.dart';

void main() {
  const bones = [
    Bone(id: 'root', name: 'Root', head: Offset(2, 2), length: 2),
    Bone(id: 'arm', name: 'Arm', parentId: 'root', head: Offset(4, 2), length: 2),
    Bone(id: 'hand', name: 'Hand', parentId: 'arm', head: Offset(6, 2), length: 1),
  ];
  const clipA = RigClip(id: 'a', name: 'Idle', length: 6, loop: false, keyframes: [
    RigKeyframe(time: 0, boneId: 'root'),
    RigKeyframe(time: 5, boneId: 'root', rotation: 90),
  ]);
  const clipB = RigClip(id: 'b', name: 'Walk', length: 8, keyframes: [
    RigKeyframe(time: 0, boneId: 'root', translation: Offset(1, 0)),
  ]);
  RigEditorController make() {
    var n = 0;
    return RigEditorController(
        rig: const Rig(id: 'r', stateId: 1, bones: bones, clips: [clipA, clipB]),
        restLayers: [],
        width: 16,
        height: 16,
        newId: () => 'new${n++}')
      ..mode = RigMode.animate;
  }

  test('clip selection isolates edits and survives saving without reordering clips', () {
    final c = make();
    addTearDown(c.dispose);
    c.selectClip('b');
    c.setPose('arm', rotation: 25);
    expect(c.rig.clips.first, clipA);
    expect(c.activeClip.id, 'b');
    expect(c.rig.clips.last.keyframes.any((k) => k.boneId == 'arm'), isTrue);
    final saved = Rig.fromJson(c.rig.toJson());
    expect(saved, c.rig);
    expect(saved.activeClip!.id, 'b');
    c.selectClip('a');
    expect(c.keyAt('arm', 0), isNull);
    c.undo();
    expect(c.rig.clips, [clipA, clipB]);
    c.selectClip('b');
    expect(c.time, 0);
    expect(c.hasFrameSelection, isFalse);
  });

  test('create duplicate rename and delete clips preserve siblings and undo', () {
    final c = make();
    addTearDown(c.dispose);
    final before = c.rig;
    c.createClip('Jump');
    final created = c.activeClip;
    expect(created.name, 'Jump');
    expect(created.keyframes, isEmpty);
    expect(c.rig.clips.take(2), [clipA, clipB]);
    c.undo();
    expect(c.rig, before);
    c.redo();
    expect(c.activeClip.id, created.id);
    c.renameClip('Jump Up');
    expect(c.activeClip.name, 'Jump Up');
    c.duplicateClip();
    final copied = c.activeClip;
    expect(copied.name, 'Jump Up copy');
    expect(copied.id, isNot(created.id));
    c.deleteClip();
    expect(c.rig.clips.any((clip) => clip.id == copied.id), isFalse);
    c.undo();
    expect(c.activeClip.id, copied.id);
  });

  test('frozen world poses ignore parent rotation, translation and local pose edits', () {
    final c = make();
    addTearDown(c.dispose);
    c.freezeJoint('arm');
    final before = c.rig;
    c.setTime(5);
    expect(c.displayBone('arm')!.head, bones[1].head);
    expect(c.displayBone('arm')!.tail, bones[1].tail);
    expect(c.displayBone('hand')!.head, bones[2].head);
    expect(c.displayBone('hand')!.tail, bones[2].tail);
    expect((c.displayBone('root')!.tail - bones[0].tail).distance, greaterThan(1));
    c.setPose('arm', rotation: 50);
    expect(c.rig, before);
    c.setPose('root', translation: const Offset(3, 2));
    expect(c.displayBone('arm')!.head, bones[1].head);
    c.selectClip('b');
    expect(c.activeClip.freezes, isEmpty);
    expect(c.displayBone('arm')!.head, const Offset(5, 2));
    c.mode = RigMode.setup;
    expect(c.shownPoseOf('root'), BonePose.rest);
    expect(c.toLocalDelta('arm', const Offset(1, 0)), const Offset(1, 0));
  });

  test('partial clip freezes preserve the captured pose and release outside the range', () {
    final c = make();
    addTearDown(c.dispose);
    c.setTime(2);
    final captured = c.displayBone('arm')!;
    c.selectFrameRange(2, 3);
    final before = c.rig;
    c.freezeJoint('arm');
    expect(c.activeClip.freezes, hasLength(2));
    c.setTime(3);
    expect((c.displayBone('arm')!.head - captured.head).distance, lessThan(1e-9));
    expect((c.displayBone('arm')!.tail - captured.tail).distance, lessThan(1e-9));
    c.setTime(5);
    expect((c.displayBone('arm')!.head - captured.head).distance, greaterThan(.1));
    final saved = Rig.fromJson(c.rig.toJson());
    expect(saved, c.rig);
    c.undo();
    expect(c.rig, before);
    c.redo();
    expect(c.activeClip.freezes, hasLength(2));
    c.unfreezeJoint('arm');
    expect(c.activeClip.freezes, isEmpty);
  });

  test('freeze markers move duplicate delete and trim with timeline frames', () {
    final c = make();
    addTearDown(c.dispose);
    c.selectFrameRange(2, 3);
    c.freezeJoint('arm');
    c.moveFrameRange(1);
    expect(c.activeClip.freezes.map((f) => f.time).toSet(), {3, 4});
    c.duplicateFrameRange();
    expect(c.activeClip.freezes.map((f) => f.time).toSet(), {3, 4, 5, 6});
    c.deleteFrameRange();
    expect(c.activeClip.freezes.map((f) => f.time).toSet(), {3, 4});
    c.setClipLength(4);
    expect(c.activeClip.freezes.map((f) => f.time).toSet(), {3});
    c.clearAnimations();
    expect(c.activeClip.freezes, isEmpty);
  });

  test('duplicated clips have independent freeze collections and deleting bones clears holds', () {
    final c = make();
    addTearDown(c.dispose);
    c.freezeJoint('arm');
    final source = c.activeClip;
    c.duplicateClip();
    c.unfreezeJoint('arm');
    expect(c.activeClip.freezes, isEmpty);
    c.selectClip(source.id);
    expect(c.activeClip.freezes, isNotEmpty);
    c.deleteBone('arm');
    expect(c.rig.clips.every((clip) => clip.freezes.isEmpty), isTrue);
  });

  test('frozen joints override IK targets while other bones remain animated', () {
    final c = RigEditorController(
      rig: const Rig(id: 'ik-rig', stateId: 1, bones: bones, ikChains: [
        IkChain(id: 'chain', name: 'Arm', tipBoneId: 'arm')
      ], clips: [
        RigClip(id: 'ik', name: 'Reach', length: 6, loop: false, ikKeyframes: [
          IkKeyframe(time: 0, chainId: 'chain', target: Offset(6, 2)),
          IkKeyframe(time: 5, chainId: 'chain', target: Offset(2, 6)),
        ])
      ]),
      restLayers: [],
      width: 16,
      height: 16,
    )..mode = RigMode.animate;
    addTearDown(c.dispose);
    final held = c.displayBone('arm')!;
    c.freezeJoint('arm');
    c.setTime(5);
    expect((c.displayBone('arm')!.head - held.head).distance, lessThan(1e-9));
    expect((c.displayBone('arm')!.tail - held.tail).distance, lessThan(1e-9));
    expect((c.displayBone('root')!.tail - bones.first.tail).distance, greaterThan(1));
  });

  test('preview and baking evaluate the same frozen transform', () {
    final c = make();
    addTearDown(c.dispose);
    c.freezeJoint('arm');
    final pixels = Uint32List(16 * 16);
    pixels[2 * 16 + 4] = 0xffff0000;
    final layer = Layer(layerId: 0, id: 'art', name: 'Art', stableKey: 'arm', pixels: pixels);
    final rig = c.rig.copyWith(parts: const [RigPart(id: 'part', layerKey: 'arm', boneId: 'arm')]);
    final baker = RigBaker(rig: rig, width: 16, height: 16, layers: [layer]);
    expect(baker.bakeFrame(rig.activeClip!, 5), orderedEquals(pixels));
    final solved = RigSolver.solveClip(rig, rig.activeClip!, 5).world['arm']!;
    expect(solved.apply(bones[1].head), c.displayBone('arm')!.head);
    expect(solved.apply(bones[1].tail), c.displayBone('arm')!.tail);
  });

  test('bake and GIF validation use the selected clip instead of always the first', () async {
    final c = make();
    addTearDown(c.dispose);
    expect(RigBakeService.canBake(c.rig), isTrue);
    c.createClip('Empty');
    expect(RigBakeService.canBake(c.rig), isFalse);
    await expectLater(RigGif.render(rig: c.rig, restLayers: [], width: 16, height: 16), throwsStateError);
    c.freezeJoint('arm');
    expect(RigBakeService.canBake(c.rig), isTrue);
    c.deleteClip();
    c.deleteClip();
    c.deleteClip();
    expect(c.rig.clips, isEmpty);
    expect(c.activeClip.freezes, isEmpty);
  });
}
