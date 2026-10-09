import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/data/models/layer.dart';
import 'package:picell/pixel/canvas/canvas_controller.dart';
import 'package:picell/pixel/canvas/canvas_gesture_handler.dart';
import 'package:picell/pixel/canvas/layer_cache_manager.dart';
import 'package:picell/pixel/canvas/pixel_viewport_controller.dart';
import 'package:picell/pixel/canvas/tool_drawing_manager.dart';
import 'package:picell/pixel/pixel_point.dart';
import 'package:picell/pixel/services/drawing_service.dart';
import 'package:picell/pixel/tools.dart';

void main() {
  late PixelCanvasController controller;
  late CanvasGestureHandler handler;
  late PixelViewportController viewport;
  late List<Offset> drags;
  late Layer layer;
  var starts = 0;

  setUp(() {
    starts = 0;
    drags = [];
    layer = Layer(layerId: 1, id: 'l', name: 'L', pixels: Uint32List(100));
    viewport = PixelViewportController(initialScale: 3.0, initialOffset: const Offset(-120, -80));
    controller = PixelCanvasController(
      width: 10,
      height: 10,
      layers: [layer],
      currentLayerIndex: 0,
      cacheManager: LayerCacheManager(width: 10, height: 10),
    )..setZoomAndOffset(3.0, const Offset(-120, -80));
    handler = CanvasGestureHandler(
      controller: controller,
      toolManager: ToolDrawingManager(width: 10, height: 10),
      viewportController: viewport,
      onStartDrawing: () {},
      onFinishDrawing: () {},
      onDrawShape: (List<PixelPoint<int>> _) {},
      onStartPixelDrag: (_) => starts++,
      onPixelDrag: drags.add,
    );
  });

  PixelDrawDetails details(Offset p) => PixelDrawDetails(
        position: p,
        size: const Size(100, 100), // 10 local px per canvas pixel
        width: 10,
        height: 10,
        currentLayer: layer,
        color: Colors.black,
        modifier: null,
        onPixelsUpdated: (_) {},
      );

  test('move tool reports movement in canvas pixels, starting from zero', () {
    const start = Offset(50, 50);
    handler.handlePointerDown(PointerDownEvent(pointer: 1, position: start), PixelTool.drag, details(start));
    expect(starts, 1);

    var pos = start;
    for (final step in [const Offset(0, -3), const Offset(0, -2), const Offset(5, 0)]) {
      pos += step;
      handler.handlePointerMove(
        PointerMoveEvent(pointer: 1, position: pos, delta: step),
        PixelTool.drag,
        details(pos),
      );
    }

    // 10 local px = 1 canvas pixel. First report must not jump.
    expect(drags.first, const Offset(0, -0.3));
    expect(drags.last.dx, closeTo(0.5, 1e-9));
    expect(drags.last.dy, closeTo(-0.5, 1e-9));
  });

  test('move tool does not touch the viewport or canvas offset', () {
    const start = Offset(50, 50);
    handler.handlePointerDown(PointerDownEvent(pointer: 1, position: start), PixelTool.drag, details(start));
    handler.handlePointerMove(
      PointerMoveEvent(pointer: 1, position: const Offset(80, 20), delta: const Offset(30, -30)),
      PixelTool.drag,
      details(const Offset(80, 20)),
    );
    expect(controller.offset, const Offset(-120, -80));
    expect(viewport.offset, const Offset(-120, -80));
    expect(viewport.scale, 3.0);
  });

  test('a tiny drag shifts pixels by at most the rounded pixel distance', () {
    final original = Uint32List(100)..[5 * 10 + 5] = 0xFFFFFFFF;
    final service = DrawingService();
    // 0.3 canvas pixels rounds to no movement at all.
    final out = service.dragPixels(
      originalPixels: original,
      currentPixels: original,
      width: 10,
      height: 10,
      deltaOffset: const Offset(0, -0.3),
    );
    expect(out, original);
    // 1.2 pixels up moves exactly one pixel.
    final moved = service.dragPixels(
      originalPixels: original,
      currentPixels: original,
      width: 10,
      height: 10,
      deltaOffset: const Offset(0, -1.2),
    );
    expect(moved[4 * 10 + 5], 0xFFFFFFFF);
  });
}
