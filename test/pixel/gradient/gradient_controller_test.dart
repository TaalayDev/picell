import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:picell/data.dart';
import 'package:picell/data/models/challenge_models.dart';
import 'package:picell/data/models/selection_region.dart';
import 'package:picell/data/repo/template_api_repo.dart';
import 'package:picell/pixel/gradient/gradient_options.dart';
import 'package:picell/pixel/gradient/gradient_renderer.dart';
import 'package:picell/pixel/providers/pixel_controller_provider.dart';
import 'package:picell/providers/challenges_provider.dart';
import 'package:picell/providers/editor_settings_provider.dart';
import 'package:picell/providers/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../rig/fake_project_repo.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.init();
  });

  const w = 8, h = 2;
  const black = Color(0xFF000000), white = Color(0xFFFFFFFF);
  const blue = 0xFF0000FF;

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
          // Right half blue, left half transparent.
          pixels: Uint32List.fromList([for (var i = 0; i < w * h; i++) i % w >= 4 ? blue : 0]),
        ),
      ]),
    ],
  );

  late ProviderContainer container;
  late PixelDrawController controller;

  Uint32List layerPixels() => controller.currentLayer.pixels;

  setUp(() {
    container = ProviderContainer(overrides: [
      projectRepo.overrideWithValue(_LayerRepo()),
      templateAPIRepoProvider.overrideWithValue(_FakeTemplateRepo()),
      // Committing a stroke records progression, which would fetch challenges.
      currentChallengesProvider.overrideWith(_NoChallenges.new),
    ]);
    container.listen(pixelDrawControllerProvider(project), (_, __) {});
    controller = container.read(pixelDrawControllerProvider(project).notifier);
    controller.setCurrentColor(black);
    controller.gradientOptions = const GradientOptions(
      endColor: white,
      steps: 2,
      blend: GradientBlend.replace,
    );
  });

  tearDown(() async {
    await controller.flushPendingProjectSave();
    container.dispose();
  });

  const start = Offset(0, 1), end = Offset(8, 1);

  test('preview renders without committing', () {
    final before = Uint32List.fromList(layerPixels());
    final preview = controller.renderGradient(start, end)!;
    expect(preview.sublist(0, 4).toSet(), {0xFF000000});
    expect(preview.sublist(4, 8).toSet(), {0xFFFFFFFF});
    expect(layerPixels(), before);
  });

  test('a gradient drag commits once and undoes in one step', () {
    final before = Uint32List.fromList(layerPixels());
    final preview = controller.renderGradient(start, end)!;
    final undoBefore = controller.undoStackSize;

    // Same sequence the canvas runs: batch start → tool end → batch end.
    expect(controller.startBatchDrawing(), isTrue);
    expect(controller.applyGradient(start, end), isTrue);
    controller.endBatchDrawing();

    expect(layerPixels(), preview, reason: 'commit must match the preview');
    expect(controller.undoStackSize, undoBefore + 1);

    controller.undo();
    expect(layerPixels(), before);
  });

  test('applies outside a batch as its own undo step', () {
    final undoBefore = controller.undoStackSize;
    expect(controller.applyGradient(start, end), isTrue);
    expect(layerPixels()[0], 0xFF000000);
    expect(controller.undoStackSize, undoBefore + 1);
  });

  test('contiguous target only fills the area under the start point', () {
    controller.gradientOptions = controller.gradientOptions.copyWith(target: GradientTarget.contiguous);
    controller.applyGradient(start, end);
    final px = layerPixels();
    for (var x = 0; x < w; x++) {
      if (x >= 4) {
        expect(px[x], blue, reason: 'blue area must be untouched ($x)');
      } else {
        expect(px[x], 0xFF000000);
      }
    }
  });

  test('selection clips the gradient', () {
    controller.setSelection(SelectionRegion(
      path: Path()..addRect(const Rect.fromLTWH(0, 0, 2, 2)),
      bounds: const Rect.fromLTWH(0, 0, 2, 2),
      shape: SelectionShape.rectangle,
    ));
    controller.applyGradient(start, end);
    final px = layerPixels();
    expect(px[0], 0xFF000000);
    expect(px[2], 0, reason: 'outside the selection');
  });

  test('without an override the options come from editor settings', () {
    controller.gradientOptions = null;
    final settings = container.read(editorSettingsNotifierProvider.notifier);
    settings.setSecondaryColor(const Color(0xFFFF0000));
    settings.setGradientSteps(2);
    settings.setGradientDither(GradientDither.none);
    settings.setGradientEnd(GradientEnd.secondaryColor);
    settings.setGradientBlend(GradientBlend.replace);

    final out = controller.renderGradient(start, end)!;
    expect(out[0], 0xFF000000);
    expect(out[7], 0xFFFF0000);
  });
}

class _FakeTemplateRepo extends Fake implements TemplateAPIRepo {}

class _LayerRepo extends FakeProjectRepo {
  @override
  Future<void> updateLayer(int projectId, int frameId, Layer layer) async {}
}

class _NoChallenges extends CurrentChallengesNotifier {
  @override
  Future<CurrentChallenges?> build() async => null;
}
