import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:picell/data/models/layer.dart';
import 'package:picell/data/models/rig/rig.dart';
import 'package:picell/pixel/rig/rig_baker.dart';
import 'package:picell/pixel/rig/rig_editor_controller.dart';
import 'package:picell/pixel/rig/rig_influence_paint.dart';

const w = 8, h = 8;

Uint32List opaque() => Uint32List(w * h)..fillRange(0, w * h, 0xFFFF0000);

void main() {
  group('RigInfluencePaint', () {
    var n = 0;
    String id() => 'p${n++}';
    const whole = RigPart(id: 'a', boneId: 'A', layerKey: 'body');

    List<RigPart> paint(List<RigPart> parts, String? bone, List<int> px) => RigInfluencePaint.paint(
          parts,
          layerKey: 'body',
          boneId: bone,
          pixels: px,
          width: w,
          height: h,
          drawOrder: 0,
          newId: id,
        );

    test('splits a whole-layer part: painted pixels move, the rest stay', () {
      final out = paint([whole], 'B', [0, 1]);
      expect(out, hasLength(2));
      final a = out.firstWhere((p) => p.boneId == 'A'), b = out.firstWhere((p) => p.boneId == 'B');
      expect(a.id, 'a');
      expect(a.mask![0], 0);
      expect(a.mask![2], 1);
      expect([b.mask![0], b.mask![1], b.mask![2]], [1, 1, 0]);
    });

    test('painting everything hands the layer over and drops the empty part', () {
      final out = paint([whole], 'B', List.generate(w * h, (i) => i));
      expect(out, hasLength(1));
      expect(out.single.boneId, 'B');
      expect(out.single.mask, isNull);
    });

    test('erasing leaves pixels with nobody and keeps the rest', () {
      final out = paint([whole], null, [5]);
      expect(out.single.boneId, 'A');
      expect(out.single.mask![5], 0);
      expect(out.single.mask![4], 1);
    });

    test('does not modify its input masks', () {
      final mask = Uint8List(w * h)..fillRange(0, w * h, 1);
      final input = [whole.copyWith(mask: () => mask)];
      paint(input, 'B', [3]);
      expect(mask[3], 1);
    });

    test('leaves other layers alone and ignores out-of-range pixels', () {
      const other = RigPart(id: 'o', boneId: 'A', layerKey: 'arm');
      final out = paint([other, whole], 'B', [-1, 9999, 2]);
      expect(out.first, other);
      expect(out.where((p) => p.layerKey == 'body'), hasLength(2));
    });

    test('brush is clipped to the canvas', () {
      expect(RigInfluencePaint.brush(0, 0, 3, w, h), hasLength(4));
      expect(RigInfluencePaint.brush(4, 4, 1, w, h), [4 * w + 4]);
    });
  });

  group('controller painting', () {
    late RigEditorController c;
    late String a, b;

    setUp(() {
      var n = 0;
      c = RigEditorController(
        rig: const Rig(id: 'r', stateId: 1),
        restLayers: [Layer(layerId: 0, id: 'l', name: 'body', pixels: opaque(), stableKey: 'body')],
        width: w,
        height: h,
        newId: () => 'id${n++}',
      );
      a = c.addBone(head: const Offset(4, 7), tail: const Offset(4, 4))!;
      b = c.addBone(head: const Offset(4, 4), tail: const Offset(4, 1), parentId: a)!;
      c.assignLayer('body', a);
    });

    test('a stroke gives pixels to the selected bone in one undo step', () {
      c.tool = RigTool.paintInfluence;
      c.selectBone(b);
      c.brushSize = 1;
      c.beginGesture();
      c.paintInfluence(const Offset(1.5, 1.5), const Offset(4.5, 1.5));
      c.endGesture();
      final parts = c.partsOfLayer('body');
      expect(parts.map((p) => p.boneId).toSet(), {a, b});
      expect(parts.firstWhere((p) => p.boneId == b).mask!.where((v) => v != 0), hasLength(4));
      c.undo();
      expect(c.partsOfLayer('body').single.boneId, a);
      expect(c.partsOfLayer('body').single.mask, isNull);
    });

    test('painting needs a selected bone unless erasing, and is setup-only', () {
      c.selectBone(null);
      expect(c.canPaintInfluence, isFalse);
      c.influenceErase = true;
      expect(c.canPaintInfluence, isTrue);
      c.mode = RigMode.animate;
      expect(c.canPaintInfluence, isFalse);
      c.tool = RigTool.paintInfluence;
      expect(c.tool, isNot(RigTool.paintInfluence));
    });

    test('painted split drives the bake: only painted pixels follow the new bone', () {
      c.selectBone(b);
      c.brushSize = 1;
      c.paintInfluence(const Offset(0.5, 0.5), const Offset(0.5, 0.5));
      c.mode = RigMode.animate;
      c.setTime(1);
      c.setPose(b, translation: const Offset(2, 0));
      c.setClipLength(3);
      final baker = RigBaker(rig: c.rig, width: w, height: h, layers: c.restLayers);
      final frame = baker.bakeFrame(c.activeClip, 1);
      expect(frame[0], 0, reason: 'painted pixel left its place');
      expect(frame[2], isNot(0), reason: '... and landed two pixels right');
      expect(frame[w * h - 1], isNot(0), reason: 'unpainted pixels stayed');
    });

    test('overlay covers each opaque pixel once, per bone', () {
      c.selectBone(b);
      c.brushSize = 2;
      c.paintInfluence(const Offset(1, 1), const Offset(1, 1));
      final overlay = c.influenceOverlay;
      expect(overlay.keys.toSet(), {a, b});
      expect(overlay[b]!.getBounds().width, greaterThan(0));
    });
  });

  group('auto-key', () {
    late RigEditorController c;
    late String id;

    setUp(() {
      c = RigEditorController(
        rig: const Rig(id: 'r', stateId: 1),
        restLayers: [Layer(layerId: 0, id: 'l', name: 'body', pixels: opaque(), stableKey: 'body')],
        width: w,
        height: h,
        newId: () => 'x',
      );
      id = c.addBone(head: const Offset(4, 7), tail: const Offset(4, 3))!;
      c.mode = RigMode.animate;
      c.setClipLength(4);
      c.setTime(2);
    });

    test('on by default: posing stores a key', () {
      expect(c.autoKey, isTrue);
      c.setPose(id, rotation: 20);
      expect(c.keyAt(id, 2)?.rotation, 20);
      expect(c.hasPendingPose, isFalse);
    });

    test('off: pose previews without keys or undo steps', () {
      c.autoKey = false;
      final rig = c.rig;
      c.setPose(id, rotation: 35);
      expect(c.poseOf(id).rotation, 35);
      expect(c.keyAt(id, 2), isNull);
      expect(c.rig, rig);
      expect(c.hasPendingPose, isTrue);
      expect(c.isPending(id), isTrue);
    });

    test('keyPending stores the preview as one undo step', () {
      c.autoKey = false;
      c.setPose(id, rotation: 35);
      c.keyPending();
      expect(c.keyAt(id, 2)?.rotation, 35);
      expect(c.hasPendingPose, isFalse);
      c.undo();
      expect(c.keyAt(id, 2), isNull);
    });

    test('changing frame, undo or discard drops the preview', () {
      c.autoKey = false;
      c.setPose(id, rotation: 35);
      c.setTime(3);
      expect(c.hasPendingPose, isFalse);
      expect(c.poseOf(id).rotation, 0);
      c.setPose(id, rotation: 10);
      c.discardPending();
      expect(c.poseOf(id).rotation, 0);
    });

    test('turning auto-key back on stores the pending pose', () {
      c.autoKey = false;
      c.setPose(id, rotation: 50);
      c.autoKey = true;
      expect(c.keyAt(id, 2)?.rotation, 50);
      expect(c.hasPendingPose, isFalse);
    });

    test('keyBone with auto-key off records the previewed pose over an existing key', () {
      c.setPose(id, rotation: 10);
      c.autoKey = false;
      c.setPose(id, rotation: 40);
      expect(c.keyAt(id, 2)?.rotation, 10);
      c.keyBone(id);
      expect(c.keyAt(id, 2)?.rotation, 40);
    });
  });
}
