import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:picell/data.dart';
import 'package:picell/data/models/selection_region.dart';
import 'package:picell/data/repo/template_api_repo.dart';
import 'package:picell/pixel/pixel_canvas_state.dart';
import 'package:picell/pixel/providers/pixel_controller_provider.dart';
import 'package:picell/providers/editor_settings_provider.dart';
import 'package:picell/providers/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'rig/fake_project_repo.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.init();
  });

  // 8×8 canvas with a 3×1 red line at (2..4, 3), which is selected.
  const w = 8, h = 8, red = 0xFFFF0000;
  int at(int x, int y) => y * w + x;

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
        Layer(
          layerId: 1,
          id: 'a',
          name: 'A',
          pixels: Uint32List.fromList([for (var i = 0; i < w * h; i++) i >= at(2, 3) && i <= at(4, 3) ? red : 0]),
        ),
      ]),
    ],
  );

  final lineSelection = SelectionRegion(
    path: Path()..addRect(const Rect.fromLTWH(2, 3, 3, 1)),
    bounds: const Rect.fromLTWH(2, 3, 3, 1),
    shape: SelectionShape.rectangle,
  );

  // A fresh editor with the line selected.
  (ProviderContainer, PixelDrawController) open() {
    final container = ProviderContainer(overrides: [
      projectRepo.overrideWithValue(_LayerRepo()),
      templateAPIRepoProvider.overrideWithValue(_FakeTemplateRepo()),
    ]);
    container.listen(pixelDrawControllerProvider(project), (_, __) {});
    final controller = container.read(pixelDrawControllerProvider(project).notifier);
    controller.setSelection(lineSelection);
    return (container, controller);
  }

  late ProviderContainer container;
  late PixelDrawController controller;

  PixelCanvasState read() => container.read(pixelDrawControllerProvider(project));
  Set<(int, int)> redCells(PixelCanvasState s) => {
        for (final (i, p) in s.currentLayer.pixels.indexed)
          if (p == red) (i % w, i ~/ w),
      };

  setUp(() => (container, controller) = open());

  tearDown(() async {
    await controller.flushPendingProjectSave();
    container.dispose();
  });

  group('setSelectionBounds', () {
    test('moves the selected pixels as a step Esc can revert', () {
      final undoBefore = controller.undoStackSize;
      controller.setSelectionBounds(const Rect.fromLTWH(4, 5, 3, 1));

      expect(redCells(read()), {(4, 5), (5, 5), (6, 5)});
      expect(read().selectionState!.region.bounds, const Rect.fromLTWH(4, 5, 3, 1));
      expect(controller.undoStackSize, undoBefore + 1);
      expect(controller.hasTransformSession, isTrue);

      controller.cancelTransformSession();
      expect(redCells(read()), {(2, 3), (3, 3), (4, 3)});
    });

    test('resizes them', () {
      // Nearest neighbour, so the stretched line keeps hard edges.
      final settings = container.read(editorSettingsNotifierProvider.notifier);
      settings.setTransformInterpolation(TransformInterpolation.nearest);
      addTearDown(() => settings.setTransformInterpolation(TransformInterpolation.bilinear));

      controller.setSelectionBounds(const Rect.fromLTWH(2, 3, 6, 1));
      expect(redCells(read()), {for (var x = 2; x < 8; x++) (x, 3)});
    });

    test('unchanged or empty bounds do nothing', () {
      final undoBefore = controller.undoStackSize;
      controller.setSelectionBounds(const Rect.fromLTWH(2, 3, 3, 1));
      controller.setSelectionBounds(const Rect.fromLTWH(2, 3, 0, 1));
      expect(controller.undoStackSize, undoBefore);
    });
  });

  group('rotateSelectionBy', () {
    test('turns the pixels around the anchor', () {
      controller.rotateSelectionBy(math.pi / 2);

      final cells = redCells(read());
      expect(cells.length, 3);
      expect(cells.map((c) => c.$1).toSet().length, 1, reason: 'a vertical line');
      expect(controller.hasTransformSession, isTrue);
    });

    test('a zero angle does nothing', () {
      final undoBefore = controller.undoStackSize;
      controller.rotateSelectionBy(0);
      expect(controller.undoStackSize, undoBefore);
    });
  });

  group('RotSprite setting', () {
    setUp(() => container.read(editorSettingsNotifierProvider.notifier).setTransformInterpolation(
          TransformInterpolation.rotSprite,
        ));
    tearDown(() => container.read(editorSettingsNotifierProvider.notifier).setTransformInterpolation(
          TransformInterpolation.bilinear,
        ));

    test('a drag previews with nearest neighbour and ends with RotSprite', () async {
      const angle = math.pi / 5;
      controller.startTransformSelection(read().selectionState!.region);
      controller.rotateSelectionNew(angle);
      final preview = read().currentLayer.pixels.toList();
      controller.endTransformSelection();
      final finished = read().currentLayer.pixels.toList();

      // The same rotation typed in renders RotSprite directly.
      final (otherContainer, other) = open();
      other.rotateSelectionBy(angle);
      final typed = otherContainer.read(pixelDrawControllerProvider(project)).currentLayer.pixels.toList();
      await other.flushPendingProjectSave();
      otherContainer.dispose();

      expect(finished, typed);
      expect(finished.every((p) => p == 0 || p == red), isTrue, reason: 'no blended colours');
      expect(preview.every((p) => p == 0 || p == red), isTrue);
    });

    test('resizing uses nearest neighbour, never blending', () {
      controller.setSelectionBounds(const Rect.fromLTWH(1, 2, 5, 3));
      expect(read().currentLayer.pixels.every((p) => p == 0 || p == red), isTrue);
    });
  });
}

class _FakeTemplateRepo extends Fake implements TemplateAPIRepo {}

class _LayerRepo extends FakeProjectRepo {
  @override
  Future<void> updateLayer(int projectId, int frameId, Layer layer) async {}
}
