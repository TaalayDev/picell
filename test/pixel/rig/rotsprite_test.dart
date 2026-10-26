import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:picell/data/models/layer.dart';
import 'package:picell/data/models/rig/rig.dart';
import 'package:picell/pixel/rig/affine2.dart';
import 'package:picell/pixel/rig/part_rasterizer.dart';
import 'package:picell/pixel/rig/rig_baker.dart';
import 'package:picell/pixel/rig/rig_editor_controller.dart';
import 'package:picell/pixel/rig/rig_solver.dart';
import 'package:picell/pixel/rig/rotsprite.dart';

const w = 16, h = 16;

Uint32List stripe() {
  // A 1px vertical line, the case plain nearest sampling handles worst.
  final px = Uint32List(w * h);
  for (var y = 2; y < 14; y++) {
    px[y * w + 8] = 0xFFFF0000;
  }
  return px;
}

/// A filled, lopsided triangle: its slanted edges have the corners Scale2x
/// smooths, and it is not symmetric about the pivot.
Uint32List triangle() {
  final px = Uint32List(w * h);
  double edge(double ax, double ay, double bx, double by, double x, double y) =>
      (bx - ax) * (y - ay) - (by - ay) * (x - ax);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final cx = x + .5, cy = y + .5;
      final e1 = edge(3, 3, 14, 6, cx, cy), e2 = edge(14, 6, 5, 13, cx, cy), e3 = edge(5, 13, 3, 3, cx, cy);
      if (e1 >= 0 && e2 >= 0 && e3 >= 0) px[y * w + x] = 0xFFFF0000;
    }
  }
  return px;
}

int count(Uint32List p) => p.where((v) => v != 0).length;

