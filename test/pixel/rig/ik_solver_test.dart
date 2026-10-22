import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:picell/data/models/rig/rig.dart';
import 'package:picell/pixel/rig/pose_interpolator.dart';
import 'package:picell/pixel/rig/rig_solver.dart';

void main() {
  // An arm lying along +x: upper arm (4 px) from the shoulder, forearm (4 px)
  // from the elbow. The hand is the forearm's tail, at (12.5, 8.5) at rest.
  const shoulder = Bone(id: 'upper', name: 'upper', head: Offset(4.5, 8.5), length: 4);
  const elbow = Bone(id: 'fore', name: 'fore', parentId: 'upper', head: Offset(8.5, 8.5), length: 4);
  const chain = IkChain(id: 'ik', tipBoneId: 'fore', boneCount: 2);

  Rig rig({List<Bone>? bones, IkChain c = chain}) =>
      Rig(id: 'r', stateId: 1, bones: bones ?? const [shoulder, elbow], ikChains: [c]);

  Offset hand(SolvedRig s) => s.world['fore']!.apply(elbow.tail);
  Offset elbowAt(SolvedRig s) => s.world['fore']!.apply(elbow.head);
  Offset shoulderAt(SolvedRig s) => s.world['upper']!.apply(shoulder.head);

  SolvedRig solve(Offset target, {Rig? r, Map<String, BonePose> poses = const {}}) =>
      RigSolver.solveIk(r ?? rig(), poses, {'ik': target});

  test('without a target nothing is solved: plain forward kinematics', () {
    final s = RigSolver.solveIk(rig(), const {'upper': BonePose(rotation: 90)}, const {});
    expect(s.poses['upper']!.rotation, 90);
    expect(s.poses['fore']?.rotation ?? 0, 0);
  });

  test('a reachable target is reached', () {
    for (final target in const [Offset(8.5, 4.5), Offset(6.5, 12.5), Offset(11.5, 6.5), Offset(5.5, 5.5)]) {
      final s = solve(target);
      expect((hand(s) - target).distance, lessThan(0.06), reason: 'target $target');
    }
  });

  test('the root of the chain stays where it is', () {
    final s = solve(const Offset(8.5, 4.5));
    expect(shoulderAt(s), const Offset(4.5, 8.5));
  });

  test('bones keep their lengths, so the elbow is where both bones can meet', () {
    final s = solve(const Offset(8.5, 4.5));
    expect((elbowAt(s) - shoulderAt(s)).distance, closeTo(4, 1e-6));
    expect((hand(s) - elbowAt(s)).distance, closeTo(4, 1e-6));
  });

  test('bend picks which of the two mirror solutions the elbow takes', () {
    const target = Offset(8.5, 4.5);
    final a = solve(target, r: rig(c: chain.copyWith(bend: 1)));
    final b = solve(target, r: rig(c: chain.copyWith(bend: -1)));
    expect((hand(a) - target).distance, lessThan(0.06));
    expect((hand(b) - target).distance, lessThan(0.06));

    // The shoulder-to-target line; the elbows lie on opposite sides of it.
    final line = target - const Offset(4.5, 8.5);
    double side(Offset p) => line.dx * (p.dy - 8.5) - line.dy * (p.dx - 4.5);
    expect(side(elbowAt(a)).sign, isNot(side(elbowAt(b)).sign));
    expect(side(elbowAt(a)).abs(), greaterThan(1));
  });

  test('a target beyond reach leaves the chain straight and pointing at it', () {
    final s = solve(const Offset(4.5, 28.5)); // 20 px straight down, reach is 8
    expect(hand(s).dx, closeTo(4.5, 0.05));
    expect(hand(s).dy, closeTo(16.5, 0.05));
    expect(elbowAt(s).dx, closeTo(4.5, 0.05));
  });

  test('a target inside the minimum reach folds the chain without breaking', () {
    final s = solve(const Offset(5.5, 8.5)); // one pixel from the shoulder
    expect((hand(s) - const Offset(5.5, 8.5)).distance, lessThan(0.1));
  });

  test('rotation limits are respected, even when the target is then missed', () {
    const limited = Bone(
      id: 'fore',
      name: 'fore',
      parentId: 'upper',
      head: Offset(8.5, 8.5),
      length: 4,
      minAngle: -10,
      maxAngle: 10,
    );
    final s = solve(const Offset(8.5, 4.5), r: rig(bones: const [shoulder, limited]));
    expect(s.poses['fore']!.rotation, inInclusiveRange(-10, 10));
  });

  test('a one-bone chain just aims the bone at the target', () {
    final r = rig(c: const IkChain(id: 'ik', tipBoneId: 'upper', boneCount: 1));
    final s = solve(const Offset(4.5, 14.5), r: r); // straight down from the shoulder
    expect(s.world['upper']!.apply(shoulder.tail).dy, closeTo(12.5, 0.1), reason: 'pointing down, length 4');
    expect(s.world['upper']!.apply(shoulder.tail).dx, closeTo(4.5, 0.1));
  });

  test('when the parent of the chain moves, the hand still reaches the same world target', () {
    const hip = Bone(id: 'hip', name: 'hip', head: Offset(2.5, 8.5), length: 2);
    const upper = Bone(id: 'upper', name: 'upper', parentId: 'hip', head: Offset(4.5, 8.5), length: 4);
    const fore = Bone(id: 'fore', name: 'fore', parentId: 'upper', head: Offset(8.5, 8.5), length: 4);
    final r = rig(bones: const [hip, upper, fore]);
    final s = RigSolver.solveIk(r, const {'hip': BonePose(rotation: 40)}, const {'ik': Offset(9.5, 5.5)});
    expect((s.world['fore']!.apply(fore.tail) - const Offset(9.5, 5.5)).distance, lessThan(0.1));
  });

  test('a mirrored parent does not send the chain the wrong way', () {
    const hip = Bone(id: 'hip', name: 'hip', head: Offset(8.5, 8.5), length: 2);
    const upper = Bone(id: 'upper', name: 'upper', parentId: 'hip', head: Offset(8.5, 8.5), length: 4);
    const fore = Bone(id: 'fore', name: 'fore', parentId: 'upper', head: Offset(12.5, 8.5), length: 4);
    final r = rig(bones: const [hip, upper, fore]);
    final s = RigSolver.solveIk(r, const {'hip': BonePose(flipX: true)}, const {'ik': Offset(5.5, 5.5)});
    expect((s.world['fore']!.apply(fore.tail) - const Offset(5.5, 5.5)).distance, lessThan(0.1));
  });

  test('a three-bone chain is searched for and reaches targets within its reach', () {
    const a = Bone(id: 'a', name: 'a', head: Offset(2.5, 8.5), length: 3);
    const b = Bone(id: 'b', name: 'b', parentId: 'a', head: Offset(5.5, 8.5), length: 3);
    const c = Bone(id: 'c', name: 'c', parentId: 'b', head: Offset(8.5, 8.5), length: 3);
    final r = rig(bones: const [a, b, c], c: const IkChain(id: 'ik', tipBoneId: 'c', boneCount: 3));
    for (final target in const [Offset(8.5, 4.5), Offset(6.5, 12.5), Offset(9.5, 9.5), Offset(4.5, 5.5)]) {
      final s = RigSolver.solveIk(r, const {}, {'ik': target});
      expect((s.world['c']!.apply(c.tail) - target).distance, lessThan(0.15), reason: 'target $target');
    }
  });

  test('a three-bone chain respects limits and stays straight when out of reach', () {
    const a = Bone(id: 'a', name: 'a', head: Offset(2.5, 8.5), length: 3);
    const b = Bone(id: 'b', name: 'b', parentId: 'a', head: Offset(5.5, 8.5), length: 3, minAngle: 0, maxAngle: 20);
    const c = Bone(id: 'c', name: 'c', parentId: 'b', head: Offset(8.5, 8.5), length: 3);
    final r = rig(bones: const [a, b, c], c: const IkChain(id: 'ik', tipBoneId: 'c', boneCount: 3));
    final s = RigSolver.solveIk(r, const {}, const {'ik': Offset(2.5, 28.5)});
    expect(s.poses['b']!.rotation, inInclusiveRange(0, 20));
  });

  test('a chain whose tip is gone, or that has no bones, is skipped', () {
    final r = rig(c: const IkChain(id: 'ik', tipBoneId: 'ghost'));
    final s = RigSolver.solveIk(r, const {}, const {'ik': Offset(1, 1)});
    expect(s.poses, isEmpty);
  });

  test('translation of a chain bone is kept and the target is still reached', () {
    final s = solve(
      const Offset(8.5, 4.5),
      poses: const {'upper': BonePose(translation: Offset(1, 0))},
    );
    expect(s.poses['upper']!.translation, const Offset(1, 0));
    expect((hand(s) - const Offset(8.5, 4.5)).distance, lessThan(0.06));
  });

  test('two chains are solved one after the other', () {
    const l = IkChain(id: 'l', tipBoneId: 'fore');
    const bones = [
      shoulder,
      elbow,
      Bone(id: 'upper2', name: 'upper2', head: Offset(4.5, 12.5), length: 4),
      Bone(id: 'fore2', name: 'fore2', parentId: 'upper2', head: Offset(8.5, 12.5), length: 4),
    ];
    final r = Rig(id: 'r', stateId: 1, bones: bones, ikChains: const [l, IkChain(id: 'r', tipBoneId: 'fore2')]);
    final s = RigSolver.solveIk(r, const {}, const {'l': Offset(8.5, 4.5), 'r': Offset(8.5, 16.5)});
    expect((s.world['fore']!.apply(const Offset(12.5, 8.5)) - const Offset(8.5, 4.5)).distance, lessThan(0.06));
    expect((s.world['fore2']!.apply(const Offset(12.5, 12.5)) - const Offset(8.5, 16.5)).distance, lessThan(0.06));
  });

  group('sampling targets over time', () {
    const clip = RigClip(id: 'c', name: 'c', length: 8, loop: false, ikKeyframes: [
      IkKeyframe(time: 2, chainId: 'ik', target: Offset(0, 0)),
      IkKeyframe(time: 6, chainId: 'ik', target: Offset(8, 4)),
    ]);

    Offset? at(RigClip c, double t) => PoseInterpolator.sampleIk(c, const [chain], t)['ik'];

    test('holds before the first key and after the last, travels in a line between', () {
      expect(at(clip, 0), const Offset(0, 0));
      expect(at(clip, 4), const Offset(4, 2));
      expect(at(clip, 7), const Offset(8, 4));
    });

    test('a chain without keys is not solved', () {
      expect(PoseInterpolator.sampleIk(const RigClip(id: 'c', name: 'c'), const [chain], 3), isEmpty);
    });

    test('a looping clip travels from the last key back to the first', () {
      final looping = clip.copyWith(loop: true);
      // 6 -> 10 (= 2 + 8): halfway is frame 8, which wraps to 0.
      expect(at(looping, 0), const Offset(4, 2));
      expect(at(looping, 8), at(looping, 0), reason: 'time wraps');
    });

    test('easing is applied', () {
      final eased = clip.copyWith(ikKeyframes: const [
        IkKeyframe(time: 2, chainId: 'ik', target: Offset(0, 0), easing: RigEasing.stepped),
        IkKeyframe(time: 6, chainId: 'ik', target: Offset(8, 4)),
      ]);
      expect(at(eased, 5), const Offset(0, 0));
      expect(at(eased, 6), const Offset(8, 4));
    });

    test('a single key is a constant target', () {
      final one = clip.copyWith(
        loop: true,
        ikKeyframes: const [IkKeyframe(time: 3, chainId: 'ik', target: Offset(2, 2))],
      );
      for (final t in [0.0, 3.0, 5.5]) {
        expect(at(one, t), const Offset(2, 2));
      }
    });
  });

  test('rotations are what the solver decides: a full circle of targets never fails', () {
    for (var deg = 0; deg < 360; deg += 15) {
      const r = 3.0; // every point stays within reach of the shoulder (1 to 7 px away)
      final target = Offset(8.5 + r * math.cos(deg * math.pi / 180), 8.5 + r * math.sin(deg * math.pi / 180));
      final s = solve(target);
      expect((hand(s) - target).distance, lessThan(0.1), reason: 'at $deg degrees');
    }
  });
}
