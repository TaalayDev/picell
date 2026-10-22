
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/data/models/rig/rig.dart';
import 'package:picell/pixel/rig/pose_interpolator.dart';
import 'package:picell/pixel/rig/rig_solver.dart';

void main() {
  Matcher near(Offset o) => predicate<Offset>((p) => (p - o).distance < 1e-9, 'is near $o');

  Rig rig(List<Bone> bones, {RigSettings settings = const RigSettings()}) =>
      Rig(id: 'r', stateId: 1, bones: bones, settings: settings);

  const shoulder = Bone(id: 'shoulder', name: 'shoulder', head: Offset(10, 10));
  const elbow = Bone(id: 'elbow', name: 'elbow', parentId: 'shoulder', head: Offset(14, 10));

  test('a bone at rest leaves points where they are', () {
    final world = RigSolver.solve(rig([shoulder, elbow]), {});
    expect(world['elbow']!.apply(const Offset(15, 10)), near(const Offset(15, 10)));
  });

  test('rotating a bone pivots about its head', () {
    final world = RigSolver.solve(rig([shoulder]), {'shoulder': const BonePose(rotation: 90)});
    expect(world['shoulder']!.apply(const Offset(10, 10)), near(const Offset(10, 10)));
    expect(world['shoulder']!.apply(const Offset(14, 10)), near(const Offset(10, 14)));
  });

  test('a child is carried by its parent and also pivots on its own head', () {
    final r = rig([shoulder, elbow]);
    final parentOnly = RigSolver.solve(r, {'shoulder': const BonePose(rotation: 90)});
    // The elbow joint swings from (14,10) to (10,14) with the shoulder.
    expect(parentOnly['elbow']!.apply(const Offset(14, 10)), near(const Offset(10, 14)));

    final both = RigSolver.solve(r, {
      'shoulder': const BonePose(rotation: 90),
      'elbow': const BonePose(rotation: -90),
    });
    // Elbow rotated back: a hand point 4 px past the elbow points along +x again.
    expect(both['elbow']!.apply(const Offset(18, 10)), near(const Offset(14, 14)));
  });

  test('translation moves a bone and its children', () {
    final world = RigSolver.solve(
      rig([shoulder, elbow]),
      {'shoulder': const BonePose(translation: Offset(3, -2))},
    );
    expect(world['elbow']!.apply(const Offset(14, 10)), near(const Offset(17, 8)));
  });

  test('flipX mirrors about the bone head', () {
    final world = RigSolver.solve(rig([shoulder]), {'shoulder': const BonePose(flipX: true)});
    expect(world['shoulder']!.apply(const Offset(13, 10)), near(const Offset(7, 10)));
  });

  test('rotation limits clamp, then snapping rounds', () {
    const limited = Bone(id: 'l', name: 'l', head: Offset.zero, minAngle: -10, maxAngle: 30);
    final clamped = RigSolver.localTransform(limited, const BonePose(rotation: 80), 0);
    expect(clamped.apply(const Offset(1, 0)), near(Affine2Helpers.unit(30)));

    const free = Bone(id: 'f', name: 'f');
    final snapped = RigSolver.localTransform(free, const BonePose(rotation: 20), 15);
    expect(snapped.apply(const Offset(1, 0)), near(Affine2Helpers.unit(15)));
    final snappedUp = RigSolver.localTransform(free, const BonePose(rotation: 23), 15);
    expect(snappedUp.apply(const Offset(1, 0)), near(Affine2Helpers.unit(30)));
  });

  test('missing or cyclic parents do not hang and act as roots', () {
    const a = Bone(id: 'a', name: 'a', parentId: 'b');
    const b = Bone(id: 'b', name: 'b', parentId: 'a');
    const orphan = Bone(id: 'o', name: 'o', parentId: 'ghost');
    final world = RigSolver.solve(rig([a, b, orphan]), {});
    expect(world.keys, containsAll(['a', 'b', 'o']));
  });
}

/// Unit vector at [degrees], clockwise on screen.
abstract final class Affine2Helpers {
  static Offset unit(double degrees) => Offset.fromDirection(degrees * 3.141592653589793 / 180);
}
