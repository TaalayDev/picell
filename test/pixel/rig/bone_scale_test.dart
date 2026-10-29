import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:picell/data/models/layer.dart';
import 'package:picell/data/models/rig/rig.dart';
import 'package:picell/pixel/rig/affine2.dart';
import 'package:picell/pixel/rig/part_rasterizer.dart';
import 'package:picell/pixel/rig/pose_interpolator.dart';
import 'package:picell/pixel/rig/rig_editor_controller.dart';
import 'package:picell/pixel/rig/rig_solver.dart';

void main() {
  Matcher near(Offset o) => predicate<Offset>((p) => (p - o).distance < 1e-9, 'is near $o');

  // A horizontal 4px bone at the origin with a child at its tip, and a
  // vertical one pointing down.
  const flat = Bone(id: 'flat', name: 'flat', head: Offset.zero, length: 4);
  const child = Bone(id: 'child', name: 'child', parentId: 'flat', head: Offset(4, 0), length: 2);
  const down = Bone(id: 'down', name: 'down', head: Offset.zero, length: 4, restAngle: 90);

  group('model', () {
    test('scale survives JSON and old rigs load at full size', () {
      const pose = BonePose(rotation: 10, scaleX: 1.5, scaleY: 0.5);
      expect(BonePose.fromJson(pose.toJson()), pose);
      expect(BonePose.fromJson({'rotation': 10}).scaleX, 1);
      expect(const BonePose().toJson().containsKey('scaleX'), isFalse, reason: 'unscaled poses save as before');

      const key = RigKeyframe(time: 2, boneId: 'b', scaleX: 2, scaleY: 0.5);
      expect(RigKeyframe.fromJson(key.toJson()), key);
      expect(RigKeyframe.fromJson({'time': 0, 'boneId': 'b'}).scaleY, 1);
    });

    test('copyWith keeps the scale', () {
      const pose = BonePose(scaleX: 2);
      expect(pose.copyWith(rotation: 30).scaleX, 2);
      expect(pose.isScaled, isTrue);
      expect(BonePose.rest.isScaled, isFalse);
    });
  });

  group('interpolation', () {
    test('scale changes evenly in ratio between keys', () {
      const clip = RigClip(id: 'c', name: 'c', length: 10, keyframes: [
        RigKeyframe(time: 0, boneId: 'flat', scaleX: 0.5),
        RigKeyframe(time: 4, boneId: 'flat', scaleX: 2, scaleY: 3),
      ]);
      final mid = PoseInterpolator.sample(clip, const [flat], 2)['flat']!;
      expect(mid.scaleX, closeTo(1, 1e-9), reason: 'halfway from 0.5 to 2');
      expect(mid.scaleY, closeTo(1.7320508, 1e-6), reason: 'halfway from 1 to 3 is √3');
      expect(PoseInterpolator.sample(clip, const [flat], 4)['flat']!.scaleX, 2);
    });
  });

  group('solver', () {
    Map<String, Affine2> solve(List<Bone> bones, Map<String, BonePose> poses) =>
        RigSolver.solve(Rig(id: 'r', stateId: 1, bones: bones), poses);

    test('stretching scales along the bone, about its head', () {
      final world = solve(const [flat], {'flat': const BonePose(scaleX: 2)});
      expect(world['flat']!.apply(flat.tail), near(const Offset(8, 0)));
      expect(world['flat']!.apply(flat.head), near(Offset.zero));
    });

    test('scale follows the bone direction, not the canvas axes', () {
      final world = solve(const [down], {'down': const BonePose(scaleX: 2, scaleY: 3)});
      expect(world['down']!.apply(down.tail), near(const Offset(0, 8)));
      // One pixel to the bone's side is "across" it: scaled by scaleY.
      expect(world['down']!.apply(const Offset(1, 0)), near(const Offset(3, 0)));
    });

    test('children ride along with a stretched parent', () {
      final world = solve(const [flat, child], {'flat': const BonePose(scaleX: 2)});
      expect(world['child']!.apply(child.head), near(const Offset(8, 0)));
    });

    test('rotation applies after scale', () {
      final world = solve(const [flat], {'flat': const BonePose(rotation: 90, scaleX: 2)});
      expect(world['flat']!.apply(flat.tail), near(const Offset(0, 8)));
    });

    test('a zero scale is held at the minimum instead of collapsing', () {
      final world = solve(const [flat], {'flat': const BonePose(scaleX: 0)});
      expect(world['flat']!.invert(), isNotNull);
    });
  });

  group('rasterizing', () {
    test('a stretched part covers proportionally more pixels, with no new colours', () {
      const red = 0xFFFF0000;
      // 8×1 canvas, a 2px red part at x = 0..1.
      final source = Uint32List.fromList([red, red, 0, 0, 0, 0, 0, 0]);
      final transform = RigSolver.localTransform(flat, const BonePose(scaleX: 2), 0);
      final out = PartRasterizer.rasterize(source, 8, 1, transform);
      expect(out.toList(), [red, red, red, red, 0, 0, 0, 0]);
    });
  });

  group('editor', () {
    Layer layer(String key) => Layer(layerId: 0, id: 'id-$key', name: key, pixels: Uint32List(256), stableKey: key);

    RigEditorController make() => RigEditorController(
          rig: const Rig(id: 'r', stateId: 1, bones: [flat, child]),
          restLayers: [layer('body')],
          width: 16,
          height: 16,
          clipName: 'Walk',
        )..mode = RigMode.animate;

    test('setPose keys scale, rounded to whole percents and kept in range', () {
      final c = make();
      c.setPose('flat', scaleX: 1.234, scaleY: 0.5);
      expect(c.keyAt('flat', 0)!.scaleX, 1.23);
      expect(c.keyAt('flat', 0)!.scaleY, 0.5);

      c.setPose('flat', scaleX: 0, scaleY: 500);
      expect(c.keyAt('flat', 0)!.scaleX, 0.01);
      expect(c.keyAt('flat', 0)!.scaleY, 20);
    });

    test('other edits keep the scale, and undo restores it', () {
      final c = make();
      c.setPose('flat', scaleX: 2);
      c.setPose('flat', rotation: 30);
      expect(c.keyAt('flat', 0)!.scaleX, 2);
      expect(c.keyAt('flat', 0)!.rotation, 30);

      c.undo();
      c.undo();
      expect(c.poseOf('flat').scaleX, 1);
    });

    test('the scale tool is animate-only', () {
      final c = make();
      c.tool = RigTool.scale;
      expect(c.tool, RigTool.scale);
      c.mode = RigMode.setup;
      expect(c.tool, RigTool.select);
      c.tool = RigTool.scale;
      expect(c.tool, RigTool.select);
    });

    test('copied and saved poses carry the scale', () {
      final c = make();
      c.setPose('flat', scaleX: 1.5, scaleY: 0.8);
      c.selectBone('flat');
      c.copyPose();
      final saved = c.savePose('Squash')!;

      c.setTime(3);
      c.pastePose();
      expect(c.keyAt('flat', 3)!.scaleX, 1.5);
      expect(c.keyAt('flat', 3)!.scaleY, 0.8);

      c.setTime(5);
      c.applyPose(saved);
      expect(c.keyAt('flat', 5)!.scaleX, 1.5);
    });

    test('the shown skeleton is stretched', () {
      final c = make();
      c.setPose('flat', scaleX: 2);
      expect(c.displayBone('flat')!.tail, near(const Offset(8, 0)));
      expect(c.displayBone('child')!.head, near(const Offset(8, 0)));
    });
  });
}
