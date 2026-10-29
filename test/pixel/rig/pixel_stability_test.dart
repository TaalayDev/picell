import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:picell/data/models/layer.dart';
import 'package:picell/data/models/rig/rig.dart';
import 'package:picell/pixel/rig/affine2.dart';
import 'package:picell/pixel/rig/part_rasterizer.dart';
import 'package:picell/pixel/rig/rig_baker.dart';
import 'package:picell/pixel/rig/rotsprite.dart';

// Posed pixel art must not fall apart: limbs stay attached at their joints,
// thin lines stay unbroken, and nothing that does not move flickers.
void main() {
  // Big enough that the whole arm stays on the canvas through every sweep.
  const w = 48, h = 48;
  const colorA = 0xFFAA0000, colorB = 0xFF00BB00, colorC = 0xFF0000CC;

  // A horizontal 1px line on row [y] from [x0] to [x1], on its own layer.
  Layer line(String key, int x0, int x1, int y, int color) => Layer(
        layerId: 0,
        id: 'id-$key',
        name: key,
        stableKey: key,
        pixels: Uint32List.fromList([
          for (var i = 0; i < w * h; i++) (i ~/ w == y && i % w >= x0 && i % w <= x1) ? color : 0,
        ]),
      );

  // 8-connected groups of opaque pixels.
  int components(Uint32List px, {int? only}) {
    bool lit(int i) => only == null ? px[i] != 0 : px[i] == only;
    final seen = <int>{};
    var n = 0;
    for (var i = 0; i < px.length; i++) {
      if (!lit(i) || !seen.add(i)) continue;
      n++;
      final stack = [i];
      while (stack.isNotEmpty) {
        final c = stack.removeLast();
        for (var dy = -1; dy <= 1; dy++) {
          for (var dx = -1; dx <= 1; dx++) {
            final x = c % w + dx, y = c ~/ w + dy;
            if (x < 0 || y < 0 || x >= w || y >= h) continue;
            final j = y * w + x;
            if (lit(j) && seen.add(j)) stack.add(j);
          }
        }
      }
    }
    return n;
  }

  // Upper arm 16.5→23.5 on row 24, forearm 23.5→29.5, hand 29.5→32.5.
  const upper = Bone(id: 'u', name: 'u', head: Offset(16.5, 24.5), length: 7);
  const lower = Bone(id: 'l', name: 'l', parentId: 'u', head: Offset(23.5, 24.5), length: 6);
  const hand = Bone(id: 'h', name: 'h', parentId: 'l', head: Offset(29.5, 24.5), length: 3);
  final layers = [line('u', 16, 22, 24, colorA), line('l', 23, 28, 24, colorB), line('h', 29, 31, 24, colorC)];

  Rig arm(RigRotationMode mode) => Rig(
        id: 'r',
        stateId: 1,
        bones: const [upper, lower, hand],
        parts: const [
          RigPart(id: 'pu', boneId: 'u', layerKey: 'u'),
          RigPart(id: 'pl', boneId: 'l', layerKey: 'l', drawOrder: 1),
          RigPart(id: 'ph', boneId: 'h', layerKey: 'h', drawOrder: 2),
        ],
        settings: RigSettings(rotationMode: mode),
      );

  for (final mode in RigRotationMode.values) {
    group('${mode.name} rotation', () {
      test('a chain stays attached through a full sweep', () {
        // Upper arm turns 0→120°, forearm -60°→60°, hand 0→-90°, one frame per
        // degree or so: every in-between angle is visited.
        const clip = RigClip(id: 'c', name: 'c', length: 121, keyframes: [
          RigKeyframe(time: 0, boneId: 'u'),
          RigKeyframe(time: 120, boneId: 'u', rotation: 120),
          RigKeyframe(time: 0, boneId: 'l', rotation: -60),
          RigKeyframe(time: 120, boneId: 'l', rotation: 60),
          RigKeyframe(time: 0, boneId: 'h'),
          RigKeyframe(time: 120, boneId: 'h', rotation: -90),
        ]);
        final baker = RigBaker(rig: arm(mode), width: w, height: h, layers: layers);
        for (var t = 0; t < clip.length; t++) {
          final px = baker.bakeFrame(clip, t.toDouble());
          expect(components(px), 1, reason: 'frame $t came apart');
          for (final color in [colorA, colorB, colorC]) {
            expect(components(px, only: color), 1, reason: 'frame $t broke a part');
          }
          expect(px.every((p) => p == 0 || p == colorA || p == colorB || p == colorC), isTrue);
        }
      });

      test('the joint pixel stays put while its bone turns', () {
        const clip = RigClip(id: 'c', name: 'c', length: 91, keyframes: [
          RigKeyframe(time: 0, boneId: 'u'),
          RigKeyframe(time: 90, boneId: 'u', rotation: 90),
        ]);
        final baker = RigBaker(rig: arm(mode), width: w, height: h, layers: layers);
        for (var t = 0; t < clip.length; t++) {
          expect(baker.bakeFrame(clip, t.toDouble())[24 * w + 16], colorA, reason: 'frame $t');
        }
      });

      test('a part whose bone does not move never changes', () {
        // Only the hand turns; the upper arm and forearm must not flicker.
        const clip = RigClip(id: 'c', name: 'c', length: 46, keyframes: [
          RigKeyframe(time: 0, boneId: 'u', rotation: 30),
          RigKeyframe(time: 0, boneId: 'l', rotation: 17),
          RigKeyframe(time: 0, boneId: 'h'),
          RigKeyframe(time: 45, boneId: 'h', rotation: 45),
        ]);
        final baker = RigBaker(rig: arm(mode), width: w, height: h, layers: layers);
        List<int> still(Uint32List px) => [for (final p in px) p == colorA || p == colorB ? p : 0];
        final first = still(baker.bakeFrame(clip, 0));
        for (var t = 1; t < clip.length; t++) {
          expect(still(baker.bakeFrame(clip, t.toDouble())), first, reason: 'frame $t');
        }
      });
    });
  }

  group('rasterizers', () {
    final source = line('x', 10, 21, 16, colorA).pixels;
    const pivot = Offset(15.5, 16.5);

    test('a thin line stays unbroken at every angle', () {
      final sprite = RotSpriteSource(source, w, h);
      for (var degrees = 0; degrees <= 180; degrees += 5) {
        final t = Affine2.rotationAbout(degrees.toDouble(), pivot);
        for (final out in [PartRasterizer.rasterize(source, w, h, t), sprite.rasterize(t)]) {
          expect(components(out), 1, reason: '$degrees°');
          expect(out.every((p) => p == 0 || p == colorA), isTrue);
        }
      }
    });

    test('filling never touches pixels sampling already covered', () {
      for (final degrees in [0.0, 90.0, 180.0, 270.0]) {
        final t = Affine2.rotationAbout(degrees, pivot);
        final out = PartRasterizer.rasterize(source, w, h, t);
        expect(out.where((p) => p == colorA).length, 12, reason: 'quarter turns are exact');
      }
    });

    test('nothing outside the mask is filled in', () {
      final mask = Uint8List(w * h);
      for (var x = 10; x <= 15; x++) {
        mask[16 * w + x] = 1;
      }
      final out = PartRasterizer.rasterize(source, w, h, Affine2.rotationAbout(33, pivot), mask: mask);
      // The six masked pixels, at most a couple doubled up where they turn.
      final lit = out.where((p) => p != 0).length;
      expect(lit, inInclusiveRange(5, 8));
      expect(components(out), 1);
    });
  });
}
