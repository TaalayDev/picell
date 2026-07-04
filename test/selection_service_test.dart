import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:picell/data/models/selection_region.dart';
import 'package:picell/pixel/services/selection_service.dart';

SelectionRegion _rectRegion(double l, double t, double w, double h) {
  final rect = Rect.fromLTWH(l, t, w, h);
  return SelectionRegion(path: Path()..addRect(rect), bounds: rect, shape: SelectionShape.rectangle);
}

Set<int> _selectedCells(SelectionRegion region, int w, int h) {
  return region.getSelectedPixelIndices(w, h).toSet();
}

void main() {
  group('growSelection / shrinkSelection', () {
    final service = SelectionService(width: 16, height: 16);

    test('grow expands a rect by 1px ring (8-neighborhood)', () {
      final grown = service.growSelection(_rectRegion(4, 4, 2, 2));
      final cells = _selectedCells(grown, 16, 16);

      // 2x2 at (4,4) grows to 4x4 at (3,3).
      expect(cells.length, 16);
      expect(cells.contains(3 * 16 + 3), isTrue); // corner (3,3) — Chebyshev
      expect(cells.contains(6 * 16 + 6), isTrue);
      expect(cells.contains(2 * 16 + 3), isFalse);
    });

    test('grow clamps at canvas edge', () {
      final grown = service.growSelection(_rectRegion(0, 0, 2, 2));
      final cells = _selectedCells(grown, 16, 16);
      expect(cells.length, 9); // 3x3 — nothing beyond the edge
      expect(cells.contains(0), isTrue);
    });

    test('shrink is the inverse of grow for interior rects', () {
      final region = _rectRegion(4, 4, 4, 4);
      final roundTrip = service.shrinkSelection(service.growSelection(region));
      expect(_selectedCells(roundTrip, 16, 16), _selectedCells(region, 16, 16));
    });

    test('shrink of a 1px-wide region becomes empty', () {
      final shrunk = service.shrinkSelection(_rectRegion(4, 4, 1, 5));
      expect(shrunk.bounds, Rect.zero);
    });

    test('edge-flush selection does not erode from the flush edge', () {
      // 3-wide strip flush against the left edge.
      final shrunk = service.shrinkSelection(_rectRegion(0, 4, 3, 8));
      final cells = _selectedCells(shrunk, 16, 16);

      // Left column survives (edge counts as selected); right column erodes.
      expect(cells.contains(5 * 16 + 0), isTrue);
      expect(cells.contains(5 * 16 + 1), isTrue);
      expect(cells.contains(5 * 16 + 2), isFalse);
      // Top/bottom rows of the strip erode.
      expect(cells.contains(4 * 16 + 0), isFalse);
    });
  });

  group('createWandSelection', () {
    final service = SelectionService(width: 8, height: 8);

    Uint32List twoIslands() {
      // Red 2x2 island at (0,0) and another red 2x2 island at (5,5),
      // transparent elsewhere.
      final pixels = Uint32List(64);
      for (final (x, y) in [(0, 0), (1, 0), (0, 1), (1, 1)]) {
        pixels[y * 8 + x] = 0xFFFF0000;
      }
      for (final (x, y) in [(5, 5), (6, 5), (5, 6), (6, 6)]) {
        pixels[y * 8 + x] = 0xFFFF0000;
      }
      return pixels;
    }

    test('contiguous selects only the tapped island', () {
      final region = service.createWandSelection(pixels: twoIslands(), x: 0, y: 0, w: 8, h: 8);
      final cells = _selectedCells(region, 8, 8);
      expect(cells, {0, 1, 8, 9});
    });

    test('non-contiguous selects both islands (select-by-color)', () {
      final region = service.createWandSelection(pixels: twoIslands(), x: 0, y: 0, w: 8, h: 8, contiguous: false);
      final cells = _selectedCells(region, 8, 8);
      expect(cells, {0, 1, 8, 9, 5 * 8 + 5, 5 * 8 + 6, 6 * 8 + 5, 6 * 8 + 6});
    });

    test('tolerance 0 is exact match; boundary is inclusive', () {
      final pixels = Uint32List(64);
      pixels[0] = 0xFF000000;
      pixels[1] = 0xFF000005; // distance 5 from pixels[0]

      final exact = service.createWandSelection(pixels: pixels, x: 0, y: 0, w: 8, h: 8);
      expect(_selectedCells(exact, 8, 8), {0});

      final tolerant = service.createWandSelection(pixels: pixels, x: 0, y: 0, w: 8, h: 8, tolerance: 5);
      expect(_selectedCells(tolerant, 8, 8).containsAll({0, 1}), isTrue);
    });
  });

  group('SelectionRegion.combine', () {
    test('add of disjoint rects contains both', () {
      final combined = _rectRegion(0, 0, 2, 2).combine(_rectRegion(5, 5, 2, 2), SelectionMode.add);
      expect(combined.contains(0, 0), isTrue);
      expect(combined.contains(6, 6), isTrue);
      expect(combined.contains(3, 3), isFalse);
    });

    test('subtract punches a hole', () {
      final combined = _rectRegion(0, 0, 6, 6).combine(_rectRegion(2, 2, 2, 2), SelectionMode.subtract);
      expect(combined.contains(0, 0), isTrue);
      expect(combined.contains(2, 2), isFalse);
      expect(combined.contains(3, 3), isFalse);
      expect(combined.contains(5, 5), isTrue);
    });

    test('subtract-all yields empty bounds', () {
      final combined = _rectRegion(2, 2, 2, 2).combine(_rectRegion(0, 0, 8, 8), SelectionMode.subtract);
      expect(combined.bounds.isEmpty, isTrue);
    });
  });

  group('invertSelection', () {
    test('double invert restores membership', () {
      final service = SelectionService(width: 8, height: 8);
      final original = _rectRegion(2, 2, 3, 3);
      final doubleInverted = service.invertSelection(service.invertSelection(original));

      for (int y = 0; y < 8; y++) {
        for (int x = 0; x < 8; x++) {
          expect(doubleInverted.contains(x, y), original.contains(x, y), reason: '($x,$y)');
        }
      }
    });
  });
}
