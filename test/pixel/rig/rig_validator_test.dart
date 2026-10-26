import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:picell/data/models/layer.dart';
import 'package:picell/data/models/rig/rig.dart';
import 'package:picell/pixel/rig/rig_editor_controller.dart';
import 'package:picell/pixel/rig/rig_validator.dart';

List<RigIssue> check(Rig rig, {Map<String, String> layers = const {'body': 'Body'}}) =>
    RigValidator.validate(rig, width: 4, height: 4, layerNames: layers);

Iterable<String> messages(List<RigIssue> i, RigIssueSeverity s) =>
    i.where((e) => e.severity == s).map((e) => e.message);

void main() {
  const root = Bone(id: 'a', name: 'root', length: 3);

  test('a healthy rig has no errors or warnings', () {
    final issues = check(const Rig(id: 'r', stateId: 1, bones: [
      root
    ], parts: [
      RigPart(id: 'p', boneId: 'a', layerKey: 'body'),
    ]));
    expect(issues, isEmpty);
  });

  test('cycles, missing parents and zero-length bones are reported', () {
    final issues = check(
        const Rig(id: 'r', stateId: 1, bones: [
          Bone(id: 'x', name: 'x', parentId: 'y', length: 1),
          Bone(id: 'y', name: 'y', parentId: 'x', length: 1),
          Bone(id: 'z', name: 'z', parentId: 'gone', length: 0),
        ]),
        layers: const {});
    expect(messages(issues, RigIssueSeverity.error).length, 3);
    expect(messages(issues, RigIssueSeverity.warning), contains(contains('no length')));
  });

  test('a mask for another canvas size is an error, an empty mask a warning', () {
    final issues = check(Rig(id: 'r', stateId: 1, bones: const [
      root,
      Bone(id: 'b', name: 'b', length: 1),
    ], parts: [
      RigPart(id: 'p', boneId: 'a', layerKey: 'body', mask: Uint8List(5)),
      RigPart(id: 'q', boneId: 'b', layerKey: 'body', mask: Uint8List(16)),
    ]));
    expect(messages(issues, RigIssueSeverity.error), [contains('different canvas size')]);
    expect(messages(issues, RigIssueSeverity.warning), [contains('owns no pixels')]);
  });

  test('parts of gone layers and bones, and layers nobody moves', () {
    final issues = check(const Rig(id: 'r', stateId: 1, bones: [
      root
    ], parts: [
      RigPart(id: 'p', boneId: 'a', layerKey: 'old'),
      RigPart(id: 'q', boneId: 'nobody', layerKey: 'body'),
    ]));
    expect(messages(issues, RigIssueSeverity.error), [contains('bone that is gone')]);
    expect(messages(issues, RigIssueSeverity.warning), [contains('no longer exists')]);
    expect(messages(issues, RigIssueSeverity.info), [contains('stays still')]);
  });

  test('IK chain problems and stray keys', () {
    final issues = check(
        const Rig(id: 'r', stateId: 1, bones: [
          root
        ], ikChains: [
          IkChain(id: 'c1', name: 'leg', tipBoneId: 'a', boneCount: 3),
          IkChain(id: 'c2', name: 'arm', tipBoneId: 'gone'),
        ], clips: [
          RigClip(id: 'k', name: 'walk', length: 4, keyframes: [
            RigKeyframe(time: 1, boneId: 'ghost'),
            RigKeyframe(time: 9, boneId: 'a'),
          ], ikKeyframes: [
            IkKeyframe(time: 0, chainId: 'c1', target: Offset(90, 0)),
          ]),
        ]),
        layers: const {});
    final text = issues.map((i) => i.message).join('\n');
    expect(text, contains('more bones than'));
    expect(text, contains('ends at a bone that is gone'));
    expect(text, contains('reach far past'));
    expect(text, contains('keys for bones or chains that are gone'));
    expect(text, contains('after its last frame'));
  });

  test('most severe first', () {
    final issues = check(
        const Rig(id: 'r', stateId: 1, bones: [
          Bone(id: 'a', name: 'dup', length: 0),
          Bone(id: 'b', name: 'dup', parentId: 'gone', length: 1),
        ]),
        layers: const {'body': 'Body'});
    final ranks = issues.map((i) => i.severity.index).toList();
    expect([...ranks]..sort(), ranks);
  });

  test('controller exposes issues, recomputes on edit, and focuses what they name', () {
    var n = 0;
    final c = RigEditorController(
      rig: const Rig(id: 'r', stateId: 1),
      restLayers: [Layer(layerId: 0, id: 'l', name: 'Body', pixels: Uint32List(16), stableKey: 'body')],
      width: 4,
      height: 4,
      newId: () => 'i${n++}',
    );
    final id = c.addBone(head: const Offset(1, 3), tail: const Offset(1, 0))!;
    expect(c.issues.single.message, contains('stays still'));
    c.assignLayer('body', id);
    expect(c.issues, isEmpty);
    c.assignLayer('body', null);
    c.selectBone(null);
    c.focusIssue(RigIssue(RigIssueSeverity.info, 'x', boneId: id));
    expect(c.selectedBoneId, id);
  });

  test('unkeyed previews bump the preview revision so the artwork redraws', () {
    var n = 0;
    final c = RigEditorController(
      rig: const Rig(id: 'r', stateId: 1),
      restLayers: const [],
      width: 4,
      height: 4,
      newId: () => 'i${n++}',
    );
    final id = c.addBone(head: const Offset(1, 3), tail: const Offset(1, 0))!;
    c.mode = RigMode.animate;
    c.autoKey = false;
    final rig = c.rig, before = c.previewRevision;
    c.setPose(id, rotation: 10);
    expect(c.rig, same(rig));
    expect(c.previewRevision, greaterThan(before));
    final mid = c.previewRevision;
    c.discardPending();
    expect(c.previewRevision, greaterThan(mid));
  });
}
