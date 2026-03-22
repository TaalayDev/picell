import 'dart:collection';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../data/models/selection_region.dart';
import '../pixel_point.dart';
import '../tools.dart';
import '../tools/mirror_modifier.dart';

class DrawingService {
  void setPixelMutable({
    required Uint32List pixels,
    required int x,
    required int y,
    required int width,
    required int height,
    required Color color,
    SelectionRegion? selection,
  }) {
    if (!_isWithinBounds(x, y, width, height)) return;
    if (!_isInSelection(x, y, selection)) return;

    final index = y * width + x;
    pixels[index] = color.value;
  }

  void fillPixelsMutable({
    required Uint32List pixels,
    required List<PixelPoint<int>> points,
    required int width,
    required Color color,
    SelectionRegion? selection,
  }) {
    for (final point in points) {
      final index = point.y * width + point.x;
      if (index >= 0 && index < pixels.length && _isInSelection(point.x, point.y, selection)) {
        pixels[index] = point.color;
      }
    }
  }

  bool _isWithinBounds(int x, int y, int width, int height) {
    return x >= 0 && x < width && y >= 0 && y < height;
  }

  bool _isInSelection(int x, int y, SelectionRegion? selection) {
    if (selection == null) return true;
    return selection.contains(x, y);
  }

  Uint32List setPixel({
    required Uint32List pixels,
    required int x,
    required int y,
    required int width,
    required int height,
    required Color color,
    SelectionRegion? selection,
    Modifier? modifier,
  }) {
    if (!_isWithinBounds(x, y, width, height)) return pixels;
    if (!_isInSelection(x, y, selection)) return pixels;

    final newPixels = Uint32List.fromList(pixels);
    final index = y * width + x;
    newPixels[index] = color.value;

    // Apply modifier if present
    if (modifier != null && !modifier.isNone) {
      final modifierPoints = modifier.apply(
        PixelPoint(x, y, color: color.value),
        width,
        height,
      );

      for (final point in modifierPoints) {
        if (_isWithinBounds(point.x, point.y, width, height) && _isInSelection(point.x, point.y, selection)) {
          final modIndex = point.y * width + point.x;
          newPixels[modIndex] = point.color;
        }
      }
    }

    return newPixels;
  }

  Uint32List fillPixels({
    required Uint32List pixels,
    required List<PixelPoint<int>> points,
    required int width,
    required Color color,
    SelectionRegion? selection,
  }) {
    final newPixels = Uint32List.fromList(pixels);

    for (final point in points) {
      final index = point.y * width + point.x;
      if (index >= 0 && index < newPixels.length && _isInSelection(point.x, point.y, selection)) {
        newPixels[index] = point.color;
      }
    }

    return newPixels;
  }

  Uint32List floodFill({
    required Uint32List pixels,
    required int x,
    required int y,
    required int width,
    required int height,
    required Color fillColor,
    SelectionRegion? selection,
  }) {
    if (!_isWithinBounds(x, y, width, height)) return pixels;
    if (!_isInSelection(x, y, selection)) return pixels;

    final newPixels = Uint32List.fromList(pixels);
    final targetColor = newPixels[y * width + x];
    final fillColorValue = fillColor.value;

    if (targetColor == fillColorValue) return pixels;

    final queue = Queue<Point<int>>();
    queue.add(Point(x, y));

    while (queue.isNotEmpty) {
      final point = queue.removeFirst();
      final px = point.x;
      final py = point.y;

      if (!_isWithinBounds(px, py, width, height)) continue;
      if (!_isInSelection(px, py, selection)) continue;

      final index = py * width + px;
      if (newPixels[index] != targetColor) continue;

      newPixels[index] = fillColorValue;

      queue.add(Point(px + 1, py));
      queue.add(Point(px - 1, py));
      queue.add(Point(px, py + 1));
      queue.add(Point(px, py - 1));
    }

    return newPixels;
  }

  Uint32List clearPixels(int width, int height) {
    return Uint32List(width * height);
  }

  Uint32List resizePixels({
    required Uint32List oldPixels,
    required int oldWidth,
    required int oldHeight,
    required int newWidth,
    required int newHeight,
  }) {
    final newPixels = Uint32List(newWidth * newHeight);

    for (int y = 0; y < min(oldHeight, newHeight); y++) {
      for (int x = 0; x < min(oldWidth, newWidth); x++) {
        newPixels[y * newWidth + x] = oldPixels[y * oldWidth + x];
      }
    }

    return newPixels;
  }

  Uint32List applyGradient({
    required Uint32List pixels,
    required List<Color> gradientColors,
  }) {
    final newPixels = Uint32List.fromList(pixels);

    for (int i = 0; i < min(pixels.length, gradientColors.length); i++) {
      if (gradientColors[i] != Colors.transparent) {
        newPixels[i] = Color.alphaBlend(
          gradientColors[i],
          Color(pixels[i]),
        ).value;
      }
    }

    return newPixels;
  }

  Color getPixelColor({
    required Uint32List pixels,
    required int x,
    required int y,
    required int width,
    required int height,
  }) {
    if (!_isWithinBounds(x, y, width, height)) return Colors.transparent;

    final index = y * width + x;
    return Color(pixels[index]);
  }

  Modifier? createModifier(PixelModifier modifierType, MirrorAxis mirrorAxis) {
    switch (modifierType) {
      case PixelModifier.mirror:
        return MirrorModifier(mirrorAxis);
      case PixelModifier.none:
      case PixelModifier.glow:
      case PixelModifier.shadow:
        return null;
    }
  }

  // Drag-related operations
  Uint32List dragPixels({
    required Uint32List originalPixels,
    required Uint32List currentPixels,
    required int width,
    required int height,
    required Offset deltaOffset,
  }) {
    int dx = deltaOffset.dx.round();
    int dy = deltaOffset.dy.round();

    if (dx == 0 && dy == 0) {
      return currentPixels;
    }

    final newPixels = Uint32List(width * height);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final index = y * width + x;
        final color = originalPixels[index];

        if (color == 0) continue;

        final newX = x + dx;
        final newY = y + dy;

        if (newX >= 0 && newX < width && newY >= 0 && newY < height) {
          final newIndex = newY * width + newX;
          newPixels[newIndex] = color;
        }
      }
    }

    return newPixels;
  }
}
