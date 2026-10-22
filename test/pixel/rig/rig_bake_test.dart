import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:picell/data.dart';
import 'package:picell/pixel/rig/rig_bake.dart';

import 'fake_project_repo.dart';
import 'rig_test_support.dart';

void main() {
  const w = 8, h = 8;
  const source = AnimationStateModel(id: 1, name: 'Walk', frameRate: 12);

  final restPixels = parseGrid([
    '........',
    '........',
    '..W.....',
    '........',
    '........',
    '........',
    '........',
    '........',
  ]);

  AnimationFrame restFrame() => AnimationFrame(
        id: 10,
        name: 'Frame 1',
        stateId: 1,
        duration: 100,
        layers: [Layer(layerId: 5, id: 'l', name: 'Body', pixels: restPixels, stableKey: 'body')],
      );

  Rig rig({int length = 3, int fps = 12, int? outputStateId}) => Rig(
        id: 'r',
        stateId: 1,
        outputStateId: outputStateId,
        bones: const [Bone(id: 'root', name: 'root', head: Offset(4.5, 4.5), length: 2)],
        parts: const [RigPart(id: 'p', boneId: 'root', layerKey: 'body')],
        clips: [
          RigClip(id: 'main', name: 'Walk', length: length, fps: fps, keyframes: const [
            RigKeyframe(time: 0, boneId: 'root'),
            RigKeyframe(time: 2, boneId: 'root', translation: Offset(2, 0)),
          ]),
        ],
      );

  late FakeProjectRepo repo;
  late RigBakeService service;
  setUp(() {
    repo = FakeProjectRepo();
    service = RigBakeService(repo);
  });

  Future<RigBakeResult> bake(Rig r, {List<AnimationStateModel>? states, List<AnimationFrame>? frames}) =>
      service.bake(
        projectId: 1,
        rig: r,
        states: states ?? [source],
        frames: frames ?? [restFrame()],
        width: w,
        height: h,
      );

  int pixelX(AnimationFrame f) {
    final out = f.layers.firstWhere((l) => l.stableKey == RigLayerKeys.output).pixels;
    return out.indexWhere((p) => p != 0) % w;
  }

  test('canBake needs a clip with keyframes', () {
    expect(RigBakeService.canBake(rig()), isTrue);
    final onlyIk = rig().copyWith(clips: [
      const RigClip(id: 'main', name: 'x', ikKeyframes: [IkKeyframe(time: 0, chainId: 'ik', target: Offset(1, 1))]),
    ]);
    expect(RigBakeService.canBake(onlyIk), isTrue, reason: 'an IK target is an animation too');
    expect(RigBakeService.canBake(const Rig(id: 'r', stateId: 1)), isFalse);
    expect(RigBakeService.canBake(rig().copyWith(clips: [const RigClip(id: 'main', name: 'x')])), isFalse);
    expect(() => bake(const Rig(id: 'r', stateId: 1)), throwsStateError);
  });

  group('first bake', () {
    test('creates an output animation with one frame per clip frame', () async {
      final result = await bake(rig(fps: 10));

      expect(result.outputState.name, 'Walk (rig)');
      expect(result.outputState.frameRate, 10);
      expect(result.rig.outputStateId, result.outputState.id);
      expect(result.states.map((s) => s.id), [1, result.outputState.id]);

      final out = result.frames.where((f) => f.stateId == result.outputState.id).toList();
      expect(out, hasLength(3));
      expect(out.map((f) => f.duration), everyElement(100));
      expect(out.map((f) => f.name), ['Frame 1', 'Frame 2', 'Frame 3']);
      expect(out.map((f) => pixelX(f)), [2, 3, 4], reason: 'the body slides right one pixel per frame');
    });

    test('each frame has a locked rig layer under an empty cleanup layer', () async {
      final result = await bake(rig());
      final frame = result.frames.firstWhere((f) => f.stateId == result.outputState.id);

      expect(frame.layers.map((l) => l.name), ['Rig', 'Cleanup']);
      expect(frame.layers.map((l) => l.stableKey), [RigLayerKeys.output, RigLayerKeys.cleanup]);
      expect(frame.layers[0].isLocked, isTrue);
      expect(frame.layers[1].isLocked, isFalse);
      expect(frame.layers[1].pixels.every((p) => p == 0), isTrue);
      expect(frame.layers.every((l) => l.layerId != 0), isTrue, reason: 'stored layers have database ids');
      expect(RigBakePlanner.isRigFrame(frame), isTrue);
    });

    test('the rest pose is left exactly as it was', () async {
      final rest = restFrame();
      final result = await bake(rig(), frames: [rest]);
      expect(result.frames.first, same(rest));
      expect(rest.layers.single.pixels, restPixels);
      expect(repo.updatedFrames, isEmpty);
      expect(repo.deletedFrames, isEmpty);
    });
  });

  test('the rest pose is the frame the rig names, not just the first', () async {
    final first = restFrame();
    final second = AnimationFrame(
      id: 11,
      name: 'Frame 2',
      stateId: 1,
      duration: 100,
      layers: [
        Layer(
          layerId: 6,
          id: 'l2',
          name: 'Body',
          pixels: parseGrid(['W.......', ...List.filled(7, '........')]),
          stableKey: 'body',
        ),
      ],
    );

    final fromFirst = await bake(rig(), frames: [first, second]);
    final fromSecond = await bake(rig().copyWith(restFrameIndex: 1), frames: [first, second]);

    int x0(RigBakeResult r) => pixelX(r.frames.firstWhere((f) => f.stateId == r.outputState.id));
    expect(x0(fromFirst), 2);
    expect(x0(fromSecond), 0);
    // An index past the end falls back to the last frame instead of failing.
    final clamped = await bake(rig().copyWith(restFrameIndex: 99), frames: [first, second]);
    expect(x0(clamped), 0);
  });

  group('re-baking', () {
    Future<(RigBakeResult, RigBakeService)> bakedOnce() async {
      final first = await bake(rig());
      return (first, service);
    }

    test('refreshes the rig layer and keeps hand edits and layer identity', () async {
      final (first, _) = await bakedOnce();
      final out = first.frames.where((f) => f.stateId == first.outputState.id).toList();

      // Paint on frame 2's cleanup layer.
      final cleanup = out[1].layers[1];
      final painted = Uint32List.fromList(cleanup.pixels)..[7 * w + 7] = 0xFFFF0000;
      final edited = [
        for (final f in first.frames)
          if (f.id == out[1].id)
            f.copyWith(layers: [f.layers[0], cleanup.copyWith(pixels: painted)])
          else
            f,
      ];

      // The animation changes: the body now moves up instead.
      final changed = first.rig.copyWith(clips: [
        RigClip(id: 'main', name: 'Walk', length: 3, keyframes: const [
          RigKeyframe(time: 0, boneId: 'root'),
          RigKeyframe(time: 2, boneId: 'root', translation: Offset(0, 2)),
        ]),
      ]);
      repo.updatedFrames.clear();
      final again = await bake(changed, states: first.states, frames: edited);

      final out2 = again.frames.where((f) => f.stateId == first.outputState.id).toList();
      expect(out2.map((f) => f.id), out.map((f) => f.id), reason: 'same frames, no churn');
      expect(out2[1].layers[1].pixels[7 * w + 7], 0xFFFF0000, reason: 'cleanup survives');
      expect(out2[1].layers.map((l) => l.layerId), out[1].layers.map((l) => l.layerId));
      final rigPixels = out2[2].layers[0].pixels;
      expect(rigPixels.indexWhere((p) => p != 0), 4 * w + 2, reason: 'moved up two rows');
      expect(repo.createdStates, hasLength(1), reason: 'no second output animation');
      expect(repo.updatedFrames, hasLength(3));
    });

    test('a longer clip adds frames at the end', () async {
      final (first, _) = await bakedOnce();
      final longer = first.rig.copyWith(clips: [first.rig.clips.first.copyWith(length: 5)]);
      final again = await bake(longer, states: first.states, frames: first.frames);
      final out = again.frames.where((f) => f.stateId == first.outputState.id).toList();
      expect(out, hasLength(5));
      expect(out.last.name, 'Frame 5');
      expect(repo.createdFrames, hasLength(3 + 2));
    });

    test('a shorter clip deletes the surplus frames', () async {
      final (first, _) = await bakedOnce();
      final shorter = first.rig.copyWith(clips: [
        first.rig.clips.first.copyWith(length: 2, keyframes: const [RigKeyframe(time: 0, boneId: 'root')]),
      ]);
      final out = first.frames.where((f) => f.stateId == first.outputState.id).toList();
      final again = await bake(shorter, states: first.states, frames: first.frames);
      expect(again.frames.where((f) => f.stateId == first.outputState.id), hasLength(2));
      expect(repo.deletedFrames, [out[2].id]);
    });

    test('a deleted rig layer is recreated with a database id', () async {
      final (first, _) = await bakedOnce();
      final stripped = [
        for (final f in first.frames)
          if (f.stateId == first.outputState.id) f.copyWith(layers: [f.layers[1]]) else f,
      ];
      final again = await bake(first.rig, states: first.states, frames: stripped);
      final frame = again.frames.firstWhere((f) => f.stateId == first.outputState.id);
      expect(frame.layers.map((l) => l.stableKey), [RigLayerKeys.output, RigLayerKeys.cleanup]);
      expect(frame.layers.map((l) => l.order), [0, 1]);
      expect(repo.createdLayers, hasLength(3));
      expect(frame.layers.every((l) => l.layerId != 0), isTrue);
    });

    test('a changed frame rate updates the animation and every frame duration', () async {
      final (first, _) = await bakedOnce();
      final faster = first.rig.copyWith(clips: [first.rig.clips.first.copyWith(fps: 20)]);
      final again = await bake(faster, states: first.states, frames: first.frames);
      expect(again.outputState.frameRate, 20);
      expect(repo.updatedStates.single.frameRate, 20);
      expect(again.frames.where((f) => f.stateId == first.outputState.id).map((f) => f.duration), everyElement(50));
    });

    test('an output animation that no longer exists is made again', () async {
      final (first, _) = await bakedOnce();
      final fresh = FakeProjectRepo();
      final again = await RigBakeService(fresh).bake(
        projectId: 1,
        rig: first.rig, // points at a state that is not in the list below
        states: [source],
        frames: [restFrame()],
        width: w,
        height: h,
      );
      expect(fresh.createdStates, hasLength(1));
      expect(again.rig.outputStateId, again.outputState.id);
    });
  });

  group('hand edits', () {
    test('removalsWithEdits lists only surplus frames that hold hand edits', () async {
      final first = await bake(rig());
      final out = first.frames.where((f) => f.stateId == first.outputState.id).toList();
      final shorter = first.rig.copyWith(clips: [first.rig.clips.first.copyWith(length: 1)]);

      expect(RigBakePlanner.removalsWithEdits(rig: shorter, frames: first.frames), isEmpty);

      final painted = Uint32List(w * h)..[0] = 0xFF00FF00;
      final edited = [
        for (final f in first.frames)
          if (f.id == out[2].id) f.copyWith(layers: [f.layers[0], f.layers[1].copyWith(pixels: painted)]) else f,
      ];
      expect(RigBakePlanner.removalsWithEdits(rig: shorter, frames: edited).map((f) => f.id), [out[2].id]);
      // Frames that survive are never reported.
      expect(RigBakePlanner.removalsWithEdits(rig: first.rig, frames: edited), isEmpty);
    });
  });
}
