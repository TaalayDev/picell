part of 'tileset_generator_screen.dart';

/// Reads the active app theme without replacing its component styles or fonts.
class _Tg {
  _Tg(this.theme);
  factory _Tg.of(BuildContext context) => _Tg(Theme.of(context));
  static const primaryMasks = [255, 110, 155, 55, 205, 38, 76, 19, 137, 127, 239, 191, 223, 2, 8, 4, 1, 0, 10, 5];
  final ThemeData theme;
  PvTokens? get tokens => theme.extension<PvTokens>();
  Color get background => tokens?.background ?? theme.scaffoldBackgroundColor;
  Color get panel => tokens?.surface ?? theme.colorScheme.surface;
  Color get elevated => tokens?.surfaceHigh ?? theme.colorScheme.surfaceContainerHighest;
  Color get canvas => background;
  Color get border => tokens?.divider ?? theme.dividerColor;
  Color get strongBorder => border;
  Color get text => tokens?.textPrimary ?? theme.colorScheme.onSurface;
  Color get muted => tokens?.textSecondary ?? theme.colorScheme.onSurfaceVariant;
  Color get accent => tokens?.primary ?? theme.colorScheme.primary;
  Color get highlight => tokens?.accent ?? theme.colorScheme.secondary;
  Color get ink => tokens?.ink ?? theme.colorScheme.onPrimary;
  Color get tint => Color.alphaBlend(accent.withValues(alpha: 0.15), panel);
  Color get green => tokens?.ok ?? theme.colorScheme.tertiary;
  Color get amber => tokens?.warn ?? theme.colorScheme.secondary;
  Color get checkerA => tokens?.checkerA ?? theme.colorScheme.surfaceContainer;
  Color get checkerB => tokens?.checkerB ?? theme.colorScheme.surfaceContainerHighest;
  double get cardRadius => tokens?.cardRadius ?? 12;
  double get buttonRadius => tokens?.buttonRadius ?? 8;
  double get chipRadius => tokens?.chipRadius ?? 8;
  Color get shadowColor =>
      tokens?.shadowColor ?? theme.cardTheme.shadowColor ?? theme.shadowColor.withValues(alpha: 0.15);
  double get shadowBlur => 4 + (tokens?.cardElevation ?? theme.cardTheme.elevation ?? 0) * 3;

  /// Silkscreen-style label for short titles, tabs and badges.
  TextStyle pixel(double size, {Color? color}) =>
      tokens?.pixelLabel(size: size, color: color ?? text) ??
      TextStyle(fontSize: size, fontWeight: FontWeight.w700, letterSpacing: 1, color: color ?? text);

  /// Monospace numerals for sizes, seeds and values.
  TextStyle monoAt(double size, {Color? color, FontWeight weight = FontWeight.w500}) =>
      tokens?.mono(size: size, color: color ?? text, weight: weight) ??
      TextStyle(fontSize: size, fontWeight: weight, fontFamily: 'monospace', color: color ?? text);

  TextStyle get mono => (theme.textTheme.bodySmall ?? const TextStyle()).copyWith(fontSize: 11, color: muted);
}

class _TgLabel extends StatelessWidget {
  const _TgLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(text,
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.8, color: _Tg.of(context).muted));
}

class _TgIconButton extends StatelessWidget {
  const _TgIconButton({required this.label, required this.icon, this.onPressed, this.selected = false, this.size = 32});
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool selected;
  final double size;
  @override
  Widget build(BuildContext context) => IconButton(
      tooltip: label,
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      style: IconButton.styleFrom(
          minimumSize: Size.square(size),
          maximumSize: Size.square(size),
          padding: EdgeInsets.zero,
          foregroundColor: selected ? _Tg.of(context).ink : _Tg.of(context).muted,
          backgroundColor: selected ? _Tg.of(context).accent : Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_Tg.of(context).buttonRadius))));
}

