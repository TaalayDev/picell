import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/services/clipboard_placement_service.dart';

void main() {
  test('preserves coordinates for equal-sized canvases', () {
    final source = Uint32List.fromList([
      1,
      2,
      3,
      4,
    ]);

    final result = placeClipboardPixels(
      source: source,
      sourceWidth: 2,
      sourceHeight: 2,
      targetWidth: 2,
      targetHeight: 2,
    );

    expect(result.pixels, source);
    expect(result.offset.dx, 0);
    expect(result.offset.dy, 0);
  });

  test('centers a smaller source without scaling it', () {
    final result = placeClipboardPixels(
      source: Uint32List.fromList([1, 2, 3, 4]),
      sourceWidth: 2,
      sourceHeight: 2,
      targetWidth: 4,
      targetHeight: 4,
    );

    expect(result.offset.dx, 1);
    expect(result.offset.dy, 1);
    expect(
      result.pixels,
      Uint32List.fromList([
        0,
        0,
        0,
        0,
        0,
        1,
        2,
        0,
        0,
        3,
        4,
        0,
        0,
        0,
        0,
        0,
      ]),
    );
  });

  test('clips a larger source to the target canvas', () {
    final result = placeClipboardPixels(
      source: Uint32List.fromList([
        1,
        2,
        3,
        4,
        5,
        6,
        7,
        8,
        9,
        10,
        11,
        12,
        13,
        14,
        15,
        16,
      ]),
      sourceWidth: 4,
      sourceHeight: 4,
      targetWidth: 2,
      targetHeight: 2,
    );

    expect(result.offset.dx, -1);
    expect(result.offset.dy, -1);
    expect(result.pixels, Uint32List.fromList([6, 7, 10, 11]));
  });
}
