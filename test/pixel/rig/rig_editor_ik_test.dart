import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:picell/data/models/layer.dart';
import 'package:picell/data/models/rig/rig.dart';
import 'package:picell/pixel/rig/rig_editor_controller.dart';

void main() {
  Layer layer(String key) => Layer(layerId: 0, id: 'id-$key', name: key, pixels: Uint32List(256), stableKey: key);

  // A leg: hip (pointing down) -> thigh -> shin, each 4 px, hanging from (8.5, 2.5).
  const hip = Bone(id: 'hip', name: 'hip', head: Offset(8.5, 2.5), length: 0.5 + 1.5, restAngle: 90);
  const thigh = Bone(id: 'thigh', name: 'thigh', parentId: 'hip', head: Offset(8.5, 4.5), length: 4, restAngle: 90);
  const shin = Bone(id: 'shin', name: 'shin', parentId: 'thigh', head: Offset(8.5, 8.5), length: 4, restAngle: 90);

  late int n;
  RigEditorController make({List<Bone> bones = const [hip, thigh, shin]}) {
    n = 0;
    return RigEditorController(
      rig: Rig(id: 'r', stateId: 1, bones: bones),
      restLayers: [layer('body')],
      width: 16,
      height: 16,
      newId: () => 'id${n++}',
    );
  }

  Offset foot(RigEditorController c) => c.displayBone('shin')!.tail;

  // Joints are drawn (and baked) on whole pixels, so a foot lands within
  // about a pixel of its target even though the solver itself is exact.
  const onThePixel = 0.75;

  group('chains', () {
    test('adding a chain defaults to two bones and selects it', () {
      final c = make();
      final id = c.addIkChain(tipBoneId: 'shin')!;
      final chain = c.ikChain(id)!;
      expect(chain.boneCount, 2);
      expect(chain.name, 'shin_ik');
      expect(c.selectedIkChain, chain);
      expect(c.rig.chainBones(chain).map((b) => b.id), ['thigh', 'shin']);
    });

    test('the length is limited to the bones above the tip, and a tip gets one chain', () {
      final c = make();
      final id = c.addIkChain(tipBoneId: 'shin', boneCount: 9)!;
      expect(c.ikChain(id)!.boneCount, 3);
      expect(c.addIkChain(tipBoneId: 'shin'), isNull, reason: 'a bone ends at most one chain');
      expect(c.addIkChain(tipBoneId: 'ghost'), isNull);
      c.setIkChain(id, boneCount: 0);
      expect(c.ikChain(id)!.boneCount, 1);
    });

    test('names stay unique', () {
      final c = make();
      final a = c.addIkChain(tipBoneId: 'shin', name: 'leg')!;
      final b = c.addIkChain(tipBoneId: 'thigh', name: 'leg')!;
      expect(c.ikChain(a)!.name, isNot(c.ikChain(b)!.name));
    });

    test('bend and length can be changed, each one undo step', () {
      final c = make();
      final id = c.addIkChain(tipBoneId: 'shin')!;
      c.setIkChain(id, bend: -1);
      expect(c.ikChain(id)!.bend, -1);
      c.undo();
      expect(c.ikChain(id)!.bend, 1);
    });

    test('removing a chain also removes its target keys but not the bones keys', () {
      final c = make()..mode = RigMode.animate;
      final id = c.addIkChain(tipBoneId: 'shin')!;
      c.setPose('thigh', rotation: 20);
      c.setIkTarget(id, const Offset(8.5, 10.5));
      c.removeIkChain(id);
      expect(c.rig.ikChains, isEmpty);
      expect(c.rig.clips.single.ikKeyframes, isEmpty);
      expect(c.keyAt('thigh', 0), isNotNull);
    });

    test('deleting the tip bone removes its chain; deleting a middle bone keeps it', () {
      final c = make()..mode = RigMode.animate;
      final id = c.addIkChain(tipBoneId: 'shin')!;
      c.setIkTarget(id, const Offset(8.5, 10.5));
      c.deleteBone('thigh');
      expect(c.rig.ikChains, hasLength(1));
      expect(c.rig.chainBones(c.rig.ikChains.single).map((b) => b.id), ['hip', 'shin'],
          reason: 'shin now hangs from hip');
      c.deleteBone('shin');
      expect(c.rig.ikChains, isEmpty);
      expect(c.rig.clips.single.ikKeyframes, isEmpty);
    });

    test('a bone knows the chains it belongs to, and whether one steers it', () {
      final c = make()..mode = RigMode.animate;
      final id = c.addIkChain(tipBoneId: 'shin')!;
      expect(c.ikChainsOf('thigh').map((x) => x.id), [id]);
      expect(c.ikChainsOf('hip'), isEmpty);
      expect(c.isIkDriven('thigh'), isFalse, reason: 'no target keys yet: the chain is off');
      c.setIkTarget(id, const Offset(10.5, 9));
      expect(c.isIkDriven('thigh'), isTrue);
      expect(c.isIkDriven('hip'), isFalse);
    });
  });

  group('targets', () {
    late RigEditorController c;
    late String id;
    setUp(() {
      c = make()..mode = RigMode.animate;
      id = c.addIkChain(tipBoneId: 'shin')!;
    });

    test('before any key the chain is off and the handle sits on the foot', () {
      expect(c.ikTarget(id), isNull);
      expect(c.ikHandle(c.ikChain(id)!), foot(c));
    });

    test('there is no handle in setup mode', () {
      c.mode = RigMode.setup;
      expect(c.ikHandle(c.ikChain(id)!), isNull);
    });

    test('setting a target keys it at the current frame, snapped, and the foot goes there', () {
      c.setIkTarget(id, const Offset(10.3, 8.8));
      expect(c.ikKeyAt(id, 0)!.target, const Offset(10.5, 9));
      expect((foot(c) - const Offset(10.5, 9)).distance, lessThan(onThePixel));
    });

    test('targets interpolate between frames and the foot follows', () {
      c.setClipLength(5);
      c.setIkTarget(id, const Offset(8.5, 10.5));
      c.setTime(4);
      c.setIkTarget(id, const Offset(12.5, 10.5));
      c.setTime(2);
      expect(c.ikTarget(id), const Offset(10.5, 10.5));
      expect((foot(c) - const Offset(10.5, 10.5)).distance, lessThan(onThePixel));
    });

    test('a drag of the target is one undo step and keeps the easing', () {
      c.setIkTarget(id, const Offset(8.5, 10.5));
      c.setIkKeyEasing(id, 0, RigEasing.stepped);
      c.beginGesture();
      for (var x = 9.5; x <= 12.5; x += 1) {
        c.setIkTarget(id, Offset(x, 10.5));
      }
      c.endGesture();
      expect(c.ikKeyAt(id, 0)!.target, const Offset(12.5, 10.5));
      expect(c.ikKeyAt(id, 0)!.easing, RigEasing.stepped);
      c.undo();
      expect(c.ikKeyAt(id, 0)!.target, const Offset(8.5, 10.5));
    });

    test('keyIkChain keys the foot where it is now, once', () {
      c.keyIkChain(id);
      expect(c.ikKeyAt(id, 0)!.target, foot(c).let(c.snapToPixel));
      c.setIkTarget(id, const Offset(11.5, 9.5));
      c.keyIkChain(id);
      expect(c.ikKeyAt(id, 0)!.target, const Offset(11.5, 9.5), reason: 'an existing key is not overwritten');
    });

    test('deleting the only key switches the chain off again', () {
      c.setIkTarget(id, const Offset(10.5, 9));
      c.deleteIkKey(id, 0);
      expect(c.ikTarget(id), isNull);
      expect(c.ikKeyTimes(id), isEmpty);
    });

    test('shrinking the clip drops target keys past the end', () {
      c.setClipLength(8);
      c.setTime(6);
      c.setIkTarget(id, const Offset(10.5, 9));
      c.setClipLength(4);
      expect(c.ikKeyTimes(id), isEmpty);
    });

    test('copy and paste carry the targets too', () {
      c.setClipLength(6);
      c.setIkTarget(id, const Offset(11.5, 9.5));
      c.copyPose();
      c.setTime(3);
      c.pastePose();
      expect(c.ikKeyAt(id, 3)!.target, const Offset(11.5, 9.5));
      c.undo();
      expect(c.ikKeyAt(id, 3), isNull);
    });

    test('the shown pose of a driven bone is the solved one, its keys are untouched', () {
      c.setPose('thigh', rotation: 0);
      c.setIkTarget(id, const Offset(11.5, 9.5));
      expect(c.keyAt('thigh', 0)!.rotation, 0);
      expect(c.shownPoseOf('thigh').rotation, isNot(0));
    });
  });

  group('grabbing the target', () {
    test('the handle is hit before bones, with the chain id, in animate mode only', () {
      final c = make()..mode = RigMode.animate;
      final id = c.addIkChain(tipBoneId: 'shin')!;
      c.setIkTarget(id, const Offset(8.5, 12.5));
      final hit = c.hitTest(const Offset(8.6, 12.4), 0.6);
      expect(hit, RigHit('shin', RigHitPart.ikTarget, chainId: id));

      // The same point on a bone that is also under the handle: the handle still wins.
      expect(c.hitTest(foot(c), 0.6)!.part, RigHitPart.ikTarget);

      c.mode = RigMode.setup;
      expect(c.hitTest(const Offset(8.6, 12.4), 0.6)?.part, isNot(RigHitPart.ikTarget));
    });

    test('selectIkChain picks the chain and its tip', () {
      final c = make();
      final id = c.addIkChain(tipBoneId: 'shin')!;
      c.selectBone('hip');
      expect(c.selectedIkChain, isNull);
      c.selectIkChain(id);
      expect(c.selectedBoneId, 'shin');
      expect(c.selectedIkChain!.id, id);
      c.selectBone('hip');
      expect(c.selectedIkChain, isNull, reason: 'picking a bone leaves the chain');
    });
  });
}

extension on Offset {
  Offset let(Offset Function(Offset) f) => f(this);
}
