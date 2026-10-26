import 'dart:math' as math;

import '../../data/models/rig/rig.dart';

enum RigIssueSeverity { error, warning, info }

/// One thing worth a look in a rig. [boneId] / [chainId] let the UI select
/// what the message is about.
class RigIssue {
  const RigIssue(this.severity, this.message, {this.boneId, this.chainId});

  final RigIssueSeverity severity;
  final String message;
  final String? boneId;
  final String? chainId;

  @override
  String toString() => '${severity.name}: $message';
}

/// Finds mistakes that would otherwise show up as a rig that quietly does
/// nothing (or, for bad masks, as a crash while baking). Pure.
abstract final class RigValidator {
  /// [layerNames] maps the rest layers' stable keys to their names. Issues
  /// come back most severe first, then in rig order.
  static List<RigIssue> validate(
    Rig rig, {
    required int width,
    required int height,
    required Map<String, String> layerNames,
  }) {
    final out = <RigIssue>[];
    final bones = {for (final b in rig.bones) b.id: b};
    final chains = {for (final c in rig.ikChains) c.id: c};

    // Skeleton.
    for (final b in rig.bones) {
      final seen = <String>{b.id};
      var cursor = b.parentId;
      while (cursor != null && bones.containsKey(cursor)) {
        if (!seen.add(cursor)) {
          out.add(RigIssue(RigIssueSeverity.error, '"${b.name}" is its own ancestor.', boneId: b.id));
          break;
        }
        cursor = bones[cursor]!.parentId;
      }
      if (b.parentId != null && !bones.containsKey(b.parentId)) {
        out.add(RigIssue(RigIssueSeverity.error, '"${b.name}" has a parent that no longer exists.', boneId: b.id));
      }
      if (b.length <= 0) {
        out.add(
            RigIssue(RigIssueSeverity.warning, '"${b.name}" has no length, so it cannot turn anything.', boneId: b.id));
      }
      final lo = b.minAngle, hi = b.maxAngle;
      if (lo != null && hi != null && lo > hi) {
        out.add(
            RigIssue(RigIssueSeverity.warning, '"${b.name}" has its angle limits the wrong way round.', boneId: b.id));
      }
    }
    final names = <String, int>{};
    for (final b in rig.bones) {
      names[b.name] = (names[b.name] ?? 0) + 1;
    }
    for (final e in names.entries) {
      if (e.value > 1) {
        out.add(RigIssue(
            RigIssueSeverity.info,
            '${e.value} bones are called "${e.key}"; presets and mirroring '
            'find bones by name.'));
      }
    }

    // Parts.
    final size = width * height;
    final driven = <String>{};
    for (final p in rig.parts) {
      final bone = bones[p.boneId];
      final layer = layerNames[p.layerKey];
      if (bone == null) {
        out.add(RigIssue(RigIssueSeverity.error, 'Layer "${layer ?? p.layerKey}" is bound to a bone that is gone.'));
        continue;
      }
      if (layer == null) {
        out.add(
            RigIssue(RigIssueSeverity.warning, '"${bone.name}" moves a layer that no longer exists.', boneId: bone.id));
        continue;
      }
      driven.add(p.layerKey);
      final mask = p.mask;
      if (mask != null) {
        if (mask.length != size) {
          out.add(RigIssue(RigIssueSeverity.error,
              'The painted area of "$layer" on "${bone.name}" was made for a different canvas size.',
              boneId: bone.id));
        } else if (!mask.any((v) => v != 0)) {
          out.add(RigIssue(RigIssueSeverity.warning, '"${bone.name}" owns no pixels of "$layer".', boneId: bone.id));
        }
      }
    }
    if (rig.bones.isNotEmpty) {
      for (final e in layerNames.entries) {
        if (!driven.contains(e.key)) {
          out.add(RigIssue(RigIssueSeverity.info, 'Layer "${e.value}" is not moved by any bone; it stays still.'));
        }
      }
    }

    // IK.
    final clip = rig.activeClip;
    for (final c in rig.ikChains) {
      final tip = bones[c.tipBoneId];
      if (tip == null) {
        out.add(RigIssue(RigIssueSeverity.error, 'IK chain "${c.name}" ends at a bone that is gone.', chainId: c.id));
        continue;
      }
      if (c.boneCount > rig.maxChainLength(c.tipBoneId)) {
        out.add(RigIssue(
            RigIssueSeverity.warning, 'IK chain "${c.name}" asks for more bones than "${tip.name}" has parents.',
            chainId: c.id, boneId: tip.id));
      }
      if (clip == null) continue;
      final links = rig.chainBones(c);
      if (links.isEmpty) continue;
      final reach = links.fold<double>(0, (sum, b) => sum + b.length);
      final root = links.first.head;
      // Rest-pose root: parents may move it, so only flag clear overreach.
      for (final k in clip.ikKeyframes.where((k) => k.chainId == c.id && !k.planted)) {
        if ((k.target - root).distance > reach * 1.5 + 2) {
          out.add(RigIssue(
              RigIssueSeverity.warning, '"${c.name}" is asked to reach far past its length on frame ${k.time + 1}.',
              chainId: c.id));
          break;
        }
      }
    }

    // Clips.
    for (final clip in rig.clips) {
      final lost = clip.keyframes.where((k) => !bones.containsKey(k.boneId)).length +
          clip.ikKeyframes.where((k) => !chains.containsKey(k.chainId)).length +
          clip.orderKeyframes.where((k) => !bones.containsKey(k.boneId)).length;
      if (lost > 0) {
        out.add(RigIssue(
            RigIssueSeverity.warning, 'Clip "${clip.name}" has $lost keys for bones or chains that are gone.'));
      }
      final late = clip.keyframes.where((k) => k.time >= clip.length).length +
          clip.ikKeyframes.where((k) => k.time >= clip.length).length +
          clip.orderKeyframes.where((k) => k.time >= clip.length).length;
      if (late > 0) {
        out.add(RigIssue(RigIssueSeverity.warning, 'Clip "${clip.name}" has $late keys after its last frame.'));
      }
    }

    int rank(RigIssueSeverity s) => s.index;
    final indexed = out.indexed.toList()
      ..sort((a, b) {
        final byRank = rank(a.$2.severity).compareTo(rank(b.$2.severity));
        return byRank != 0 ? byRank : math.max(0, a.$1).compareTo(b.$1);
      });
    return [for (final e in indexed) e.$2];
  }
}
