import 'dart:typed_data';

import '../../data/models/layer.dart';

/// Flattens layers into one pixel buffer the way the canvas draws them.
class LayerMergeService {
  const LayerMergeService._();

  /// Composites [layers] (bottom first) with source-over blending. Each
  /// layer's effects and opacity are baked in; hidden layers are skipped.
  static Uint32List composite(List<Layer> layers, int width, int height) {
    final out = Uint32List(width * height);
    for (final layer in layers) {
      if (!layer.isVisible || layer.opacity <= 0) continue;
      final src = layer.processedPixels(width, height);
      final opacity = layer.opacity.clamp(0.0, 1.0);
      for (var i = 0; i < out.length && i < src.length; i++) {
        final s = src[i];
        if (s == 0) continue;
        out[i] = blendOver(out[i], s, opacity);
      }
    }
    return out;
  }

  /// Draws ARGB [src] at [opacity] over ARGB [dst] (straight alpha).
  static int blendOver(int dst, int src, double opacity) {
    final sa = ((src >>> 24) & 0xFF) / 255.0 * opacity;
    if (sa <= 0) return dst;
    final da = ((dst >>> 24) & 0xFF) / 255.0;
    if (sa >= 1 || da <= 0) {
      return (((sa * 255).round() & 0xFF) << 24) | (src & 0x00FFFFFF);
    }
    final outA = sa + da * (1 - sa);
    int channel(int shift) {
      final sc = (src >>> shift) & 0xFF;
      final dc = (dst >>> shift) & 0xFF;
      return ((sc * sa + dc * da * (1 - sa)) / outA).round().clamp(0, 255);
    }

    return ((outA * 255).round() << 24) | (channel(16) << 16) | (channel(8) << 8) | channel(0);
  }
}
