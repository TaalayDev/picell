import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:picell/data/models/layer.dart';
import 'package:picell/data/models/rig/rig.dart';
import 'package:picell/pixel/rig/rig_editor_controller.dart';

void main() {
  Layer layer(String key) => Layer(layerId: 0, id: 'id-$key', name: key, pixels: Uint32List(64), stableKey: key);

  late int n;
  late RigEditorController c;

  RigEditorController make({Rig? rig}) {
    n = 0;
    return RigEditorController(
      rig: rig ?? const Rig(id: 'r', stateId: 1),
      restLayers: [layer('body'), layer('arm'), layer('head')],
      width: 8,
      height: 8,
      newId: () => 'id${n++}',
    );
  }

  setUp(() => c = make());

  String addRoot() => c.addBone(head: const Offset(2.2, 6.7), tail: const Offset(2.4, 2.1))!;

  test('clearing removes keys and all clips in one undo step while keeping the rig', () {
    final id = addRoot();
    c.mode = RigMode.animate;
    c.setClipLength(12);
    c.setTime(5);
    c.setPose(id, rotation: 30);
    final before = c.rig;
    expect(c.canClearAnimations, isTrue);
    c.clearAnimations();
    expect(c.rig.clips, hasLength(1));
    expect(c.activeClip.length, 1);
    expect(c.activeClip.keyframes, isEmpty);
    expect(c.activeClip.ikKeyframes, isEmpty);
    expect(c.time, 0);
    expect(c.rig.bones, before.bones);
    expect(c.rig.parts, before.parts);
    expect(c.canClearAnimations, isFalse);
    c.undo();
    expect(c.rig, before);
    c.redo();
    expect(c.activeClip.length, 1);
    expect(c.canClearAnimations, isFalse);
  });

  test('clearing also removes secondary clips and IK target animation', () {
    final populated = RigEditorController(
      rig: const Rig(id: 'multi', stateId: 1, clips: [
        RigClip(id: 'walk', name: 'Walk', length: 12, keyframes: [RigKeyframe(time: 4, boneId: 'bone', rotation: 20)]),
        RigClip(
            id: 'run',
            name: 'Run',
            length: 16,
            ikKeyframes: [IkKeyframe(time: 3, chainId: 'arm', target: Offset(4, 5))]),
      ]),
      restLayers: [],
      width: 8,
      height: 8,
    );
    final before = populated.rig;
    populated.clearAnimations();
    expect(populated.rig.clips, hasLength(1));
    expect(populated.activeClip.length, 1);
    expect(populated.activeClip.keyframes, isEmpty);
    expect(populated.activeClip.ikKeyframes, isEmpty);
    populated.undo();
    expect(populated.rig, before);
    populated.dispose();
  });

  group('creating bones', () {
    test('snaps to half pixels, including centres and pixel boundaries', () {
      final id = c.addBone(head: const Offset(1.2, 1.9), tail: const Offset(5.7, 1.1))!;
      final b = c.bone(id)!;
      expect(b.head, const Offset(1, 2));
      expect(b.tail, const Offset(5.5, 1));
      expect(c.selectedBoneId, id);
      expect(c.snapToPixel(const Offset(2.49, 3.01)), const Offset(2.5, 3));
    });

    test('angle follows screen axes: down is 90 degrees', () {
      final id = c.addBone(head: const Offset(1.5, 1.5), tail: const Offset(1.5, 5.5))!;
      expect(c.bone(id)!.restAngle, 90);
    });

    test('a bone shorter than half a pixel is rejected', () {
      expect(c.addBone(head: const Offset(1.1, 1.1), tail: const Offset(1.2, 1.2)), isNull);
      expect(c.rig.bones, isEmpty);
      expect(c.canUndo, isFalse);
    });

    test('points outside the canvas are clamped onto it', () {
      final id = c.addBone(head: const Offset(-5, -5), tail: const Offset(50, 50))!;
      expect(c.bone(id)!.head, Offset.zero);
      expect(c.bone(id)!.tail.dx, closeTo(8, 1e-9));
    });

    test('names are unique and an unknown parent becomes a root', () {
      final a = c.addBone(head: const Offset(1, 1), tail: const Offset(1, 5), parentId: 'ghost')!;
      final b = c.addBone(head: const Offset(3, 1), tail: const Offset(3, 5))!;
      expect(c.bone(a)!.parentId, isNull);
      expect(c.bone(a)!.name, isNot(c.bone(b)!.name));
    });
  });

  group('editing bones', () {
    test('moveBone carries descendants in half-pixel steps', () {
      final root = addRoot();
      final child = c.addBone(head: const Offset(2.5, 2.5), tail: const Offset(5.5, 2.5), parentId: root)!;
      final before = c.bone(child)!.head;

      c.moveBone(root, const Offset(1.4, 0.6));

      expect(c.bone(root)!.head, const Offset(3.5, 7));
      expect(c.bone(child)!.head, before + const Offset(1.5, .5));
    });

    test('setBoneTail keeps the head and recomputes length and angle', () {
      final id = c.addBone(head: const Offset(1.5, 1.5), tail: const Offset(5.5, 1.5))!;
      c.setBoneTail(id, const Offset(1.5, 6.2));
      final b = c.bone(id)!;
      expect(b.head, const Offset(1.5, 1.5));
      expect(b.restAngle, 90);
      expect(b.length, 4.5);
      // A collapsing drag is ignored.
      c.setBoneTail(id, const Offset(1.6, 1.6));
      expect(c.bone(id)!.length, 4.5);
    });

    test('rename trims and ignores blanks', () {
      final id = addRoot();
      c.renameBone(id, '  spine ');
      expect(c.bone(id)!.name, 'spine');
      c.renameBone(id, '   ');
      expect(c.bone(id)!.name, 'spine');
    });

    test('limits are stored, swapped if reversed, and cleared with null', () {
      final id = addRoot();
      c.setBoneLimits(id, min: 90, max: -30);
      expect(c.bone(id)!.minAngle, -30);
      expect(c.bone(id)!.maxAngle, 90);
      c.setBoneLimits(id);
      expect(c.bone(id)!.minAngle, isNull);
      expect(c.bone(id)!.maxAngle, isNull);
    });
  });

  group('hierarchy', () {
    late String a, b, d;
    setUp(() {
      a = c.addBone(head: const Offset(1, 1), tail: const Offset(1, 3))!;
      b = c.addBone(head: const Offset(1, 3), tail: const Offset(1, 5), parentId: a)!;
      d = c.addBone(head: const Offset(1, 5), tail: const Offset(1, 7), parentId: b)!;
    });

    test('tree lists parents before children with depth', () {
      expect(c.tree.map((e) => (e.bone.id, e.depth)), [(a, 0), (b, 1), (d, 2)]);
    });

    test('reparent rejects cycles and self-parenting', () {
      expect(c.reparent(a, d), isFalse);
      expect(c.reparent(a, a), isFalse);
      expect(c.reparent(a, 'ghost'), isFalse);
      expect(c.bone(a)!.parentId, isNull);
      expect(c.reparent(d, a), isTrue);
      expect(c.bone(d)!.parentId, a);
      expect(c.reparent(d, null), isTrue);
      expect(c.bone(d)!.parentId, isNull);
    });

    test('deleting a bone hands its children to its parent', () {
      c.deleteBone(b);
      expect(c.bone(b), isNull);
      expect(c.bone(d)!.parentId, a);
    });

    test('deleting a root promotes its children to roots', () {
      c.deleteBone(a);
      expect(c.bone(b)!.parentId, isNull);
    });

    test('deleting a bone drops its parts and keyframes and clears selection', () {
      c.selectBone(b);
      c.assignLayer('arm', b);
      c.assignLayer('body', a);
      c.deleteBone(b);
      expect(c.rig.parts.map((p) => p.layerKey), ['body']);
      expect(c.selectedBoneId, isNull);
    });
  });

  group('parts', () {
    test('assigning binds a layer; reassigning keeps one part per layer', () {
      final a = addRoot();
      final b = c.addBone(head: const Offset(5, 1), tail: const Offset(5, 5))!;
      c.assignLayer('arm', a);
      final partId = c.partOfLayer('arm')!.id;
      c.assignLayer('arm', b);

      expect(c.rig.parts, hasLength(1));
      expect(c.boneOfLayer('arm')!.id, b);
      expect(c.partOfLayer('arm')!.id, partId, reason: 'part identity is kept');
    });

    test('draw order follows the layer stack', () {
      final a = addRoot();
      c.assignLayer('body', a);
      c.assignLayer('head', a);
      expect(c.partOfLayer('body')!.drawOrder, 0);
      expect(c.partOfLayer('head')!.drawOrder, 2);
    });

    test('null unassigns; unknown layers and bones are ignored', () {
      final a = addRoot();
      c.assignLayer('arm', a);
      c.assignLayer('arm', null);
      expect(c.rig.parts, isEmpty);
      c.assignLayer('nope', a);
      c.assignLayer('arm', 'ghost');
      expect(c.rig.parts, isEmpty);
    });

    test('unassignedLayers lists layers no bone drives', () {
      final a = addRoot();
      c.assignLayer('arm', a);
      expect(c.unassignedLayers.map((l) => l.stableKey), ['body', 'head']);
    });
  });

  group('hit testing', () {
    test('handles beat bodies, and a miss returns null', () {
      final id = c.addBone(head: const Offset(1.5, 1.5), tail: const Offset(5.5, 1.5))!;
      expect(c.hitTest(const Offset(1.6, 1.6), 0.5), RigHit(id, RigHitPart.head));
      expect(c.hitTest(const Offset(5.4, 1.4), 0.5), RigHit(id, RigHitPart.tail));
      expect(c.hitTest(const Offset(3.5, 1.7), 0.5), RigHit(id, RigHitPart.body));
      expect(c.hitTest(const Offset(3.5, 4), 0.5), isNull);
    });

    test('a child joint on its parent tip is reachable as the child', () {
      final p = c.addBone(head: const Offset(1.5, 1.5), tail: const Offset(1.5, 4.5))!;
      final k = c.addBone(head: const Offset(1.5, 4.5), tail: const Offset(4.5, 4.5), parentId: p)!;
      // Both handles coincide; the later (top) bone wins.
      expect(c.hitTest(const Offset(1.5, 4.5), 0.4)!.boneId, k);
    });
  });

  group('undo and redo', () {
    test('each edit is one step and redo is cleared by a new edit', () {
      final id = addRoot();
      c.renameBone(id, 'a');
      c.renameBone(id, 'b');
      c.undo();
      expect(c.bone(id)!.name, 'a');
      c.redo();
      expect(c.bone(id)!.name, 'b');
      c.undo();
      c.renameBone(id, 'c');
      expect(c.canRedo, isFalse);
    });

    test('a drag collapses into a single undo step', () {
      final id = addRoot();
      final start = c.bone(id)!.head;
      c.beginGesture();
      for (var i = 0; i < 5; i++) {
        c.moveBone(id, const Offset(1, 0));
      }
      c.endGesture();
      expect(c.bone(id)!.head, start + const Offset(5, 0));
      c.undo();
      expect(c.bone(id)!.head, start);
    });

    test('a gesture that changes nothing leaves no undo entry', () {
      addRoot();
      c.undo();
      c.redo();
      final steps = c.canUndo;
      c.beginGesture();
      c.endGesture();
      expect(c.canUndo, steps);
    });

    test('undoing a creation clears a selection that no longer exists', () {
      addRoot();
      expect(c.selectedBoneId, isNotNull);
      c.undo();
      expect(c.selectedBoneId, isNull);
    });

    test('hasChanges is false again after undoing everything', () {
      expect(c.hasChanges, isFalse);
      addRoot();
      expect(c.hasChanges, isTrue);
      c.undo();
      expect(c.hasChanges, isFalse);
    });
  });

  group('attaching new bones', () {
    late String a;
    setUp(() => a = c.addBone(head: const Offset(1.5, 1.5), tail: const Offset(5.5, 1.5))!);

    test('starting on a tip, a joint or the body attaches to that bone', () {
      final tip = c.attachPoint(const Offset(5.4, 1.6), 0.6);
      expect(tip.parentId, a);
      expect(tip.head, const Offset(5.5, 1.5));

      final joint = c.attachPoint(const Offset(1.6, 1.4), 0.6);
      expect(joint.parentId, a);
      expect(joint.head, const Offset(1.5, 1.5));

      final body = c.attachPoint(const Offset(3.2, 1.8), 0.6);
      expect(body.parentId, a);
      expect(body.head, const Offset(3, 1.5), reason: 'nearest half-pixel position on the bone');
    });

    test('away from every bone it is a free root on the pixel under the pointer', () {
      final free = c.attachPoint(const Offset(3.2, 5.8), 0.6);
      expect(free.parentId, isNull);
      expect(free.head, const Offset(3, 6));
    });

    test('a bone drawn from the body becomes its child', () {
      final at = c.attachPoint(const Offset(3.4, 1.4), 0.6);
      final child = c.addBone(head: at.head, tail: const Offset(3.5, 6.5), parentId: at.parentId)!;
      expect(c.bone(child)!.parentId, a);
      expect(c.bone(child)!.head, const Offset(3.5, 1.5));
    });

    test('in animate mode a new bone cannot be attached to a posed position by accident', () {
      // attachPoint follows what is drawn; the rest pose in setup is the only place bones are drawn.
      c.mode = RigMode.animate;
      c.setPose(a, rotation: 90);
      expect(c.attachPoint(const Offset(3.4, 1.4), 0.3).parentId, isNull, reason: 'the bone has swung away');
    });
  });

  group('connected bones stay connected', () {
    test('reshaping a bone carries children attached at its tip, and their subtrees', () {
      final a = c.addBone(head: const Offset(1.5, 1.5), tail: const Offset(1.5, 4.5))!;
      final b = c.addBone(head: const Offset(1.5, 4.5), tail: const Offset(1.5, 6.5), parentId: a)!;
      final d = c.addBone(head: const Offset(1.5, 6.5), tail: const Offset(1.5, 7.5), parentId: b)!;

      c.setBoneTail(a, const Offset(4.5, 4.5));

      expect(c.bone(a)!.tail.dx, closeTo(4.5, 1e-9));
      expect(c.bone(a)!.tail.dy, closeTo(4.5, 1e-9));
      expect(c.bone(b)!.head, const Offset(4.5, 4.5), reason: 'still attached to the tip');
      expect((c.bone(d)!.head - c.bone(b)!.tail).distance, lessThan(1e-9), reason: 'subtree rotates with the joint');
      expect(c.bone(b)!.restAngle, closeTo(45, 1e-9));
    });

    test('body attachments follow the resized axis while separate roots stay put', () {
      final a = c.addBone(head: const Offset(1.5, 1.5), tail: const Offset(1.5, 6.5))!;
      final mid = c.addBone(head: const Offset(1.5, 3.5), tail: const Offset(5.5, 3.5), parentId: a)!;
      final other = c.addBone(head: const Offset(6.5, 1.5), tail: const Offset(6.5, 5.5))!;

      c.setBoneTail(a, const Offset(1.5, 4.5));

      expect(c.bone(mid)!.head.dx, closeTo(1.5, 1e-9));
      expect(c.bone(mid)!.head.dy, closeTo(2.7, 1e-9));
      expect(c.bone(other)!.head, const Offset(6.5, 1.5));
    });

    test('the whole reshape is one undo step', () {
      final a = c.addBone(head: const Offset(1.5, 1.5), tail: const Offset(1.5, 4.5))!;
      final b = c.addBone(head: const Offset(1.5, 4.5), tail: const Offset(1.5, 6.5), parentId: a)!;
      c.setBoneTail(a, const Offset(4.5, 4.5));
      c.undo();
      expect(c.bone(b)!.head, const Offset(1.5, 4.5));
      expect(c.bone(a)!.tail.dx, closeTo(1.5, 1e-9));
    });

    test('in animate mode a parent carries its children (forward kinematics)', () {
      final a = c.addBone(head: const Offset(1.5, 6.5), tail: const Offset(1.5, 3.5))!;
      final b = c.addBone(head: const Offset(1.5, 3.5), tail: const Offset(4.5, 3.5), parentId: a)!;
      c.mode = RigMode.animate;
      c.setPose(a, rotation: 90);
      expect(c.displayBone(b)!.head.dx, closeTo(4.5, 1e-9), reason: 'the child rode the parent tip');
      expect(c.displayBone(b)!.head.dy, closeTo(6.5, 1e-9));
    });
  });

  group('half-pixel joined joints', () {
    test('continuing from an endpoint automatically parents a new half-pixel bone', () {
      final a = c.addBone(head: const Offset(1, 1), tail: const Offset(3.5, 1))!;
      final b = c.addBone(head: const Offset(3.5, 1), tail: const Offset(4, 1))!;
      expect(c.bone(b)!.parentId, a);
      expect(c.bone(b)!.head, c.bone(a)!.tail);
      expect(c.bone(b)!.length, .5);
      final restored = Rig.fromJson(c.rig.toJson());
      expect(restored.bones.last.head, const Offset(3.5, 1));
      expect(restored.bones.last.parentId, a);
    });

    test('moving a shared joint reshapes the parent without tearing the child away', () {
      final a = c.addBone(head: const Offset(1, 1), tail: const Offset(3, 1))!;
      final b = c.addBone(head: const Offset(3, 1), tail: const Offset(5, 1))!;
      c.moveBone(b, const Offset(.5, .5));
      expect(c.bone(a)!.head, const Offset(1, 1));
      expect(c.bone(a)!.tail, const Offset(3.5, 1.5));
      expect(c.bone(b)!.head, c.bone(a)!.tail);
      c.undo();
      expect(c.bone(b)!.head, const Offset(3, 1));
      expect(c.bone(a)!.tail, const Offset(3, 1));
    });

    test('connecting existing bones moves the subtree, rejects cycles and undoes', () {
      final a = c.addBone(head: const Offset(1, 1), tail: const Offset(3, 1))!;
      final b = c.addBone(head: const Offset(5, 2), tail: const Offset(6, 2))!;
      final d = c.addBone(head: const Offset(6, 2), tail: const Offset(7, 2))!;
      expect(c.connectToBone(b, a), isTrue);
      expect(c.bone(b)!.head, c.bone(a)!.tail);
      expect(c.bone(d)!.head, c.bone(b)!.tail);
      expect(c.connectToBone(a, d), isFalse);
      c.undo();
      expect(c.bone(b)!.parentId, isNull);
      expect(c.bone(d)!.head, const Offset(6, 2));
      c.moveBone(b, const Offset(-2, -1));
      expect(c.connectJoint(b), isTrue);
      expect(c.bone(b)!.parentId, a);
    });

    test('disconnect preserves rest positions and isolates subsequent movement', () {
      final a = c.addBone(head: const Offset(1, 1), tail: const Offset(3, 1))!;
      final b = c.addBone(head: const Offset(3, 1), tail: const Offset(5, 1))!;
      final before = c.bone(b)!;
      c.reparent(b, null);
      expect(c.bone(b)!.head, before.head);
      c.moveBone(a, const Offset(.5, 0));
      expect(c.bone(b)!.head, before.head);
      c.undo();
      c.undo();
      expect(c.bone(b)!.parentId, a);
    });

    test('non-right-angle poses preserve exact shared joints and half-pixel motion', () {
      final a = c.addBone(head: const Offset(1, 1), tail: const Offset(3.5, 1))!;
      final b = c.addBone(head: const Offset(3.5, 1), tail: const Offset(5, 1))!;
      c.mode = RigMode.animate;
      c.setPose(a, rotation: 33, translation: const Offset(.5, .5));
      expect((c.displayBone(a)!.tail - c.displayBone(b)!.head).distance, lessThan(1e-9));
      expect(c.displayBone(a)!.head, const Offset(1.5, 1.5));
      expect(c.jointMoveBoneId(b), a);
    });
  });

  group('binding a layer while drawing', () {
    test('an armed layer is bound to the next bone and then disarmed', () {
      c.selectLayer('arm');
      expect(c.activeLayerKey, 'arm');

      final id = c.addBone(head: const Offset(1.5, 1.5), tail: const Offset(1.5, 5.5))!;

      expect(c.boneOfLayer('arm')!.id, id);
      expect(c.activeLayerKey, isNull, reason: 'one layer, one bone');
      final next = c.addBone(head: const Offset(4.5, 1.5), tail: const Offset(4.5, 5.5))!;
      expect(c.boneOfLayer('arm')!.id, id, reason: 'the second bone leaves the layer alone');
      expect(c.partOfLayer('arm')!.boneId, isNot(next));
    });

    test('creating the bone and binding the layer is a single undo step', () {
      c.selectLayer('arm');
      c.addBone(head: const Offset(1.5, 1.5), tail: const Offset(1.5, 5.5));
      c.undo();
      expect(c.rig.bones, isEmpty);
      expect(c.rig.parts, isEmpty);
    });

    test('without an armed layer nothing is bound', () {
      c.addBone(head: const Offset(1.5, 1.5), tail: const Offset(1.5, 5.5));
      expect(c.rig.parts, isEmpty);
    });

    test('arming again, or null, disarms; unknown layers are ignored', () {
      c.selectLayer('arm');
      c.selectLayer('arm');
      expect(c.activeLayerKey, isNull);
      c.selectLayer('arm');
      c.selectLayer(null);
      expect(c.activeLayerKey, isNull);
      c.selectLayer('nope');
      expect(c.activeLayerKey, isNull);
    });

    test('arming a layer that already has a bone moves it to the new bone', () {
      final first = addRoot();
      c.assignLayer('arm', first);
      c.selectLayer('arm');
      final second = c.addBone(head: const Offset(5.5, 1.5), tail: const Offset(5.5, 5.5))!;
      expect(c.boneOfLayer('arm')!.id, second);
      expect(c.rig.parts.where((p) => p.layerKey == 'arm'), hasLength(1));
    });

    test('a rejected bone keeps the layer armed', () {
      c.selectLayer('arm');
      expect(c.addBone(head: const Offset(1.1, 1.1), tail: const Offset(1.2, 1.2)), isNull);
      expect(c.activeLayerKey, 'arm');
    });

    test('switching to animate mode disarms the layer', () {
      c.selectLayer('arm');
      c.mode = RigMode.animate;
      expect(c.activeLayerKey, isNull);
    });
  });

  test('listeners are notified on edits', () {
    var calls = 0;
    c.addListener(() => calls++);
    addRoot();
    expect(calls, greaterThan(0));
  });
}
