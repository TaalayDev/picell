import 'dart:typed_data';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/data.dart';
import 'package:picell/data/repo/template_api_repo.dart';
import 'package:picell/pixel/pixel_canvas_state.dart';
import 'package:picell/pixel/providers/pixel_controller_provider.dart';
import 'package:picell/pixel/rig/rig_bake.dart';
import 'package:picell/providers/providers.dart';

import 'fake_project_repo.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const w = 8, h = 8;

  Project project({int frameCount = 1}) => Project(
        id: 1,
        name: 'Hero',
        width: w,
        height: h,
        createdAt: DateTime(2026),
        editedAt: DateTime(2026),
        states: const [AnimationStateModel(id: 1, name: 'Walk', frameRate: 12)],
        frames: [
          for (var i = 0; i < frameCount; i++)
            AnimationFrame(
              id: 10 + i,
              name: 'Frame ${i + 1}',
              stateId: 1,
              duration: 100,
              layers: [
                Layer(layerId: 5 + i, id: 'body$i', name: 'Body', pixels: Uint32List(w * h)..[2 * w + 2] = 0xFFFFFFFF),
              ],
            ),
        ],
      );

  late FakeProjectRepo repo;
  late ProviderContainer container;
  late Project p;
  late PixelDrawController controller;

  void start(Project project) {
    p = project;
    container = ProviderContainer(overrides: [
      projectRepo.overrideWithValue(repo),
      // The templates client would reach for local storage and the network.
      templateAPIRepoProvider.overrideWithValue(_FakeTemplateRepo()),
    ]);
    // Keep the notifier alive for the whole test.
    container.listen(pixelDrawControllerProvider(p), (_, __) {});
    controller = container.read(pixelDrawControllerProvider(p).notifier);
  }

  setUp(() {
    repo = FakeProjectRepo();
    start(project());
  });

  tearDown(() async {
    // Disposing the whole container while a debounced save is pending would
    // make that save read providers of a dead container; flush it first.
    await controller.flushPendingProjectSave();
    container.dispose();
  });

  PixelCanvasState view() => container.read(pixelDrawControllerProvider(p));

  Rig riggedFor(List<AnimationFrame> frames) => Rig(
        id: 'r',
        stateId: 1,
        bones: const [Bone(id: 'root', name: 'root', head: Offset(4.5, 4.5), length: 2)],
        parts: [RigPart(id: 'p', boneId: 'root', layerKey: frames.first.layers.first.stableKey!)],
        clips: const [
          RigClip(id: 'main', name: 'Walk', length: 3, keyframes: [
            RigKeyframe(time: 0, boneId: 'root'),
            RigKeyframe(time: 2, boneId: 'root', translation: Offset(2, 0)),
          ]),
        ],
      );

  test('prepareRigEditing keys the layers of the animation and nothing else', () {
    final frames = controller.prepareRigEditing(1);
    expect(frames.single.layers.single.stableKey, 'body0');
    expect(view().frames.single.layers.single.stableKey, 'body0');
  });

  test('applying a rig bakes into a new animation, shows it, and is one undo step', () async {
    final frames = controller.prepareRigEditing(1);
    final rig = riggedFor(frames);

    final stored = await controller.applyRig(rig);

    final s = view();
    expect(s.animationStates.map((x) => x.name), ['Walk', 'Walk (rig)']);
    expect(stored.outputStateId, s.animationStates.last.id);
    expect(s.frames.where((f) => f.stateId == stored.outputStateId), hasLength(3));
    expect(s.frames.where((f) => f.stateId == 1), hasLength(1), reason: 'the rest pose stays');

    // The editor lands on the first baked frame, on its touch-up layer.
    expect(s.currentAnimationState.id, stored.outputStateId);
    expect(s.currentFrameIndex, 0);
    expect(s.currentLayer.stableKey, RigLayerKeys.cleanup);

    // Findable from either animation.
    expect(controller.rigForState(1)?.id, 'r');
    expect(controller.rigForState(stored.outputStateId!)?.id, 'r');

    // One undo step takes the whole bake back.
    expect(controller.canUndo, isTrue);
    controller.undo();
    expect(view().animationStates.map((x) => x.name), ['Walk']);
    expect(view().frames, hasLength(1));
    expect(controller.rigForState(1), isNotNull, reason: 'the rig itself is not part of undo');
  });

  test('baking twice reuses the output animation', () async {
    final frames = controller.prepareRigEditing(1);
    final first = await controller.applyRig(riggedFor(frames));

    final second = await controller.applyRig(first);
    expect(second.outputStateId, first.outputStateId);
    expect(view().animationStates, hasLength(2));
    expect(repo.createdStates, hasLength(1));
    expect(view().frames.where((f) => f.stateId == first.outputStateId), hasLength(3));
  });

  test('a rig without keyframes is only saved', () async {
    controller.prepareRigEditing(1);
    const bare = Rig(id: 'r', stateId: 1);
    final stored = await controller.applyRig(bare);
    expect(stored, bare);
    expect(view().animationStates, hasLength(1));
    expect(controller.canUndo, isFalse);
    expect(controller.rigForState(1), isNotNull);
  });

  test('bake: false saves the rig without touching the animations', () async {
    final frames = controller.prepareRigEditing(1);
    await controller.applyRig(riggedFor(frames), bake: false);
    expect(view().animationStates, hasLength(1));
    expect(controller.canUndo, isFalse);
    expect(controller.rigForState(1), isNotNull);
  });

  test('a failed bake leaves the project and undo history untouched but keeps the rig', () async {
    final frames = controller.prepareRigEditing(1);
    repo.failCreateState = StateError('disk full');

    await expectLater(controller.applyRig(riggedFor(frames)), throwsStateError);

    expect(view().animationStates, hasLength(1));
    expect(view().frames, hasLength(1));
    expect(controller.canUndo, isFalse, reason: 'the snapshot taken for the bake is discarded');
    expect(controller.rigForState(1), isNotNull, reason: 'the user does not lose their rig');
  });

  test('rigBakeLosses reports nothing before a first bake', () {
    expect(controller.rigBakeLosses(const Rig(id: 'r', stateId: 1)), isEmpty);
  });

  group('rig session: which frame is the rest pose', () {
    test('a layer added on the frame being edited is what the rig sees', () async {
      start(project(frameCount: 2));
      controller.selectFrame(11); // the second frame
      await controller.addLayer('Hat');

      final session = controller.prepareRigSession();

      expect(session.restFrameIndex, 1, reason: 'the frame being edited, not the first one');
      final layers = session.frames[session.restFrameIndex].layers;
      expect(layers.map((l) => l.name), contains('Hat'));
      expect(layers.every((l) => l.stableKey != null), isTrue, reason: 'new layers can be bound to bones');
      // The first frame is untouched: it has no Hat.
      expect(session.frames.first.layers.map((l) => l.name), isNot(contains('Hat')));
    });

    test('pixels painted on the current frame since the last time are seen', () {
      start(project(frameCount: 2));
      controller.prepareRigSession(); // the rig was opened once before
      controller.selectFrame(11);
      final edited = controller.currentLayer.copyWith(pixels: Uint32List(w * h)..[0] = 0xFFFF0000);
      controller.updateLayer(edited);

      final session = controller.prepareRigSession();

      expect(session.frames[session.restFrameIndex].layers.first.pixels[0], 0xFFFF0000);
    });

    test('keys given to existing layers stay put when a new layer appears', () async {
      final first = controller.prepareRigSession();
      final bodyKey = first.frames.single.layers.single.stableKey;
      await controller.addLayer('Hat');

      final again = controller.prepareRigSession().frames.single.layers;
      expect(again.firstWhere((l) => l.name == 'Body').stableKey, bodyKey);
      expect(again.firstWhere((l) => l.name == 'Hat').stableKey, isNotNull);
      expect(again.map((l) => l.stableKey).toSet(), hasLength(2));
    });

    test('opened from the baked animation, it uses the frame the rig was set up on', () async {
      start(project(frameCount: 2));
      controller.selectFrame(11);
      final session = controller.prepareRigSession();
      final rig = Rig(
        id: 'r',
        stateId: 1,
        restFrameIndex: session.restFrameIndex,
        bones: const [Bone(id: 'root', name: 'root', head: Offset(4.5, 4.5), length: 2)],
        parts: [RigPart(id: 'p', boneId: 'root', layerKey: session.frames[1].layers.first.stableKey!)],
        clips: const [
          RigClip(id: 'main', name: 'Walk', length: 2, keyframes: [RigKeyframe(time: 1, boneId: 'root')]),
        ],
      );
      final stored = await controller.applyRig(rig);

      // The editor now shows the baked animation; its frame 0 is current.
      expect(view().currentAnimationState.id, stored.outputStateId);
      final again = controller.prepareRigSession();
      expect(again.source.id, 1);
      expect(again.restFrameIndex, 1, reason: 'not the baked frame being shown, not frame 0');
      expect(again.frames, hasLength(2));
    });

    test('a stale rest frame index is clamped', () {
      controller.prepareRigSession();
      controller.saveRig(const Rig(id: 'r', stateId: 1, restFrameIndex: 7));
      expect(controller.prepareRigSession().restFrameIndex, 0, reason: 'opened from the source: the current frame');
    });
  });
}

class _FakeTemplateRepo extends Fake implements TemplateAPIRepo {}
