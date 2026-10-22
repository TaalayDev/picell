import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:picell/data/models/layer.dart';
import 'package:picell/data/models/rig/rig.dart';
import 'package:picell/pixel/rig/presets/bone_presets.dart';
import 'package:picell/pixel/rig/presets/motion_catalog.dart';
import 'package:picell/pixel/rig/rig_editor_controller.dart';

void main() {
  const w = 32, h = 32;

  /// A layer with a filled rectangle of art, so the art bounds are known.
  Layer art(String key, String name, {int x0 = 8, int y0 = 4, int x1 = 24, int y1 = 30}) {
    final px = Uint32List(w * h);
    for (var y = y0; y < y1; y++) {
      for (var x = x0; x < x1; x++) {
        px[y * w + x] = 0xFFFFFFFF;
      }
    }
    return Layer(layerId: 0, id: 'id-$key', name: name, pixels: px, stableKey: key);
  }

  Layer empty(String key, String name) =>
      Layer(layerId: 0, id: 'id-$key', name: name, pixels: Uint32List(w * h), stableKey: key);

  var n = 0;
  RigEditorController make({List<Layer>? layers, Rig? rig}) {
    n = 0;
    return RigEditorController(
      rig: rig ?? const Rig(id: 'r', stateId: 1),
      restLayers: layers ?? [art('body', 'Body')],
      width: w,
      height: h,
      newId: () => 'id${n++}',
    );
  }

  group('placing a skeleton', () {
    test('only in setup mode', () {
      final c = make()..mode = RigMode.animate;
      c.beginPlacement(BonePresets.humanoid);
      expect(c.placement, isNull);
    });

    test('a figure starts fitted to the artwork', () {
      final c = make();
      c.beginPlacement(BonePresets.humanoid);
      expect(c.placement!.box, const Rect.fromLTRB(8, 4, 24, 30));
      expect(c.placement!.attach, isFalse);
    });

    test('with no artwork it starts on the middle of the canvas', () {
      final c = make(layers: [empty('body', 'Body')]);
      c.beginPlacement(BonePresets.humanoid);
      final box = c.placement!.box;
      expect(box.center.dx, closeTo(16, 1));
      expect(box.width, greaterThan(20));
      expect(box.left, greaterThanOrEqualTo(0));
      expect(box.right, lessThanOrEqualTo(w));
    });

    test('hidden layers are not part of the artwork', () {
      final hidden = art('hat', 'Hat', x0: 0, y0: 0, x1: 4, y1: 4);
      final c = make(layers: [art('body', 'Body'), Layer(layerId: 0, id: 'x', name: 'Hat', pixels: hidden.pixels, stableKey: 'hat', isVisible: false)]);
      c.beginPlacement(BonePresets.humanoid);
      expect(c.placement!.box.left, 8);
    });

    test('an add-on starts small at the end of the selected bone, attached to it', () {
      final c = make();
      final spine = c.addBone(head: const Offset(15.5, 24.5), tail: const Offset(15.5, 10.5))!;
      c.beginPlacement(BonePresets.tail);
      final p = c.placement!;
      expect(p.attach, isTrue);
      expect(p.box.center.dx, closeTo(15.5, 1));
      expect(p.box.center.dy, closeTo(10.5, 1));
      expect(p.box.width, lessThan(14), reason: 'a part, not a figure');
      c.cancelPlacement();
      expect(c.bone(spine), isNotNull);
    });

    test('an add-on with nothing selected is not attached; a figure never is', () {
      final c = make();
      c.beginPlacement(BonePresets.tail);
      expect(c.placement!.attach, isFalse);
      c.addBone(head: const Offset(15.5, 24.5), tail: const Offset(15.5, 10.5));
      c.beginPlacement(BonePresets.humanoid);
      expect(c.placement!.attach, isFalse, reason: 'a whole figure does not hang from a bone by default');
    });

    test('the box never starts smaller than the minimum or off the canvas', () {
      final c = make(layers: [art('dot', 'Dot', x0: 30, y0: 30, x1: 32, y1: 32)]);
      c.beginPlacement(BonePresets.humanoid);
      final box = c.placement!.box;
      expect(box.width, greaterThanOrEqualTo(RigEditorController.minPlacementSize));
      expect(box.height, greaterThanOrEqualTo(RigEditorController.minPlacementSize));
      expect(box.right, lessThanOrEqualTo(w));
      expect(box.bottom, lessThanOrEqualTo(h));
    });
  });

  group('moving and stretching the box', () {
    late RigEditorController c;
    setUp(() {
      c = make();
      c.beginPlacement(BonePresets.humanoid); // 8,4 -> 24,30
    });

    test('moving shifts it by whole pixels', () {
      c.movePlacement(const Offset(2.4, -1.6));
      expect(c.placement!.box, const Rect.fromLTRB(10, 2, 26, 28));
    });

    test('each edge and corner pulls only what it names', () {
      c.dragPlacementHandle(PlacementHandle.right, const Offset(30.2, 99));
      expect(c.placement!.box, const Rect.fromLTRB(8, 4, 30, 30));
      c.dragPlacementHandle(PlacementHandle.top, const Offset(99, 1.4));
      expect(c.placement!.box, const Rect.fromLTRB(8, 1, 30, 30));
      c.dragPlacementHandle(PlacementHandle.bottomLeft, const Offset(4, 31));
      expect(c.placement!.box, const Rect.fromLTRB(4, 1, 30, 31));
      c.dragPlacementHandle(PlacementHandle.topLeft, const Offset(6, 3));
      expect(c.placement!.box, const Rect.fromLTRB(6, 3, 30, 31));
    });

    test('it stops at the minimum size and never turns inside out', () {
      c.dragPlacementHandle(PlacementHandle.right, const Offset(-50, 0));
      expect(c.placement!.box.width, RigEditorController.minPlacementSize);
      expect(c.placement!.box.left, 8);
      c.dragPlacementHandle(PlacementHandle.bottom, const Offset(0, -50));
      expect(c.placement!.box.height, RigEditorController.minPlacementSize);
      c.dragPlacementHandle(PlacementHandle.left, const Offset(100, 0));
      expect(c.placement!.box.width, RigEditorController.minPlacementSize);
    });

    test('moving is not a stretch handle', () {
      final before = c.placement!.box;
      c.dragPlacementHandle(PlacementHandle.move, const Offset(0, 0));
      expect(c.placement!.box, before);
    });

    test('handleAt finds corners, edges, the inside, and nothing outside', () {
      expect(c.placementHandleAt(const Offset(8.1, 4.1), 0.5), PlacementHandle.topLeft);
      expect(c.placementHandleAt(const Offset(23.9, 29.9), 0.5), PlacementHandle.bottomRight);
      expect(c.placementHandleAt(const Offset(8, 15), 0.5), PlacementHandle.left);
      expect(c.placementHandleAt(const Offset(24.2, 15), 0.5), PlacementHandle.right);
      expect(c.placementHandleAt(const Offset(15, 4.2), 0.5), PlacementHandle.top);
      expect(c.placementHandleAt(const Offset(15, 30), 0.5), PlacementHandle.bottom);
      expect(c.placementHandleAt(const Offset(16, 17), 0.5), PlacementHandle.move);
      expect(c.placementHandleAt(const Offset(2, 2), 0.5), isNull);
    });

    test('flip, IK and attach are switches; attach needs a selected bone', () {
      c.setPlacementFlip(true);
      c.setPlacementIk(true);
      expect(c.placement!.flip, isTrue);
      expect(c.placement!.withIk, isTrue);
      c.setPlacementAttach(true);
      expect(c.placement!.attach, isFalse, reason: 'nothing is selected');
      expect(c.canAttachPlacement, isFalse);
    });

    test('the preview matches what is then added', () {
      c.dragPlacementHandle(PlacementHandle.right, const Offset(28, 0));
      c.setPlacementFlip(true);
      final ghost = c.placementGhost;
      c.commitPlacement();
      expect(ghost.length, c.rig.bones.length);
      for (var i = 0; i < ghost.length; i++) {
        expect(c.rig.bones[i].head, ghost[i].head);
        expect((c.rig.bones[i].tail - ghost[i].tail).distance, lessThan(1e-6));
      }
    });

    test('cancelling, or leaving setup, drops the placement', () {
      c.cancelPlacement();
      expect(c.placement, isNull);
      c.beginPlacement(BonePresets.humanoid);
      c.mode = RigMode.animate;
      expect(c.placement, isNull);
    });
  });

  group('adding the skeleton', () {
    test('puts every bone on the rig as one undo step and selects the first', () {
      final c = make();
      c.beginPlacement(BonePresets.humanoid);
      final placed = c.commitPlacement()!;

      expect(c.rig.bones.length, BonePresets.humanoid.bones.length);
      expect(placed.boneIds, [for (final b in c.rig.bones) b.id]);
      expect(c.selectedBoneId, c.rig.bones.first.id);
      expect(c.placement, isNull);
      expect(c.rig.ikChains, isEmpty, reason: 'IK only when asked for');

      c.undo();
      expect(c.rig.bones, isEmpty);
    });

    test('with IK on it adds the chains', () {
      final c = make();
      c.beginPlacement(BonePresets.humanoid);
      c.setPlacementIk(true);
      c.commitPlacement();
      expect(c.rig.ikChains.length, 4);
      c.undo();
      expect(c.rig.ikChains, isEmpty);
    });

    test('an add-on hangs from the selected bone and keeps the existing bones', () {
      final c = make();
      final spine = c.addBone(head: const Offset(15.5, 24.5), tail: const Offset(15.5, 10.5))!;
      c.beginPlacement(BonePresets.tail);
      c.commitPlacement();
      final tailBones = c.rig.bones.where((b) => b.name.startsWith('tail')).toList();
      expect(tailBones.length, 4);
      expect(tailBones.first.parentId, spine);
      expect(c.rig.bones.length, 5);
      expect(c.bone(spine)!.parentId, isNull);
    });

    test('a second copy gets numbered names instead of clashing', () {
      final c = make();
      c.beginPlacement(BonePresets.humanoidSimple);
      c.commitPlacement();
      c.beginPlacement(BonePresets.humanoidSimple);
      c.commitPlacement();
      final names = c.rig.bones.map((b) => b.name).toList();
      expect(names.toSet().length, names.length);
      expect(names.where((n) => n.endsWith('_2')), isNotEmpty);
    });

    test('layers named like a new bone are bound to it, once', () {
      final c = make(layers: [
        empty('head', 'Head'),
        empty('arm', 'Left Arm'),
        empty('thigh', 'thigh_r'),
        empty('body', 'Torso art'),
        empty('headcopy', 'head'),
      ]);
      c.beginPlacement(BonePresets.humanoid);
      final placed = c.commitPlacement()!;

      expect(placed.boundLayers, 3);
      expect(c.boneOfLayer('head')!.name, 'head');
      expect(c.boneOfLayer('arm')!.name, 'arm_l');
      expect(c.boneOfLayer('thigh')!.name, 'thigh_r');
      expect(c.boneOfLayer('body'), isNull);
      expect(c.boneOfLayer('headcopy'), isNull, reason: 'one layer per bone: the head is taken');
      expect(c.partOfLayer('thigh')!.drawOrder, 2, reason: 'drawn at its place in the layer stack');
    });

    test('a layer that already has a bone is left alone', () {
      final c = make(layers: [empty('head', 'Head')]);
      final first = c.addBone(head: const Offset(1.5, 1.5), tail: const Offset(1.5, 5.5))!;
      c.assignLayer('head', first);
      c.beginPlacement(BonePresets.humanoid);
      expect(c.commitPlacement()!.boundLayers, 0);
      expect(c.boneOfLayer('head')!.id, first);
    });

    test('commit with no placement does nothing', () {
      expect(make().commitPlacement(), isNull);
    });
  });

  group('animation presets', () {
    late RigEditorController c;
    setUp(() {
      c = make(layers: [empty('body', 'Body')]);
      c.beginPlacement(BonePresets.humanoid);
      c.commitPlacement();
      c.mode = RigMode.animate;
    });

    Bone named(String name) => c.rig.bones.firstWhere((b) => b.name == name);

    test('are only applied while animating', () {
      c.mode = RigMode.setup;
      final r = c.applyMotion(MotionPresets.walk);
      expect(r.isEmpty, isTrue);
      expect(c.rig.clips, isEmpty);
    });

    test('a walk keys the bones it finds and sets the clip timing', () {
      final r = c.applyMotion(MotionPresets.walk);
      final clip = c.rig.clips.single;
      expect(r.matched.length, 11);
      expect(clip.length, 8);
      expect(clip.fps, 10);
      expect(clip.loop, isTrue);
      expect(c.keyTimes(named('thigh_l').id), {for (var i = 0; i < 8; i++) i});
      expect(c.keyTimes(named('hand_l').id), isEmpty, reason: 'a walk does not use the hands');
    });

    test('it replaces the keys of the bones it animates and keeps the others', () {
      c.setClipLength(8);
      c.setPose(named('thigh_l').id, rotation: 99);
      c.setPose(named('foot_l').id, rotation: 7);
      c.applyMotion(MotionPresets.walk);
      expect(c.keyAt(named('thigh_l').id, 0)!.rotation, isNot(99));
      expect(c.keyAt(named('foot_l').id, 0)!.rotation, 7, reason: 'foot is not in the walk');
    });

    test('a one-shot preset makes the clip play once; the shorter length drops later keys', () {
      c.setClipLength(40);
      c.setTime(30);
      c.setPose(named('foot_l').id, rotation: 7);
      c.applyMotion(MotionPresets.jump);
      expect(c.rig.clips.single.loop, isFalse);
      expect(c.rig.clips.single.length, 12);
      expect(c.keyAt(named('foot_l').id, 30), isNull, reason: 'frame 30 no longer exists');
      expect(c.time, lessThanOrEqualTo(11));
    });

    test('is one undo step', () {
      c.applyMotion(MotionPresets.walk);
      expect(c.rig.clips.single.keyframes, isNotEmpty);
      c.undo();
      expect(c.rig.clips, isEmpty, reason: 'back to a rig with no animation');
    });

    test('respects the rotation limits of a bone', () {
      c.setBoneLimits(named('thigh_l').id, min: -5, max: 5);
      c.applyMotion(MotionPresets.walk);
      for (final k in c.rig.clips.single.keyframes.where((k) => k.boneId == named('thigh_l').id)) {
        expect(k.rotation, inInclusiveRange(-5, 5));
      }
    });

    test('intensity and mirror reach the keys', () {
      c.applyMotion(MotionPresets.wave, mirror: true, intensity: 0.5);
      expect(c.keyAt(named('arm_l').id, 0)!.rotation, closeTo(75, 1e-9));
      expect(c.keyAt(named('arm_r').id, 0), isNull);
    });

    test('names it cannot find leave the clip alone', () {
      final bare = make()..mode = RigMode.animate;
      bare.addBone(head: const Offset(1.5, 1.5), tail: const Offset(1.5, 5.5));
      final r = bare.applyMotion(MotionPresets.walk);
      expect(r.isEmpty, isTrue);
      expect(r.missing, isNotEmpty);
      expect(bare.rig.clips, isEmpty);
      expect(bare.hasChanges, isTrue, reason: 'only the bone, not an animation');
    });

    test('an any-bone preset works on the selected bone and what hangs from it', () {
      final tail = make();
      tail.beginPlacement(BonePresets.tail);
      tail.commitPlacement();
      tail.mode = RigMode.animate;
      final first = tail.rig.bones.first;

      tail.selectBone(null);
      expect(tail.applyMotion(MotionPresets.followThrough).isEmpty, isTrue, reason: 'needs a selected bone');

      tail.selectBone(first.id);
      final r = tail.applyMotion(MotionPresets.followThrough);
      expect(r.keyframes.map((k) => k.boneId).toSet().length, 4);
      expect(tail.rig.clips.single.length, 12);
    });

    test('coverage reports what a preset would find', () {
      expect(c.motionCoverage(MotionPresets.walk), (matched: 11, total: 11));
      expect(c.motionCoverage(MotionPresets.quadrupedWalk).matched, lessThan(15));
      expect(c.motionCoverage(MotionPresets.sway).total, 0);
    });

    test('applying twice gives the same keys, not doubled ones', () {
      c.applyMotion(MotionPresets.walk);
      final first = c.rig.clips.single.keyframes.length;
      c.applyMotion(MotionPresets.walk);
      expect(c.rig.clips.single.keyframes.length, first);
    });

    test('baking and the editor agree: the walk is a real animation the baker accepts', () {
      c.applyMotion(MotionPresets.walk);
      expect(c.rig.clips.single.keyframes, isNotEmpty);
      expect(c.activeClip.keyframes.every((k) => k.time >= 0 && k.time < 8), isTrue);
    });
  });
}
