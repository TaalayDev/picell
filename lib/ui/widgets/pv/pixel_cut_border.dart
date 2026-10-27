import 'package:flutter/material.dart';

/// A rectangle whose corners are cut in pixel-art stair steps.
///
/// Use on a few hero elements only (primary buttons, FAB, banners); regular
/// cards keep the theme's rounded corners.
class PixelCutBorder extends OutlinedBorder {
  const PixelCutBorder({this.step = 2, this.steps = 3, super.side});

  /// Size of one stair step in logical pixels.
  final double step;

  /// Number of steps per corner. The corner cut is `step * steps` wide.
  final int steps;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(side.width);

  /// One corner in clockwise order, going from the left edge up to the top edge.
  List<Offset> _corner() {
    final c = step * steps;
    final pts = <Offset>[Offset(0, c)];
    for (var i = 0; i < steps; i++) {
      pts.add(Offset((i + 1) * step, c - i * step));
      pts.add(Offset((i + 1) * step, c - (i + 1) * step));
    }
    return pts;
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final tl = _corner();
    final w = rect.width, h = rect.height;
    Offset at(Offset p, double sx, double sy, double ox, double oy) =>
        Offset(rect.left + ox + sx * p.dx, rect.top + oy + sy * p.dy);

    final pts = <Offset>[
      for (final p in tl) at(p, 1, 1, 0, 0),
      for (final p in tl.reversed) at(p, -1, 1, w, 0),
      for (final p in tl) at(p, -1, -1, w, h),
      for (final p in tl.reversed) at(p, 1, -1, 0, h),
    ];
    return Path()..addPolygon(pts, true);
  }

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => getOuterPath(rect.deflate(side.width));

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.none) return;
    canvas.drawPath(getOuterPath(rect), side.toPaint());
  }

  @override
  OutlinedBorder copyWith({BorderSide? side, double? step, int? steps}) =>
      PixelCutBorder(step: step ?? this.step, steps: steps ?? this.steps, side: side ?? this.side);

  @override
  ShapeBorder scale(double t) => PixelCutBorder(step: step * t, steps: steps, side: side.scale(t));
}
