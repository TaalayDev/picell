import 'dart:ui' as ui;

import '../../data/models/layer.dart';

class PixelCanvasOnionSkinFrame {
  const PixelCanvasOnionSkinFrame({
    required this.frameId,
    required this.width,
    required this.height,
    required this.layers,
    required this.opacity,
  });

  final int frameId;
  final int width;
  final int height;
  final List<Layer> layers;
  final double opacity;

  bool hasSameRasterData(PixelCanvasOnionSkinFrame other) {
    if (frameId != other.frameId || width != other.width || height != other.height) {
      return false;
    }
    if (layers.length != other.layers.length) {
      return false;
    }
    for (var i = 0; i < layers.length; i++) {
      if (layers[i] != other.layers[i]) {
        return false;
      }
    }
    return true;
  }
}

class PixelCanvasResolvedOnionSkinFrame {
  const PixelCanvasResolvedOnionSkinFrame({required this.frameId, required this.image, required this.opacity});

  final int frameId;
  final ui.Image image;
  final double opacity;
}

bool samePixelCanvasOnionSkinFrames(List<PixelCanvasOnionSkinFrame> a, List<PixelCanvasOnionSkinFrame> b) {
  if (identical(a, b)) {
    return true;
  }
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    final current = a[i];
    final next = b[i];
    if (current.opacity != next.opacity || !current.hasSameRasterData(next)) {
      return false;
    }
  }
  return true;
}
