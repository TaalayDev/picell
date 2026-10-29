import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:picell/data.dart';
import 'package:picell/data/repo/template_api_repo.dart';
import 'package:picell/pixel/pixel_canvas_state.dart';
import 'package:picell/pixel/providers/pixel_controller_provider.dart';
import 'package:picell/pixel/services/layer_merge_service.dart';
import 'package:picell/providers/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'rig/fake_project_repo.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.init();
  });

  const blue = 0xFF0000FF, halfRed = 0x80FF0000, green = 0xFF00FF00, white = 0xFFFFFFFF;

  group('LayerMergeService.blendOver', () {
    test('opaque source replaces the destination', () {
      expect(LayerMergeService.blendOver(blue, green, 1), green);
    });

    test('a translucent source over nothing keeps its colour and alpha', () {
      expect(LayerMergeService.blendOver(0, halfRed, 1), halfRed);
    });

    test('a translucent source mixes with an opaque destination', () {
      expect(LayerMergeService.blendOver(blue, halfRed, 1), 0xFF80007F);
    });

    test('two translucent colours combine their alpha', () {
      expect(LayerMergeService.blendOver(halfRed, 0x800000FF, 1), 0xC05500AA);
    });

    test('layer opacity scales the source alpha', () {
      expect(LayerMergeService.blendOver(blue, 0xFFFF0000, 0.5), 0xFF800080);
      expect(LayerMergeService.blendOver(blue, green, 0), blue);
    });
  });

  // 2×1 canvas, one frame. L0 is blue, L1 half red over a green pixel, L2 is
  // hidden and L3 locked.
  Layer layer(int id, String name, List<int> pixels, {bool visible = true, bool locked = false}) => Layer(
        layerId: id,
        id: name,
        name: name,
        pixels: Uint32List.fromList(pixels),
        isVisible: visible,
        isLocked: locked,
        order: id - 1,
      );

  final project = Project(
    id: 1,
    name: 'P',
    width: 2,
    height: 1,
    createdAt: DateTime(2026),
    editedAt: DateTime(2026),
    states: const [AnimationStateModel(id: 1, name: 'Idle', frameRate: 12)],
    frames: [
      AnimationFrame(id: 10, name: 'F', stateId: 1, duration: 100, layers: [
        layer(1, 'L0', [blue, 0]),
        layer(2, 'L1', [halfRed, green]),
        layer(3, 'L2', [white, white], visible: false),
        layer(4, 'L3', [white, white], locked: true),
      ]),
    ],
  );

  late ProviderContainer container;
  late PixelDrawController controller;
  late _LayerRepo repo;

  PixelCanvasState read() => container.read(pixelDrawControllerProvider(project));
  List<String> names() => [for (final l in read().currentFrame.layers) l.name];

  setUp(() {
    repo = _LayerRepo();
    container = ProviderContainer(overrides: [
      projectRepo.overrideWithValue(repo),
      templateAPIRepoProvider.overrideWithValue(_FakeTemplateRepo()),
    ]);
    container.listen(pixelDrawControllerProvider(project), (_, __) {});
    controller = container.read(pixelDrawControllerProvider(project).notifier);
  });

  tearDown(() async {
    await controller.flushPendingProjectSave();
    container.dispose();
  });

  group('mergeLayers', () {
    test('merge down composites into the lower layer as one undo step', () async {
      controller.selectLayer(1);
      final undoBefore = controller.undoStackSize;

      expect(await controller.mergeLayerDown(), isTrue);
      final merged = read().currentFrame.layers.first;
      expect(names(), ['L0', 'L2', 'L3']);
      expect(merged.layerId, 1, reason: 'the lower layer keeps its identity');
      expect(merged.pixels, [0xFF80007F, green]);
      expect(merged.opacity, 1.0);
      expect(merged.effects, isEmpty);
      expect(read().currentLayerIndex, 0);
      expect([for (final l in read().currentFrame.layers) l.order], [0, 1, 2]);
      expect(controller.undoStackSize, undoBefore + 1);

      controller.undo();
      expect(names(), ['L0', 'L1', 'L2', 'L3']);
      expect(read().currentFrame.layers.first.pixels, [blue, 0]);
    });

    test('hidden and locked layers are left out of a merge', () async {
      expect(await controller.mergeLayers([0, 1, 2, 3]), isTrue);
      expect(names(), ['L0', 'L2', 'L3']);
      expect(read().currentFrame.layers[1].pixels, [white, white]);
    });

    test('fewer than two mergeable layers does nothing', () async {
      final undoBefore = controller.undoStackSize;
      expect(await controller.mergeLayers([2, 3]), isFalse);
      controller.selectLayer(0);
      expect(await controller.mergeLayerDown(), isFalse, reason: 'nothing below the bottom layer');
      expect(names(), ['L0', 'L1', 'L2', 'L3']);
      expect(controller.undoStackSize, undoBefore);
    });

    test('merging bakes layer opacity in', () async {
      controller.selectLayer(1);
      await controller.setLayersOpacity([1], 0.5);
      await controller.mergeLayerDown();

      final merged = read().currentFrame.layers.first;
      expect(merged.pixels[1], 0x8000FF00, reason: 'green at half opacity over nothing');
      expect(merged.opacity, 1.0);
    });
  });

  group('reorderLayers', () {
    test('dragging one layer moves it as one undo step and keeps it active', () async {
      controller.selectLayer(0);
      final undoBefore = controller.undoStackSize;

      await controller.reorderLayers(0, 2);
      expect(names(), ['L1', 'L2', 'L0', 'L3']);
      expect(read().currentLayerIndex, 2);
      expect(controller.undoStackSize, undoBefore + 1);

      controller.undo();
      expect(names(), ['L0', 'L1', 'L2', 'L3']);
    });

    test('dragging a selected layer moves the whole selection as a block', () async {
      controller.selectLayer(1);
      controller.selectedLayerIndices = [0, 1];

      await controller.reorderLayers(1, 3);
      expect(names(), ['L2', 'L3', 'L0', 'L1']);
      expect(controller.selectedLayerIndices, [2, 3]);
      expect(read().currentLayerIndex, 3);
    });

    test('dragging an unselected layer moves only that layer', () async {
      controller.selectLayer(1);
      controller.selectedLayerIndices = [0, 1];

      await controller.reorderLayers(3, 0);
      expect(names(), ['L3', 'L0', 'L1', 'L2']);
    });

    test('dropping in place records no undo step', () async {
      final undoBefore = controller.undoStackSize;
      await controller.reorderLayers(2, 2);
      expect(controller.undoStackSize, undoBefore);
    });
  });

  group('undo and redo keep layer rows in step', () {
    test('undoing a merge restores the merged-away layer row', () async {
      controller.selectLayer(1);
      await controller.mergeLayerDown();
      expect(repo.deletedLayers, [2]);

      controller.undo();
      expect(repo.restoredLayers.map((r) => (r.$1, r.$2.layerId)), [(10, 2)]);
      expect(repo.restoredLayers.single.$2.pixels, [halfRed, green]);

      repo.deletedLayers.clear();
      controller.redo();
      expect(repo.deletedLayers, [2]);
    });

    test('undoing a layer duplicate deletes the copies', () async {
      await controller.duplicateLayers([0]);
      final copyId = repo.createdLayers.single.layerId;

      controller.undo();
      expect(repo.deletedLayers, [copyId]);
    });
  });

  group('duplicateLayers', () {
    test('copies go in one block above the topmost selected layer', () async {
      await controller.duplicateLayers([0, 1]);

      expect(names(), ['L0', 'L1', 'Copy of L0', 'Copy of L1', 'L2', 'L3']);
      expect(read().currentLayerIndex, 3, reason: 'the top copy is active');
      expect(read().currentFrame.layers[2].pixels, [blue, 0]);
    });
  });
}

class _FakeTemplateRepo extends Fake implements TemplateAPIRepo {}

class _LayerRepo extends FakeProjectRepo {
  @override
  Future<void> updateLayer(int projectId, int frameId, Layer layer) async {}
}
