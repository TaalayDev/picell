import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/data/models/layer.dart';
import 'package:picell/data/models/selection_region.dart';
import 'package:picell/data/models/selection_state.dart';
import 'package:picell/pixel/canvas/canvas_controller.dart';
import 'package:picell/pixel/canvas/canvas_gesture_handler.dart';
import 'package:picell/pixel/canvas/canvas_input_adapter.dart';
import 'package:picell/pixel/canvas/canvas_runtime_config.dart';
import 'package:picell/pixel/canvas/layer_cache_manager.dart';
import 'package:picell/pixel/canvas/pixel_viewport_controller.dart';
import 'package:picell/pixel/canvas/selection_handle_geometry.dart';
import 'package:picell/pixel/canvas/tool_drawing_manager.dart';
import 'package:picell/pixel/services/selection_service.dart';
import 'package:picell/pixel/tools.dart';
import 'package:picell/pixel/tools/selection_tools.dart';

// Replaces the old selection_coordinates_test, which drove the selection
// overlay widget removed in the selection rewrite. The same behaviour now
// lives in PixelCanvasInputAdapter, driven here with raw pointer events.
void main() {
  // A 10×10 canvas drawn at 100×100: one pixel is 10 screen units.
  const canvasSize = Size(100, 100);
  final layer = Layer(layerId: 1, id: 'layer-1', name: 'Layer 1', pixels: Uint32List(100));

  SelectionRegion rect(double x, double y, double w, double h) => SelectionRegion(
        path: Path()..addRect(Rect.fromLTWH(x, y, w, h)),
        bounds: Rect.fromLTWH(x, y, w, h),
        shape: SelectionShape.rectangle,
      );

  group('RectSelectionTool', () {
    PixelDrawDetails detailsAt(Offset position) => PixelDrawDetails(
          position: position,
          size: const Size(200, 200),
          width: 10,
          height: 10,
          currentLayer: layer,
          color: Colors.black,
          modifier: null,
          onPixelsUpdated: (_) {},
        );

    test('maps widget positions to canvas pixels', () {
      SelectionRegion? result;
      final tool = RectSelectionTool(
        selectionService: SelectionService(width: 10, height: 10),
        onConfirm: (region) => result = region,
      );
      tool.onStart(detailsAt(const Offset(50, 60)));
      tool.onEnd(detailsAt(const Offset(150, 160)));
      expect(result!.bounds, const Rect.fromLTRB(2, 3, 8, 9));
    });

    test('a click without a drag confirms no selection', () {
      SelectionRegion? result = rect(0, 0, 2, 2);
      final tool = RectSelectionTool(
        selectionService: SelectionService(width: 10, height: 10),
        onConfirm: (region) => result = region,
      );
      tool.onStart(detailsAt(const Offset(50, 60)));
      tool.onEnd(detailsAt(const Offset(50, 60)));
      expect(result, isNull);
    });
  });

  group('PixelCanvasInputAdapter selection handling', () {
    // The selection covers pixels (2..5, 2..3): screen (20, 20)–(60, 40).
    final selection = rect(2, 2, 4, 2);

    late PixelCanvasController controller;
    late ToolDrawingManager toolManager;
    late PixelCanvasInputAdapter adapter;
    late List<SelectionRegion> resized;
    late List<double> angles;
    late List<Offset> moves;
    late int transformStarts;
    var pointer = 0;

    setUp(() {
      resized = [];
      angles = [];
      moves = [];
      transformStarts = 0;
      controller = PixelCanvasController(
        width: 10,
        height: 10,
        layers: [layer],
        currentLayerIndex: 0,
        cacheManager: LayerCacheManager(width: 10, height: 10),
      );
      controller.setSelection(selection);
      toolManager = ToolDrawingManager(width: 10, height: 10, onLassoUpdate: controller.updateLassoPreview);
      toolManager.setCurrentSelection(selection);
      adapter = PixelCanvasInputAdapter(
        controller: controller,
        gestureHandler: CanvasGestureHandler(
          controller: controller,
          toolManager: toolManager,
          viewportController: PixelViewportController(),
          onStartDrawing: () {},
          onFinishDrawing: () {},
          onDrawShape: (_) {},
        ),
        toolManager: toolManager,
        config: PixelCanvasRuntimeConfig(
          width: 10,
          height: 10,
          currentTool: PixelTool.select,
          currentLayer: layer,
          currentColor: Colors.black,
          brushSize: 1,
          sprayIntensity: 1,
          modifier: null,
          selectionState: SelectionState(region: selection),
          showSelectionMoveHandle: false,
          showSelectionTransformHandles: true,
          showSelectionAnchorHandle: true,
          onSelectionResize: (region, _, __, ___) => resized.add(region),
          onSelectionRotate: (_, __, angle, ___) => angles.add(angle),
          onMoveSelection: moves.add,
          onTransformStart: (_) => transformStarts++,
        ),
        getCanvasSize: () => canvasSize,
      );
    });

    final geometry = CanvasSelectionHandleGeometry.compute(
      selectionRegion: selection,
      canvasSize: canvasSize,
      canvasWidth: 10,
      canvasHeight: 10,
      showSelectionMoveHandle: false,
      showSelectionTransformHandles: true,
      showSelectionAnchorHandle: true,
      selectionAnchorPoint: null,
      handleScale: 1.0,
    )!;

    // Presses at [from], moves through [path], releases at the last point.
    void drag(Offset from, List<Offset> path) {
      final id = ++pointer;
      adapter.handlePointerDown(PointerDownEvent(pointer: id, position: from));
      for (final p in path) {
        adapter.handlePointerMove(PointerMoveEvent(pointer: id, position: p));
      }
      adapter.handlePointerUp(PointerUpEvent(pointer: id, position: path.isEmpty ? from : path.last));
    }

    Future<void> withKeys(WidgetTester tester, List<LogicalKeyboardKey> keys, void Function() body) async {
      for (final k in keys) {
        await tester.sendKeyDownEvent(k);
      }
      body();
      for (final k in keys.reversed) {
        await tester.sendKeyUpEvent(k);
      }
    }

    final corner = geometry.transformHandleRects[CanvasSelectionHandle.bottomRight]!.center;

    testWidgets('a corner handle resizes freely without modifiers', (tester) async {
      // 4 pixels right, no vertical change.
      drag(corner, [corner + const Offset(40, 0)]);
      expect(resized.last.bounds, const Rect.fromLTWH(2, 2, 8, 2));
    });

    testWidgets('Shift keeps the aspect ratio', (tester) async {
      await withKeys(tester, [LogicalKeyboardKey.shiftLeft], () {
        drag(corner, [corner + const Offset(40, 0)]);
      });
      expect(resized.last.bounds, const Rect.fromLTWH(2, 2, 8, 4));
    });

    testWidgets('Alt resizes around the centre', (tester) async {
      await withKeys(tester, [LogicalKeyboardKey.altLeft], () {
        drag(corner, [corner + const Offset(10, 0)]);
      });
      expect(resized.last.bounds, const Rect.fromLTRB(1, 2, 7, 4));
    });

    testWidgets('Shift snaps rotation to 15° steps', (tester) async {
      final pivot = selection.bounds.center * 10;
      final handle = geometry.rotationHandleCenter!;
      Offset turned(double degrees) {
        final a = degrees * math.pi / 180;
        final d = handle - pivot;
        return pivot + Offset(d.dx * math.cos(a) - d.dy * math.sin(a), d.dx * math.sin(a) + d.dy * math.cos(a));
      }

      drag(handle, [turned(20)]);
      expect(angles.last, closeTo(20 * math.pi / 180, 1e-6));

      await withKeys(tester, [LogicalKeyboardKey.shiftLeft], () {
        drag(handle, [turned(20)]);
      });
      expect(angles.last, closeTo(15 * math.pi / 180, 1e-9));
    });

    testWidgets('dragging inside the selection moves it in whole pixels', (tester) async {
      // 0.4-pixel steps: the move starts after the drag threshold, then the
      // fractions accumulate instead of being lost.
      const start = Offset(30, 30);
      drag(start, [for (var i = 1; i <= 5; i++) start + Offset(i * 4.0, 0)]);

      expect(transformStarts, 1);
      expect(moves.fold(Offset.zero, (a, b) => a + b), const Offset(2, 0));
    });

    group('combine mode at pointer-down', () {
      // Shape drawn by the gesture, overlapping the right half of the
      // selection and beyond.
      final drawn = rect(4, 2, 4, 2);

      testWidgets('Shift adds, Alt subtracts, Shift+Alt intersects', (tester) async {
        Future<SelectionRegion?> run(List<LogicalKeyboardKey> keys) async {
          for (final k in keys) {
            await tester.sendKeyDownEvent(k);
          }
          final id = ++pointer;
          adapter.handlePointerDown(PointerDownEvent(pointer: id, position: const Offset(85, 85)));
          final result = toolManager.resolveSelectionGesture(drawn);
          adapter.handlePointerCancel(PointerCancelEvent(pointer: id));
          for (final k in keys.reversed) {
            await tester.sendKeyUpEvent(k);
          }
          return result;
        }

        expect((await run([LogicalKeyboardKey.shiftLeft]))!.bounds, const Rect.fromLTWH(2, 2, 6, 2));
        expect((await run([LogicalKeyboardKey.altLeft]))!.bounds, const Rect.fromLTWH(2, 2, 2, 2));
        expect(
          (await run([LogicalKeyboardKey.shiftLeft, LogicalKeyboardKey.altLeft]))!.bounds,
          const Rect.fromLTWH(4, 2, 2, 2),
        );
        expect((await run([]))!.bounds, drawn.bounds, reason: 'no modifier replaces');
      });
    });
  });
}
