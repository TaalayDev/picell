import 'dart:collection';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../data/models/selection_region.dart';
import '../pixel_point.dart';
import '../pixel_utils.dart';

enum TransformMode {
  none,
  move,
  scale,
  rotate,
}

enum ScaleHandle {
  topLeft,
  topCenter,
  topRight,
  rightCenter,
  bottomRight,
  bottomCenter,
  bottomLeft,
  leftCenter,
}

class SelectionService {
  final int width;
  final int height;

  SelectionService({required this.width, required this.height});

  // ── Creation Methods ──

  SelectionRegion createRectangleSelection(int startX, int startY, int endX, int endY) {
    final minX = min(startX, endX);
    final minY = min(startY, endY);
    final maxX = max(startX, endX);
    final maxY = max(startY, endY);

    final rect = Rect.fromLTRB(
      minX.toDouble(),
      minY.toDouble(),
      maxX + 1.0,
      maxY + 1.0,
    );
    final path = Path()..addRect(rect);
    return SelectionRegion(path: path, bounds: rect, shape: SelectionShape.rectangle);
  }

  SelectionRegion createEllipseSelection(int startX, int startY, int endX, int endY) {
    final minX = min(startX, endX);
    final minY = min(startY, endY);
    final maxX = max(startX, endX);
    final maxY = max(startY, endY);

    final rect = Rect.fromLTRB(
      minX.toDouble(),
      minY.toDouble(),
      maxX + 1.0,
      maxY + 1.0,
    );
    final path = Path()..addOval(rect);
    return SelectionRegion(path: path, bounds: rect, shape: SelectionShape.ellipse);
  }

  SelectionRegion? createSelectionFromPoints({
    required Offset startPoint,
    required Offset endPoint,
    required Size canvasSize,
    required int gridWidth,
    required int gridHeight,
    SelectionShape shape = SelectionShape.rectangle,
  }) {
    final pixelWidth = canvasSize.width / gridWidth;
    final pixelHeight = canvasSize.height / gridHeight;

    final startX = (startPoint.dx / pixelWidth).floor();
    final startY = (startPoint.dy / pixelHeight).floor();
    final endX = (endPoint.dx / pixelWidth).floor();
    final endY = (endPoint.dy / pixelHeight).floor();

    final minX = min(startX, endX);
    final minY = min(startY, endY);
    final maxX = max(startX, endX);
    final maxY = max(startY, endY);

    final w = maxX - minX + 1;
    final h = maxY - minY + 1;

    if (w <= 1 || h <= 1) return null;

    if (shape == SelectionShape.ellipse) {
      return createEllipseSelection(minX, minY, maxX, maxY);
    }
    return createRectangleSelection(minX, minY, maxX, maxY);
  }

  SelectionRegion createLassoSelection(List<Offset> points) {
    if (points.length < 3) {
      return SelectionRegion(
        path: Path(),
        bounds: Rect.zero,
        shape: SelectionShape.lasso,
      );
    }

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    path.close();

    return SelectionRegion(
      path: path,
      bounds: path.getBounds(),
      shape: SelectionShape.lasso,
    );
  }

  SelectionRegion createWandSelection({
    required Uint32List pixels,
    required int x,
    required int y,
    required int w,
    required int h,
    int tolerance = 0,
  }) {
    if (x < 0 || x >= w || y < 0 || y >= h) {
      return SelectionRegion(path: Path(), bounds: Rect.zero, shape: SelectionShape.wand);
    }

    final targetColor = pixels[y * w + x];
    final visited = <int>{};
    final matched = <int>{};
    final queue = Queue<int>();
    queue.add(y * w + x);

    while (queue.isNotEmpty) {
      final idx = queue.removeFirst();
      if (visited.contains(idx)) continue;
      visited.add(idx);

      final px = idx % w;
      final py = idx ~/ w;
      if (px < 0 || px >= w || py < 0 || py >= h) continue;

      final color = pixels[idx];
      if (_colorDistance(color, targetColor) <= tolerance) {
        matched.add(idx);

        if (px > 0) queue.add(idx - 1);
        if (px < w - 1) queue.add(idx + 1);
        if (py > 0) queue.add(idx - w);
        if (py < h - 1) queue.add(idx + w);
      }
    }

    return _pixelIndicesToRegion(matched, w, SelectionShape.wand);
  }

  SelectionRegion createAutoSelection({
    required Uint32List pixels,
    required int w,
    required int h,
  }) {
    final nonEmpty = <int>{};
    for (int i = 0; i < pixels.length; i++) {
      if (pixels[i] != 0) {
        nonEmpty.add(i);
      }
    }

    if (nonEmpty.isEmpty) {
      return SelectionRegion(path: Path(), bounds: Rect.zero, shape: SelectionShape.autoSelect);
    }

    return _pixelIndicesToRegion(nonEmpty, w, SelectionShape.autoSelect);
  }

