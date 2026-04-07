import 'package:flutter/rendering.dart';

import 'canvas_controller.dart';
import 'canvas_painter.dart';
import 'canvas_quad_vertices_buffer.dart';
import 'canvas_runtime_config.dart';
import 'layer_cache_manager.dart';

class PixelCanvasRenderPipeline {
  PixelCanvasRenderPipeline({
    required PixelCanvasController controller,
    required LayerCacheManager cacheManager,
    required PixelCanvasRuntimeConfig config,
  })  : _controller = controller,
        _cacheManager = cacheManager,
        _config = config,
        _delegate = PixelCanvasPaintDelegate(
          controller: controller,
          cacheManager: cacheManager,
          config: config,
          quadVerticesBuffer: PixelCanvasQuadVerticesBuffer(),
        );

  PixelCanvasController _controller;
  LayerCacheManager _cacheManager;
  PixelCanvasRuntimeConfig _config;
  final PixelCanvasPaintDelegate _delegate;

  void update({
    PixelCanvasController? controller,
    LayerCacheManager? cacheManager,
    PixelCanvasRuntimeConfig? config,
  }) {
    _controller = controller ?? _controller;
    _cacheManager = cacheManager ?? _cacheManager;
    _config = config ?? _config;
    _delegate.update(
      controller: controller,
      cacheManager: cacheManager,
      config: config,
    );
  }

  void paint(PaintingContext context, Offset offset, Size size) {
    final canvas = context.canvas;
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    _delegate.paint(canvas, size);
    canvas.restore();
  }
}
