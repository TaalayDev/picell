
import 'package:flutter_test/flutter_test.dart';
import 'package:picell/pixel/rig/affine2.dart';

void main() {
  Matcher near(Offset o) => predicate<Offset>((p) => (p - o).distance < 1e-9, 'is near $o');

  test('positive rotation is clockwise on screen (y down)', () {
    // A point to the right of the origin swings down.
    expect(Affine2.rotation(90).apply(const Offset(1, 0)), near(const Offset(0, 1)));
  });

  test('rotationAbout keeps its pivot fixed', () {
    final t = Affine2.rotationAbout(90, const Offset(4, 4));
    expect(t.apply(const Offset(4, 4)), near(const Offset(4, 4)));
    expect(t.apply(const Offset(5, 4)), near(const Offset(4, 5)));
  });

  test('flipX mirrors about its axis', () {
    final t = Affine2.flipX(4);
    expect(t.apply(const Offset(5, 2)), near(const Offset(3, 2)));
    expect(t.apply(const Offset(4, 2)), near(const Offset(4, 2)));
  });

  test('then / after compose in the stated order', () {
    final move = Affine2.translation(10, 0);
    final turn = Affine2.rotation(90);
    // move first, then rotate: (1,0) -> (11,0) -> (0,11)
    expect(move.then(turn).apply(const Offset(1, 0)), near(const Offset(0, 11)));
    expect(turn.after(move).apply(const Offset(1, 0)), near(const Offset(0, 11)));
  });

  test('invert undoes the transform, and singular matrices have none', () {
    final t = Affine2.rotation(33).then(Affine2.translation(3, -2)).then(Affine2.flipX(2));
    final p = t.invert()!.apply(t.apply(const Offset(7, 5)));
    expect(p, near(const Offset(7, 5)));
    expect(const Affine2(0, 0, 0, 0, 1, 1).invert(), isNull);
  });

  test('withIntegerDisplacementAt moves the point by whole pixels only', () {
    final t = Affine2.translation(2.4, -1.6).withIntegerDisplacementAt(const Offset(3.5, 3.5));
    final moved = t.apply(const Offset(3.5, 3.5));
    expect(moved, near(const Offset(5.5, 1.5)));

    // A rotated joint stays on the grid too.
    final r = Affine2.rotationAbout(30, const Offset(8.5, 6.5)).then(Affine2.translation(0.3, 0.3));
    final p = r.withIntegerDisplacementAt(const Offset(8.5, 6.5)).apply(const Offset(8.5, 6.5));
    expect(p.dx - 8.5, closeTo((p.dx - 8.5).roundToDouble(), 1e-9));
    expect(p.dy - 6.5, closeTo((p.dy - 6.5).roundToDouble(), 1e-9));
  });

  test('applyVector ignores translation', () {
    final t = Affine2.rotation(90).thenTranslate(50, 50);
    expect(t.applyVector(const Offset(1, 0)), near(const Offset(0, 1)));
  });
}
