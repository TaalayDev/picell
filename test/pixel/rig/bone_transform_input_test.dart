import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:picell/data/models/layer.dart';
import 'package:picell/data/models/rig/rig.dart';
import 'package:picell/pixel/rig/affine2.dart';
import 'package:picell/pixel/rig/pose_interpolator.dart';
import 'package:picell/pixel/rig/rig_editor_controller.dart';
import 'package:picell/pixel/rig/rig_solver.dart';

void main() {
  Matcher near(Offset o) => predicate<Offset>((p) => (p - o).distance < 1e-9, 'is near $o');

  // A 4px bone pointing right from (4, 8), with a 2px child at its tip.
  const parent = Bone(id: 'parent', name: 'parent', head: Offset(4, 8), length: 4);
  const child = Bone(id: 'child', name: 'child', parentId: 'parent', head: Offset(8, 8), length: 2);
  const down = Bone(id: 'down', name: 'down', head: Offset.zero, length: 4, restAngle: 90);

  group('flipY', () {
    test('survives JSON and old rigs load unflipped', () {
      const pose = BonePose(flipY: true);
      expect(BonePose.fromJson(pose.toJson()), pose);
      expect(BonePose.fromJson({'rotation': 0}).flipY, isFalse);
      expect(const BonePose().toJson().containsKey('flipY'), isFalse);

      const key = RigKeyframe(time: 1, boneId: 'b', flipY: true);
      expect(RigKeyframe.fromJson(key.toJson()), key);
    });

    test('mirrors the bone upside down about its head', () {
      Map<String, Affine2> solve(Bone bone) =>
          RigSolver.solve(Rig(id: 'r', stateId: 1, bones: [bone]), {bone.id: const BonePose(flipY: true)});
      expect(solve(down)['down']!.apply(down.tail), near(const Offset(0, -4)));
      // Along a horizontal bone the tip stays; things beside it swap sides.
      final flat = solve(parent)['parent']!;
      expect(flat.apply(parent.tail), near(parent.tail));
      expect(flat.apply(const Offset(5, 9)), near(const Offset(5, 7)));
    });

    test('holds like flipX between keys', () {
      const clip = RigClip(id: 'c', name: 'c', length: 4, keyframes: [
        RigKeyframe(time: 0, boneId: 'parent', flipY: true),
        RigKeyframe(time: 2, boneId: 'parent'),
      ]);
      expect(PoseInterpolator.sample(clip, const [parent], 1)['parent']!.flipY, isTrue);
      expect(PoseInterpolator.sample(clip, const [parent], 2)['parent']!.flipY, isFalse);
    });
  });

  group('editor', () {
    Layer layer(String key) => Layer(layerId: 0, id: 'id-$key', name: key, pixels: Uint32List(256), stableKey: key);

    RigEditorController make({double snap = 0, bool selectBoth = true}) {
      final c = RigEditorController(
        rig: Rig(id: 'r', stateId: 1, bones: const [parent, child], settings: RigSettings(snapAngleDegrees: snap)),
        restLayers: [layer('body')],
        width: 16,
        height: 16,
        clipName: 'Walk',
      )..mode = RigMode.animate;
      c.selectBone('parent');
      if (selectBoth) {
        c.toggleMultiSelect();
        c.toggleBoneSelection('child');
      }
      return c;
    }

    test('typed values go to every selected bone as one undo step', () {
      final c = make();
      final undoBefore = c.canUndo;
      c.transformSelectedBones(rotation: 30, scaleX: 1.5);

      expect(c.keyAt('parent', 0)!.rotation, 30);
      expect(c.keyAt('child', 0)!.rotation, 30);
      expect(c.keyAt('child', 0)!.scaleX, 1.5);

      c.undo();
      expect(c.keyAt('parent', 0), isNull);
      expect(c.keyAt('child', 0), isNull);
      expect(c.canUndo, undoBefore);
    });

    test('relative values add rotation and offset and multiply scale', () {
      final c = make();
      c.setPose('parent', rotation: 10, scaleX: 2);
      c.setPose('child', rotation: -5, translation: const Offset(1, 1));
      c.transformSelectedBones(rotation: 20, translation: const Offset(2, 0), scaleX: 0.5, relative: true);

      expect(c.keyAt('parent', 0)!.rotation, 30);
      expect(c.keyAt('parent', 0)!.scaleX, 1);
      expect(c.keyAt('child', 0)!.rotation, 15);
      expect(c.keyAt('child', 0)!.translation, const Offset(3, 1));
    });

    test('flips are set on every selected bone', () {
      final c = make();
      c.transformSelectedBones(flipY: true);
      expect(c.keyAt('parent', 0)!.flipY, isTrue);
      expect(c.keyAt('child', 0)!.flipY, isTrue);
      expect(c.keyAt('child', 0)!.flipX, isFalse);
    });

    test('a nudge moves the topmost selected bone and its child rides along', () {
      final c = make();
      final childHead = c.displayBone('child')!.head;
      c.nudgeSelectedBones(const Offset(1, 0));

      expect(c.keyAt('parent', 0)!.translation, const Offset(1, 0));
      expect(c.keyAt('child', 0), isNull, reason: 'not moved twice');
      expect(c.displayBone('child')!.head, near(childHead + const Offset(1, 0)));
    });

    test('a nudge moves a child the screen direction even when its parent is turned', () {
      final c = make(selectBoth: false);
      c.setPose('parent', rotation: 90);
      c.selectBone('child');
      final before = c.displayBone('child')!.head;
      c.nudgeSelectedBones(const Offset(1, 0));
      expect(c.displayBone('child')!.head, near(before + const Offset(1, 0)));
    });

    test('[ and ] turn by the snap step, or one degree without snapping', () {
      final free = make();
      expect(free.rotationStep, 1);
      free.rotateSelectedBones(free.rotationStep);
      expect(free.keyAt('parent', 0)!.rotation, 1);
      expect(free.keyAt('child', 0)!.rotation, 1);

      final snapped = make(snap: 15);
      expect(snapped.rotationStep, 15);
      snapped.rotateSelectedBones(-snapped.rotationStep);
      expect(snapped.keyAt('parent', 0)!.rotation, -15);
    });

    test('with auto-key off the changes wait to be keyed together', () {
      final c = make();
      c.autoKey = false;
      c.transformSelectedBones(rotation: 45);
      expect(c.keyAt('parent', 0), isNull);
      expect(c.poseOf('parent').rotation, 45);
      expect(c.isPending('child'), isTrue);

      c.keyPending();
      expect(c.keyAt('parent', 0)!.rotation, 45);
      expect(c.keyAt('child', 0)!.rotation, 45);
    });

    test('nothing happens in setup mode', () {
      final c = make()..mode = RigMode.setup;
      c.transformSelectedBones(rotation: 30);
      c.nudgeSelectedBones(const Offset(1, 0));
      expect(c.rig.clips, isEmpty);
    });
  });
}