  SelectionRegion selectAll() {
    final rect = Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble());
    final path = Path()..addRect(rect);
    return SelectionRegion(path: path, bounds: rect, shape: SelectionShape.rectangle);
  }

  SelectionRegion invertSelection(SelectionRegion region) {
    final allPath = Path()..addRect(Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()));
    final invertedPath = Path.combine(PathOperation.difference, allPath, region.path);
    return SelectionRegion(
      path: invertedPath,
      bounds: invertedPath.getBounds(),
      shape: SelectionShape.custom,
    );
  }

  // ── Pixel Operations ──

  /// Extract pixels within selection from source
  Uint32List extractPixels(SelectionRegion region, Uint32List source, int w, int h) {
    final result = Uint32List(w * h);
    final indices = region.getSelectedPixelIndices(w, h);
    for (final idx in indices) {
      if (idx >= 0 && idx < source.length) {
        result[idx] = source[idx];
      }
    }
    return result;
  }

  /// Clear (zero) pixels within selection
  Uint32List clearPixelsInSelection(SelectionRegion region, Uint32List source, int w, int h) {
    final result = Uint32List.fromList(source);
    final indices = region.getSelectedPixelIndices(w, h);
    for (final idx in indices) {
      if (idx >= 0 && idx < result.length) {
        result[idx] = 0;
      }
    }
    return result;
  }

  /// Move selected pixels by delta, returning new pixel data
  Uint32List moveSelectedPixels({
    required SelectionRegion region,
    required Uint32List layerPixels,
    required Offset delta,
  }) {
    final indices = region.getSelectedPixelIndices(width, height);
    // Collect selected pixels with positions
    final selectedEntries = <_PixelEntry>[];
    for (final idx in indices) {
      if (idx >= 0 && idx < layerPixels.length && layerPixels[idx] != 0) {
        final x = idx % width;
        final y = idx ~/ width;
        selectedEntries.add(_PixelEntry(x, y, layerPixels[idx]));
      }
    }

    // Clear original positions
    final result = Uint32List.fromList(layerPixels);
    for (final idx in indices) {
      if (idx >= 0 && idx < result.length) {
        result[idx] = 0;
      }
    }

    // Place at new positions
    final dx = delta.dx.round();
    final dy = delta.dy.round();
    for (final entry in selectedEntries) {
      final nx = entry.x + dx;
      final ny = entry.y + dy;
      if (nx >= 0 && nx < width && ny >= 0 && ny < height) {
        result[ny * width + nx] = entry.color;
      }
    }

    return result;
  }

  /// Apply scale transformation to selected pixels
  Uint32List scaleSelectedPixels({
    required SelectionRegion region,
    required Uint32List layerPixels,
    required double scaleX,
    required double scaleY,
    required Offset pivot,
  }) {
    final indices = region.getSelectedPixelIndices(width, height);
    final bounds = region.bounds;
    final selW = bounds.width.ceil();
    final selH = bounds.height.ceil();

    if (selW <= 0 || selH <= 0) return layerPixels;

    // Extract selection into local buffer
    final selPixels = Uint32List(selW * selH);
    for (final idx in indices) {
      if (idx >= 0 && idx < layerPixels.length && layerPixels[idx] != 0) {
        final x = idx % width;
        final y = idx ~/ width;
        final lx = x - bounds.left.floor();
        final ly = y - bounds.top.floor();
        if (lx >= 0 && lx < selW && ly >= 0 && ly < selH) {
          selPixels[ly * selW + lx] = layerPixels[idx];
        }
      }
    }

    final avgScale = (scaleX + scaleY) / 2;
    final scaled = PixelUtils.applyScale(
      selPixels, selW, selH, avgScale,
      pivot.dx - bounds.left, pivot.dy - bounds.top,
      1, 0,
    );

    // Clear original and place scaled
    final result = Uint32List.fromList(layerPixels);
    for (final idx in indices) {
      if (idx >= 0 && idx < result.length) result[idx] = 0;
    }

    for (int y = 0; y < selH; y++) {
      for (int x = 0; x < selW; x++) {
        final idx = y * selW + x;
        if (idx < scaled.length && scaled[idx] != 0) {
          final wx = bounds.left.floor() + x;
          final wy = bounds.top.floor() + y;
          if (wx >= 0 && wx < width && wy >= 0 && wy < height) {
            result[wy * width + wx] = scaled[idx];
          }
        }
      }
    }

    return result;
  }

  /// Apply rotation transformation to selected pixels
  Uint32List rotateSelectedPixels({
    required SelectionRegion region,
    required Uint32List layerPixels,
    required double angle,
    required Offset pivot,
  }) {
    final indices = region.getSelectedPixelIndices(width, height);
    final bounds = region.bounds;
    final selW = bounds.width.ceil();
    final selH = bounds.height.ceil();

    if (selW <= 0 || selH <= 0) return layerPixels;

    // Extract selection into local buffer
    final selPixels = Uint32List(selW * selH);
    for (final idx in indices) {
      if (idx >= 0 && idx < layerPixels.length && layerPixels[idx] != 0) {
        final x = idx % width;
        final y = idx ~/ width;
        final lx = x - bounds.left.floor();
        final ly = y - bounds.top.floor();
        if (lx >= 0 && lx < selW && ly >= 0 && ly < selH) {
          selPixels[ly * selW + lx] = layerPixels[idx];
        }
      }
    }

    final rotated = PixelUtils.applyRotation(
      selPixels, selW, selH, angle,
      pivot.dx - bounds.left, pivot.dy - bounds.top,
      1.0, 1, 0,
    );

    // Clear original and place rotated
    final result = Uint32List.fromList(layerPixels);
    for (final idx in indices) {
      if (idx >= 0 && idx < result.length) result[idx] = 0;
    }

    for (int y = 0; y < selH; y++) {
      for (int x = 0; x < selW; x++) {
        final idx = y * selW + x;
        if (idx < rotated.length && rotated[idx] != 0) {
          final wx = bounds.left.floor() + x;
          final wy = bounds.top.floor() + y;
          if (wx >= 0 && wx < width && wy >= 0 && wy < height) {
            result[wy * width + wx] = rotated[idx];
          }
        }
      }
    }

    return result;
  }

  /// Flip selected pixels
  Uint32List flipSelectedPixels({
    required SelectionRegion region,
    required Uint32List layerPixels,
    required bool horizontal,
  }) {
    final indices = region.getSelectedPixelIndices(width, height);
    final bounds = region.bounds;
    final minX = bounds.left.floor();
    final minY = bounds.top.floor();
    final maxX = bounds.right.ceil() - 1;
    final maxY = bounds.bottom.ceil() - 1;

    final result = Uint32List.fromList(layerPixels);

    // Collect selected pixels
    final selectedEntries = <_PixelEntry>[];
    for (final idx in indices) {
      if (idx >= 0 && idx < layerPixels.length && layerPixels[idx] != 0) {
        selectedEntries.add(_PixelEntry(idx % width, idx ~/ width, layerPixels[idx]));
      }
    }

    // Clear originals
    for (final idx in indices) {
      if (idx >= 0 && idx < result.length) result[idx] = 0;
    }

    // Place flipped
    for (final entry in selectedEntries) {
      int nx, ny;
      if (horizontal) {
        nx = maxX - (entry.x - minX);
        ny = entry.y;
      } else {
        nx = entry.x;
        ny = maxY - (entry.y - minY);
      }
      if (nx >= 0 && nx < width && ny >= 0 && ny < height) {
        result[ny * width + nx] = entry.color;
      }
    }

    return result;
  }

  /// Copy pixels in selection to clipboard buffer
  Uint32List copySelectedPixels(SelectionRegion region, Uint32List source) {
    final indices = region.getSelectedPixelIndices(width, height);
    final result = Uint32List(width * height);
    for (final idx in indices) {
      if (idx >= 0 && idx < source.length) {
        result[idx] = source[idx];
      }
    }
    return result;
  }

  // ── Hit Testing ──

  bool isPointInSelection(SelectionRegion? region, int x, int y) {
    if (region == null) return false;
    return region.contains(x, y);
  }

  // ── Helpers ──

  SelectionRegion _pixelIndicesToRegion(Set<int> indices, int w, SelectionShape shape) {
    if (indices.isEmpty) {
      return SelectionRegion(path: Path(), bounds: Rect.zero, shape: shape);
    }

    final path = Path();
    // Use run-length encoding per row for efficient path construction
    final rows = <int, List<int>>{};
    for (final idx in indices) {
      final y = idx ~/ w;
      final x = idx % w;
      rows.putIfAbsent(y, () => []).add(x);
    }

    for (final entry in rows.entries) {
      final y = entry.key;
      final xs = entry.value..sort();

      int runStart = xs.first;
      int runEnd = runStart;
      for (int i = 1; i < xs.length; i++) {
        if (xs[i] == runEnd + 1) {
          runEnd = xs[i];
        } else {
          path.addRect(Rect.fromLTRB(
            runStart.toDouble(),
            y.toDouble(),
            runEnd + 1.0,
            y + 1.0,
          ));
          runStart = xs[i];
          runEnd = runStart;
        }
      }
      path.addRect(Rect.fromLTRB(
        runStart.toDouble(),
        y.toDouble(),
        runEnd + 1.0,
        y + 1.0,
      ));
    }

    return SelectionRegion(
      path: path,
      bounds: path.getBounds(),
      shape: shape,
    );
  }

  int _colorDistance(int c1, int c2) {
    final r1 = (c1 >> 16) & 0xFF;
    final g1 = (c1 >> 8) & 0xFF;
    final b1 = c1 & 0xFF;
    final a1 = (c1 >> 24) & 0xFF;
    final r2 = (c2 >> 16) & 0xFF;
    final g2 = (c2 >> 8) & 0xFF;
    final b2 = c2 & 0xFF;
    final a2 = (c2 >> 24) & 0xFF;

    final dr = r1 - r2;
    final dg = g1 - g2;
    final db = b1 - b2;
    final da = a1 - a2;

    return sqrt(dr * dr + dg * dg + db * db + da * da).round();
  }
}

class _PixelEntry {
  final int x;
  final int y;
  final int color;
  const _PixelEntry(this.x, this.y, this.color);
}
