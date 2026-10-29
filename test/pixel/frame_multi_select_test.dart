import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:picell/data.dart';
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

  // Idle holds frames 10..14 (one pixel each, value = id); Run holds 20.
  AnimationFrame frame(int id, int stateId, int order) => AnimationFrame(
        id: id,
        name: 'F$id',
        stateId: stateId,
        duration: 100 + id,
        order: order,
        layers: [
          Layer(layerId: id * 10, id: 'l$id', name: 'L', pixels: Uint32List.fromList([id, 0]))
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
      for (var i = 0; i < 5; i++) frame(10 + i, 1, i),
      frame(20, 2, 0),
    ],
  );

  late ProviderContainer container;
  late PixelDrawController controller;
  late FakeProjectRepo repo;

  PixelCanvasState read() => container.read(pixelDrawControllerProvider(project));
  List<int> idleIds() => [for (final f in read().frames.where((f) => f.stateId == 1)) f.id];
  int activeId() => read().currentFrame.id;

  setUp(() {
    repo = FakeProjectRepo();
    container = ProviderContainer(overrides: [
      projectRepo.overrideWithValue(repo),
      templateAPIRepoProvider.overrideWithValue(_FakeTemplateRepo()),
    ]);
    container.listen(pixelDrawControllerProvider(project), (_, __) {});
    controller = container.read(pixelDrawControllerProvider(project).notifier);
    controller.selectFrame(12);
  });

  tearDown(() async {
    await controller.flushPendingProjectSave();
    container.dispose();
  });

  group('removeFramesByIds', () {
    test('deletes every selected frame as one undo step', () async {
      final undoBefore = controller.undoStackSize;
      await controller.removeFramesByIds({11, 13});

      expect(idleIds(), [10, 12, 14]);
      expect(repo.deletedFrames.toSet(), {11, 13});
      expect(activeId(), 12);
      expect(controller.undoStackSize, undoBefore + 1);

      controller.undo();
      expect(idleIds(), [10, 11, 12, 13, 14]);
      expect(activeId(), 12);
    });

    test('moves the active frame to a surviving neighbour when it is deleted', () async {
      await controller.removeFramesByIds({12, 13, 14});

      expect(idleIds(), [10, 11]);
      expect(activeId(), 11);
      expect(read().currentFrameIndex, 1);
    });

    test('never deletes the last frame of an animation', () async {
      await controller.removeFramesByIds({10, 11, 12, 13, 14, 20});

      expect(idleIds(), [12], reason: 'the active frame survives');
      expect(read().frames.where((f) => f.stateId == 2).map((f) => f.id), [20]);
      expect(activeId(), 12);
    });

    test('a lone last frame is left alone and records no undo step', () async {
      final undoBefore = controller.undoStackSize;
      await controller.removeFramesByIds({20});

      expect(read().frames.where((f) => f.stateId == 2).map((f) => f.id), [20]);
      expect(controller.undoStackSize, undoBefore);
    });
  });

  group('reorderFramesByIds', () {
    test('moves a block forward after the target as one undo step', () async {
      final undoBefore = controller.undoStackSize;
      await controller.reorderFramesByIds({10, 12}, 13);

      expect(idleIds(), [11, 13, 10, 12, 14]);
      expect([for (final f in read().frames.where((f) => f.stateId == 1)) f.order], [0, 1, 2, 3, 4]);
      expect(activeId(), 12, reason: 'the active frame stays active');
      expect(controller.undoStackSize, undoBefore + 1);

      controller.undo();
      expect(idleIds(), [10, 11, 12, 13, 14]);
      expect(activeId(), 12);
    });

    test('moves a block backward before the target', () async {
      await controller.reorderFramesByIds({13, 14}, 11);

      expect(idleIds(), [10, 13, 14, 11, 12]);
      expect(activeId(), 12);
    });

    test('keeps single-frame dragging working', () async {
      await controller.reorderFrames(0, 4);

      expect(idleIds(), [11, 12, 13, 14, 10]);
    });

    test('ignores drops that change nothing', () async {
      final undoBefore = controller.undoStackSize;
      await controller.reorderFramesByIds({11, 12}, 12);
      await controller.reorderFramesByIds({10}, 999);
      await controller.reorderFramesByIds({20}, 11);

      expect(idleIds(), [10, 11, 12, 13, 14]);
      expect(controller.undoStackSize, undoBefore);
    });
  });

  group('duplicateFramesByIds', () {
    test('inserts copies after the last copied frame as one undo step', () async {
      final undoBefore = controller.undoStackSize;
      await controller.duplicateFramesByIds({11, 13});

      final idle = read().frames.where((f) => f.stateId == 1).toList();
      expect(idle.map((f) => f.name), ['F10', 'F11', 'F12', 'F13', 'Copy of F11', 'Copy of F13', 'F14']);
      expect(idle.map((f) => f.order), [0, 1, 2, 3, 4, 5, 6]);
      expect(idle[4].layers.single.pixels, [11, 0]);
      expect(idle[5].duration, 113);
      expect(activeId(), 12);
      expect(controller.undoStackSize, undoBefore + 1);

      controller.undo();
      expect(idleIds(), [10, 11, 12, 13, 14]);
    });

    test('copies never alias the source pixels', () async {
      await controller.duplicateFramesByIds({12});

      final idle = read().frames.where((f) => f.stateId == 1).toList();
      expect(idle[3].name, 'Copy of F12');
      expect(identical(idle[3].layers.single.pixels, idle[2].layers.single.pixels), isFalse);
    });
  });

  group('undo and redo keep the database in step', () {
    test('undoing a delete restores the rows, redoing deletes them again', () async {
      await controller.removeFramesByIds({11, 13});
      expect(repo.deletedFrames.toSet(), {11, 13});

      controller.undo();
      expect(repo.restoredFrames.map((f) => f.id).toSet(), {11, 13});
      expect(repo.restoredFrames.firstWhere((f) => f.id == 11).layers.single.pixels, [11, 0]);

      repo.deletedFrames.clear();
      controller.redo();
      expect(repo.deletedFrames.toSet(), {11, 13});
    });

    test('undoing a duplicate deletes the copies', () async {
      await controller.duplicateFramesByIds({11});
      final copyId = repo.createdFrames.last.id;

      controller.undo();
      expect(repo.deletedFrames, [copyId]);
      expect(repo.restoredFrames, isEmpty);

      controller.redo();
      expect(repo.restoredFrames.map((f) => f.id), [copyId]);
    });

    test('undoing a reorder writes no rows', () async {
      await controller.reorderFramesByIds({10}, 13);
      controller.undo();
      controller.redo();

      expect(repo.deletedFrames, isEmpty);
      expect(repo.restoredFrames, isEmpty);
      expect(repo.deletedLayers, isEmpty);
      expect(repo.restoredLayers, isEmpty);
    });
  });
}

class _FakeTemplateRepo extends Fake implements TemplateAPIRepo {}
