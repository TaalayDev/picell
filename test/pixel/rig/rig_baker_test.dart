import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:picell/data/models/layer.dart';
import 'package:picell/data/models/rig/rig.dart';
import 'package:picell/pixel/rig/rig_baker.dart';

import 'rig_test_support.dart';

void main() {
  const w = 8, h = 8;

  Layer layer(String key, List<String> rows, {bool visible = true, double opacity = 1}) => Layer(
        layerId: 0,
        id: 'id-$key',
        name: key,
        pixels: parseGrid(rows),
        stableKey: key,
        isVisible: visible,
        opacity: opacity,
      );

  // A 2-pixel "arm" hanging from a "body".
  final body = layer('body', [
    '........',
    '........',
    '..WWWW..',
    '..WWWW..',
    '........',
    '........',
    '........',
    '........',
  ]);
  final arm = layer('arm', [
    '........',
    '........',
    '........',
    '........',
    '..RR....',
    '........',
    '........',
    '........',
  ]);

  Rig rig({List<RigPart>? parts, RigSettings settings = const RigSettings(), List<RigClip>? clips}) => Rig(
        id: 'r',
        stateId: 1,
        settings: settings,
        bones: const [
          Bone(id: 'root', name: 'root', head: Offset(4, 4)),
          Bone(id: 'arm', name: 'arm', parentId: 'root', head: Offset(2, 4)),
        ],
        parts: parts ??
            const [
              RigPart(id: 'pb', boneId: 'root', layerKey: 'body', drawOrder: 0),
              RigPart(id: 'pa', boneId: 'arm', layerKey: 'arm', drawOrder: 1),
            ],
        clips: clips ?? const [],
      );

  RigBaker baker(Rig r, [List<Layer>? layers]) => RigBaker(rig: r, width: w, height: h, layers: layers ?? [body, arm]);

  RigClip clip(List<RigKeyframe> keys, {int length = 4, bool loop = false}) =>
      RigClip(id: 'c', name: 'c', length: length, loop: loop, keyframes: keys);

  test('an unposed rig reproduces the rest-pose composite', () {
    final out = baker(rig()).bakeFrame(clip(const []), 0);
    expect(renderGrid(out, w), [
      '........',
      '........',
      '..WWWW..',
      '..WWWW..',
      '..RR....',
      '........',
      '........',
      '........',
    ]);
  });

  test('moving the root carries its child along', () {
    final c = clip(const [RigKeyframe(time: 0, boneId: 'root', translation: Offset(2, 1))]);
    expect(renderGrid(baker(rig()).bakeFrame(c, 0), w), [
      '........',
      '........',
      '........',
      '....WWWW',
      '....WWWW',
      '....RR..',
      '........',
      '........',
    ]);
  });

  test('draw order decides overlaps, highest on top', () {
    // Put the arm over the body, then under it.
    final overlapArm = layer('arm', [
      '........',
      '........',
      '..RR....',
      '........',
      '........',
      '........',
      '........',
      '........',
    ]);
    List<String> row2(RigPart arm) =>
        renderGrid(baker(rig(parts: [const RigPart(id: 'pb', boneId: 'root', layerKey: 'body'), arm]), [body, overlapArm]).bakeFrame(clip(const []), 0), w)
            .sublist(2, 3);

    expect(row2(const RigPart(id: 'pa', boneId: 'arm', layerKey: 'arm', drawOrder: 5)), ['..RRWW..']);
    expect(row2(const RigPart(id: 'pa', boneId: 'arm', layerKey: 'arm', drawOrder: -5)), ['..WWWW..']);
  });

  test('hidden, transparent and unknown layers are skipped', () {
    final hidden = layer('arm', ['........', '........', '........', '........', '..RR....', '........', '........', '........'],
        visible: false);
    final out = baker(rig(), [body, hidden]).bakeFrame(clip(const []), 0);
    expect(renderGrid(out, w)[4], '........');

    final missing = baker(rig(), [body]).bakeFrame(clip(const []), 0);
    expect(renderGrid(missing, w)[4], '........');
  });

  test('layers no bone drives stay put while the rest moves', () {
    final r = rig(parts: const [RigPart(id: 'pa', boneId: 'arm', layerKey: 'arm', drawOrder: 1)]);
    final c = clip(const [RigKeyframe(time: 0, boneId: 'arm', rotation: 90)]);
    expect(renderGrid(baker(r).bakeFrame(c, 0), w), [
      '........',
      '........',
      '..WWWW..',
      '..WWWW..',
      '.R......',
      '.R......',
      '........',
      '........',
    ]);
  });

  test('still layers interleave with parts by layer position', () {
    // The still arm layer (position 1) sits above the bound body (position 0).
    final overlapArm = layer('arm', [
      '........',
      '........',
      '..RR....',
      '........',
      '........',
      '........',
      '........',
      '........',
    ]);
    final r = rig(parts: const [RigPart(id: 'pb', boneId: 'root', layerKey: 'body', drawOrder: 0)]);
    final c = clip(const [RigKeyframe(time: 0, boneId: 'root', translation: Offset(1, 0))]);
    final out = renderGrid(baker(r, [body, overlapArm]).bakeFrame(c, 0), w);
    expect(out[2], '..RRWWW.', reason: 'the still layer stays on top of the moved body');
  });

  test('layers without a stable key are drawn as still layers', () {
    final plain = Layer(layerId: 0, id: 'x', name: 'x', pixels: parseGrid(['W.......', ...List.filled(7, '........')]));
    final out = baker(rig(parts: const []), [plain]).bakeFrame(clip(const []), 0);
    expect(renderGrid(out, w).first, 'W.......');
  });

  test('a part bound to a missing bone is ignored', () {
    final r = rig(parts: const [RigPart(id: 'p', boneId: 'ghost', layerKey: 'body')]);
    expect(baker(r, [body]).bakeFrame(clip(const []), 0).every((p) => p == 0), isTrue);
  });

  test('layer opacity is applied to the part', () {
    final faint = layer('body', ['WWWWWWWW', '........', '........', '........', '........', '........', '........', '........'],
        opacity: 0.5);
    final r = rig(parts: const [RigPart(id: 'pb', boneId: 'root', layerKey: 'body')]);
    final px = baker(r, [faint]).bakeFrame(clip(const []), 0)[0];
    expect((px >> 24) & 0xFF, closeTo(128, 1));
  });

  test('rotating the arm swings only the arm pixels, about its joint', () {
    // Joint at (2,4); the arm covers (2,4) and (3,4). A clockwise quarter turn
    // sends them to (1,4) and (1,5): left of the joint and one below.
    final c = clip(const [RigKeyframe(time: 0, boneId: 'arm', rotation: 90)]);
    expect(renderGrid(baker(rig()).bakeFrame(c, 0), w), [
      '........',
      '........',
      '..WWWW..',
      '..WWWW..',
      '.R......',
      '.R......',
      '........',
      '........',
    ]);
  });

  test('bakeClip returns one fresh buffer per frame, and equal poses match', () {
    final c = clip(const [
      RigKeyframe(time: 0, boneId: 'root', translation: Offset(0, 0), easing: RigEasing.stepped),
      RigKeyframe(time: 2, boneId: 'root', translation: Offset(1, 0), easing: RigEasing.stepped),
    ], length: 4);
    final b = baker(rig());
    final frames = b.bakeClip(c);

    expect(frames, hasLength(4));
    expect(frames[0], frames[1], reason: 'stepped: held pose');
    expect(frames[2], frames[3]);
    expect(frames[1], isNot(frames[2]));
    expect(identical(frames[0], frames[1]), isFalse, reason: 'frames must not share a mutable buffer');

    // Mutating a baked frame must not corrupt later bakes (cache safety).
    frames[0][0] = 0xFFFFFFFF;
    expect(b.bakeFrame(c, 0)[0], 0);
  });

  test('rest-pose layers are never modified', () {
    final before = Uint32List.fromList(body.pixels);
    final c = clip(const [RigKeyframe(time: 0, boneId: 'root', rotation: 33, translation: Offset(1, 1))]);
    baker(rig()).bakeClip(c);
    expect(body.pixels, before);
  });

  test('angle snapping makes nearby rotations bake identically', () {
    final r = rig(settings: const RigSettings(snapAngleDegrees: 15));
    RigClip at(double deg) => clip([RigKeyframe(time: 0, boneId: 'arm', rotation: deg)]);
    final b = baker(r);
    expect(b.bakeFrame(at(14), 0), b.bakeFrame(at(16), 0));
    expect(b.bakeFrame(at(14), 0), isNot(b.bakeFrame(at(40), 0)));
  });

  test('an IK target moves a limb to it, and the pixels follow', () {
    // A two-bone arm of 2 px each along the row below the body; the arm layer
    // is bound to the lower bone, so its pixels travel with the hand.
    final r = Rig(
      id: 'r',
      stateId: 1,
      bones: const [
        Bone(id: 'upper', name: 'upper', head: Offset(1.5, 4.5), length: 2),
        Bone(id: 'lower', name: 'lower', parentId: 'upper', head: Offset(3.5, 4.5), length: 2),
      ],
      parts: const [RigPart(id: 'pa', boneId: 'lower', layerKey: 'arm', drawOrder: 1)],
      ikChains: const [IkChain(id: 'ik', tipBoneId: 'lower')],
    );
    final c = clip(const [], loop: false).copyWith(ikKeyframes: const [
      IkKeyframe(time: 0, chainId: 'ik', target: Offset(3.5, 2.5)),
    ]);

    final out = baker(r, [arm]).bakeFrame(c, 0);
    // At rest the arm layer's pixels are at (2,4) and (3,4); with the hand
    // lifted they must have left row 4.
    final rows = renderGrid(out, w);
    expect(rows[4], isNot('..RR....'));
    expect(out.where((p) => p != 0), hasLength(2), reason: 'the two arm pixels, moved');
  });

  test('a chain without target keys is left to the bones own keyframes', () {
    final r = Rig(
      id: 'r',
      stateId: 1,
      bones: const [Bone(id: 'upper', name: 'upper', head: Offset(1.5, 4.5), length: 2)],
      parts: const [RigPart(id: 'pa', boneId: 'upper', layerKey: 'arm', drawOrder: 1)],
      ikChains: const [IkChain(id: 'ik', tipBoneId: 'upper', boneCount: 1)],
    );
    expect(renderGrid(baker(r, [arm]).bakeFrame(clip(const []), 0), w)[4], '..RR....');
  });
}
