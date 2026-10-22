
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/data/models/rig/rig.dart';
import 'package:picell/pixel/rig/pose_interpolator.dart';

void main() {
  const bone = Bone(id: 'b', name: 'b');
  double rot(RigClip clip, double t) => PoseInterpolator.sample(clip, [bone], t)['b']!.rotation;

  RigClip clip(List<RigKeyframe> keys, {bool loop = false, int length = 8}) =>
      RigClip(id: 'c', name: 'c', length: length, loop: loop, keyframes: keys);

  test('easing curves hit their endpoints and differ in the middle', () {
    for (final e in RigEasing.values) {
      expect(PoseInterpolator.ease(e, 0), 0, reason: '$e');
      expect(PoseInterpolator.ease(e, 1), 1, reason: '$e');
    }
    expect(PoseInterpolator.ease(RigEasing.linear, 0.5), 0.5);
    expect(PoseInterpolator.ease(RigEasing.easeIn, 0.5), lessThan(0.5));
    expect(PoseInterpolator.ease(RigEasing.easeOut, 0.5), greaterThan(0.5));
    expect(PoseInterpolator.ease(RigEasing.easeInOut, 0.5), closeTo(0.5, 1e-12));
    expect(PoseInterpolator.ease(RigEasing.stepped, 0.99), 0);
    expect(PoseInterpolator.ease(RigEasing.linear, 2), 1, reason: 'clamped');
  });

  test('bones without keyframes stay at rest', () {
    final poses = PoseInterpolator.sample(clip(const []), [bone], 3);
    expect(poses['b'], BonePose.rest);
  });

  test('interpolates between keys, holds after the last when not looping', () {
    final c = clip(const [
      RigKeyframe(time: 2, boneId: 'b', rotation: 10),
      RigKeyframe(time: 6, boneId: 'b', rotation: 50),
    ]);
    expect(rot(c, 2), 10);
    expect(rot(c, 4), 30);
    expect(rot(c, 6), 50);
    expect(rot(c, 7.5), 50);
  });

  test('before the first key the bone eases in from rest', () {
    final c = clip(const [RigKeyframe(time: 4, boneId: 'b', rotation: 40)]);
    expect(rot(c, 0), 0);
    expect(rot(c, 2), 20);
  });

  test('stepped easing holds the previous pose until the next key', () {
    final c = clip(const [
      RigKeyframe(time: 0, boneId: 'b', rotation: 0, easing: RigEasing.stepped),
      RigKeyframe(time: 4, boneId: 'b', rotation: 40),
    ]);
    expect(rot(c, 3.9), 0);
    expect(rot(c, 4), 40);
  });

  test('a looping clip closes the cycle back to its first key', () {
    final c = clip(const [
      RigKeyframe(time: 0, boneId: 'b', rotation: 0),
      RigKeyframe(time: 4, boneId: 'b', rotation: 40),
    ], loop: true);
    // 4 -> 8 returns to 0 over the wrap segment.
    expect(rot(c, 6), 20);
    expect(rot(c, 8), 0, reason: 'time wraps to the start');
    expect(rot(c, 10), rot(c, 2));
  });

  test('translation interpolates and flip follows the previous key', () {
    final c = clip(const [
      RigKeyframe(time: 0, boneId: 'b', translation: Offset(0, 0)),
      RigKeyframe(time: 4, boneId: 'b', translation: Offset(8, -4), flipX: true),
    ]);
    final mid = PoseInterpolator.sample(c, [bone], 2)['b']!;
    expect(mid.translation, const Offset(4, -2));
    expect(mid.flipX, isFalse);
    expect(PoseInterpolator.sample(c, [bone], 4)['b']!.flipX, isTrue);
  });

  test('unsorted keyframes are handled', () {
    final c = clip(const [
      RigKeyframe(time: 6, boneId: 'b', rotation: 50),
      RigKeyframe(time: 2, boneId: 'b', rotation: 10),
    ]);
    expect(rot(c, 4), 30);
  });
}
