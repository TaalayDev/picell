import 'dart:typed_data';
import 'dart:ui';

import '../../data/models/rig/rig.dart';

/// Resolves inherited layers at evaluation time, so changing a parent, binding
/// or rest joint cannot leave stale masks in the saved rig. Pixels are owned
/// by one nearest bone segment; explicit masks remain authoritative.
abstract final class RigLayerInfluences {
  static List<RigPart> resolve(Rig rig, int width, int height) {
    final result = <RigPart>[];
    final directlyBound = {for (final p in rig.parts) p.boneId};
    final bones = {for (final b in rig.bones) b.id: b};
    for (final part in rig.parts) {
      final root = bones[part.boneId];
      if (root == null || part.attachmentId != null) {
        result.add(part);
        continue;
      }
      final chain = <Bone>[root];
      final seen = {root.id};
      void walk(String parent) {
        for (final child in rig.bones) {
          if (child.parentId != parent ||
              child.connection != BoneConnection.explicit ||
              directlyBound.contains(child.id) ||
              !seen.add(child.id)) {
            continue;
          }
          chain.add(child);
          walk(child.id);
        }
      }

      walk(root.id);
      if (chain.length == 1) {
        result.add(part);
        continue;
      }
      final masks = [for (final _ in chain) Uint8List(width * height)];
      for (var i = 0; i < width * height; i++) {
        if (part.mask != null && (i >= part.mask!.length || part.mask![i] == 0)) continue;
        final point = Offset((i % width) + .5, (i ~/ width) + .5);
        var best = 0;
        var distance = double.infinity;
        for (var j = 0; j < chain.length; j++) {
          final bone = chain[j];
          final axis = bone.tail - bone.head;
          final square = axis.distanceSquared;
          final v = point - bone.head;
          final t = square == 0 ? 0.0 : ((v.dx * axis.dx + v.dy * axis.dy) / square).clamp(0.0, 1.0);
          final d = (point - bone.head - axis * t).distanceSquared;
          if (d < distance) {
            best = j;
            distance = d;
          }
        }
        masks[best][i] = 1;
      }
      for (var j = 0; j < chain.length; j++) {
        result.add(part.copyWith(id: '${part.id}:influence:${chain[j].id}', boneId: chain[j].id, mask: () => masks[j]));
      }
    }
    return result;
  }
}