class _TgChecker extends CustomPainter {
  const _TgChecker(this.a, this.b);
  final Color a, b;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = a);
    final paint = Paint()..color = b;
    for (var y = 0.0; y < size.height; y += 8) {
      for (var x = 0.0; x < size.width; x += 8) {
        if ((x ~/ 8 + y ~/ 8).isEven) canvas.drawRect(Rect.fromLTWH(x, y, 8, 8), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TgChecker oldDelegate) => oldDelegate.a != a || oldDelegate.b != b;
}

class _TgPixelFrame extends StatelessWidget {
  const _TgPixelFrame({this.image, this.padding = 8});
  final ui.Image? image;
  final double padding;
  @override
  Widget build(BuildContext context) => ClipRRect(
      borderRadius: BorderRadius.circular(_Tg.of(context).buttonRadius),
      child: CustomPaint(
          painter: _TgChecker(_Tg.of(context).checkerA, _Tg.of(context).checkerB),
          child: Padding(
              padding: EdgeInsets.all(padding),
              child: RawImage(image: image, fit: BoxFit.contain, filterQuality: FilterQuality.none))));
}

class _TgPerspectiveArt extends CustomPainter {
  const _TgPerspectiveArt(this.perspective);
  final TilesetPerspective perspective;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24, size.height / 16);
    final paint = Paint();
    void rect(int color, double x, double y, double width, double height) {
      paint.color = Color(color);
      canvas.drawRect(Rect.fromLTWH(x, y, width, height), paint);
    }

    void polygon(int color, List<Offset> points) {
      paint.color = Color(color);
      final path = Path()..addPolygon(points, true);
      canvas.drawPath(path, paint);
    }

    if (perspective == TilesetPerspective.side) {
      rect(0xff7ec4f0, 0, 0, 24, 16);
      rect(0xffb9e2fa, 0, 9, 24, 7);
      rect(0xffffffff, 3, 2, 5, 1);
      rect(0xffffffff, 4, 1, 3, 1);
      rect(0xffffffff, 17, 4, 4, 1);
      rect(0xff1c1420, 3, 8, 14, 1);
      rect(0xffb8f060, 3, 9, 14, 1);
      rect(0xff5cc04a, 3, 10, 14, 1);
      rect(0xff80482f, 3, 11, 14, 3);
      rect(0xffa8693f, 5, 12, 2, 1);
      rect(0xffa8693f, 11, 11, 2, 1);
      rect(0xff5a3224, 3, 14, 14, 1);
      rect(0xff1c1420, 18, 11, 5, 1);
      rect(0xffb8f060, 18, 12, 5, 1);
      rect(0xff80482f, 18, 13, 5, 2);
    } else if (perspective == TilesetPerspective.topDown) {
      rect(0xff4fae4a, 0, 0, 24, 16);
      for (var x = 0; x < 24; x++) {
        for (var y = 0; y < 16; y++) {
          if ((x * 7 + y * 13) % 11 == 0) rect(0xff3d9440, x.toDouble(), y.toDouble(), 1, 1);
        }
      }
      rect(0xffe0c088, 9, 0, 4, 16);
      rect(0xffe0c088, 13, 6, 8, 4);
      rect(0xffc89c62, 9, 0, 1, 16);
      rect(0xff3f8fd8, 0, 10, 7, 6);
      rect(0xff8cc8f6, 1, 11, 3, 1);
      rect(0xff2f7a35, 18, 1, 4, 4);
      rect(0xff5cc04a, 19, 1, 2, 2);
    } else {
      rect(0xffd9ecf8, 0, 0, 24, 16);
      polygon(0xff7ad050, const [Offset(12, 1), Offset(20, 5), Offset(12, 9), Offset(4, 5)]);
      polygon(0xffa8693f, const [Offset(4, 5), Offset(12, 9), Offset(12, 15), Offset(4, 11)]);
      polygon(0xff6e3d28, const [Offset(12, 9), Offset(20, 5), Offset(20, 11), Offset(12, 15)]);
      rect(0xffb8f060, 10, 2, 4, 1);
      rect(0xff1c1420, 12, 9, 1, 6);
    }
  }

  @override
  bool shouldRepaint(covariant _TgPerspectiveArt oldDelegate) => oldDelegate.perspective != perspective;
}

class _TgLogo extends CustomPainter {
  const _TgLogo(this.primary, this.highlight);
  final Color primary, highlight;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 12, size.height / 12);
    final paint = Paint();
    void r(int c, double x, double y, double w, double h) {
      paint.color = Color(c);
      canvas.drawRect(Rect.fromLTWH(x, y, w, h), paint);
    }

    r(primary.toARGB32(), 0, 0, 12, 12);
    r(highlight.toARGB32(), 0, 0, 12, 1);
    r(highlight.toARGB32(), 0, 0, 1, 12);
    r(0xff5cc04a, 2, 7, 8, 1);
    r(0xffb8f060, 2, 6, 4, 1);
    r(0xff80482f, 2, 8, 8, 2);
    r(0xffffffff, 7, 3, 2, 2);
  }

  @override
  bool shouldRepaint(covariant _TgLogo oldDelegate) =>
      oldDelegate.primary != primary || oldDelegate.highlight != highlight;
}

class _TgEmptyArt extends CustomPainter {
  const _TgEmptyArt(this.edge, this.fill, this.background);
  final Color edge, fill, background;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 60, size.height / 30);
    final paint = Paint();
    void r(int c, double x, double y, double w, double h) {
      paint.color = Color(c);
      canvas.drawRect(Rect.fromLTWH(x, y, w, h), paint);
    }

    for (final p in [(6.0, 14.0, 12.0), (26.0, 8.0, 8.0), (46.0, 18.0, 10.0)]) {
      r(edge.toARGB32(), p.$1, p.$2, p.$3, 1);
      r(fill.toARGB32(), p.$1, p.$2 + 1, p.$3, 4);
    }
    r(edge.toARGB32(), 0, 22, 60, 1);
    r(fill.toARGB32(), 0, 23, 60, 7);
    r(background.toARGB32(), 22, 22, 10, 8);
  }

  @override
  bool shouldRepaint(covariant _TgEmptyArt oldDelegate) =>
      oldDelegate.edge != edge || oldDelegate.fill != fill || oldDelegate.background != background;
}
