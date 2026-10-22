import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:picell/data.dart';
import 'package:picell/data/repo/template_api_repo.dart';
import 'package:picell/pixel/providers/pixel_controller_provider.dart';
import 'package:picell/providers/providers.dart';

import 'rig/fake_project_repo.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const w = 2, h = 2;
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
        Layer(layerId: 5, id: 'a', name: 'A', pixels: Uint32List.fromList([1, 0, 0, 0]), opacity: 0.5),
        Layer(layerId: 6, id: 'b', name: 'B', pixels: Uint32List.fromList([0, 2, 0, 0]), opacity: 0.5),
        Layer(layerId: 7, id: 'c', name: 'C', pixels: Uint32List.fromList([0, 0, 3, 0]), opacity: 0.5),
      ]),
    ],
  );

  late ProviderContainer container;
  late PixelDrawController controller;

  setUp(() {
    container = ProviderContainer(overrides: [
      projectRepo.overrideWithValue(FakeProjectRepo()),
      templateAPIRepoProvider.overrideWithValue(_FakeTemplateRepo()),
    ]);
    container.listen(pixelDrawControllerProvider(project), (_, __) {});
    controller = container.read(pixelDrawControllerProvider(project).notifier);
  });

  tearDown(() async {
    await controller.flushPendingProjectSave();
    container.dispose();
  });

  AnimationFrame generated(List<List<int>> layers) => AnimationFrame(
        id: 0,
        stateId: 0,
        name: 'g',
        duration: 80,
        layers: [
          for (final (i, p) in layers.indexed)
            Layer(layerId: i, id: 'g$i', name: 'g$i', pixels: Uint32List.fromList(p)),
        ],
      );

  test('replaces every source layer and leaves the others alone', () async {
    await controller.addGeneratedEffectFrames(
      [
        generated([
          [9, 9, 9, 9],
          [8, 8, 8, 8],
        ]),
      ],
      sourceFrameId: 10,
      sourceLayerIds: const [5, 7],
      activeLayerId: 7,
    );
    final state = container.read(pixelDrawControllerProvider(project));
    final frame = state.frames.last;
    expect(frame.layers[0].pixels, [9, 9, 9, 9]);
    expect(frame.layers[1].pixels, [0, 2, 0, 0]);
    expect(frame.layers[2].pixels, [8, 8, 8, 8]);
    expect(frame.layers.map((l) => l.opacity), everyElement(0.5));
    expect(state.currentLayerIndex, 2);
    // The source frame is untouched.
    expect(state.frames.first.layers[0].pixels, [1, 0, 0, 0]);
  });

  test('flattened output resets opacity only on layers that received pixels', () async {
    await controller.addGeneratedEffectFrames(
      [
        generated([
          [0, 0, 0, 0],
          [4, 4, 4, 4],
        ]),
      ],
      sourceFrameId: 10,
      sourceLayerIds: const [5, 6],
      flattened: true,
    );
    final layers = container.read(pixelDrawControllerProvider(project)).frames.last.layers;
    expect(layers[0].opacity, 0.5);
    expect(layers[1].opacity, 1.0);
    expect(layers[2].opacity, 0.5);
  });

  test('rejects a layer count mismatch and unknown layers', () async {
    expect(
      controller.addGeneratedEffectFrames([generated([[1, 1, 1, 1]])],
          sourceFrameId: 10, sourceLayerIds: const [5, 6]),
      throwsArgumentError,
    );
    expect(
      controller.addGeneratedEffectFrames([generated([[1, 1, 1, 1]])], sourceFrameId: 10, sourceLayerId: 99),
      throwsStateError,
    );
  });

  test('the single-layer call keeps working', () async {
    await controller.addGeneratedEffectFrames([generated([[7, 7, 7, 7]])], sourceFrameId: 10, sourceLayerId: 6);
    final frame = container.read(pixelDrawControllerProvider(project)).frames.last;
    expect(frame.layers[1].pixels, [7, 7, 7, 7]);
  });
}

class _FakeTemplateRepo extends Fake implements TemplateAPIRepo {}
