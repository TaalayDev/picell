import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/rig/affine2.dart';
import 'package:picell/pixel/rig/part_rasterizer.dart';

import 'rig_test_support.dart';

void main() {
  const w = 4, h = 4;
  final sprite = parseGrid([
    '....',
    '.RG.',
    '.BY.',
    '....',
  ]);
  List<String> draw(Affine2 t, {Uint8List? mask}) =>
      renderGrid(PartRasterizer.rasterize(sprite, w, h, t, mask: mask), w);

  test('identity reproduces the source in a new buffer', () {
    final out = PartRasterizer.rasterize(sprite, w, h, Affine2.identity);
    expect(out, sprite);
    expect(identical(out, sprite), isFalse);
  });

  test('whole-pixel translation shifts exactly and clips at the edge', () {
    expect(draw(Affine2.translation(1, 1)), [
      '....',
      '....',
      '..RG',
      '..BY',
    ]);
    expect(draw(Affine2.translation(-2, 0)), [
      '....',
      'G...',
      'Y...',
      '....',
    ]);
  });

  test('a quarter turn about the sprite centre is exact', () {
    // Clockwise 90 degrees about the canvas centre (2,2).
    expect(draw(Affine2.rotationAbout(90, const Offset(2, 2))), [
      '....',
      '.BR.',
      '.YG.',
      '....',
    ]);
    expect(draw(Affine2.rotationAbout(180, const Offset(2, 2))), [
      '....',
      '.YB.',
      '.GR.',
      '....',
    ]);
  });

  test('flipX mirrors about the canvas centre', () {
    expect(draw(Affine2.flipX(2)), [
      '....',
      '.GR.',
      '.YB.',
      '....',
    ]);
  });

  test('output only contains source colours (no blending)', () {
    final out = PartRasterizer.rasterize(sprite, w, h, Affine2.rotationAbout(37, const Offset(2, 2)));
    final allowed = {0, ...sprite};
    expect(out.every(allowed.contains), isTrue);
  });

  test('a mask limits which source pixels are drawn', () {
    final mask = Uint8List(w * h)
      ..[1 * w + 1] = 1 // R
      ..[2 * w + 2] = 1; // Y
    expect(draw(Affine2.identity, mask: mask), [
      '....',
      '.R..',
      '..Y.',
      '....',
    ]);
  });

  test('a collapsing transform draws nothing', () {
    expect(PartRasterizer.rasterize(sprite, w, h, const Affine2(0, 0, 0, 0, 0, 0)).every((p) => p == 0), isTrue);
  });

  test('inputs are never modified', () {
    final before = Uint32List.fromList(sprite);
    final mask = Uint8List(w * h)..fillRange(0, w * h, 1);
    PartRasterizer.rasterize(sprite, w, h, Affine2.rotation(45), mask: mask);
    expect(sprite, before);
    expect(mask.every((m) => m == 1), isTrue);
  });

  test('mismatched buffer sizes are rejected', () {
    expect(() => PartRasterizer.rasterize(Uint32List(3), w, h, Affine2.identity), throwsArgumentError);
    expect(
      () => PartRasterizer.rasterize(sprite, w, h, Affine2.identity, mask: Uint8List(2)),
      throwsArgumentError,
    );
  });
}
