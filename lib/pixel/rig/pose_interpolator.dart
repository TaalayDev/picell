import 'dart:ui';

import '../../data/models/rig/rig.dart';

export '../../data/models/rig/bone_pose.dart';

/// Samples a [RigClip] into per-bone poses.
abstract final class PoseInterpolator {
  /// Maps linear progress [t] (0..1) through [easing].
  static double ease(RigEasing easing, double t) {
    t = t.clamp(0.0, 1.0);
    switch (easing) {
      case RigEasing.linear:
        return t;
      case RigEasing.easeIn:
        return t * t;
      case RigEasing.easeOut:
        return 1 - (1 - t) * (1 - t);
      case RigEasing.easeInOut:
        return t * t * (3 - 2 * t);
      case RigEasing.stepped:
        // Hold the previous pose until the next keyframe is reached.
        return t >= 1 ? 1 : 0;
    }
  }

  /// Poses of every bone in [bones] at frame [time] of [clip]. Fractional
  /// times are allowed (previews scrub between frames).
  ///
  /// Before a bone's first keyframe it sits at rest and eases to that key.
  /// After its last keyframe it holds, or - when the clip loops - eases back
  /// to its first keyframe at `first.time + clip.length`, so cycles close.
  static Map<String, BonePose> sample(RigClip clip, Iterable<Bone> bones, double time) {
    final byBone = <String, List<RigKeyframe>>{};
    for (final key in clip.keyframes) {
      byBone.putIfAbsent(key.boneId, () => []).add(key);
    }
    for (final keys in byBone.values) {
      keys.sort((x, y) => x.time.compareTo(y.time));
    }
    return {
      for (final bone in bones) bone.id: _sampleBone(clip, byBone[bone.id] ?? const [], time),
    };
  }

  static BonePose _sampleBone(RigClip clip, List<RigKeyframe> keys, double time) {
    if (keys.isEmpty) return BonePose.rest;

    // For a looping clip, keep time inside one period so the wrap segment
    // (last key -> first key) is reachable from both its sides.
    if (clip.loop && clip.length > 0) {
      time = time % clip.length;
      if (time < 0) time += clip.length;
    }

    final first = keys.first, last = keys.last;

    if (time < first.time) {
      if (clip.loop && clip.length > 0) {
        return _between(last, last.time - clip.length, first, first.time, time);
      }
      return _between(null, 0, first, first.time, time);
    }
    if (time >= last.time) {
      if (clip.loop && clip.length > 0) {
        return _between(last, last.time, first, first.time + clip.length, time);
      }
      return _fromKey(last);
    }

    for (var i = 0; i < keys.length - 1; i++) {
      final from = keys[i], to = keys[i + 1];
      if (time >= from.time && time < to.time) {
        return _between(from, from.time, to, to.time, time);
      }
    }
    return _fromKey(last);
  }

  /// Pose at [time] between [from] (at [fromTime]) and [to] (at [toTime]).
  /// A null [from] means the rest pose.
  static BonePose _between(RigKeyframe? from, num fromTime, RigKeyframe to, num toTime, double time) {
    final start = from == null ? BonePose.rest : _fromKey(from);
    final end = _fromKey(to);
    final span = toTime - fromTime;
    final progress = span <= 0 ? 1.0 : (time - fromTime) / span;
    final k = from?.curve?.transform(progress) ?? ease(from?.easing ?? RigEasing.linear, progress);
    return BonePose(
      rotation: start.rotation + (end.rotation - start.rotation) * k,
      translation: Offset.lerp(start.translation, end.translation, k)!,
      flipX: start.flipX,
    );
  }

  /// Where each IK chain's target is at [time], for the chains that have
  /// keys. A chain without keys is absent: it is not solved.
  ///
  /// Targets travel in straight lines between keys. Before the first key the
  /// target holds at the first; after the last it holds, or - when the clip
  /// loops - travels back to the first key at `first.time + clip.length`.
  static Map<String, Offset> sampleIk(RigClip clip, Iterable<IkChain> chains, double time) {
    final byChain = <String, List<IkKeyframe>>{};
    for (final key in clip.ikKeyframes) {
      byChain.putIfAbsent(key.chainId, () => []).add(key);
    }
    final out = <String, Offset>{};
    final sampleTime = clip.loop && clip.length > 0
        ? ((time % clip.length) + clip.length) % clip.length
        : time.clamp(0.0, (clip.length - 1).toDouble());
    for (final chain in chains) {
      final all = byChain[chain.id];
      if (all == null || all.isEmpty) continue;
      final contacts = all.where((key) => key.planted && key.time == sampleTime.floor());
      if (contacts.isNotEmpty) {
        out[chain.id] = contacts.last.target;
        continue;
      }
      final keys = all.where((key) => !key.planted).toList();
      if (keys.isEmpty) continue;
      keys.sort((a, b) => a.time.compareTo(b.time));
      out[chain.id] = _sampleTarget(clip, keys, time);
    }
    return out;
  }

  /// How many layers each bone's artwork is moved in the stacking order at
  /// [time]; bones at their normal place are absent. Steps, never blends: a
  /// bone keeps its last key's offset until its next key, and sits at its
  /// normal place before its first key (also when the clip loops, so a
  /// single key can never leak into the start of the next round).
  static Map<String, int> sampleOrder(RigClip clip, double time) {
    if (clip.orderKeyframes.isEmpty) return const {};
    final best = <String, DrawOrderKeyframe>{};
    for (final k in clip.orderKeyframes) {
      if (k.time > time) continue;
      final current = best[k.boneId];
      if (current == null || k.time >= current.time) best[k.boneId] = k;
    }
    return {
      for (final e in best.entries)
        if (e.value.offset != 0) e.key: e.value.offset,
    };
  }

  static Offset _sampleTarget(RigClip clip, List<IkKeyframe> keys, double time) {
    final loops = clip.loop && clip.length > 0;
    if (loops) {
      time = time % clip.length;
      if (time < 0) time += clip.length;
    }
    final first = keys.first, last = keys.last;

    Offset between(IkKeyframe from, num fromTime, IkKeyframe to, num toTime) {
      final span = toTime - fromTime;
      final progress = span <= 0 ? 1.0 : (time - fromTime) / span;
      return Offset.lerp(from.target, to.target, from.curve?.transform(progress) ?? ease(from.easing, progress))!;
    }

    if (time < first.time) {
      return loops ? between(last, last.time - clip.length, first, first.time) : first.target;
    }
    if (time >= last.time) {
      return loops ? between(last, last.time, first, first.time + clip.length) : last.target;
    }
    for (var i = 0; i < keys.length - 1; i++) {
      if (time >= keys[i].time && time < keys[i + 1].time) {
        return between(keys[i], keys[i].time, keys[i + 1], keys[i + 1].time);
      }
    }
    return last.target;
  }

  static BonePose _fromKey(RigKeyframe k) => BonePose(rotation: k.rotation, translation: k.translation, flipX: k.flipX);
}
