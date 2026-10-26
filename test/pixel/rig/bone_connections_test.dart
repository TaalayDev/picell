import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:picell/data/models/layer.dart';
import 'package:picell/data/models/rig/rig.dart';
import 'package:picell/pixel/rig/rig_baker.dart';
import 'package:picell/pixel/rig/rig_editor_controller.dart';
import 'package:picell/pixel/rig/rig_layer_influences.dart';

void main() {
  const root = Bone(id: 'root', name: 'Root', head: Offset(1, 2), length: 2);
  const child = Bone(id: 'child', name: 'Child', parentId: 'root', head: Offset(3, 2), length: 2);
  const part = RigPart(id: 'part', boneId: 'root', layerKey: 'sprite');
  Rig rig({List<Bone>? bones, List<RigPart>? parts}) =>
      Rig(id: 'rig', stateId: 1, bones: bones ?? [root, child], parts: parts ?? [part]);

  test('connection kind survives serialization and old links remain explicit', () {
    expect(Bone.fromJson(child.toJson()).connection, BoneConnection.explicit);
    final implicit = child.copyWith(connection: BoneConnection.implicit);
    expect(Bone.fromJson(implicit.toJson()), implicit);
    final legacy = child.toJson()..remove('connection');
    expect(Bone.fromJson(legacy).connection, BoneConnection.explicit);
  });

  test('unattached creation inherits first bone motion without moving the joint', () {
    var n = 0;
    final c = RigEditorController(
        rig: rig(bones: [root], parts: []), restLayers: [], width: 8, height: 8, newId: () => '${n++}');
    addTearDown(c.dispose);
    final id = c.addBone(head: const Offset(5, 5), tail: const Offset(7, 5))!;
    expect(c.bone(id)!.parentId, root.id);
    expect(c.bone(id)!.connection, BoneConnection.implicit);
    expect(c.bone(id)!.head, const Offset(5, 5));
    c.mode = RigMode.animate;
    c.setPose(root.id, translation: const Offset(1, 0));
    expect(c.displayBone(id)!.head, const Offset(6, 5));
  });

  test('continuing a bone is explicit; disconnect and undo retain the link kind', () {
    final c = RigEditorController(rig: rig(bones: [root], parts: []), restLayers: [], width: 8, height: 8);
    addTearDown(c.dispose);
    final id = c.addBone(head: root.tail, tail: const Offset(5, 2))!;
    expect(c.bone(id)!.connection, BoneConnection.explicit);
    expect(c.bone(id)!.parentId, root.id);
    c.reparent(id, null);
    expect(c.bone(id)!.parentId, isNull);
    c.undo();
    expect(c.bone(id)!.parentId, root.id);
    expect(c.bone(id)!.connection, BoneConnection.explicit);
    expect(c.reparent(root.id, id), false);
  });

  test('explicit shared layer partitions pixels exactly once across bones', () {
    final parts = RigLayerInfluences.resolve(rig(), 8, 8);
    expect(parts.map((p) => p.boneId), ['root', 'child']);
    for (var i = 0; i < 64; i++) {
      expect(parts.fold<int>(0, (sum, p) => sum + p.mask![i]), 1);
    }
    expect(parts[0].mask![2 * 8 + 1], 1);
    expect(parts[1].mask![2 * 8 + 4], 1);
  });

  test('implicit links and separate child bindings stop layer inheritance', () {
    expect(RigLayerInfluences.resolve(rig(bones: [root, child.copyWith(connection: BoneConnection.implicit)]), 8, 8),
        [part]);
    final assigned = RigPart(id: 'other', boneId: child.id, layerKey: 'other');
    expect(RigLayerInfluences.resolve(rig(parts: [part, assigned]), 8, 8), [part, assigned]);
  });

  test('shared layer bakes unchanged at rest and child moves only its region', () {
    final pixels = Uint32List(64)
      ..[2 * 8 + 1] = 0xffff0000
      ..[2 * 8 + 4] = 0xff00ff00;
    final layer = Layer(layerId: 0, id: 'layer', name: 'Sprite', stableKey: 'sprite', pixels: pixels);
    final baker = RigBaker(rig: rig(), width: 8, height: 8, layers: [layer]);
    expect(baker.bakeFrame(const RigClip(id: 'rest', name: 'Rest'), 0), pixels);
    final moved = baker.bakeFrame(
        const RigClip(id: 'move', name: 'Move', keyframes: [
          RigKeyframe(time: 0, boneId: 'child', translation: Offset(0, 2)),
        ]),
        0);
    expect(moved[2 * 8 + 1], 0xffff0000);
    expect(moved[2 * 8 + 4], 0);
    expect(moved[4 * 8 + 4], 0xff00ff00);
  });
}
