import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:picell/data/models/layer.dart';
import 'package:picell/data/models/rig/rig.dart';
import 'package:picell/pixel/rig/rig_editor_controller.dart';

void main() {
  Matcher near(Offset o) => predicate<Offset>((p) => (p - o).distance < 1e-9, 'is near $o');

  Layer layer(String key) => Layer(layerId: 0, id: 'id-$key', name: key, pixels: Uint32List(256), stableKey: key);

  // spine: (8.5,12.5) pointing up 6 px; arm child at its tip pointing right 4 px.
  const spine = Bone(id: 'spine', name: 'spine', head: Offset(8.5, 12.5), length: 6, restAngle: -90);
  const arm = Bone(id: 'arm', name: 'arm', parentId: 'spine', head: Offset(8.5, 6.5), length: 4);

  RigEditorController make({List<Bone> bones = const [spine, arm], int fps = 12}) => RigEditorController(
        rig: Rig(id: 'r', stateId: 1, bones: bones),
        restLayers: [layer('body')],
        width: 16,
        height: 16,
        defaultFps: fps,
        clipName: 'Walk',
      )..mode = RigMode.animate;

  group('modes and tools', () {
    test('switching modes swaps tools that do not apply', () {
      final c = make();
      expect(c.tool, RigTool.rotate);
      c.tool = RigTool.createBone;
      expect(c.tool, RigTool.rotate, reason: 'drawing bones is setup-only');
      c.mode = RigMode.setup;
      expect(c.tool, RigTool.select);
      c.tool = RigTool.move;
      expect(c.tool, RigTool.select, reason: 'posing is animate-only');
    });

    test('looking at animate mode does not change the rig', () {
      final c = make();
      expect(c.activeClip.name, 'Walk');
      expect(c.rig.clips, isEmpty);
      expect(c.hasChanges, isFalse);
    });
  });

  group('keyframes', () {
    test('the first edit stores the clip in the rig and keys the bone', () {
      final c = make();
      c.setPose('arm', rotation: 30);
      expect(c.rig.clips, hasLength(1));
      expect(c.rig.clips.single.fps, 12);
      expect(c.keyAt('arm', 0)!.rotation, 30);
      expect(c.hasChanges, isTrue);
    });

    test('poses interpolate between keys as the frame changes', () {
      final c = make();
      c.setClipLength(5);
      c.setPose('arm', rotation: 0);
      c.setTime(4);
      c.setPose('arm', rotation: 80);
      c.setTime(2);
      expect(c.poseOf('arm').rotation, 40);
    });

    test('editing at an unkeyed frame keys it with the values shown there', () {
      final c = make();
      c.setClipLength(5);
      c.setPose('arm', rotation: 0);
      c.setTime(4);
      c.setPose('arm', rotation: 80);
      c.setTime(2);
      c.setPose('arm', translation: const Offset(1, 0));
      final key = c.keyAt('arm', 2)!;
      expect(key.rotation, 40, reason: 'rotation is kept as it was interpolated');
      expect(key.translation, const Offset(1, 0));
    });

    test('rotation is clamped to the bone limits', () {
      final c = make(bones: const [Bone(id: 'b', name: 'b', head: Offset(4, 4), length: 3, minAngle: -10, maxAngle: 30)]);
      c.setPose('b', rotation: 90);
      expect(c.keyAt('b', 0)!.rotation, 30);
      c.setPose('b', rotation: -90);
      expect(c.keyAt('b', 0)!.rotation, -10);
    });

    test('deleteKey, keyBone and easing', () {
      final c = make();
      c.keyBone('arm');
      expect(c.keyAt('arm', 0), isNotNull);
      c.setKeyEasing('arm', 0, RigEasing.stepped);
      expect(c.keyAt('arm', 0)!.easing, RigEasing.stepped);
      c.setPose('arm', rotation: 15);
      expect(c.keyAt('arm', 0)!.easing, RigEasing.stepped, reason: 'editing keeps the easing');
      c.deleteKey('arm', 0);
      expect(c.keyAt('arm', 0), isNull);
      expect(c.keyTimes('arm'), isEmpty);
    });

    test('a custom curve survives editing and is cleared by a preset easing', () {
      final c = make();
      final curve = EasingCurve(.34, 1.56, .64, 1);
      c.keyBone('arm');
      c.setKeyCurve('arm', 0, curve);
      expect(c.keyAt('arm', 0)!.curve, curve);
      c.setPose('arm', rotation: 15);
      expect(c.keyAt('arm', 0)!.curve, curve, reason: 'editing keeps the curve');
      c.setKeyEasing('arm', 0, RigEasing.easeIn);
      expect(c.keyAt('arm', 0)!.curve, isNull);
      expect(c.keyAt('arm', 0)!.easing, RigEasing.easeIn);
    });

    test('copy and paste move a whole pose to another frame', () {
      final c = make();
      c.setClipLength(6);
      c.setPose('arm', rotation: 45);
      c.setPose('spine', translation: const Offset(2, 0));
      c.copyPose();
      c.setTime(3);
      c.pastePose();
      expect(c.keyAt('arm', 3)!.rotation, 45);
      expect(c.keyAt('spine', 3)!.translation, const Offset(2, 0));
      // Pasting is one undo step.
      c.undo();
      expect(c.keyAt('arm', 3), isNull);
      expect(c.keyAt('spine', 3), isNull);
    });

    test('shrinking the clip drops keys past the end and clamps the playhead', () {
      final c = make();
      c.setClipLength(8);
      c.setTime(6);
      c.setPose('arm', rotation: 10);
      c.setClipLength(4);
      expect(c.rig.clips.single.keyframes, isEmpty);
      expect(c.time, 3);
      c.undo();
      expect(c.keyAt('arm', 6), isNotNull);
    });

    test('clip settings are clamped', () {
      final c = make();
      c.setClipLength(0);
      expect(c.activeClip.length, 1);
      c.setClipLength(9999);
      expect(c.activeClip.length, 240);
      c.setFps(500);
      expect(c.activeClip.fps, 60);
      c.setLoop(false);
      expect(c.activeClip.loop, isFalse);
    });

    test('a rotate drag is one undo step', () {
      final c = make();
      c.beginGesture();
      for (var r = 5.0; r <= 50; r += 5) {
        c.setPose('arm', rotation: r);
      }
      c.endGesture();
      expect(c.keyAt('arm', 0)!.rotation, 50);
      c.undo();
      expect(c.keyAt('arm', 0), isNull);
    });

    test('deleting a bone removes its keys', () {
      final c = make();
      c.setPose('arm', rotation: 20);
      c.deleteBone('arm');
      expect(c.rig.clips.single.keyframes, isEmpty);
    });
  });

  group('posed geometry', () {
    test('setup mode shows the rest pose even if keys exist', () {
      final c = make();
      c.setPose('spine', rotation: 90);
      c.mode = RigMode.setup;
      expect(c.displayBone('spine')!.tail, near(spine.tail));
    });

    test('animate mode shows bones posed, and children follow their parent', () {
      final c = make();
      c.setPose('spine', rotation: 90); // swing the spine a quarter turn clockwise
      final s = c.displayBone('spine')!;
      expect(s.head, near(const Offset(8.5, 12.5)));
      expect(s.tail, near(const Offset(14.5, 12.5)), reason: 'up becomes right');
      // The arm's joint rode the spine's tip.
      expect(c.displayBone('arm')!.head, near(const Offset(14.5, 12.5)));
    });

    test('hit testing follows the posed bones', () {
      final c = make();
      c.setPose('spine', rotation: 90);
      expect(c.hitTest(const Offset(12, 12.5), 0.5)!.boneId, 'spine');
      expect(c.hitTest(const Offset(8.5, 9), 0.5), isNull, reason: 'the rest position is empty now');
    });

    test('rotation sign flips under a mirrored parent', () {
      final c = make();
      expect(c.rotationSign('arm'), 1);
      c.setPose('spine', flipX: true);
      expect(c.rotationSign('arm'), -1);
      expect(c.rotationSign('spine'), 1, reason: 'a bone mirrors itself, not its own rotation');
    });

    test('toLocalDelta undoes the parent rotation', () {
      final c = make();
      c.setPose('spine', rotation: 90);
      // A world move right is, in the arm's rest frame, a move up (y negative).
      expect(c.toLocalDelta('arm', const Offset(1, 0)), near(const Offset(0, -1)));
    });
  });
}
