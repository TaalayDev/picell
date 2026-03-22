import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:vector_math/vector_math_64.dart';

enum SelectionShape { rectangle, ellipse, lasso, wand, autoSelect, custom }

enum SelectionMode { replace, add, subtract }

class SelectionRegion {
  final Path path;
  final Rect bounds;
  final SelectionShape shape;
  final SelectionMode mode;

  const SelectionRegion({
    required this.path,
    required this.bounds,
    required this.shape,
    this.mode = SelectionMode.replace,
  });

  bool contains(int x, int y) {
    final point = Offset(x + 0.5, y + 0.5);
    if (!bounds.contains(point)) return false;
    return path.contains(point);
  }

  SelectionRegion combine(SelectionRegion other, SelectionMode combineMode) {
    final Path combinedPath;
    switch (combineMode) {
      case SelectionMode.add:
        combinedPath = Path.combine(PathOperation.union, path, other.path);
        break;
      case SelectionMode.subtract:
        combinedPath = Path.combine(PathOperation.difference, path, other.path);
        break;
      case SelectionMode.replace:
        return other;
    }
    return SelectionRegion(
      path: combinedPath,
      bounds: combinedPath.getBounds(),
      shape: SelectionShape.custom,
      mode: combineMode,
    );
  }

  SelectionRegion shifted(Offset delta) {
    final shiftedPath = path.shift(delta);
    return SelectionRegion(
      path: shiftedPath,
      bounds: bounds.shift(delta),
      shape: shape,
      mode: mode,
    );
  }

  SelectionRegion transformed(Matrix4 matrix) {
    final m = Float64List.fromList(matrix.storage);
    final transformedPath = path.transform(m);
    return SelectionRegion(
      path: transformedPath,
      bounds: transformedPath.getBounds(),
      shape: SelectionShape.custom,
      mode: mode,
    );
  }

  /// Get all pixel indices within this selection for a canvas of given dimensions
  List<int> getSelectedPixelIndices(int canvasWidth, int canvasHeight) {
    final indices = <int>[];
    final minX = max(0, bounds.left.floor());
    final maxX = min(canvasWidth, bounds.right.ceil());
    final minY = max(0, bounds.top.floor());
    final maxY = min(canvasHeight, bounds.bottom.ceil());

    for (int y = minY; y < maxY; y++) {
      for (int x = minX; x < maxX; x++) {
        if (contains(x, y)) {
          indices.add(y * canvasWidth + x);
        }
      }
    }
    return indices;
  }

  SelectionRegion copyWith({
    Path? path,
    Rect? bounds,
    SelectionShape? shape,
    SelectionMode? mode,
  }) {
    return SelectionRegion(
      path: path ?? this.path,
      bounds: bounds ?? (path != null ? path.getBounds() : this.bounds),
      shape: shape ?? this.shape,
      mode: mode ?? this.mode,
    );
  }
}
