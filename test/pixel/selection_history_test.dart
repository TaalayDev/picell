import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:picell/data.dart';
import 'package:picell/data/models/selection_region.dart';
import 'package:picell/data/repo/template_api_repo.dart';
import 'package:picell/pixel/pixel_canvas_state.dart';
import 'package:picell/pixel/providers/pixel_canvas_provider.dart';
import 'package:picell/pixel/providers/pixel_controller_provider.dart';
import 'package:picell/providers/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'rig/fake_project_repo.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.init();
  });

  // 4×2 canvas. Layer A has a red pixel at (0, 0); layer B, above it, has a
  // green 2×1 block at (2, 1).
  const w = 4, h = 2, red = 0xFFFF0000, green = 0xFF00FF00;
  List<int> px(Map<int, int> set) => [for (var i = 0; i < w * h; i++) set[i] ?? 0];

  final project = Project(
    id: 1,
    name: 'P',
    width: w,
    height: h,
    createdAt: DateTime(2026),
    editedAt: DateTime(2026),
    states: const [AnimationStateModel(id: 1, name: 'Idle', frameRate: 12)],
    frames: [
      AnimationFrame(id: 10, name: 'F', stateId: 1, duration: 100, layers: [
        Layer(layerId: 1, id: 'a', name: 'A', pixels: Uint32List.fromList(px({0: red}))),
        Layer(layerId: 2, id: 'b', name: 'B', pixels: Uint32List.fromList(px({6: green, 7: green})), order: 1),
      ]),
    ],
  );

  SelectionRegion rect(double x, double y, double width, double height) => SelectionRegion(
        path: Path()..addRect(Rect.fromLTWH(x, y, width, height)),
        bounds: Rect.fromLTWH(x, y, width, height),
        shape: SelectionShape.rectangle,
      );

  late ProviderContainer container;
  late PixelDrawController controller;

  PixelCanvasState read() => container.read(pixelDrawControllerProvider(project));
  Rect? bounds() => read().selectionState?.region.bounds;

  setUp(() {
    container = ProviderContainer(overrides: [
      projectRepo.overrideWithValue(_LayerRepo()),
      templateAPIRepoProvider.overrideWithValue(_FakeTemplateRepo()),
    ]);
    container.listen(pixelDrawControllerProvider(project), (_, __) {});
    controller = container.read(pixelDrawControllerProvider(project).notifier);
  });

  tearDown(() async {
    await controller.flushPendingProjectSave();
    container.dispose();
  });

  group('undoable selection changes', () {
    test('each selection is an undo step, and redo brings it back', () {
      final undoBefore = controller.undoStackSize;
      controller.selectRegion(rect(0, 0, 1, 1));
      controller.selectRegion(rect(1, 0, 2, 2));
      expect(controller.undoStackSize, undoBefore + 2);
      expect(controller.undoStackSummary.last, startsWith('Selection'));

      controller.undo();
      expect(bounds(), const Rect.fromLTWH(0, 0, 1, 1));
      controller.undo();
      expect(read().selectionState, isNull);

      controller.redo();
      controller.redo();
      expect(bounds(), const Rect.fromLTWH(1, 0, 2, 2));
    });

    test('deselect is undoable and deselecting nothing records nothing', () {
      final undoBefore = controller.undoStackSize;
      controller.selectRegion(null);
      expect(controller.undoStackSize, undoBefore);

      controller.selectRegion(rect(0, 0, 2, 1));
      controller.selectRegion(null);
      expect(read().selectionState, isNull);
      controller.undo();
      expect(bounds(), const Rect.fromLTWH(0, 0, 2, 1));
    });

    test('select all, invert, grow and shrink are one step each', () {
      final undoBefore = controller.undoStackSize;
      controller.selectRegion(rect(0, 0, 1, 1));
      controller.invertSelectionRegion();
      controller.selectAll();
      controller.shrinkSelectionRegion();
      expect(controller.undoStackSize, undoBefore + 4);

      controller.undo();
      expect(bounds(), const Rect.fromLTWH(0, 0, 4, 2), reason: 'back to select all');
    });

    test('undo walks back through selections and pixel edits in order', () {
      controller.selectRegion(rect(0, 0, 1, 1));
      controller.startTransformSelection(read().selectionState!.region);
      controller.moveSelection(const Offset(1, 0));
      controller.endTransformSelection();
      controller.selectRegion(rect(3, 1, 1, 1));

      controller.undo();
      expect(bounds(), const Rect.fromLTWH(1, 0, 1, 1), reason: 'the moved selection');
      expect(read().currentLayer.pixels.toList(), px({1: red}));

      controller.undo();
      expect(read().currentLayer.pixels.toList(), px({0: red}));
      expect(bounds(), const Rect.fromLTWH(0, 0, 1, 1));
    });

    test('undoing a selection never restores floating pixels', () {
      controller.selectRegion(rect(0, 0, 1, 1));
      controller.startTransformSelection(read().selectionState!.region);
      controller.moveSelection(const Offset(1, 0));
      controller.endTransformSelection();
      controller.selectRegion(null);

      controller.undo();
      expect(read().selectionState!.capturedPixels, isNull);
      expect(read().selectionState!.isTransforming, isFalse);
    });
  });

  test('selections made with the selection tools go through the undoable path', () {
    // The canvas confirms tool selections through the canvas notifier.
    final notifier = container.read(pixelCanvasNotifierProvider(project).notifier);
    final undoBefore = controller.undoStackSize;
    notifier.setSelection(rect(0, 0, 2, 2));
    notifier.clearSelection();
    expect(controller.undoStackSize, undoBefore + 2);
    expect(notifier.canReselect, isTrue);

    notifier.reselect();
    expect(bounds(), const Rect.fromLTWH(0, 0, 2, 2));
  });

  group('reselect', () {
    test('brings back the last deselected selection as an undo step', () {
      expect(controller.canReselect, isFalse);
      controller.selectRegion(rect(1, 0, 2, 1));
      controller.selectRegion(null);
      expect(controller.canReselect, isTrue);

      final undoBefore = controller.undoStackSize;
      controller.reselect();
      expect(bounds(), const Rect.fromLTWH(1, 0, 2, 1));
      expect(controller.undoStackSize, undoBefore + 1);
    });

    test('does nothing when nothing was deselected', () {
      final undoBefore = controller.undoStackSize;
      controller.reselect();
      expect(read().selectionState, isNull);
      expect(controller.undoStackSize, undoBefore);
    });
  });

  group('selectLayerPixels', () {
    test('selects the opaque pixels of any layer, not just the active one', () {
      controller.selectLayer(0);
      controller.selectLayerPixels(1);
      expect(bounds(), const Rect.fromLTWH(2, 1, 2, 1));
      expect(read().currentLayerIndex, 0, reason: 'the active layer stays');

      controller.undo();
      expect(read().selectionState, isNull);
    });

    test('an empty layer or a bad index selects nothing', () {
      controller.selectLayerPixels(5);
      expect(read().selectionState, isNull);
    });
  });

  group('intersect', () {
    test('keeps only the overlap of the two shapes', () {
      final combined = rect(0, 0, 3, 2).combine(rect(2, 1, 2, 1), SelectionMode.intersect);
      expect(combined.bounds, const Rect.fromLTWH(2, 1, 1, 1));
      expect(combined.contains(2, 1), isTrue);
      expect(combined.contains(3, 1), isFalse);
      expect(combined.contains(0, 0), isFalse);
    });

    test('disjoint shapes intersect to nothing', () {
      final combined = rect(0, 0, 1, 1).combine(rect(3, 1, 1, 1), SelectionMode.intersect);
      expect(combined.bounds.isEmpty, isTrue);
    });
  });
}

class _FakeTemplateRepo extends Fake implements TemplateAPIRepo {}

class _LayerRepo extends FakeProjectRepo {
  @override
  Future<void> updateLayer(int projectId, int frameId, Layer layer) async {}
}