void main() {
  group('scale2x', () {
    test('rounds an inside corner and leaves flat areas alone', () {
      // 3x3 with the middle pixel 1, up and left 2, right 3, down 4.
      final src = Uint32List.fromList([0, 2, 0, 2, 1, 3, 0, 4, 0]);
      final big = RotSpriteSource.scale2x(src, 3, 3);
      int at(int x, int y) => big[y * 6 + x];
      expect([at(2, 2), at(3, 2), at(2, 3), at(3, 3)], [2, 1, 1, 1]);

      final flat = Uint32List(9)..fillRange(0, 9, 7);
      expect(RotSpriteSource.scale2x(flat, 3, 3).every((v) => v == 7), isTrue);
    });

    test('a lone pixel stays a solid 2x2 block', () {
      final src = Uint32List(9)..[4] = 5;
      final big = RotSpriteSource.scale2x(src, 3, 3);
      expect([
        for (var y = 2; y < 4; y++)
          for (var x = 2; x < 4; x++) big[y * 6 + x]
      ], [
        5,
        5,
        5,
        5
      ]);
    });
  });

  group('RotSpriteSource.rasterize', () {
    test('identity, mirrors and quarter turns use the original pixels exactly', () {
      final src = stripe();
      final sprite = RotSpriteSource(src, w, h);
      for (final t in [
        Affine2.identity,
        Affine2.translation(2, 1),
        Affine2.flipX(8),
        Affine2.rotationAbout(90, const Offset(8, 8)),
        Affine2.rotationAbout(180, const Offset(8, 8)),
      ]) {
        expect(RotSpriteSource.isAxisAligned(t), isTrue, reason: '$t');
        expect(sprite.rasterize(t), PartRasterizer.rasterize(src, w, h, t), reason: '$t');
      }
    });

    test('other angles are not axis aligned', () {
      expect(RotSpriteSource.isAxisAligned(Affine2.rotation(45)), isFalse);
      expect(RotSpriteSource.isAxisAligned(Affine2.rotation(30)), isFalse);
    });

    test('never invents colours, and keeps a thin line as long as the original', () {
      final src = stripe();
      final sprite = RotSpriteSource(src, w, h);
      final t = Affine2.rotationAbout(30, const Offset(8, 8));
      final out = sprite.rasterize(t);
      expect(out.toSet().difference({0, 0xFFFF0000}), isEmpty);
      expect(count(out), inInclusiveRange(10, 16));
    });

    test('a 1px line rotated 45° stays connected', () {
      final src = Uint32List(w * h);
      for (var y = 2; y < 14; y++) {
        src[y * w + 8] = 1;
      }
      final t = Affine2.rotationAbout(45, const Offset(8, 8));
      bool connected(Uint32List p) {
        final pts = [
          for (var i = 0; i < p.length; i++)
            if (p[i] != 0) (i % w, i ~/ w)
        ];
        if (pts.isEmpty) return false;
        final seen = {pts.first};
        final queue = [pts.first];
        while (queue.isNotEmpty) {
          final (x, y) = queue.removeLast();
          for (final n in pts) {
            if (!seen.contains(n) && (n.$1 - x).abs() <= 1 && (n.$2 - y).abs() <= 1) {
              seen.add(n);
              queue.add(n);
            }
          }
        }
        return seen.length == pts.length;
      }

      expect(connected(RotSpriteSource(src, w, h).rasterize(t)), isTrue);
    });

    test('respects the mask without bleeding the neighbour colour', () {
      final src = Uint32List(w * h);
      for (var x = 4; x < 12; x++) {
        src[8 * w + x] = x < 8 ? 1 : 2;
      }
      final mask = Uint8List(w * h);
      for (var x = 4; x < 8; x++) {
        mask[8 * w + x] = 1;
      }
      final out = RotSpriteSource(src, w, h, mask: mask).rasterize(Affine2.rotationAbout(30, const Offset(6, 8)));
      expect(out.toSet().difference({0, 1}), isEmpty);
    });

    test('a collapsing transform draws nothing, and bad sizes are refused', () {
      final sprite = RotSpriteSource(stripe(), w, h);
      expect(count(sprite.rasterize(const Affine2(0, 0, 0, 0, 0, 0))), 0);
      expect(() => RotSpriteSource(Uint32List(3), w, h), throwsArgumentError);
    });

    test('big canvases get a smaller enlargement', () {
      expect(RotSpriteSource.factorFor(64, 96), 8);
      expect(RotSpriteSource.factorFor(200, 200), 4);
      expect(RotSpriteSource.factorFor(512, 512), 2);
    });
  });

  group('rig integration', () {
    Layer layer() => Layer(layerId: 0, id: 'l', name: 'l', pixels: triangle(), stableKey: 'k');

    Rig rig(RigRotationMode mode, {double? boneSnap, double rigSnap = 0}) => Rig(
          id: 'r',
          stateId: 1,
          bones: [Bone(id: 'a', name: 'a', head: const Offset(8, 8), length: 5, snapAngle: boneSnap)],
          parts: const [RigPart(id: 'p', boneId: 'a', layerKey: 'k')],
          settings: RigSettings(rotationMode: mode, snapAngleDegrees: rigSnap),
          clips: const [
            RigClip(id: 'c', name: 'c', length: 2, keyframes: [RigKeyframe(time: 0, boneId: 'a', rotation: 30)]),
          ],
        );

    test('the rig setting chooses the rasterizer; quarter turns agree', () {
      final nearest = RigBaker(rig: rig(RigRotationMode.nearest), width: w, height: h, layers: [layer()]);
      final smooth = RigBaker(rig: rig(RigRotationMode.rotsprite), width: w, height: h, layers: [layer()]);
      final clip = nearest.rig.clips.single;
      final a = smooth.bakeFrame(clip, 0), b = nearest.bakeFrame(clip, 0);
      expect(a, isNot(b), reason: 'the slanted edges are smoothed differently');
      expect(a.toSet().difference({0, 0xFFFF0000}), isEmpty);

      final quarter = clip.copyWith(keyframes: [const RigKeyframe(time: 0, boneId: 'a', rotation: 90)]);
      expect(smooth.bakeFrame(quarter, 0), nearest.bakeFrame(quarter, 0));
    });

    test('settings round trip through json and default to nearest', () {
      const s = RigSettings(rotationMode: RigRotationMode.rotsprite, snapAngleDegrees: 15);
      expect(RigSettings.fromJson(s.toJson()), s);
      expect(RigSettings.fromJson(const {}).rotationMode, RigRotationMode.nearest);
      expect(const RigSettings().toJson().containsKey('rotationMode'), isFalse);
    });
  });

  group('per-bone angle snap', () {
    const base = Bone(id: 'a', name: 'a', head: Offset(0, 0), length: 4);
    double angleOf(Bone b, double rot, double rigSnap) {
      final t = RigSolver.localTransform(b, BonePose(rotation: rot), rigSnap);
      return t.apply(const Offset(1, 0)).direction * 180 / 3.141592653589793;
    }

    test('a bone setting overrides the rig, and 0 switches snapping off', () {
      expect(angleOf(base, 37, 15), closeTo(30, 1e-6));
      expect(angleOf(base.copyWith(snapAngle: () => 90), 37, 15), closeTo(0, 1e-6));
      expect(angleOf(base.copyWith(snapAngle: () => 45), 37, 0), closeTo(45, 1e-6));
      expect(angleOf(base.copyWith(snapAngle: () => 0), 37, 15), closeTo(37, 1e-6));
    });

    test('snapping never carries a bone past its limits', () {
      final limited = base.copyWith(snapAngle: () => 45, maxAngle: () => 30);
      expect(angleOf(limited, 28, 0), closeTo(30, 1e-6));
    });

    test('json round trip', () {
      final b = base.copyWith(snapAngle: () => 22.5);
      expect(Bone.fromJson(b.toJson()), b);
      expect(Bone.fromJson(base.toJson()).snapAngle, isNull);
    });
  });

  group('controller', () {
    test('snap and rotation mode are edited with undo', () {
      final c = RigEditorController(rig: const Rig(id: 'r', stateId: 1), restLayers: const [], width: w, height: h);
      final id = c.addBone(head: const Offset(4, 4), tail: const Offset(4, 9))!;
      c.setBoneSnap(id, 45);
      expect(c.bone(id)!.snapAngle, 45);
      c.setBoneSnap(id, null);
      expect(c.bone(id)!.snapAngle, isNull);
      c.setBoneSnap(id, -5);
      expect(c.bone(id)!.snapAngle, isNull, reason: 'negative steps are refused');

      c.setRigSnap(15);
      c.setRotationMode(RigRotationMode.rotsprite);
      expect(c.rig.settings.snapAngleDegrees, 15);
      expect(c.rig.settings.rotationMode, RigRotationMode.rotsprite);
      c.undo();
      expect(c.rig.settings.rotationMode, RigRotationMode.nearest);
      expect(c.rig.settings.snapAngleDegrees, 15);
    });
  });
}
