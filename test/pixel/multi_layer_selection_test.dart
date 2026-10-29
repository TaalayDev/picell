import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:picell/data.dart';
import 'package:picell/data/models/selection_region.dart';
import 'package:picell/data/repo/template_api_repo.dart';
import 'package:picell/pixel/providers/pixel_controller_provider.dart';
import 'package:picell/pixel/services/pixel_transform_service.dart';
import 'package:picell/providers/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'rig/fake_project_repo.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Scale and rotate read the interpolation setting from editor settings.
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.init();
  });

  // 4×2 canvas. The selection is the left 2×2 square. Every layer has one
  // pixel inside it; A and B are editable, C is locked, D is hidden and E is
  // not selected in the layers panel.
  const w = 4, h = 2;
  const red = 0xFFFF0000, green = 0xFF00FF00;
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
        Layer(layerId: 2, id: 'b', name: 'B', pixels: Uint32List.fromList(px({4: green}))),
        Layer(layerId: 3, id: 'c', name: 'C', pixels: Uint32List.fromList(px({0: 3})), isLocked: true),
        Layer(layerId: 4, id: 'd', name: 'D', pixels: Uint32List.fromList(px({0: 4})), isVisible: false),
        Layer(layerId: 5, id: 'e', name: 'E', pixels: Uint32List.fromList(px({0: 5}))),
      ]),
    ],
  );

  final region = SelectionRegion(
    path: Path()..addRect(const Rect.fromLTWH(0, 0, 2, 2)),
    bounds: const Rect.fromLTWH(0, 0, 2, 2),
    shape: SelectionShape.rectangle,
  );

  late ProviderContainer container;
  late PixelDrawController controller;

  List<List<int>> layers() => [
        for (final l in container.read(pixelDrawControllerProvider(project)).currentFrame.layers) l.pixels.toList(),
      ];

  // Locked, hidden and unselected layers never change.
  void expectUntouched(List<List<int>> now) {
    expect(now[2], px({0: 3}));
    expect(now[3], px({0: 4}));
    expect(now[4], px({0: 5}));
  }

  setUp(() {
    container = ProviderContainer(overrides: [
      projectRepo.overrideWithValue(_LayerRecordingRepo()),
      templateAPIRepoProvider.overrideWithValue(_FakeTemplateRepo()),
    ]);
    container.listen(pixelDrawControllerProvider(project), (_, __) {});
    controller = container.read(pixelDrawControllerProvider(project).notifier);
    controller.selectedLayerIndices = const [0, 1, 2, 3];
    controller.setSelection(region);
  });

  tearDown(() async {
    await controller.flushPendingProjectSave();
    container.dispose();
  });

  void expectUndoRestoresAll() {
    controller.undo();
    final now = layers();
    expect(now[0], px({0: red}));
    expect(now[1], px({4: green}));
    expectUntouched(now);
  }

  test('Delete clears the selection on every editable selected layer as one undo step', () {
    controller.clearSelectionArea();
    final now = layers();
    expect(now[0], px({}));
    expect(now[1], px({}));
    expectUntouched(now);

    expectUndoRestoresAll();
  });

  test('moving the selection moves every selected layer, one undo reverts all', () {
    controller.startTransformSelection(region);
    controller.moveSelection(const Offset(1, 0));
    controller.moveSelection(const Offset(1, 0));
    controller.endTransformSelection();

    var now = layers();
    expect(now[0], px({2: red}));
    expect(now[1], px({6: green}));
    expectUntouched(now);

    // A second drag continues from the floating pixels on every layer.
    final moved = container.read(pixelDrawControllerProvider(project)).selectionState!.region;
    controller.startTransformSelection(moved);
    controller.moveSelection(const Offset(-1, 0));
    controller.endTransformSelection();
    now = layers();
    expect(now[0], px({1: red}));
    expect(now[1], px({5: green}));

    controller.undo();
    expect(layers()[0], px({2: red}));
    expect(layers()[1], px({6: green}));
    expectUndoRestoresAll();
  });

  test('scaling the selection scales every selected layer the same way', () {
    controller.startTransformSelection(region);
    controller.resizeSelectionNew(const Rect.fromLTWH(0, 0, 4, 2));
    controller.endTransformSelection();

    final now = layers();
    // A's pixel sits in row 0 and B's in row 1; the horizontal stretch must
    // cover the same columns on both.
    final aRow = now[0].sublist(0, w).map((p) => p != 0).toList();
    final bRow = now[1].sublist(w).map((p) => p != 0).toList();
    expect(aRow.where((v) => v).length, greaterThan(1));
    expect(bRow, aRow);
    expect(now[0].sublist(w), everyElement(0));
    expect(now[1].sublist(0, w), everyElement(0));
    expectUntouched(now);

    expectUndoRestoresAll();
  });

  test('rotating the selection rotates every selected layer like rotating each alone', () {
    void rotate() {
      controller.setSelection(region);
      controller.startTransformSelection(region);
      controller.rotateSelectionNew(math.pi / 2);
      controller.endTransformSelection();
    }

    rotate();
    final together = layers();
    // A quarter turn clockwise about the square's centre:
    // (0,0) → (1,0) and (0,1) → (0,0), with nothing lost.
    expect(together[0], px({1: red}));
    expect(together[1], px({0: green}));
    expectUntouched(together);
    expectUndoRestoresAll();

    // Rotate each layer on its own and compare.
    for (final index in [0, 1]) {
      controller.selectLayer(index);
      controller.selectedLayerIndices = [index];
      rotate();
      expect(layers()[index], together[index], reason: 'layer $index');
      controller.undo();
    }
  });

  test('flipping the selection flips every selected layer', () {
    controller.transformSelection(PixelTransform.flipHorizontal);
    final now = layers();
    expect(now[0], px({1: red}));
    expect(now[1], px({5: green}));
    expectUntouched(now);

    expectUndoRestoresAll();
  });

  test('cut returns the selected layers merged and clears them', () {
    final copied = controller.cutSelectionPixels()!;
    expect(copied.toList(), px({0: red, 4: green}));
    final now = layers();
    expect(now[0], px({}));
    expect(now[1], px({}));
    expectUntouched(now);

    expectUndoRestoresAll();
  });

  test('with only the active layer selected, edits leave other layers alone', () {
    controller.selectedLayerIndices = const [0];
    controller.setSelection(region);
    controller.startTransformSelection(region);
    controller.moveSelection(const Offset(2, 0));
    controller.endTransformSelection();
    controller.clearSelectionArea();

    final now = layers();
    expect(now[0], px({}));
    expect(now[1], px({4: green}));
    expectUntouched(now);
  });

  test('a half turn of a small selection keeps every pixel', () {
    controller.startTransformSelection(region);
    controller.rotateSelectionNew(math.pi);
    controller.endTransformSelection();

    final now = layers();
    expect(now[0], px({5: red}));
    expect(now[1], px({1: green}));
  });

  group('single layer: a drag after an edit starts from the edited pixels', () {
    SelectionRegion currentRegion() => container.read(pixelDrawControllerProvider(project)).selectionState!.region;

    void drag(Offset by) {
      controller.startTransformSelection(currentRegion());
      controller.moveSelection(by);
      controller.endTransformSelection();
    }

    setUp(() {
      controller.selectedLayerIndices = const [0];
      controller.setSelection(region);
    });

    test('deleted pixels do not come back', () {
      drag(const Offset(2, 0));
      expect(layers()[0], px({2: red}));
      controller.clearSelectionArea();
      expect(layers()[0], px({}));

      drag(const Offset(-2, 0));
      expect(layers()[0], px({}));
    });

    test('pixels drawn into the selection move with it', () {
      drag(const Offset(2, 0));
      controller.applyAutomationPixels(Uint32List.fromList(px({2: red, 7: green})));

      drag(const Offset(-2, 0));
      expect(layers()[0], px({0: red, 5: green}));
    });

    test('an undone drag is not replayed by the next one', () {
      drag(const Offset(2, 0));
      controller.undo();
      expect(layers()[0], px({0: red}));

      controller.setSelection(region);
      drag(const Offset(1, 0));
      expect(layers()[0], px({1: red}));
    });
  });

  test('a multi-selection that leaves out the active layer acts on the active layer only', () {
    controller.selectedLayerIndices = const [1, 4];
    controller.setSelection(region);
    controller.clearSelectionArea();

    final now = layers();
    expect(now[0], px({}));
    expect(now[1], px({4: green}));
    expect(now[4], px({0: 5}));
  });
}

class _FakeTemplateRepo extends Fake implements TemplateAPIRepo {}

class _LayerRecordingRepo extends FakeProjectRepo {
  final updatedLayers = <Layer>[];

  @override
  Future<void> updateLayer(int projectId, int frameId, Layer layer) async => updatedLayers.add(layer);
}
