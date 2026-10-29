import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:picell/data.dart';
import 'package:picell/data/models/selection_region.dart';
import 'package:picell/data/repo/template_api_repo.dart';
import 'package:picell/pixel/pixel_canvas_state.dart';
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

  // 5×5 canvas, two frames. Layer A is opaque everywhere, each pixel's low
  // bits holding its index; layer B, above it, has one red pixel in the
  // middle (index 12).
  const w = 5, h = 5, red = 0xFFFF0000, blue = 0xFF0000FF;
  int a(int i) => 0xFF000000 | i;
  List<int> layerA() => [for (var i = 0; i < w * h; i++) a(i)];

  AnimationFrame frame(int id, int order) => AnimationFrame(
        id: id,
        name: 'F$id',
        stateId: 1,
        duration: 100,
        order: order,
        layers: [
          Layer(
            layerId: id * 10,
            id: 'a$id',
            name: 'A',
            pixels: Uint32List.fromList(layerA()),
            anchorPoint: const Offset(2, 2),
          ),
          Layer(
            layerId: id * 10 + 1,
            id: 'b$id',
            name: 'B',
            pixels: Uint32List.fromList([for (var i = 0; i < w * h; i++) i == 12 ? red : 0]),
            order: 1,
          ),
        ],
      );

  final project = Project(
    id: 1,
    name: 'P',
    width: w,
    height: h,
    createdAt: DateTime(2026),
    editedAt: DateTime(2026),
    states: const [AnimationStateModel(id: 1, name: 'Idle', frameRate: 12)],
    frames: [frame(10, 0), frame(11, 1)],
  );

  SelectionRegion rect(double x, double y, double width, double height) => SelectionRegion(
        path: Path()..addRect(Rect.fromLTWH(x, y, width, height)),
        bounds: Rect.fromLTWH(x, y, width, height),
        shape: SelectionShape.rectangle,
      );

  late ProviderContainer container;
  late PixelDrawController controller;
  late FakeProjectRepo repo;

  PixelCanvasState read() => container.read(pixelDrawControllerProvider(project));
  List<int> layerPixels(int index) => read().currentFrame.layers[index].pixels.toList();
  // Indices of [index]'s pixels equal to [color].
  Set<int> painted(int index, int color) => {
        for (final (i, p) in layerPixels(index).indexed)
          if (p == color) i,
      };

  setUp(() {
    repo = _LayerRepo();
    container = ProviderContainer(overrides: [
      projectRepo.overrideWithValue(repo),
      templateAPIRepoProvider.overrideWithValue(_FakeTemplateRepo()),
    ]);
    container.listen(pixelDrawControllerProvider(project), (_, __) {});
    controller = container.read(pixelDrawControllerProvider(project).notifier);
    controller.selectFrame(10);
    controller.selectLayer(0);
  });

  tearDown(() async {
    await controller.flushPendingProjectSave();
    container.dispose();
  });

  group('fillSelection', () {
    test('fills the selection on the active layer as one undo step', () {
      controller.setSelection(rect(1, 0, 2, 2));
      final undoBefore = controller.undoStackSize;
      controller.fillSelection(const Color(blue));

      expect(painted(0, blue), {1, 2, 6, 7});
      expect(layerPixels(0)[0], a(0));
      expect(controller.undoStackSize, undoBefore + 1);

      controller.undo();
      expect(layerPixels(0), layerA());
    });

    test('fills every selected layer together', () {
      controller.selectLayer(1);
      controller.selectedLayerIndices = [0, 1];
      controller.setSelection(rect(0, 0, 1, 1));
      final undoBefore = controller.undoStackSize;
      controller.fillSelection(const Color(blue));

      expect(painted(0, blue), {0});
      expect(painted(1, blue), {0});
      expect(controller.undoStackSize, undoBefore + 1);
    });

    test('does nothing without a selection', () {
      final undoBefore = controller.undoStackSize;
      controller.fillSelection(const Color(blue));
      expect(controller.undoStackSize, undoBefore);
    });
  });

  group('strokeSelection', () {
    test('draws a 1-pixel ring just inside the selection', () {
      controller.setSelection(rect(1, 1, 3, 3));
      controller.strokeSelection(const Color(blue));

      expect(painted(0, blue), {6, 7, 8, 11, 13, 16, 17, 18});
    });

    test('or just outside it, without the diagonal corners', () {
      controller.setSelection(rect(1, 1, 3, 3));
      controller.strokeSelection(const Color(blue), inside: false);

      expect(painted(0, blue), {1, 2, 3, 5, 9, 10, 14, 15, 19, 21, 22, 23});
    });

    test('the canvas border counts as outside', () {
      controller.selectAll();
      controller.strokeSelection(const Color(blue));

      expect(painted(0, blue).length, 16, reason: 'the 5×5 border ring');
      expect(painted(0, blue).contains(12), isFalse);
    });
  });

  group('copyMergedSelectionPixels', () {
    test('copies what every visible layer shows inside the selection', () {
      controller.setSelection(rect(1, 2, 2, 1));
      final copied = controller.copyMergedSelectionPixels()!;

      expect(copied[11], a(11));
      expect(copied[12], red, reason: 'layer B covers layer A here');
      expect(copied[0], 0, reason: 'outside the selection');
      expect(controller.copySelectionPixels()![12], a(12), reason: 'a plain copy is the active layer only');
    });

    test('is null without a selection', () {
      expect(controller.copyMergedSelectionPixels(), isNull);
    });
  });

  group('paste in place', () {
    // A red pixel at (0, 0) copied from a 2×1 canvas.
    final source = Uint32List.fromList([red, 0]);

    test('keeps the copied coordinates across canvas sizes', () async {
      await controller.pastePixels(source, rect(0, 0, 1, 1), sourceWidth: 2, sourceHeight: 1, inPlace: true);

      // Pasted above the active (bottom) layer, and active itself.
      expect(read().currentLayer.name, 'Pasted');
      expect(read().currentLayerIndex, 1);
      expect(read().currentFrame.layers.last.name, 'B');
      expect(painted(read().currentLayerIndex, red), {0});
      expect(read().selectionState!.region.bounds, const Rect.fromLTWH(0, 0, 1, 1));
    });

    test('a plain paste centers it instead', () async {
      await controller.pastePixels(source, rect(0, 0, 1, 1), sourceWidth: 2, sourceHeight: 1);

      // Offset ((5 - 2) / 2, (5 - 1) / 2) = (1, 2).
      expect(painted(read().currentLayerIndex, red), {11});
    });
  });

  group('cropCanvasToSelection', () {
    test('crops every frame and layer and saves the project', () async {
      controller.setSelection(rect(1, 1, 3, 2));
      expect(controller.canCropToSelection, isTrue);

      final cropped = (await controller.cropCanvasToSelection())!;
      expect((cropped.width, cropped.height), (3, 2));
      for (final frame in cropped.frames) {
        expect(frame.layers[0].pixels.toList(), [a(6), a(7), a(8), a(11), a(12), a(13)]);
        expect(frame.layers[1].pixels.toList(), [0, 0, 0, 0, red, 0]);
        expect(frame.layers[0].anchorPoint, const Offset(1, 1), reason: 'anchors move with the content');
      }
      expect(repo.updatedProjects.last.width, 3);
      expect(repo.updatedProjects.last.height, 2);
    });

    test('the old editor stops saving afterwards', () async {
      controller.setSelection(rect(0, 0, 2, 2));
      await controller.cropCanvasToSelection();
      final saves = repo.updatedProjects.length;

      controller.fillSelection(const Color(blue));
      await controller.flushPendingProjectSave();
      expect(repo.updatedProjects.length, saves);
    });

    test('needs a selection smaller than the canvas', () async {
      expect(controller.canCropToSelection, isFalse);
      controller.selectAll();
      expect(controller.canCropToSelection, isFalse);
      expect(await controller.cropCanvasToSelection(), isNull);
    });

    test('is not offered for a project with a bone rig', () async {
      final rigged = project.copyWith(rigData: '[]');
      final riggedContainer = ProviderContainer(overrides: [
        projectRepo.overrideWithValue(_LayerRepo()),
        templateAPIRepoProvider.overrideWithValue(_FakeTemplateRepo()),
      ]);
      riggedContainer.listen(pixelDrawControllerProvider(rigged), (_, __) {});
      final riggedController = riggedContainer.read(pixelDrawControllerProvider(rigged).notifier);
      riggedController.setSelection(rect(1, 1, 2, 2));

      expect(riggedController.canCropToSelection, isFalse);
      expect(await riggedController.cropCanvasToSelection(), isNull);
      await riggedController.flushPendingProjectSave();
      riggedContainer.dispose();
    });

    test('selections hanging off the canvas are clipped to it', () async {
      controller.setSelection(rect(3.5, 3.5, 4, 4));
      final cropped = (await controller.cropCanvasToSelection())!;
      expect((cropped.width, cropped.height), (2, 2));
      expect(cropped.frames.first.layers[0].pixels.toList(), [a(18), a(19), a(23), a(24)]);
    });
  });
}

class _FakeTemplateRepo extends Fake implements TemplateAPIRepo {}

class _LayerRepo extends FakeProjectRepo {
  @override
  Future<void> updateLayer(int projectId, int frameId, Layer layer) async {}
}
