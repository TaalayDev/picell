import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:picell/data.dart';
import 'package:picell/data/models/selection_region.dart';
import 'package:picell/data/repo/template_api_repo.dart';
import 'package:picell/pixel/pixel_canvas_state.dart';
import 'package:picell/pixel/providers/editor_selection_provider.dart';
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

  // 2×1 canvas. Idle holds frames 10..13, Run holds 20. Every frame has three
  // layers whose left pixel is the frame id times ten plus the layer index.
  AnimationFrame frame(int id, int stateId, int order) => AnimationFrame(
        id: id,
        name: 'F$id',
        stateId: stateId,
        duration: 100,
        order: order,
        layers: [
          for (var i = 0; i < 3; i++)
            Layer(
              layerId: id * 10 + i,
              id: 'l$id-$i',
              name: 'L$i',
              pixels: Uint32List.fromList([id * 10 + i, 0]),
            ),
        ],
      );

  final project = Project(
    id: 1,
    name: 'P',
    width: 2,
    height: 1,
    createdAt: DateTime(2026),
    editedAt: DateTime(2026),
    states: const [
      AnimationStateModel(id: 1, name: 'Idle', frameRate: 12),
      AnimationStateModel(id: 2, name: 'Run', frameRate: 12),
    ],
    frames: [
      for (var i = 0; i < 4; i++) frame(10 + i, 1, i),
      frame(20, 2, 0),
    ],
  );

  late ProviderContainer container;
  late PixelDrawController controller;

  PixelCanvasState read() => container.read(pixelDrawControllerProvider(project));
  List<int> idleIds() => [for (final f in read().frames.where((f) => f.stateId == 1)) f.id];
  int activeId() => read().currentFrame.id;
  List<int> layerNames() => [for (final l in read().currentFrame.layers) l.pixels.first];

  // The selection is always non-empty, inside the current animation and holds
  // the active frame.
  void expectValidSelection() {
    final ids = controller.selectedFrameIds;
    final current = {for (final f in read().currentFrames) f.id};
    expect(ids, contains(activeId()));
    expect(current.containsAll(ids), isTrue, reason: '$ids not all in $current');
  }

  setUp(() {
    container = ProviderContainer(overrides: [
      projectRepo.overrideWithValue(_LayerRepo()),
      templateAPIRepoProvider.overrideWithValue(_FakeTemplateRepo()),
    ]);
    container.listen(pixelDrawControllerProvider(project), (_, __) {});
    controller = container.read(pixelDrawControllerProvider(project).notifier);
    controller.selectFrame(10);
  });

  tearDown(() async {
    await controller.flushPendingProjectSave();
    container.dispose();
  });

  group('frame selection', () {
    test('starts with only the active frame', () {
      expect(controller.selectedFrameIds, {10});
      expect(controller.editorSelection.target, EditorSelectionTarget.canvas);
    });

    test('toggle adds and removes frames and moves the active frame', () {
      controller.selectFrames(12, toggle: true);
      expect(controller.selectedFrameIds, {10, 12});
      expect(activeId(), 12);
      expect(controller.editorSelection.target, EditorSelectionTarget.frames);

      controller.selectFrames(12, toggle: true);
      expect(controller.selectedFrameIds, {10});
      expect(activeId(), 10);

      controller.selectFrames(10, toggle: true);
      expect(controller.selectedFrameIds, {10}, reason: 'the last frame stays selected');
    });

    test('range selects from the anchor', () {
      controller.selectFrames(11);
      controller.selectFrames(13, extendRange: true);
      expect(controller.selectedFrameIds, {11, 12, 13});
      expect(activeId(), 13);

      controller.selectFrames(10, extendRange: true);
      expect(controller.selectedFrameIds, {10, 11}, reason: 'the anchor stays at 11');
    });

    test('a plain click collapses the selection', () {
      controller.selectAllFrames();
      expect(controller.selectedFrameIds, {10, 11, 12, 13});

      controller.selectFrames(12);
      expect(controller.selectedFrameIds, {12});
    });

    test('selectFrame, next and previous collapse it too', () {
      controller.selectAllFrames();
      controller.selectFrame(11);
      expect(controller.selectedFrameIds, {11});

      controller.selectAllFrames();
      controller.nextFrame();
      expect(controller.selectedFrameIds, {12});

      controller.selectAllFrames();
      controller.previousFrame();
      expect(controller.selectedFrameIds, {11});
    });

    test('a frame of another animation switches to it and is selected alone', () {
      controller.selectFrames(11, toggle: true);
      controller.selectFrames(20, toggle: true, extendRange: true);

      expect(read().currentAnimationState.id, 2);
      expect(activeId(), 20);
      expect(controller.selectedFrameIds, {20});
    });

    test('switching animation collapses the selection', () {
      controller.selectAllFrames();
      controller.selectAnimationState(2);
      expect(controller.selectedFrameIds, {20});

      controller.selectAnimationState(1);
      expect(controller.selectedFrameIds, {10});
    });
  });

  group('frame ops keep the selection valid', () {
    test('delete collapses to the surviving active frame', () async {
      controller.selectFrames(11);
      controller.selectFrames(12, extendRange: true);
      await controller.removeFramesByIds(controller.selectedFrameIds);

      expect(idleIds(), [10, 13]);
      expect(controller.selectedFrameIds, {activeId()});
      expectValidSelection();
    });

    test('undo and redo of a delete never leave a stale selection', () async {
      controller.selectAllFrames();
      await controller.removeFramesByIds(controller.selectedFrameIds);
      expect(idleIds(), [10]);

      controller.undo();
      expect(idleIds(), [10, 11, 12, 13]);
      expectValidSelection();

      controller.redo();
      expect(idleIds(), [10]);
      expectValidSelection();
    });

    test('reorder keeps the moved frames selected', () async {
      controller.selectFrames(10);
      controller.selectFrames(11, toggle: true);
      await controller.reorderFramesByIds(controller.selectedFrameIds, 13);

      expect(idleIds(), [12, 13, 10, 11]);
      expect(controller.selectedFrameIds, {10, 11});
      expect(activeId(), 11);
    });

    test('duplicate keeps the source frames selected', () async {
      controller.selectFrames(11, toggle: true);
      await controller.duplicateFramesByIds(controller.selectedFrameIds);

      expect(idleIds().length, 6);
      expect(controller.selectedFrameIds, {10, 11});
      expectValidSelection();
    });
  });

  group('keyboard frame ops', () {
    test('extendFrameSelection grows and shrinks from the anchor', () {
      controller.selectFrame(11);
      controller.extendFrameSelection(1);
      controller.extendFrameSelection(1);
      expect(controller.selectedFrameIds, {11, 12, 13});
      expect(activeId(), 13);

      controller.extendFrameSelection(1);
      expect(controller.selectedFrameIds, {11, 12, 13}, reason: 'stops at the last frame');

      controller.extendFrameSelection(-1);
      expect(controller.selectedFrameIds, {11, 12});
      controller.extendFrameSelection(-1);
      controller.extendFrameSelection(-1);
      expect(controller.selectedFrameIds, {10, 11});
    });

    test('moveSelectedFrames shifts the block by one as one undo step', () async {
      controller.selectFrame(11);
      controller.extendFrameSelection(1);
      final undoBefore = controller.undoStackSize;

      await controller.moveSelectedFrames(1);
      expect(idleIds(), [10, 13, 11, 12]);
      expect(controller.selectedFrameIds, {11, 12});
      expect(controller.undoStackSize, undoBefore + 1);

      await controller.moveSelectedFrames(-1);
      await controller.moveSelectedFrames(-1);
      expect(idleIds(), [11, 12, 10, 13]);

      controller.undo();
      expect(idleIds(), [10, 11, 12, 13]);
    });

    test('moveSelectedFrames at either end does nothing', () async {
      controller.selectFrame(10);
      final undoBefore = controller.undoStackSize;
      await controller.moveSelectedFrames(-1);

      controller.selectFrame(13);
      await controller.moveSelectedFrames(1);
      expect(idleIds(), [10, 11, 12, 13]);
      expect(controller.undoStackSize, undoBefore);
    });

    test('moveSelectedFrames gathers a split selection', () async {
      controller.selectFrames(12, toggle: true);
      await controller.moveSelectedFrames(1);

      expect(idleIds(), [11, 13, 10, 12]);
    });
  });

  group('keyboard layer ops', () {
    test('moveSelectedLayers moves the selection up and down as one undo step', () async {
      controller.selectLayer(0);
      final undoBefore = controller.undoStackSize;

      await controller.moveSelectedLayers(1);
      expect(layerNames(), [101, 100, 102]);
      expect(read().currentLayerIndex, 1, reason: 'the active layer moves with it');
      expect(controller.undoStackSize, undoBefore + 1);
      expect([for (final l in read().currentFrame.layers) l.order], [0, 1, 2]);

      await controller.moveSelectedLayers(-1);
      expect(layerNames(), [100, 101, 102]);

      controller.undo();
      expect(layerNames(), [101, 100, 102]);
    });

    test('moveSelectedLayers moves a multi-selection and keeps it selected', () async {
      controller.selectLayer(1);
      controller.selectedLayerIndices = [0, 1];

      await controller.moveSelectedLayers(1);
      expect(layerNames(), [102, 100, 101]);
      expect(controller.selectedLayerIndices, [1, 2]);
      expect(read().currentLayerIndex, 2);
    });

    test('moveSelectedLayers at the top does nothing', () async {
      controller.selectLayer(2);
      final undoBefore = controller.undoStackSize;
      await controller.moveSelectedLayers(1);

      expect(layerNames(), [100, 101, 102]);
      expect(controller.undoStackSize, undoBefore);
    });

    test('selectAdjacentLayer steps and stops at the ends', () {
      controller.selectLayer(0);
      controller.selectAdjacentLayer(1);
      expect(read().currentLayerIndex, 1);
      controller.selectAdjacentLayer(1);
      controller.selectAdjacentLayer(1);
      expect(read().currentLayerIndex, 2);
      controller.selectAdjacentLayer(-1);
      expect(read().currentLayerIndex, 1);
    });
  });

  group('frame menu ops', () {
    List<int> runIds() => [for (final f in read().frames.where((f) => f.stateId == 2)) f.id];

    test('duration change is one undo step and a no-op records nothing', () async {
      final undoBefore = controller.undoStackSize;
      await controller.updateFramesDurationByIds({10, 11}, 100);
      expect(controller.undoStackSize, undoBefore, reason: 'already 100ms');

      await controller.updateFramesDurationByIds({10, 11}, 250);
      expect([for (final f in read().currentFrames) f.duration], [250, 250, 100, 100]);
      expect(controller.undoStackSize, undoBefore + 1);

      controller.undo();
      expect([for (final f in read().currentFrames) f.duration], [100, 100, 100, 100]);
    });

    test('renameFrame is one undo step and ignores blank names', () {
      final undoBefore = controller.undoStackSize;
      controller.renameFrame(11, '  ');
      expect(controller.undoStackSize, undoBefore);

      controller.renameFrame(11, ' Jump ');
      expect(read().currentFrames[1].name, 'Jump');
      controller.undo();
      expect(read().currentFrames[1].name, 'F11');
    });

    test('reverseFrames swaps the selected slots end to end', () async {
      controller.selectFrame(11);
      final undoBefore = controller.undoStackSize;
      await controller.reverseFrames({10, 11, 13});

      expect(idleIds(), [13, 11, 12, 10]);
      expect([for (final f in read().currentFrames) f.order], [0, 1, 2, 3]);
      expect(activeId(), 11);
      expect(controller.undoStackSize, undoBefore + 1);

      controller.undo();
      expect(idleIds(), [10, 11, 12, 13]);
    });

    test('reverseFrames needs two frames', () async {
      final undoBefore = controller.undoStackSize;
      await controller.reverseFrames({12});
      expect(controller.undoStackSize, undoBefore);
    });

    test('moving frames to another animation appends them there', () async {
      controller.selectFrame(12);
      final undoBefore = controller.undoStackSize;
      await controller.moveFramesToState({11, 12}, 2);

      expect(idleIds(), [10, 13]);
      expect(runIds(), [20, 11, 12]);
      expect([for (final f in read().frames.where((f) => f.stateId == 2)) f.order], [0, 1, 2]);
      expect(read().currentAnimationState.id, 1, reason: 'the view stays on Idle');
      expect(activeId(), 13, reason: 'the nearest remaining frame becomes active');
      expect(controller.undoStackSize, undoBefore + 1);
      expectValidSelection();

      controller.undo();
      expect(idleIds(), [10, 11, 12, 13]);
      expect(runIds(), [20]);
    });

    test('moving never empties an animation', () async {
      controller.selectFrame(11);
      await controller.moveFramesToState({10, 11, 12, 13}, 2);

      expect(idleIds(), [11], reason: 'the active frame stays behind');
      expect(runIds(), [20, 10, 12, 13]);
    });

    test('copying frames leaves the originals in place', () async {
      await controller.moveFramesToState({10, 12}, 2, copy: true);

      expect(idleIds(), [10, 11, 12, 13]);
      final run = read().frames.where((f) => f.stateId == 2).toList();
      expect(run.map((f) => f.name), ['F20', 'F10', 'F12']);
      expect(run[1].layers.first.pixels.first, 100);
      expect(identical(run[1].layers.first.pixels, read().frames.first.layers.first.pixels), isFalse);
    });

    test('frames already in the target animation are skipped', () async {
      final undoBefore = controller.undoStackSize;
      await controller.moveFramesToState({20}, 2);
      await controller.moveFramesToState({10}, 99);
      expect(controller.undoStackSize, undoBefore);
    });
  });

  group('deleteSelected', () {
    test('frames target deletes the selected frames as one undo step', () async {
      controller.selectFrames(12, toggle: true);
      final undoBefore = controller.undoStackSize;

      expect(await controller.deleteSelected(), isTrue);
      expect(idleIds(), [11, 13]);
      expect(controller.undoStackSize, undoBefore + 1);
      expectValidSelection();
    });

    test('layers target deletes the selected layers and resets the layer selection', () async {
      controller.selectLayer(1);
      controller.selectedLayerIndices = [1, 2];
      controller.setSelectionTarget(EditorSelectionTarget.layers);
      final undoBefore = controller.undoStackSize;

      expect(await controller.deleteSelected(), isTrue);
      expect(layerNames(), [100]);
      expect(idleIds(), [10, 11, 12, 13], reason: 'frames are untouched');
      expect(controller.undoStackSize, undoBefore + 1);
      expect(controller.selectedLayerIndices, [0]);
    });

    test('canvas target without a pixel selection does nothing', () async {
      controller.setSelectionTarget(EditorSelectionTarget.canvas);
      final undoBefore = controller.undoStackSize;

      expect(await controller.deleteSelected(), isFalse);
      expect(layerNames(), [100, 101, 102]);
      expect(controller.undoStackSize, undoBefore);
    });

    test('canvas target clears the selected pixels', () async {
      controller.selectLayer(0);
      controller.setSelection(SelectionRegion(
        path: Path()..addRect(const Rect.fromLTWH(0, 0, 1, 1)),
        bounds: const Rect.fromLTWH(0, 0, 1, 1),
        shape: SelectionShape.rectangle,
      ));
      controller.setSelectionTarget(EditorSelectionTarget.canvas);

      expect(await controller.deleteSelected(), isTrue);
      expect(layerNames(), [0, 101, 102]);
      expect(idleIds(), [10, 11, 12, 13]);
    });
  });

  group('duplicateSelected', () {
    test('frames target copies the selected frames', () async {
      controller.selectFrames(11, toggle: true);

      expect(await controller.duplicateSelected(), isTrue);
      expect(
          [for (final f in read().currentFrames) f.name], ['F10', 'F11', 'Copy of F10', 'Copy of F11', 'F12', 'F13']);
    });

    test('layers target copies the selected layers', () async {
      controller.selectLayer(2);
      controller.selectedLayerIndices = [0, 2];
      controller.setSelectionTarget(EditorSelectionTarget.layers);

      expect(await controller.duplicateSelected(), isTrue);
      expect(read().currentFrame.layers.length, 5);
      expect(idleIds(), [10, 11, 12, 13]);
    });

    test('canvas target without a pixel selection does nothing', () async {
      expect(await controller.duplicateSelected(), isFalse);
      expect(read().currentFrame.layers.length, 3);
      expect(idleIds(), [10, 11, 12, 13]);
    });
  });
}

class _FakeTemplateRepo extends Fake implements TemplateAPIRepo {}

class _LayerRepo extends FakeProjectRepo {
  @override
  Future<void> updateLayer(int projectId, int frameId, Layer layer) async {}

  @override
  Future<void> deleteLayer(int layerId) async {}
}
