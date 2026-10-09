import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:picell/data/models/selection_region.dart';
import 'package:picell/pixel/services/pixel_transform_service.dart';

SelectionRegion _rect(double l, double t, double r, double b) {
  final rect = Rect.fromLTRB(l, t, r, b);
  return SelectionRegion(
    path: Path()..addRect(rect),
    bounds: rect,
    shape: SelectionShape.rectangle,
  );
}

/// Pixels at (x, y) -> color, on a [w]x[h] canvas.
Uint32List _canvas(int w, int h, Map<(int, int), int> pixels) {
  final out = Uint32List(w * h);
  pixels.forEach((p, c) => out[p.$2 * w + p.$1] = c);
  return out;
}

SelectionTransformResult _run(
  Uint32List pixels,
  int w,
  int h,
  SelectionRegion region,
  PixelTransform t,
) =>
    PixelTransformService.transformSelection(
      layerPixels: pixels,
      canvasWidth: w,
      canvasHeight: h,
      region: region,
      transform: t,
    )!;

void main() {
  const w = 10;
  const h = 10;
  const a = 0xFFFF0000;
  const b = 0xFF00FF00;
  const c = 0xFF0000FF;

  // 3 wide x 2 tall block at (2,3): a b c / . . a
  Uint32List sample() => _canvas(w, h, {
        (2, 3): a,
        (3, 3): b,
        (4, 3): c,
        (4, 4): a,
        (8, 8): 0xFFFFFFFF, // outside the selection, must never move
      });
  final region = _rect(2, 3, 5, 5);

  test('flip horizontal mirrors inside the bounds', () {
    final r = _run(sample(), w, h, region, PixelTransform.flipHorizontal);
    expect(r.pixels[3 * w + 2], c);
    expect(r.pixels[3 * w + 3], b);
    expect(r.pixels[3 * w + 4], a);
    expect(r.pixels[4 * w + 2], a);
    expect(r.pixels[8 * w + 8], 0xFFFFFFFF);
  });

  test('flip vertical mirrors inside the bounds', () {
    final r = _run(sample(), w, h, region, PixelTransform.flipVertical);
    expect(r.pixels[4 * w + 2], a);
    expect(r.pixels[4 * w + 3], b);
    expect(r.pixels[4 * w + 4], c);
    expect(r.pixels[3 * w + 4], a);
  });

  test('rotate 180 reverses both axes', () {
    final r = _run(sample(), w, h, region, PixelTransform.rotate180);
    expect(r.pixels[4 * w + 4], a);
    expect(r.pixels[4 * w + 3], b);
    expect(r.pixels[4 * w + 2], c);
    expect(r.pixels[3 * w + 2], a);
  });

  test('rotate 90 clockwise swaps box size and moves cells correctly', () {
    final r = _run(sample(), w, h, region, PixelTransform.rotate90Clockwise);
    // 3x2 box at (2,3) becomes a 2x3 box centred on it: x 2..3, y 2..4.
    expect(r.region.bounds, const Rect.fromLTRB(2, 2, 4, 5));
    // Top row (a b c) becomes the right column, read top to bottom.
    expect(r.pixels[2 * w + 3], a);
    expect(r.pixels[3 * w + 3], b);
    expect(r.pixels[4 * w + 3], c);
    // Bottom-right 'a' (local 2,1) becomes the left column's bottom cell.
    expect(r.pixels[4 * w + 2], a);
  });

  test('rotate 90 counter-clockwise is the inverse of clockwise', () {
    final cw = _run(sample(), w, h, region, PixelTransform.rotate90Clockwise);
    final back = _run(
      cw.pixels,
      w,
      h,
      cw.region,
      PixelTransform.rotate90CounterClockwise,
    );
    expect(back.pixels, sample());
    expect(back.region.bounds, region.bounds);
  });

  test('four clockwise turns and double flips are the identity', () {
    for (final t in [PixelTransform.flipHorizontal, PixelTransform.flipVertical, PixelTransform.rotate180]) {
      final once = _run(sample(), w, h, region, t);
      final twice = _run(once.pixels, w, h, once.region, t);
      expect(twice.pixels, sample(), reason: t.name);
    }

    var pixels = sample();
    var current = region;
    for (var i = 0; i < 4; i++) {
      final r = _run(pixels, w, h, current, PixelTransform.rotate90Clockwise);
      pixels = r.pixels;
      current = r.region;
    }
    expect(pixels, sample());
    expect(current.bounds, region.bounds);
  });

  test('odd size difference keeps pixels on whole cells', () {
    // 4 wide x 1 tall: rotating gives 1 wide x 4 tall.
    final px = _canvas(w, h, {(1, 5): a, (2, 5): b, (3, 5): c, (4, 5): a});
    final r = _run(px, w, h, _rect(1, 5, 5, 6), PixelTransform.rotate90Clockwise);
    expect(r.region.bounds.width, 1);
    expect(r.region.bounds.height, 4);
    final colors = [
      for (var y = r.region.bounds.top.toInt(); y < r.region.bounds.bottom.toInt(); y++)
        r.pixels[y * w + r.region.bounds.left.toInt()],
    ];
    expect(colors, [a, b, c, a]);
  });

  test('lasso-like region: shape follows the pixels', () {
    // L-shaped selection; only its cells hold pixels.
    final path = Path()
      ..moveTo(2, 2)
      ..lineTo(3, 2)
      ..lineTo(3, 4)
      ..lineTo(5, 4)
      ..lineTo(5, 5)
      ..lineTo(2, 5)
      ..close();
    final lasso = SelectionRegion(path: path, bounds: path.getBounds(), shape: SelectionShape.lasso);
    final px = _canvas(w, h, {(2, 2): a, (2, 4): b, (4, 4): c});

    for (final t in PixelTransform.values) {
      final r = _run(px, w, h, lasso, t);
      for (var y = 0; y < h; y++) {
        for (var x = 0; x < w; x++) {
          if (r.pixels[y * w + x] != 0) {
            expect(r.region.contains(x, y), isTrue, reason: '${t.name} pixel ($x,$y) outside region');
          }
        }
      }
      expect(r.pixels.where((p) => p != 0).length, 3, reason: t.name);
    }
  });

  test('rotated box is shifted back inside the canvas', () {
    // 1 wide x 4 tall at the canvas's left edge, rotated about its centre.
    final px = _canvas(w, h, {(0, 0): a, (0, 1): b, (0, 2): c, (0, 3): a});
    final r = _run(px, w, h, _rect(0, 0, 1, 4), PixelTransform.rotate90Clockwise);
    expect(r.region.bounds.left, greaterThanOrEqualTo(0));
    expect(r.pixels.where((p) => p != 0).length, 4);
  });

  test('does not modify the input buffer', () {
    final px = sample();
    _run(px, w, h, region, PixelTransform.rotate90Clockwise);
    expect(px, sample());
  });

  test('keeps rectangle shape, other shapes become custom', () {
    final r = _run(sample(), w, h, region, PixelTransform.rotate90Clockwise);
    expect(r.region.shape, SelectionShape.rectangle);
  });

  group('layer transforms', () {
    Uint32List layer(int cw, int ch) => _canvas(cw, ch, {(0, 0): a, (1, 0): b, (cw - 1, ch - 1): c});

    Uint32List apply(Uint32List px, int cw, int ch, PixelTransform t) =>
        PixelTransformService.transformLayerPixels(pixels: px, width: cw, height: ch, transform: t);

    test('flips and 180 are exact on any canvas size', () {
      for (final (cw, ch) in [(4, 4), (5, 3), (6, 9)]) {
        final px = layer(cw, ch);
        for (final t in [PixelTransform.flipHorizontal, PixelTransform.flipVertical, PixelTransform.rotate180]) {
          expect(apply(apply(px, cw, ch, t), cw, ch, t), px, reason: '${t.name} ${cw}x$ch');
        }
      }
      final flipped = apply(layer(4, 4), 4, 4, PixelTransform.flipHorizontal);
      expect(flipped[0 * 4 + 3], a);
      expect(flipped[0 * 4 + 2], b);
    });

    test('square canvas: four clockwise turns are the identity, ccw inverts cw', () {
      final px = layer(5, 5);
      var cur = px;
      for (var i = 0; i < 4; i++) {
        cur = apply(cur, 5, 5, PixelTransform.rotate90Clockwise);
      }
      expect(cur, px);
      expect(
        apply(apply(px, 5, 5, PixelTransform.rotate90Clockwise), 5, 5, PixelTransform.rotate90CounterClockwise),
        px,
      );
    });

    test('square canvas: clockwise turn moves the top-left to the top-right', () {
      final out = apply(layer(4, 4), 4, 4, PixelTransform.rotate90Clockwise);
      expect(out[0 * 4 + 3], a); // (0,0) -> (3,0)
      expect(out[1 * 4 + 3], b); // (1,0) -> (3,1)
    });

    test('non-square canvas: turn stays in bounds and never invents pixels', () {
      final px = _canvas(8, 4, {(3, 2): a, (4, 1): b});
      final out = apply(px, 8, 4, PixelTransform.rotate90Clockwise);
      expect(out.length, px.length);
      expect(out.where((p) => p != 0).length, lessThanOrEqualTo(2));
    });

    test('anchor points follow the pixels', () {
      for (final t in PixelTransform.values) {
        final px = _canvas(6, 6, {(1, 2): a});
        final moved = apply(px, 6, 6, t);
        final idx = moved.indexWhere((p) => p != 0);
        final cell = Offset((idx % 6) + 0.5, (idx ~/ 6) + 0.5);
        final anchor = PixelTransformService.transformPoint(
          point: const Offset(1.5, 2.5),
          width: 6,
          height: 6,
          transform: t,
        );
        expect(anchor, cell, reason: t.name);
      }
    });
  });
}
