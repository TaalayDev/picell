import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/selection_region.dart';

/// In-app clipboard that stores a pixel selection so it can be pasted
/// elsewhere on the same canvas or a different layer.
///
/// We intentionally use an internal buffer rather than the system clipboard
/// because image pixel data is platform-specific and not universally supported
/// by [Clipboard.setData] / [Clipboard.getData].
class PixelClipboardData {
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

final pixelClipboardProvider =
    StateProvider<PixelClipboardData?>((ref) => null);
