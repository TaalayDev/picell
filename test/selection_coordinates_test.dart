import 'dart:typed_data';

import 'package:flutter/material.dart' hide SelectionOverlay;
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/data/models/layer.dart';
import 'package:picell/data/models/selection_region.dart';
import 'package:picell/data/models/selection_state.dart';
import 'package:picell/pixel/canvas/pixel_canvas.dart';
import 'package:picell/pixel/canvas/widgets/selection_overlay.dart';
import 'package:picell/pixel/services/selection_service.dart';
import 'package:picell/pixel/tools.dart';
import 'package:picell/pixel/tools/selection_tools.dart';

void main() {
  group('Selection coordinates', () {
    test('rectangle selection uses widget size to map to pixel coordinates', () {
      SelectionRegion? result;
      final layer = Layer(
        layerId: 1,
        id: 'layer-1',
        name: 'Layer 1',
        pixels: Uint32List(100),
      );

      final tool = RectSelectionTool(
        selectionService: SelectionService(width: 10, height: 10),
        onPreview: (_) {},
        onConfirm: (region) => result = region,
      );

      PixelDrawDetails detailsFor(Offset position) {
        return PixelDrawDetails(
          position: position,
          size: const Size(200, 200),
          width: 10,
          height: 10,
          currentLayer: layer,
          color: Colors.black,
          modifier: null,
          onPixelsUpdated: (_) {},
        );
      }

      tool.onStart(detailsFor(const Offset(50, 60)));
      tool.onEnd(detailsFor(const Offset(150, 160)));

      expect(result, isNotNull);
      expect(result!.bounds, const Rect.fromLTRB(2, 3, 8, 9));
    });

    test('single-pixel rectangle selection clears the selection', () {
      SelectionRegion? result = SelectionRegion(
        path: Path()..addRect(const Rect.fromLTWH(0, 0, 2, 2)),
        bounds: const Rect.fromLTWH(0, 0, 2, 2),
        shape: SelectionShape.rectangle,
      );
      final layer = Layer(
        layerId: 1,
        id: 'layer-1',
        name: 'Layer 1',
        pixels: Uint32List(100),
      );

      final tool = RectSelectionTool(
        selectionService: SelectionService(width: 10, height: 10),
        onPreview: (_) {},
        onConfirm: (region) => result = region,
      );

      PixelDrawDetails detailsFor(Offset position) {
        return PixelDrawDetails(
          position: position,
          size: const Size(200, 200),
          width: 10,
          height: 10,
          currentLayer: layer,
          color: Colors.black,
          modifier: null,
          onPixelsUpdated: (_) {},
        );
      }

      tool.onStart(detailsFor(const Offset(50, 60)));
      tool.onEnd(detailsFor(const Offset(50, 60)));

      expect(result, isNull);
    });

    testWidgets('resize handle respects parent scale transform', (tester) async {
      SelectionRegion? resizedRegion;
      double? resizedScaleX;
      double? resizedScaleY;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.topLeft,
            child: Transform(
              alignment: Alignment.topLeft,
              transform: Matrix4.diagonal3Values(2.0, 2.0, 1.0),
              child: SizedBox(
                width: 100,
                height: 100,
                child: SelectionOverlay(
                  selectionRegion: SelectionRegion(
                    path: Path()..addRect(const Rect.fromLTWH(2, 2, 2, 2)),
                    bounds: const Rect.fromLTWH(2, 2, 2, 2),
                    shape: SelectionShape.rectangle,
                  ),
                  zoomLevel: 2.0,
                  canvasOffset: Offset.zero,
                  canvasWidth: 10,
                  canvasHeight: 10,
                  canvasSize: const Size(100, 100),
                  onSelectionResize: (newRegion, scaleX, scaleY, pivot) {
                    resizedRegion = newRegion;
                    resizedScaleX = scaleX;
                    resizedScaleY = scaleY;
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      const rightHandleCenter = Offset(80, 60);
      await tester.dragFrom(rightHandleCenter, const Offset(20, 0));
      await tester.pump();

      expect(resizedRegion, isNotNull);
      expect(resizedScaleX, closeTo(1.5, 0.001));
      expect(resizedScaleY, closeTo(1.0, 0.001));
      expect(resizedRegion!.bounds, const Rect.fromLTRB(2, 2, 5, 4));
    });

    testWidgets('move accumulates sub-pixel drag under parent scale', (tester) async {
      Offset totalDelta = Offset.zero;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.topLeft,
            child: Transform(
              alignment: Alignment.topLeft,
              transform: Matrix4.diagonal3Values(2.0, 2.0, 1.0),
              child: SizedBox(
                width: 100,
                height: 100,
                child: SelectionOverlay(
                  selectionRegion: SelectionRegion(
                    path: Path()..addRect(const Rect.fromLTWH(2, 2, 4, 4)),
                    bounds: const Rect.fromLTWH(2, 2, 4, 4),
                    shape: SelectionShape.rectangle,
                  ),
                  zoomLevel: 2.0,
                  canvasOffset: Offset.zero,
                  canvasWidth: 10,
                  canvasHeight: 10,
                  canvasSize: const Size(100, 100),
                  onSelectionMove: (delta) {
                    totalDelta += delta;
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      final moveDetector = tester.widgetList<GestureDetector>(find.byType(GestureDetector)).firstWhere(
            (widget) => widget.onPanStart != null && widget.child is SizedBox,
          );

      moveDetector.onPanStart!(
        DragStartDetails(globalPosition: const Offset(48, 48)),
      );
      moveDetector.onPanUpdate!(
        DragUpdateDetails(globalPosition: const Offset(68, 48)),
      );
      moveDetector.onPanUpdate!(
        DragUpdateDetails(globalPosition: const Offset(76, 48)),
      );
      moveDetector.onPanUpdate!(
        DragUpdateDetails(globalPosition: const Offset(84, 48)),
      );
      moveDetector.onPanEnd!(DragEndDetails());

      expect(totalDelta, const Offset(2, 0));
    });

    testWidgets('tap on selection body can clear active selection', (tester) async {
      var tapCount = 0;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 100,
              height: 100,
              child: SelectionOverlay(
                selectionRegion: SelectionRegion(
                  path: Path()..addRect(const Rect.fromLTWH(2, 2, 4, 4)),
                  bounds: const Rect.fromLTWH(2, 2, 4, 4),
                  shape: SelectionShape.rectangle,
                ),
                zoomLevel: 1.0,
                canvasOffset: Offset.zero,
                canvasWidth: 10,
                canvasHeight: 10,
                canvasSize: const Size(100, 100),
                onSelectionTap: () {
                  tapCount++;
                },
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      final moveDetector =
          tester.widgetList<GestureDetector>(find.byType(GestureDetector)).firstWhere((widget) => widget.onTap != null);
      moveDetector.onTap!();

      expect(tapCount, 1);
    });

    testWidgets('move area is disabled when direct move is off', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 100,
              height: 100,
              child: SelectionOverlay(
                selectionRegion: SelectionRegion(
                  path: Path()..addRect(const Rect.fromLTWH(2, 2, 4, 4)),
                  bounds: const Rect.fromLTWH(2, 2, 4, 4),
                  shape: SelectionShape.rectangle,
                ),
                allowDirectMove: false,
                showMoveHandle: true,
                zoomLevel: 1.0,
                canvasOffset: Offset.zero,
                canvasWidth: 10,
                canvasHeight: 10,
                canvasSize: const Size(100, 100),
                onSelectionMove: (_) {},
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      final hasBodyMoveDetector =
          tester.widgetList<GestureDetector>(find.byType(GestureDetector)).any((widget) => widget.child is SizedBox);

      expect(hasBodyMoveDetector, isFalse);
      expect(find.byIcon(Icons.open_with), findsOneWidget);
    });

    testWidgets('tap outside selection clears active selection in canvas', (tester) async {
      final layer = Layer(
        layerId: 1,
        id: 'layer-1',
        name: 'Layer 1',
        pixels: Uint32List(100),
      );
      final selectionRegion = SelectionRegion(
        path: Path()..addRect(const Rect.fromLTWH(2, 2, 4, 4)),
        bounds: const Rect.fromLTWH(2, 2, 4, 4),
        shape: SelectionShape.rectangle,
      );
      SelectionRegion? clearedTo = selectionRegion;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 100,
              height: 100,
              child: PixelCanvas(
                width: 10,
                height: 10,
                layers: [layer],
                currentLayerIndex: 0,
                onTapPixel: (_, __) {},
                currentTool: PixelTool.select,
                currentColor: Colors.black,
                onDrawShape: (_) {},
                onStartDrawing: () {},
                onFinishDrawing: () {},
                onSelectionChanged: (region) {
                  clearedTo = region;
                },
                selectionState: SelectionState(region: selectionRegion),
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.tapAt(const Offset(85, 85));
      await tester.pump();

      expect(clearedTo, isNull);
    });

    testWidgets('pencil drawing still reaches canvas with active selection', (tester) async {
      final layer = Layer(
        layerId: 1,
        id: 'layer-1',
        name: 'Layer 1',
        pixels: Uint32List(100),
      );
      final selectionRegion = SelectionRegion(
        path: Path()..addRect(const Rect.fromLTWH(2, 2, 4, 4)),
        bounds: const Rect.fromLTWH(2, 2, 4, 4),
        shape: SelectionShape.rectangle,
      );
      List<dynamic>? drawnPoints;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 100,
              height: 100,
              child: PixelCanvas(
                width: 10,
                height: 10,
                layers: [layer],
                currentLayerIndex: 0,
                onTapPixel: (_, __) {},
                currentTool: PixelTool.pencil,
                currentColor: Colors.black,
                onDrawShape: (points) {
                  drawnPoints = points;
                },
                onStartDrawing: () {},
                onFinishDrawing: () {},
                selectionState: SelectionState(region: selectionRegion),
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.tapAt(const Offset(35, 35));
      await tester.pump();

      expect(drawnPoints, isNotNull);
      expect(drawnPoints, isNotEmpty);
    });

    testWidgets('active selection tool drags selection from inside body', (tester) async {
      final layer = Layer(
        layerId: 1,
        id: 'layer-1',
        name: 'Layer 1',
        pixels: Uint32List(100),
      );
      final selectionRegion = SelectionRegion(
        path: Path()..addRect(const Rect.fromLTWH(2, 2, 4, 4)),
        bounds: const Rect.fromLTWH(2, 2, 4, 4),
        shape: SelectionShape.rectangle,
      );
      Offset totalDelta = Offset.zero;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 100,
              height: 100,
              child: PixelCanvas(
                width: 10,
                height: 10,
                layers: [layer],
                currentLayerIndex: 0,
                onTapPixel: (_, __) {},
                currentTool: PixelTool.select,
                currentColor: Colors.black,
                onDrawShape: (_) {},
                onStartDrawing: () {},
                onFinishDrawing: () {},
                onMoveSelection: (delta) {
                  totalDelta += delta;
                },
                selectionState: SelectionState(region: selectionRegion),
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.dragFrom(const Offset(35, 35), const Offset(20, 0));
      await tester.pump();

      expect(totalDelta, const Offset(2, 0));
    });

    testWidgets('selection tool keeps pivot visible', (tester) async {
      final layer = Layer(
        layerId: 1,
        id: 'layer-1',
        name: 'Layer 1',
        pixels: Uint32List(100),
      );
      final selectionRegion = SelectionRegion(
        path: Path()..addRect(const Rect.fromLTWH(2, 2, 4, 4)),
        bounds: const Rect.fromLTWH(2, 2, 4, 4),
        shape: SelectionShape.rectangle,
      );

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 100,
              height: 100,
              child: PixelCanvas(
                width: 10,
                height: 10,
                layers: [layer],
                currentLayerIndex: 0,
                onTapPixel: (_, __) {},
                currentTool: PixelTool.select,
                currentColor: Colors.black,
                onDrawShape: (_) {},
                onStartDrawing: () {},
                onFinishDrawing: () {},
                selectionState: SelectionState(region: selectionRegion),
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.byIcon(Icons.adjust), findsOneWidget);
    });
  });
}
