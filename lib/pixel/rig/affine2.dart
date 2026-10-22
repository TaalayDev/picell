import 'dart:math' as math;
import 'dart:ui';

/// A 2D affine transform in screen space (x right, y down):
///
///     x' = a*x + c*y + tx
///     y' = b*x + d*y + ty
///
/// Positive rotation angles are clockwise on screen.
class Affine2 {
  final double a, b, c, d, tx, ty;

  const Affine2(this.a, this.b, this.c, this.d, this.tx, this.ty);

  static const identity = Affine2(1, 0, 0, 1, 0, 0);

  factory Affine2.translation(double dx, double dy) => Affine2(1, 0, 0, 1, dx, dy);

  factory Affine2.rotation(double degrees) {
    final r = degrees * math.pi / 180;
    final cos = math.cos(r), sin = math.sin(r);
    return Affine2(cos, sin, -sin, cos, 0, 0);
  }

  /// Mirrors horizontally about the vertical line `x = pivotX`.
  factory Affine2.flipX(double pivotX) => Affine2(-1, 0, 0, 1, 2 * pivotX, 0);

  /// Rotation by [degrees] about [pivot].
  factory Affine2.rotationAbout(double degrees, Offset pivot) =>
      Affine2.translation(-pivot.dx, -pivot.dy).then(Affine2.rotation(degrees)).thenTranslate(pivot.dx, pivot.dy);

  /// `this` applied after [first]: `(this ∘ first)(p) = this(first(p))`.
  Affine2 after(Affine2 first) => Affine2(
        a * first.a + c * first.b,
        b * first.a + d * first.b,
        a * first.c + c * first.d,
        b * first.c + d * first.d,
        a * first.tx + c * first.ty + tx,
        b * first.tx + d * first.ty + ty,
      );

  /// [next] applied after `this`: `next ∘ this`.
  Affine2 then(Affine2 next) => next.after(this);

  Affine2 thenTranslate(double dx, double dy) => Affine2(a, b, c, d, tx + dx, ty + dy);

  Offset apply(Offset p) => Offset(a * p.dx + c * p.dy + tx, b * p.dx + d * p.dy + ty);

  /// [v] transformed without the translation (for directions and deltas).
  Offset applyVector(Offset v) => Offset(a * v.dx + c * v.dy, b * v.dx + d * v.dy);

  double get determinant => a * d - b * c;

  /// Null when the transform collapses an axis and cannot be inverted.
  Affine2? invert() {
    final det = determinant;
    if (det.abs() < 1e-12) return null;
    final ia = d / det, ib = -b / det, ic = -c / det, id = a / det;
    return Affine2(ia, ib, ic, id, -(ia * tx + ic * ty), -(ib * tx + id * ty));
  }

  /// This transform with its translation nudged so that [point] moves by a
  /// whole number of pixels. Keeps a part's joint on the pixel grid, which is
  /// what makes posed pixel art look deliberate instead of jittery.
  Affine2 withIntegerDisplacementAt(Offset point) {
    final moved = apply(point);
    final dx = moved.dx - point.dx, dy = moved.dy - point.dy;
    return thenTranslate(dx.roundToDouble() - dx, dy.roundToDouble() - dy);
  }

  /// Stable text key for caches; values are rounded so float noise from
  /// equivalent poses still hits the same entry.
  String get cacheKey => [a, b, c, d, tx, ty].map((v) => (v * 1e5).round()).join(',');

  @override
  bool operator ==(Object other) =>
      other is Affine2 &&
      other.a == a &&
      other.b == b &&
      other.c == c &&
      other.d == d &&
      other.tx == tx &&
      other.ty == ty;

  @override
  int get hashCode => Object.hash(a, b, c, d, tx, ty);

  @override
  String toString() => 'Affine2($a, $b, $c, $d, $tx, $ty)';
}
