import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';

extension ListIntX on List<int> {
  int max() {
    if (isEmpty) return 0;
    return reduce((value, element) => value > element ? value : element);
  }

  int min() {
    if (isEmpty) return 0;
    return reduce((value, element) => value < element ? value : element);
  }

  double average() {
    if (isEmpty) return 0;
    return fold(0, (sum, element) => sum + element) / length;
  }
}

extension ListX<T> on List<T> {
  List<T> mapIndexed(T Function(int index, T item) f) {
    return asMap().entries.map((e) => f(e.key, e.value)).toList();
  }
}

extension Uint32ListX on Uint32List {
  /// Creates a deep copy of the Uint32List
  Uint32List copy() {
    return Uint32List.fromList(this);
  }

  /// Copies a section of pixels from source to destination
  void copyArea({
    required Uint32List source,
    required int sourceWidth,
    required int destWidth,
    required int srcX,
    required int srcY,
    required int destX,
    required int destY,
    required int width,
    required int height,
  }) {
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final srcIndex = (srcY + y) * sourceWidth + (srcX + x);
        final destIndex = (destY + y) * destWidth + (destX + x);

        // Check bounds for both source and destination
        if (srcIndex >= 0 && srcIndex < source.length && destIndex >= 0 && destIndex < this.length) {
          this[destIndex] = source[srcIndex];
        }
      }
    }
  }

  /// Clears a rectangular area by setting all pixels to transparent
  void clearArea({
    required int canvasWidth,
    required int x,
    required int y,
    required int width,
    required int height,
  }) {
    for (int iy = 0; iy < height; iy++) {
      for (int ix = 0; ix < width; ix++) {
        final index = (y + iy) * canvasWidth + (x + ix);
        if (index >= 0 && index < this.length) {
          this[index] = 0; // Transparent
        }
      }
    }
  }

  /// Extract pixels in a selection area into a separate Uint32List
  Uint32List extractArea(
      {required int canvasWidth, required int x, required int y, required int width, required int height}) {
    final result = Uint32List(width * height);
    for (int iy = 0; iy < height; iy++) {
      for (int ix = 0; ix < width; ix++) {
        final sourceIndex = (y + iy) * canvasWidth + (x + ix);
        final targetIndex = iy * width + ix;
        if (sourceIndex >= 0 && sourceIndex < this.length && targetIndex >= 0 && targetIndex < result.length) {
          result[targetIndex] = this[sourceIndex];
        }
      }
    }
    return result;
  }
}

extension PointX on Point<int> {
  /// Checks if this point is inside the given rectangle
  bool isInRect(int x, int y, int width, int height) {
    return this.x >= x && this.x < x + width && this.y >= y && this.y < y + height;
  }

  /// Offsets a point by given delta
  Point<int> offset(int dx, int dy) {
    return Point<int>(this.x + dx, this.y + dy);
  }
}


extension StringX on String {
  String capitalize() {
    return isNotEmpty ? '${this[0].toUpperCase()}${substring(1)}' : '';
  }
}
