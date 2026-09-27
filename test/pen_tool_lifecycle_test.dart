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
import 'package:picell/pixel/tools.dart';

void main() {
  group('Pen tool lifecycle', () {
    late Layer layer;
    late PixelCanvasController controller;
    late ToolDrawingManager toolManager;
    late CanvasGestureHandler gestureHandler;
    late List<List<PixelPoint<int>>> committedShapes;
    late int starts;
    late int finishes;
    late int cancellations;

    setUp(() {
      layer = Layer(
        layerId: 1,
        id: 'layer-1',
        name: 'Layer 1',
        pixels: Uint32List(100),
      );
      controller = PixelCanvasController(
        width: 10,
        height: 10,
        layers: [layer],
        currentLayerIndex: 0,
        cacheManager: LayerCacheManager(width: 10, height: 10),
      );
      toolManager = ToolDrawingManager(width: 10, height: 10);
      committedShapes = [];
      starts = 0;
      finishes = 0;
      cancellations = 0;
      gestureHandler = CanvasGestureHandler(
        controller: controller,
        toolManager: toolManager,
        viewportController: PixelViewportController(),
        onStartDrawing: () => starts++,
        onFinishDrawing: () => finishes++,
        onCancelDrawing: () => cancellations++,
        onDrawShape: (pixels) =>
            committedShapes.add(List<PixelPoint<int>>.from(pixels)),
      );
    });

    PixelDrawDetails detailsAt(Offset position) {
      return PixelDrawDetails(
        position: position,
        size: const Size(100, 100),
        width: 10,
        height: 10,
        currentLayer: layer,
        color: Colors.black,
        modifier: null,
        onPixelsUpdated: (_) {},
      );
    }

    void tap(int pointer, Offset position) {
      gestureHandler.handlePointerDown(
        PointerDownEvent(pointer: pointer, position: position),
        PixelTool.pen,
        detailsAt(position),
      );
      gestureHandler.handlePointerUp(
        PointerUpEvent(pointer: pointer, position: position),
        PixelTool.pen,
        detailsAt(position),
      );
    }

    test('keeps one drawing batch open until the path is explicitly finished',
        () {
      tap(1, const Offset(20, 20));
      tap(2, const Offset(70, 20));

      expect(starts, 1);
      expect(finishes, 0);
      expect(committedShapes, isEmpty);
      expect(gestureHandler.isPenDrawingActive, isTrue);

      toolManager.closePenPath(
        controller,
        detailsAt(Offset.zero),
        close: false,
      );
      gestureHandler.finishPenDrawing();

      expect(finishes, 1);
      expect(committedShapes, hasLength(1));
      expect(committedShapes.single, isNotEmpty);
      expect(controller.isDrawingPenPath, isFalse);

      tap(3, const Offset(30, 60));
      expect(starts, 2);
      expect(finishes, 1);
      expect(committedShapes, hasLength(1));
    });

    test('closing at the first point commits exactly once', () {
      tap(1, const Offset(20, 20));
      tap(2, const Offset(70, 20));
      tap(3, const Offset(22, 22));

      expect(starts, 1);
      expect(finishes, 1);
      expect(committedShapes, hasLength(1));
      expect(gestureHandler.isPenDrawingActive, isFalse);
      expect(controller.penPoints, isEmpty);
    });

    test('cancel clears preview and cancels the pending batch', () {
      tap(1, const Offset(20, 20));
      tap(2, const Offset(70, 20));

      gestureHandler.cancelPenDrawing();

      expect(cancellations, 1);
      expect(finishes, 0);
      expect(committedShapes, isEmpty);
      expect(controller.previewPixels, isEmpty);
      expect(controller.penPoints, isEmpty);
      expect(controller.isDrawingPenPath, isFalse);
      expect(gestureHandler.isPenDrawingActive, isFalse);
    });
  });
}
