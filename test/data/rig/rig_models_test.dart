import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:picell/data.dart';

void main() {
  Rig sample({int stateId = 3, int? outputStateId = 9}) => Rig(
        id: 'r1',
        stateId: stateId,
        restFrameIndex: 2,
        outputStateId: outputStateId,
        name: 'Hero',
        bones: const [
          Bone(id: 'root', name: 'Root', head: Offset(8, 12), length: 4),
          Bone(
            id: 'arm',
            name: 'Arm',
            parentId: 'root',
            head: Offset(8.5, 6),
            length: 5,
            restAngle: -90,
            minAngle: -45,
            maxAngle: 120,
          ),
        ],
        parts: [
          RigPart(
            id: 'p1',
            boneId: 'arm',
            layerKey: 'k1',
            mask: Uint8List.fromList([0, 0, 1, 1, 1, 0, 1, 0]),
            drawOrder: 2,
            pivotOverride: const Offset(1, 2),
          ),
          const RigPart(id: 'p2', boneId: 'root', layerKey: 'k2'),
        ],
        clips: const [
          RigClip(id: 'c', name: 'Walk', fps: 10, length: 6, loop: false, keyframes: [
            RigKeyframe(
              time: 2,
              boneId: 'arm',
              rotation: 30,
              translation: Offset(1, -1),
              flipX: true,
              easing: RigEasing.stepped,
            ),
          ], ikKeyframes: [
            IkKeyframe(time: 3, chainId: 'ik1', target: Offset(9.5, 4.5), easing: RigEasing.easeOut),
          ]),
        ],
        ikChains: const [IkChain(id: 'ik1', name: 'Arm IK', tipBoneId: 'arm', boneCount: 2, bend: -1)],
        poses: const [
          RigPose(
            id: 'pose1',
            name: 'Punch',
            bones: {
              'arm': BonePose(rotation: -40, translation: Offset(2, 0), flipX: true),
              'root': BonePose.rest,
            },
            ik: {'ik1': Offset(10.5, 3.5)},
          ),
        ],
        settings: const RigSettings(snapAngleDegrees: 15, interpolation: 1),
      );

  test('Rig survives a JSON round trip, including masks', () {
    final rig = sample();
    final back = Rig.fromJson(jsonDecode(jsonEncode(rig.toJson())) as Map<String, dynamic>);
    expect(back, rig);
    expect(back.parts.first.mask, Uint8List.fromList([0, 0, 1, 1, 1, 0, 1, 0]));
  });

  test('mask run-length coding round trips and compresses runs', () {
    final mask = Uint8List(1024)..fillRange(100, 900, 1);
    final runs = RigPart.encodeMask(mask);
    expect(runs, [0, 100, 1, 800, 0, 124]);
    expect(RigPart.decodeMask(runs), mask);
    expect(RigPart.decodeMask(RigPart.encodeMask(Uint8List(0))), isEmpty);
  });

  test('fromJson tolerates missing optional fields', () {
    final rig = Rig.fromJson({'id': 'x', 'stateId': 1});
    expect(rig.bones, isEmpty);
    expect(rig.settings, const RigSettings());
    expect(rig.restFrameIndex, 0, reason: 'rigs saved before the field existed use the first frame');
  });

  group('RigDocument', () {
    test('encodes nothing for an empty list and decodes null/garbage to empty', () {
      expect(RigDocument.encode(const []), isNull);
      expect(RigDocument.decode(null), isEmpty);
      expect(RigDocument.decode(''), isEmpty);
      expect(RigDocument.decode('{not json'), isEmpty);
    });

    test('round trips', () {
      final encoded = RigDocument.encode([sample()]);
      expect(RigDocument.decode(encoded), [sample()]);
    });

    test('remapStateIds rewrites ids and drops rigs of unknown states', () {
      final encoded = RigDocument.encode([sample(stateId: 3), sample(stateId: 4).copyWith(id: 'r2')]);
      final remapped = RigDocument.decode(RigDocument.remapStateIds(encoded, {3: 30}));
      expect(remapped.map((r) => r.stateId), [30]);
      expect(RigDocument.remapStateIds(encoded, {}), isNull);
    });

    test('remapStateIds remaps the output state too, and forgets one that no longer exists', () {
      final encoded = RigDocument.encode([sample()]);
      final both = RigDocument.decode(RigDocument.remapStateIds(encoded, {3: 30, 9: 90})).single;
      expect(both.outputStateId, 90);
      final onlySource = RigDocument.decode(RigDocument.remapStateIds(encoded, {3: 30})).single;
      expect(onlySource.stateId, 30);
      expect(onlySource.outputStateId, isNull);
    });
  });

  group('Layer', () {
    Layer layer({String? key, Offset? anchor}) => Layer(
          layerId: 1,
          id: 'a',
          name: 'L',
          pixels: Uint32List(4),
          anchorPoint: anchor,
          stableKey: key,
        );

    test('stableKey and anchorPoint survive JSON and copyWith(id:)', () {
      final l = layer(key: 'k', anchor: const Offset(1.5, 2));
      final back = Layer.fromJson(jsonDecode(jsonEncode(l.toJson())) as Map<String, dynamic>);
      expect(back.stableKey, 'k');
      expect(back.anchorPoint, const Offset(1.5, 2));
      // Frame duplication regenerates the id but must keep the key.
      expect(l.copyWith(id: 'b', layerId: 0).stableKey, 'k');
    });

    test('legacy JSON without stableKey loads as null', () {
      final json = layer().toJson();
      expect(json.containsKey('stableKey'), isFalse);
      expect(Layer.fromJson(json).stableKey, isNull);
    });
  });

  test('Project carries rigData through JSON and copyWith', () {
    final project = Project(
      id: 1,
      name: 'p',
      width: 8,
      height: 8,
      createdAt: DateTime.fromMillisecondsSinceEpoch(1000),
      editedAt: DateTime.fromMillisecondsSinceEpoch(2000),
      rigData: RigDocument.encode([sample()]),
    );
    final back = Project.fromJson(jsonDecode(jsonEncode(project.toJson())) as Map<String, dynamic>);
    expect(back.rigData, project.rigData);
    expect(project.copyWith(clearRigData: true).rigData, isNull);
    expect(project.copyWith(name: 'q').rigData, project.rigData);
  });
}
