import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/data/models/rig/rig.dart';
import 'package:picell/pixel/rig/pose_interpolator.dart';

void main() {
  group('EasingCurve', () {
    test('hits both end points', () {
      final c = EasingCurve(.3, 1.4, .7, -.3);
      expect(c.transform(0), 0);
      expect(c.transform(1), 1);
    });

    test('the default control points are linear', () {
      for (final t in [.1, .25, .5, .8]) {
        expect(EasingCurve.linear.transform(t), closeTo(t, 1e-6));
      }
    });

    test('ease in is slow at the start, ease out at the end', () {
      expect(EasingCurve.easeIn.transform(.25), lessThan(.25));
      expect(EasingCurve.easeOut.transform(.25), greaterThan(.25));
      expect(EasingCurve.easeInOut.transform(.5), closeTo(.5, 1e-6));
    });

    test('is monotonic in time for a well-behaved curve', () {
      final c = EasingCurve(.2, 0, .8, 1);
      var last = -1.0;
      for (var i = 0; i <= 50; i++) {
        final v = c.transform(i / 50);
        expect(v, greaterThanOrEqualTo(last));
        last = v;
      }
    });

    test('overshoots and anticipates', () {
      expect(EasingCurve(.34, 1.56, .64, 1).transform(.5), greaterThan(1));
      expect(EasingCurve(.36, 0, .66, -.56).transform(.5), lessThan(0.5));
      expect(EasingCurve(.36, 0, .66, -.56).transform(.8), lessThan(0.8));
    });

    test('control points are clamped and JSON round trips', () {
      final c = EasingCurve(-1, 5, 2, -9);
      expect([c.x1, c.y1, c.x2, c.y2], [0, EasingCurve.maxY, 1, EasingCurve.minY]);
      final back = EasingCurve.fromJson(EasingCurve(.2, .4, .6, 1.2).toJson());
      expect(back, EasingCurve(.2, .4, .6, 1.2));
      expect(EasingCurve.fromJson([1, 2]), isNull);
      expect(EasingCurve.fromJson('x'), isNull);
    });
  });

  group('keys with curves', () {
    final curve = EasingCurve(.34, 1.56, .64, 1);

    test('keyframe JSON keeps the curve and omits it when unset', () {
      final k = RigKeyframe(time: 0, boneId: 'a', curve: curve);
      expect(RigKeyframe.fromJson(k.toJson()).curve, curve);
      expect(const RigKeyframe(time: 0, boneId: 'a').toJson().containsKey('curve'), isFalse);
      final ik = IkKeyframe(time: 0, chainId: 'c', target: Offset.zero, curve: curve);
      expect(IkKeyframe.fromJson(ik.toJson()).curve, curve);
    });

    test('copyWith can clear the curve', () {
      final k = RigKeyframe(time: 0, boneId: 'a', curve: curve);
      expect(k.copyWith(rotation: 5).curve, curve);
      expect(k.copyWith(curve: () => null).curve, isNull);
    });

    test('the interpolator uses the curve instead of the easing', () {
      const bone = Bone(id: 'a', name: 'a', head: Offset.zero, length: 4);
      final clip = RigClip(id: 'c', name: 'c', length: 8, keyframes: [
        RigKeyframe(time: 0, boneId: 'a', rotation: 0, easing: RigEasing.stepped, curve: curve),
        const RigKeyframe(time: 4, boneId: 'a', rotation: 100),
      ]);
      final mid = PoseInterpolator.sample(clip, [bone], 2)['a']!.rotation;
      expect(mid, closeTo(100 * curve.transform(.5), 1e-6));
      expect(mid, greaterThan(100), reason: 'overshoot');
    });
  });
}
