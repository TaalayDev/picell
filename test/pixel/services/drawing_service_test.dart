import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/pixel_point.dart';
import 'package:picell/pixel/services/drawing_service.dart';

void main() {
  final service = DrawingService();

  test('semi-transparent drawing blends over an existing pixel', () {
    const destination = Color(0xFF0000FF);
    const source = Color(0x80FF0000);

    final result = service.setPixel(
      pixels: Uint32List.fromList([destination.toARGB32()]),
      x: 0,
      y: 0,
      width: 1,
      height: 1,
      color: source,
    );

    expect(
      result.single,
      Color.alphaBlend(source, destination).toARGB32(),
    );
    expect((result.single >>> 24) & 0xFF, 0xFF);
  });

  test('zero-opacity drawing is a no-op unless erasing', () {
    const destination = Color(0xFF336699);
    final pixels = Uint32List.fromList([destination.toARGB32()]);

    final painted = service.setPixel(
      pixels: pixels,
      x: 0,
      y: 0,
      width: 1,
      height: 1,
      color: Colors.transparent,
    );
    final erased = service.setPixel(
      pixels: pixels,
      x: 0,
      y: 0,
      width: 1,
      height: 1,
      color: Colors.transparent,
      erase: true,
    );

    expect(painted.single, destination.toARGB32());
    expect(erased.single, 0);
  });

  test('shape pixels use the same source-over compositing', () {
    const destination = Color(0xFF00FF00);
    const source = Color(0x400000FF);
    final pixels = Uint32List.fromList([destination.toARGB32()]);

    service.fillPixelsMutable(
      pixels: pixels,
      points: [PixelPoint(0, 0, color: source.toARGB32())],
      width: 1,
      color: source,
    );

    expect(
      pixels.single,
      Color.alphaBlend(source, destination).toARGB32(),
    );
  });

  test('flood fill composites once and terminates for transparent colors', () {
    const destination = Color(0xFFFFFFFF);
    const source = Color(0x80000000);
    final pixels = Uint32List.fromList([
      destination.toARGB32(),
      destination.toARGB32(),
    ]);

    final blended = service.floodFill(
      pixels: pixels,
      x: 0,
      y: 0,
      width: 2,
      height: 1,
      fillColor: source,
    );
    final unchanged = service.floodFill(
      pixels: pixels,
      x: 0,
      y: 0,
      width: 2,
      height: 1,
      fillColor: Colors.transparent,
    );

    expect(
      blended,
      everyElement(Color.alphaBlend(source, destination).toARGB32()),
    );
    expect(unchanged, orderedEquals(pixels));
  });
}
