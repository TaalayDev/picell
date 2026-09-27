import 'dart:typed_data';

import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../data/models/layer.dart';
import '../data/models/selection_region.dart';

sealed class EditorClipboardData {
  const EditorClipboardData();
}

/// In-app clipboard that stores a pixel selection so it can be pasted
/// elsewhere on the same canvas or a different layer.
///
/// We intentionally use an internal buffer rather than the system clipboard
/// because image pixel data is platform-specific and not universally supported
/// by [Clipboard.setData] / [Clipboard.getData].
class PixelClipboardData extends EditorClipboardData {
  /// Full-canvas-sized pixel buffer (same dimensions as the source canvas).
  /// Non-selected pixels are transparent (0x00000000).
  final Uint32List pixels;

  /// Width of the source canvas.
  final int width;

  /// Height of the source canvas.
  final int height;

  /// The selection region that was active when the copy was taken.
  final SelectionRegion region;

  const PixelClipboardData({
    required this.pixels,
    required this.width,
    required this.height,
    required this.region,
  });
}

/// Immutable snapshots of one or more layers copied from an editor tab.
class LayerClipboardData extends EditorClipboardData {
  const LayerClipboardData({
    required this.layers,
    required this.width,
    required this.height,
  });

  final List<Layer> layers;
  final int width;
  final int height;
}

class EditorClipboardNotifier extends StateNotifier<EditorClipboardData?> {
  EditorClipboardNotifier() : super(null);

  void store(EditorClipboardData data) => state = data;

  EditorClipboardData? take() {
    final data = state;
    state = null;
    return data;
  }

  void restoreIfEmpty(EditorClipboardData data) {
    state ??= data;
  }

  void clear() => state = null;
}

final pixelClipboardProvider =
    StateNotifierProvider<EditorClipboardNotifier, EditorClipboardData?>(
  (ref) => EditorClipboardNotifier(),
);
