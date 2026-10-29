import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/pixel_utils.dart';
import 'package:picell/pixel/rig/rotsprite.dart';

// rotSpriteWithBounds rotates free-standing buffers such as a canvas
// selection with the rig's RotSprite.
void main() {
  const r = 0xFFFF0000;

  group('rotSpriteWithBounds', () {
    // A 3×1 red line at (0, 0), rotated around its middle pixel's centre so
    // quarter turns land on whole pixels.
    final line = Uint32List.fromList([r, r, r]);
    const bounds = Rect.fromLTWH(0, 0, 3, 1);
    const center = Offset(1.5, 0.5);

    Rect rotatedBounds(double angle) {
      final corners = [bounds.topLeft, bounds.topRight, bounds.bottomLeft, bounds.bottomRight].map((p) {
        final d = p - center;
        return center +
            Offset(d.dx * math.cos(angle) - d.dy * math.sin(angle), d.dx * math.sin(angle) + d.dy * math.cos(angle));
      }).toList();
      final xs = corners.map((p) => p.dx), ys = corners.map((p) => p.dy);
      return Rect.fromLTRB(xs.reduce(math.min).floorToDouble(), ys.reduce(math.min).floorToDouble(),
          xs.reduce(math.max).ceilToDouble(), ys.reduce(math.max).ceilToDouble());
    }

    test('quarter turns match exact nearest-neighbour rotation', () {
      final target = rotatedBounds(math.pi / 2);
      final rot = rotSpriteWithBounds(line, 3, 1, math.pi / 2, bounds, target, center);
      final nearest = PixelUtils.applyRotationWithBounds(line, 3, 1, math.pi / 2, bounds, target, center, 0, 0);
      expect(rot, nearest);
      expect(rot.where((p) => p == r).length, 3);
    });

    test('never invents colours and keeps a diagonal line connected', () {
      const angle = math.pi / 4;
      final target = rotatedBounds(angle);
      final out = rotSpriteWithBounds(line, 3, 1, angle, bounds, target, center);
      expect(out.every((p) => p == 0 || p == r), isTrue);

      final w = target.width.round();
      final cells = [
        for (var i = 0; i < out.length; i++)
          if (out[i] == r) (i % w, i ~/ w),
      ];
      expect(cells.length, greaterThanOrEqualTo(2));
      // Every lit cell touches another one, diagonals included.
      for (final (x, y) in cells) {
        expect(cells.any((c) => c != (x, y) && (c.$1 - x).abs() <= 1 && (c.$2 - y).abs() <= 1), isTrue);
      }
    });

    test('fractional bounds sample like nearest-neighbour rotation does', () {
      // A shifted, unrotated buffer must come back unchanged.
      const shifted = Rect.fromLTWH(0.25, 0.25, 3, 1);
      final out = rotSpriteWithBounds(line, 3, 1, 0, shifted, shifted, center);
      expect(out, line);
    });

    test('empty bounds give an empty buffer', () {
      expect(rotSpriteWithBounds(line, 3, 1, 0.3, bounds, Rect.zero, center), isEmpty);
    });
  });
}
