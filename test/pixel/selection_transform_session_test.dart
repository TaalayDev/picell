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

  // 4×2 canvas, one layer with a red pixel at (0, 0). The selection is that
  // pixel.
  const w = 4, h = 2, red = 0xFFFF0000;
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
      ]),
    ],
  );

  SelectionRegion rect(double x, double y) => SelectionRegion(
        path: Path()..addRect(Rect.fromLTWH(x, y, 1, 1)),
        bounds: Rect.fromLTWH(x, y, 1, 1),
        shape: SelectionShape.rectangle,
      );

  late ProviderContainer container;
  late PixelDrawController controller;

  PixelCanvasState read() => container.read(pixelDrawControllerProvider(project));
  List<int> pixels() => read().currentLayer.pixels.toList();
  Rect? bounds() => read().selectionState?.region.bounds;

  // One pointer drag of the move handle by [delta].
  void drag(Offset delta) {
    controller.startTransformSelection(read().selectionState!.region);
    controller.moveSelection(delta);
    controller.endTransformSelection();
  }

  setUp(() {
    container = ProviderContainer(overrides: [
      projectRepo.overrideWithValue(_LayerRepo()),
      templateAPIRepoProvider.overrideWithValue(_FakeTemplateRepo()),
    ]);
    container.listen(pixelDrawControllerProvider(project), (_, __) {});
    controller = container.read(pixelDrawControllerProvider(project).notifier);
    controller.setSelection(rect(0, 0));
  });

  tearDown(() async {
    await controller.flushPendingProjectSave();
    container.dispose();
  });

  group('transform session', () {
    test('no session before the first transform', () {
      expect(controller.hasTransformSession, isFalse);
      expect(controller.commitTransformSession(), isFalse);
      expect(controller.cancelTransformSession(), isFalse);
      expect(read().selectionState, isNotNull, reason: 'Enter/Esc fall back to deselect in the UI');
    });

    test('Esc puts pixels and selection back and drops every step of the session', () async {
      final undoBefore = controller.undoStackSize;
      drag(const Offset(1, 0));
      drag(const Offset(1, 1));
      expect(pixels(), px({6: red}));
      expect(controller.hasTransformSession, isTrue);
      expect(controller.undoStackSize, undoBefore + 2);

      expect(controller.cancelTransformSession(), isTrue);
      expect(pixels(), px({0: red}));
      expect(bounds(), const Rect.fromLTWH(0, 0, 1, 1));
      expect(read().selectionState!.isTransforming, isFalse);
      expect(read().selectionState!.capturedPixels, isNull);
      expect(controller.undoStackSize, undoBefore);
      expect(controller.hasTransformSession, isFalse);
    });

    test('Enter drops the pixels in place and keeps the selection', () {
      final undoBefore = controller.undoStackSize;
      drag(const Offset(2, 1));

      expect(controller.commitTransformSession(), isTrue);
      expect(pixels(), px({6: red}));
      expect(bounds(), const Rect.fromLTWH(2, 1, 1, 1));
      expect(read().selectionState!.capturedPixels, isNull);
      expect(controller.hasTransformSession, isFalse);
      expect(controller.undoStackSize, undoBefore + 1, reason: 'the move stays undoable');

      // A new session starts from the committed pixels.
      drag(const Offset(-1, 0));
      controller.cancelTransformSession();
      expect(pixels(), px({6: red}));
    });

    test('anything that drops the floating pixels ends the session', () {
      drag(const Offset(1, 0));
      controller.setSelection(rect(3, 1));
      expect(controller.hasTransformSession, isFalse);
      expect(controller.cancelTransformSession(), isFalse);
      expect(pixels(), px({1: red}));
    });

    test('Esc in the middle of a drag cancels it too', () {
      final undoBefore = controller.undoStackSize;
      controller.startTransformSelection(read().selectionState!.region);
      controller.moveSelection(const Offset(3, 0));

      expect(controller.cancelTransformSession(), isTrue);
      expect(pixels(), px({0: red}));
      expect(read().selectionState!.isTransforming, isFalse);
      expect(controller.undoStackSize, undoBefore);
    });
  });

  group('nudgeSelection', () {
    test('a burst of nudges is one undo step', () {
      final undoBefore = controller.undoStackSize;
      controller.nudgeSelection(const Offset(1, 0));
      controller.nudgeSelection(const Offset(1, 0));
      controller.nudgeSelection(const Offset(0, 1));

      expect(pixels(), px({6: red}));
      expect(bounds(), const Rect.fromLTWH(2, 1, 1, 1));
      expect(controller.undoStackSize, undoBefore + 1);
    });

    test('a pause ends the burst, so the next nudge is a new undo step', () async {
      final undoBefore = controller.undoStackSize;
      controller.nudgeSelection(const Offset(1, 0));
      await Future<void>.delayed(const Duration(milliseconds: 700));
      expect(read().selectionState!.isTransforming, isFalse);

      controller.nudgeSelection(const Offset(1, 0));
      expect(controller.undoStackSize, undoBefore + 2);
      expect(pixels(), px({2: red}));

      // Both bursts belong to one session: Esc reverts them together.
      controller.cancelTransformSession();
      expect(pixels(), px({0: red}));
    });

    test('Esc cancels nudges like a drag', () {
      controller.nudgeSelection(const Offset(1, 0));
      controller.nudgeSelection(const Offset(1, 0));

      expect(controller.cancelTransformSession(), isTrue);
      expect(pixels(), px({0: red}));
      expect(bounds(), const Rect.fromLTWH(0, 0, 1, 1));
    });

    test('a drag after nudges closes the nudge step first', () {
      final undoBefore = controller.undoStackSize;
      controller.nudgeSelection(const Offset(1, 0));
      drag(const Offset(1, 0));

      expect(pixels(), px({2: red}));
      expect(controller.undoStackSize, undoBefore + 2);
      expect(read().selectionState!.isTransforming, isFalse);
    });

    test('does nothing without a selection', () {
      controller.setSelection(null);
      final undoBefore = controller.undoStackSize;
      controller.nudgeSelection(const Offset(1, 0));
      expect(controller.undoStackSize, undoBefore);
      expect(pixels(), px({0: red}));
    });
  });
}

class _FakeTemplateRepo extends Fake implements TemplateAPIRepo {}

class _LayerRepo extends FakeProjectRepo {
  @override
  Future<void> updateLayer(int projectId, int frameId, Layer layer) async {}
}
