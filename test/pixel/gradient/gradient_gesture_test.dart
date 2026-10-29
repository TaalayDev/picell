import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/data/models/layer.dart';
import 'package:picell/pixel/canvas/canvas_controller.dart';
import 'package:picell/pixel/canvas/canvas_gesture_handler.dart';
import 'package:picell/pixel/canvas/layer_cache_manager.dart';
import 'package:picell/pixel/canvas/pixel_viewport_controller.dart';
import 'package:picell/pixel/canvas/tool_drawing_manager.dart';
import 'package:picell/pixel/tools.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final layer = Layer(
    layerId: 1,
    id: 'layer-1',
    name: 'Layer 1',
    pixels: Uint32List(100),
  );
  late PixelCanvasController controller;
  late ToolDrawingManager toolManager;
  late CanvasGestureHandler handler;
  late List<String> log;

  setUp(() {
    log = [];
    controller = PixelCanvasController(
      width: 10,
      height: 10,
      layers: [layer],
      currentLayerIndex: 0,
      cacheManager: LayerCacheManager(width: 10, height: 10),
    );
    toolManager = ToolDrawingManager(
      width: 10,
      height: 10,
      onGradientPreview: (s, e) => controller.setGradient(s, e),
      onGradientApply: (s, e) => log.add('apply'),
      onGradientClear: () => controller.setGradient(null, null),
      onGradientCancel: () => log.add('cancel'),
    );
    handler = CanvasGestureHandler(
      controller: controller,
      toolManager: toolManager,
      viewportController: PixelViewportController(),
      onStartDrawing: () => log.add('batch start'),
      onFinishDrawing: () => log.add('batch end'),
      onCancelDrawing: () => log.add('batch cancel'),
      onDrawShape: (_) {},
    );
  });

  PixelDrawDetails at(Offset p) => PixelDrawDetails(
        position: p,
        size: const Size(100, 100),
        width: 10,
        height: 10,
        currentLayer: layer,
        color: Colors.black,
        modifier: null,
        onPixelsUpdated: (_) {},
      );

  void down(int pointer, Offset p) =>
      handler.handlePointerDown(PointerDownEvent(pointer: pointer, position: p), PixelTool.gradient, at(p));
  void move(int pointer, Offset p) =>
      handler.handlePointerMove(PointerMoveEvent(pointer: pointer, position: p), PixelTool.gradient, at(p));
  void up(int pointer, Offset p) =>
      handler.handlePointerUp(PointerUpEvent(pointer: pointer, position: p), PixelTool.gradient, at(p));

  test('a gradient drag runs outside the drawing batch and stays pending', () {
    down(1, const Offset(10, 50));
    move(1, const Offset(90, 50));
    up(1, const Offset(90, 50));

    expect(log, isEmpty, reason: 'no batch, nothing committed yet');
    expect(toolManager.hasPendingGradient, isTrue);
    expect(controller.gradientEnd, const Offset(9, 5));

    expect(toolManager.commitGradient(), isTrue);
    expect(log, ['apply']);
    expect(controller.gradientStart, isNull);
  });

  test('a second finger restores the pending gradient instead of committing', () {
    down(1, const Offset(10, 50));
    move(1, const Offset(90, 50));
    up(1, const Offset(90, 50));

    down(1, const Offset(50, 90)); // would start a new gradient...
    down(2, const Offset(60, 90)); // ...but it's a pinch
    up(2, const Offset(60, 90));
    up(1, const Offset(50, 90));

    expect(log, isEmpty);
    expect(toolManager.hasPendingGradient, isTrue);
    expect(controller.gradientStart, const Offset(1, 5));
  });
}
