import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:picell/data/models/layer.dart';
import 'package:picell/data/models/rig/rig.dart';
import 'package:picell/pixel/rig/pose_interpolator.dart';
import 'package:picell/pixel/rig/rig_baker.dart';
import 'package:picell/pixel/rig/rig_editor_controller.dart';

const w = 8, h = 4;

Layer solid(String key, int color, {required int x0, required int x1}) {
  final px = Uint32List(w * h);
  for (var y = 0; y < h; y++) {
    for (var x = x0; x < x1; x++) {
      px[y * w + x] = color;
    }
  }
  return Layer(layerId: 0, id: 'id-$key', name: key, pixels: px, stableKey: key);
}

void main() {
  group('draw order keys', () {
    const clip = RigClip(
      id: 'c',
      name: 'c',
      length: 8,
      orderKeyframes: [
        DrawOrderKeyframe(time: 2, boneId: 'a', offset: 1),
        DrawOrderKeyframe(time: 5, boneId: 'a', offset: 0),
      ],
    );

    test('a key holds until the next key', () {
      expect(PoseInterpolator.sampleOrder(clip, 2.0), {'a': 1});
      expect(PoseInterpolator.sampleOrder(clip, 4.9), {'a': 1});
      expect(PoseInterpolator.sampleOrder(clip, 5.0), isEmpty);
      expect(PoseInterpolator.sampleOrder(clip, 7.0), isEmpty);
    });

    test('before the first key a bone is at its normal place, looping or not', () {
      final single = clip.copyWith(orderKeyframes: [const DrawOrderKeyframe(time: 3, boneId: 'a', offset: 2)]);
      expect(PoseInterpolator.sampleOrder(single, 1), isEmpty);
      expect(PoseInterpolator.sampleOrder(single, 3), {'a': 2});
      expect(PoseInterpolator.sampleOrder(single, 7), {'a': 2});
    });

    test('json round trip', () {
      expect(RigClip.fromJson(clip.toJson()), clip);
    });

    test('the baker draws a moved bone in front of the layer above it', () {
      // 'back' (bone A) is below 'front' (bone B) and they overlap on x 2..4.
      var n = 0;
      final c = RigEditorController(
        rig: const Rig(id: 'r', stateId: 1),
        restLayers: [solid('back', 0xFF0000FF, x0: 0, x1: 4), solid('front', 0xFF00FF00, x0: 2, x1: 6)],
        width: w,
        height: h,
        newId: () => 'i${n++}',
      );
      final a = c.addBone(head: const Offset(1, 3), tail: const Offset(1, 0))!;
      final b = c.addBone(head: const Offset(5, 3), tail: const Offset(5, 0))!;
      c.assignLayer('back', a);
      c.assignLayer('front', b);
      c.mode = RigMode.animate;
      c.setClipLength(4);
      c.setTime(2);
      c.shiftDrawOrder(a, 1);
      expect(c.drawOrderOf(a), 1);
      final baker = RigBaker(rig: c.rig, width: w, height: h, layers: c.restLayers);
      expect(baker.bakeFrame(c.activeClip, 0)[2], 0xFF00FF00, reason: 'front wins at rest');
      expect(baker.bakeFrame(c.activeClip, 2)[2], 0xFF0000FF, reason: 'back brought in front');
    });

    test('keys follow frame edits and vanish with the bone', () {
      var n = 0;
      final c = RigEditorController(
        rig: const Rig(id: 'r', stateId: 1),
        restLayers: [solid('back', 0xFF0000FF, x0: 0, x1: 4)],
        width: w,
        height: h,
        newId: () => 'i${n++}',
      );
      final a = c.addBone(head: const Offset(1, 3), tail: const Offset(1, 0))!;
      c.mode = RigMode.animate;
      c.setClipLength(8);
      c.setTime(4);
      c.shiftDrawOrder(a, 1);
      c.selectFrameRange(0, 1);
      c.deleteFrameRange();
      expect(c.orderKeyTimes(a), {2});
      c.undo();
      expect(c.orderKeyTimes(a), {4});
      c.deleteOrderKey(a, 4);
      expect(c.activeClip.orderKeyframes, isEmpty);
      c.undo();
      c.deleteBone(a);
      expect(c.activeClip.orderKeyframes, isEmpty);
    });
  });

  group('mirror pose', () {
    late RigEditorController c;
    late String armL, armR, spine;

    setUp(() {
      var n = 0;
      c = RigEditorController(
        rig: const Rig(id: 'r', stateId: 1),
        restLayers: [solid('body', 0xFF0000FF, x0: 0, x1: 4)],
        width: w,
        height: h,
        newId: () => 'i${n++}',
      );
      spine = c.addBone(head: const Offset(4, 3), tail: const Offset(4, 1), name: 'spine')!;
      armL = c.addBone(head: const Offset(2, 1), tail: const Offset(1, 3), name: 'arm_l')!;
      armR = c.addBone(head: const Offset(6, 1), tail: const Offset(7, 3), name: 'arm_r')!;
      c.mode = RigMode.animate;
      c.setClipLength(4);
      c.setTime(1);
    });

    test('pairs bones by side name', () {
      expect(c.mirrorPairs, {armL: armR, armR: armL});
      expect(c.canMirrorPose, isTrue);
    });

    test('swap exchanges left and right poses and leaves the centre alone', () {
      c.setPose(armL, rotation: 30);
      c.setPose(spine, rotation: 5);
      c.mirrorPose();
      expect(c.poseOf(armR).rotation, 30);
      expect(c.poseOf(armL).rotation, 0);
      expect(c.poseOf(spine).rotation, 5);
      c.undo();
      expect(c.poseOf(armL).rotation, 30);
    });

    test('reflect also negates rotation and moves centre bones', () {
      c.setPose(armL, rotation: 30);
      c.setPose(spine, rotation: 5, translation: const Offset(1, 2));
      c.mirrorPose(reflect: true);
      expect(c.poseOf(armR).rotation, -30);
      expect(c.poseOf(spine).rotation, -5);
      expect(c.poseOf(spine).translation, const Offset(-1, 2));
    });

    test('rigs without left/right names cannot mirror', () {
      final plain = RigEditorController(
        rig: const Rig(id: 'r', stateId: 1),
        restLayers: const [],
        width: w,
        height: h,
      );
      plain.addBone(head: const Offset(1, 3), tail: const Offset(1, 0), name: 'tail');
      plain.mode = RigMode.animate;
      expect(plain.canMirrorPose, isFalse);
    });
  });

  group('loop seam', () {
    late RigEditorController c;
    late String id;

    setUp(() {
      var n = 0;
      c = RigEditorController(
        rig: const Rig(id: 'r', stateId: 1),
        restLayers: const [],
        width: w,
        height: h,
        newId: () => 'i${n++}',
      );
      id = c.addBone(head: const Offset(4, 3), tail: const Offset(4, 0))!;
      c.mode = RigMode.animate;
      c.setClipLength(5);
    });

    test('a last key repeating the first is a stutter; fixing removes it', () {
      c.setTime(0);
      c.setPose(id, rotation: 20);
      c.setTime(2);
      c.setPose(id, rotation: -20);
      c.setTime(4);
      c.setPose(id, rotation: 20);
      expect(c.hasLoopSeamIssue, isTrue);
      expect(c.fixLoopSeam(), 1);
      expect(c.keyTimes(id), {0, 2});
      expect(c.hasLoopSeamIssue, isFalse);
      c.undo();
      expect(c.keyTimes(id), {0, 2, 4});
    });

    test('a clip that does not loop is offered the fix too', () {
      c.setTime(0);
      c.setPose(id, rotation: 20);
      c.setLoop(false);
      expect(c.hasLoopSeamIssue, isTrue);
      c.fixLoopSeam();
      expect(c.activeClip.loop, isTrue);
    });

    test('a healthy loop has nothing to fix', () {
      c.setTime(0);
      c.setPose(id, rotation: 20);
      c.setTime(2);
      c.setPose(id, rotation: -20);
      expect(c.hasLoopSeamIssue, isFalse);
      expect(c.fixLoopSeam(), 0);
    });
  });
}
