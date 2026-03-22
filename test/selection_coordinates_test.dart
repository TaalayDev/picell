import 'dart:typed_data';

import 'package:flutter/material.dart' hide SelectionOverlay;
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/data/models/layer.dart';
import 'package:picell/data/models/selection_region.dart';
import 'package:picell/pixel/canvas/widgets/selection_overlay.dart';
import 'package:picell/pixel/services/selection_service.dart';
import 'package:picell/pixel/tools.dart';
import 'package:picell/pixel/tools/selection_tool.dart';

void main() {
  group('Selection coordinates', () {
    test('rectangle selection uses widget size to map to pixel coordinates',
        () {
      SelectionRegion? result;
      final layer = Layer(
        layerId: 1,
        id: 'layer-1',
        name: 'Layer 1',
        pixels: Uint32List(100),
      );

      final tool = SelectionTool(
        selectionService: SelectionService(width: 10, height: 10),
        onSelectionChanged: (_) {},
        onSelectionEnd: (region) => result = region,
        getCanvasSize: () => const Size(10, 10),
        gridWidth: 10,
        gridHeight: 10,
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

    testWidgets('resize handle respects parent scale transform',
        (tester) async {
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
  });
}
