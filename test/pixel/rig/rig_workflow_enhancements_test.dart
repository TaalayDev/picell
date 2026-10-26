import 'package:flutter_test/flutter_test.dart';
import 'package:picell/data/models/rig/rig.dart';
import 'package:picell/pixel/rig/rig_editor_controller.dart';
import 'package:picell/pixel/rig/pose_interpolator.dart';

void main() {
  const bones = [
    Bone(id: 'hip', name: 'Hips', head: Offset(4, 1), length: 1, restAngle: 90),
    Bone(id: 'thigh', name: 'Thigh', parentId: 'hip', head: Offset(4, 2), length: 3, restAngle: 90),
    Bone(id: 'shin', name: 'Foot', parentId: 'thigh', head: Offset(4, 5), length: 3),
  ];
  RigEditorController make({List<RigClip> clips = const []}) => RigEditorController(
        rig: Rig(
            id: 'r',
            stateId: 1,
            bones: bones,
            clips: clips,
            ikChains: const [IkChain(id: 'leg', tipBoneId: 'shin', boneCount: 2)]),
        restLayers: [],
        width: 16,
        height: 16,
      );

  test('numeric geometry preserves connections, exact angles, half steps and atomic undo', () {
    final c = make();
    addTearDown(c.dispose);
    final before = c.rig;
    expect(c.setBoneGeometry('hip', x: 4.6, y: 1.6, length: 2.2, angle: 45), isTrue);
    expect(c.bone('hip')!.head, const Offset(4.5, 1.5));
    expect(c.bone('hip')!.length, closeTo(2, 1e-9));
    expect(c.bone('hip')!.restAngle, closeTo(45, 1e-9));
    expect((c.bone('hip')!.tail - c.bone('thigh')!.head).distance, lessThan(1e-9));
    expect((c.bone('thigh')!.tail - c.bone('shin')!.head).distance, lessThan(1e-9));
    c.undo();
    expect(c.rig, before);
    expect(c.setBoneGeometry('hip', length: 0), isFalse);
    expect(c.setBoneGeometry('hip', x: double.nan), isFalse);
    expect(c.rig, before);
  });

  test('foot contacts hold only selected frames and survive saving, release and undo', () {
    final c = make();
    addTearDown(c.dispose);
    c.mode = RigMode.animate;
    c.setClipLength(8);
    c.setTime(0);
    c.setPose('hip', translation: Offset.zero);
    c.setTime(7);
    c.setPose('hip', translation: const Offset(.5, 0));
    c.selectBone('shin');
    c.setTime(2);
    c.selectFrameRange(2, 4);
    final contact = c.displayBone('shin')!.tail;
    final before = c.rig;
    c.plantFoot();
    expect(c.hasFootPlant, isTrue);
    for (var frame = 2; frame <= 4; frame++) {
      c.setTime(frame);
      expect((c.displayBone('shin')!.tail - contact).distance, lessThan(.01));
    }
    final restored = Rig.fromJson(c.rig.toJson());
    expect(restored, c.rig);
    for (final frame in [0.0, 1.99, 5.0, 7.0]) {
      expect(PoseInterpolator.sampleIk(restored.clips.first, restored.ikChains, frame), isEmpty);
    }
    expect(PoseInterpolator.sampleIk(restored.clips.first, restored.ikChains, 4.9)['leg'], contact);
    c.undo();
    expect(c.rig, before);
    c.redo();
    c.releaseFootPlant();
    expect(c.hasFootPlant, isFalse);
    c.undo();
    expect(c.hasFootPlant, isTrue);
  });

  test('old target keys interpolate normally and contacts override only their own frame', () {
    const chain = IkChain(id: 'leg', tipBoneId: 'shin');
    const clip = RigClip(id: 'c', name: 'C', length: 8, loop: false, ikKeyframes: [
      IkKeyframe(time: 0, chainId: 'leg', target: Offset.zero),
      IkKeyframe(time: 7, chainId: 'leg', target: Offset(7, 7)),
      IkKeyframe(time: 3, chainId: 'leg', target: Offset(10, 10), planted: true),
    ]);
    expect(PoseInterpolator.sampleIk(clip, [chain], 2)['leg'], const Offset(2, 2));
    expect(PoseInterpolator.sampleIk(clip, [chain], 3.9)['leg'], const Offset(10, 10));
    expect(PoseInterpolator.sampleIk(clip, [chain], 4)['leg'], const Offset(4, 4));
    expect(
        IkKeyframe.fromJson(const IkKeyframe(time: 0, chainId: 'leg', target: Offset.zero).toJson()).planted, isFalse);
  });

  const clip = RigClip(id: 'c', name: 'Timeline', length: 8, keyframes: [
    RigKeyframe(time: 0, boneId: 'hip'),
    RigKeyframe(time: 2, boneId: 'hip', rotation: 20),
    RigKeyframe(time: 3, boneId: 'hip', rotation: 30),
    RigKeyframe(time: 6, boneId: 'hip', rotation: 60),
    RigKeyframe(time: 3, boneId: 'shin', rotation: 5),
  ], ikKeyframes: [
    IkKeyframe(time: 2, chainId: 'leg', target: Offset(7, 5), planted: true),
    IkKeyframe(time: 3, chainId: 'leg', target: Offset(7, 5), planted: true),
    IkKeyframe(time: 6, chainId: 'leg', target: Offset(6, 5)),
  ]);

  test('move ranges handles overlap, every track and foot contact keys atomically', () {
    final c = make(clips: [clip]);
    addTearDown(c.dispose);
    c.selectFrameRange(2, 3);
    c.moveFrameRange(1);
    expect(c.keyAt('hip', 2), isNull);
    expect(c.keyAt('hip', 3)!.rotation, 20);
    expect(c.keyAt('hip', 4)!.rotation, 30);
    expect(c.keyAt('shin', 4)!.rotation, 5);
    expect(c.ikKeyAt('leg', 3)!.planted, isTrue);
    expect(c.ikKeyAt('leg', 4)!.planted, isTrue);
    expect(c.activeClip.keyframes.map((k) => (k.boneId, k.time)).toSet().length, c.activeClip.keyframes.length);
    c.undo();
    expect(c.activeClip, clip);
  });

  test('duplicate inserts selected frames without overwriting later frames', () {
    final c = make(clips: [clip]);
    addTearDown(c.dispose);
    c.selectFrameRange(2, 3);
    c.duplicateFrameRange();
    expect(c.activeClip.length, 10);
    expect(c.keyAt('hip', 4)!.rotation, 20);
    expect(c.keyAt('hip', 5)!.rotation, 30);
    expect(c.keyAt('hip', 8)!.rotation, 60);
    expect(c.ikKeyAt('leg', 4)!.planted, isTrue);
    expect(c.ikKeyAt('leg', 8)!.target, const Offset(6, 5));
    expect((c.rangeStart, c.rangeEnd), (4, 5));
    c.undo();
    expect(c.activeClip, clip);
  });

  test('delete closes the range on all tracks, supports undo and retains one empty frame', () {
    final c = make(clips: [clip]);
    addTearDown(c.dispose);
    c.selectFrameRange(2, 3);
    c.deleteFrameRange();
    expect(c.activeClip.length, 6);
    expect(c.keyAt('hip', 4)!.rotation, 60);
    expect(c.ikKeyAt('leg', 4)!.planted, isFalse);
    expect(c.activeClip.ikKeyframes.where((k) => k.planted), isEmpty);
    c.undo();
    expect(c.activeClip, clip);
    c.selectFrameRange(0, 7);
    c.deleteFrameRange();
    expect(c.activeClip.length, 1);
    expect(c.activeClip.keyframes, isEmpty);
    expect(c.activeClip.ikKeyframes, isEmpty);
  });

  test('selection clamps reversed ranges and the timeline respects the frame limit', () {
    final c = make(clips: [clip]);
    addTearDown(c.dispose);
    c.selectFrameRange(3, 2);
    expect((c.rangeStart, c.rangeEnd), (2, 3));
    c.moveFrameRange(-99);
    expect((c.rangeStart, c.rangeEnd), (0, 1));
    c.setClipLength(240);
    c.selectFrameRange(0, 239);
    final before = c.rig;
    c.duplicateFrameRange();
    expect(c.rig, before);
  });
}
