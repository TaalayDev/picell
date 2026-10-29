import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:picell/data/models/selection_region.dart';
import 'package:picell/pixel/gradient/gradient_mask.dart';
import 'package:picell/pixel/gradient/gradient_options.dart';

void main() {
  // 4×3 canvas:   A A B A
  //               A B B A
  //               A A A A      (B splits nothing; all A's are connected)
  const a = 0xFF0000FF, b = 0xFFFF0000;
  final pixels = Uint32List.fromList([a, a, b, a, a, b, b, a, a, a, a, a]);

  SelectionRegion rect(double x, double y, double w, double h) => SelectionRegion(
        path: Path()..addRect(Rect.fromLTWH(x, y, w, h)),
        bounds: Rect.fromLTWH(x, y, w, h),
        shape: SelectionShape.rectangle,
      );

  Uint8List? build(GradientTarget target, int sx, int sy, {SelectionRegion? selection}) => GradientMask.build(
        pixels: pixels,
        width: 4,
        height: 3,
        target: target,
        seedX: sx,
        seedY: sy,
        selection: selection,
      );

  test('whole layer without selection needs no mask', () {
    expect(build(GradientTarget.layer, 0, 0), isNull);
  });

  test('selection rasterises at pixel centres', () {
    final mask = build(GradientTarget.layer, 0, 0, selection: rect(1, 0, 2, 2));
    expect(mask, [0, 1, 1, 0, 0, 1, 1, 0, 0, 0, 0, 0]);
  });

  test('contiguous is 4-connected and exact-colour', () {
    expect(build(GradientTarget.contiguous, 2, 0), [0, 0, 1, 0, 0, 1, 1, 0, 0, 0, 0, 0]);
    expect(build(GradientTarget.contiguous, 0, 0), [1, 1, 0, 1, 1, 0, 0, 1, 1, 1, 1, 1]);
  });

  test('contiguous is clipped to the selection', () {
    final mask = build(GradientTarget.contiguous, 0, 0, selection: rect(0, 0, 2, 3));
    expect(mask, [1, 1, 0, 0, 1, 0, 0, 0, 1, 1, 0, 0]);
  });

  test('seed outside the canvas paints nothing', () {
    expect(build(GradientTarget.contiguous, -1, 0)!.every((v) => v == 0), isTrue);
    expect(build(GradientTarget.contiguous, 4, 2)!.every((v) => v == 0), isTrue);
  });
}
