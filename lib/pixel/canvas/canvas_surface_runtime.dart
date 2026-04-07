import 'dart:typed_data';

import 'canvas_surface_image_resolver.dart';
import 'canvas_surface_models.dart';

class PixelCanvasSurfaceRuntime {
  PixelCanvasSurfaceRuntime()
      : imageResolver = PixelCanvasSurfaceImageResolver();

  final PixelCanvasSurfaceImageResolver imageResolver;

  void update({
    required Uint8List? backgroundImageBytes,
    required List<PixelCanvasOnionSkinFrame> onionSkinFrames,
  }) {
    imageResolver.update(
      backgroundImageBytes: backgroundImageBytes,
      onionSkinFrames: onionSkinFrames,
    );
  }

  void dispose() {
    imageResolver.dispose();
  }
}
