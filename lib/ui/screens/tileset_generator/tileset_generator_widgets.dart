part of 'tileset_generator_screen.dart';

abstract final class _Tg {
  static const primaryMasks = [255, 110, 155, 55, 205, 38, 76, 19, 137, 127, 239, 191, 223, 2, 8, 4, 1, 0, 10, 5];
  static const background = Color(0xff141518);
  static const panel = Color(0xff1a1b1f);
  static const elevated = Color(0xff202228);
  static const canvas = Color(0xff101114);
  static const border = Color(0xff2b2e36);
  static const strongBorder = Color(0xff3a3e4a);
  static const text = Color(0xffe7e9ef);
  static const muted = Color(0xff9096a4);
  static const accent = Color(0xff8b6cf0);
  static const highlight = Color(0xffa58cff);
  static const tint = Color(0x268b6cf0);
  static const green = Color(0xff5fd38d);
  static const amber = Color(0xfff0c870);
  static const mono = TextStyle(fontFamily: 'monospace', fontSize: 11, color: muted);
  static ThemeData theme() => ThemeData(
        useMaterial3: true,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: background,
        fontFamily: 'Inter',
        colorScheme: const ColorScheme.dark(
            primary: accent,
            onPrimary: Colors.white,
            secondary: highlight,
            surface: panel,
            onSurface: text,
            outline: strongBorder),
        visualDensity: VisualDensity.compact,
        textTheme: const TextTheme(
            bodyMedium: TextStyle(fontSize: 13, color: text),
            bodySmall: TextStyle(fontSize: 11, color: muted),
            labelLarge: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        dividerTheme: const DividerThemeData(color: border, thickness: 1, space: 1),
        inputDecorationTheme: InputDecorationTheme(
            isDense: true,
            filled: true,
            fillColor: background,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: border)),
            enabledBorder:
                OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: border)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: accent))),
        outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
                foregroundColor: text,
                side: const BorderSide(color: strongBorder),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                minimumSize: const Size(0, 34))),
        filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                minimumSize: const Size(0, 34))),
        chipTheme: ChipThemeData(
            backgroundColor: background,
            selectedColor: tint,
            showCheckmark: true,
            checkmarkColor: highlight,
            side: const BorderSide(color: border),
            padding: const EdgeInsets.symmetric(horizontal: 6),
            labelPadding: const EdgeInsets.symmetric(horizontal: 4),
            labelStyle: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
        sliderTheme: const SliderThemeData(
            trackHeight: 3,
            thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: RoundSliderOverlayShape(overlayRadius: 12)),
        popupMenuTheme: PopupMenuThemeData(
            color: elevated,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10), side: const BorderSide(color: strongBorder))),
      );
}

class _TgLabel extends StatelessWidget {
  const _TgLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.8, color: _Tg.muted));
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
          foregroundColor: selected ? Colors.white : _Tg.muted,
          backgroundColor: selected ? _Tg.accent : Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7))));
}

class _TgChecker extends CustomPainter {
  const _TgChecker();
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xff23252c));
    final paint = Paint()..color = const Color(0xff2c2f37);
    for (var y = 0.0; y < size.height; y += 8) {
      for (var x = 0.0; x < size.width; x += 8) {
        if ((x ~/ 8 + y ~/ 8).isEven) canvas.drawRect(Rect.fromLTWH(x, y, 8, 8), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TgChecker oldDelegate) => false;
}

class _TgPixelFrame extends StatelessWidget {
  const _TgPixelFrame({this.image, this.padding = 8});
  final ui.Image? image;
  final double padding;
  @override
  Widget build(BuildContext context) => ClipRRect(
      borderRadius: BorderRadius.circular(7),
      child: CustomPaint(
          painter: const _TgChecker(),
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
  const _TgLogo();
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 12, size.height / 12);
    final paint = Paint();
    void r(int c, double x, double y, double w, double h) {
      paint.color = Color(c);
      canvas.drawRect(Rect.fromLTWH(x, y, w, h), paint);
    }

    r(0xff8b6cf0, 0, 0, 12, 12);
    r(0xffa58cff, 0, 0, 12, 1);
    r(0xffa58cff, 0, 0, 1, 12);
    r(0xff5cc04a, 2, 7, 8, 1);
    r(0xffb8f060, 2, 6, 4, 1);
    r(0xff80482f, 2, 8, 8, 2);
    r(0xffffffff, 7, 3, 2, 2);
  }

  @override
  bool shouldRepaint(covariant _TgLogo oldDelegate) => false;
}

class _TgEmptyArt extends CustomPainter {
  const _TgEmptyArt();
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 60, size.height / 30);
    final paint = Paint();
    void r(int c, double x, double y, double w, double h) {
      paint.color = Color(c);
      canvas.drawRect(Rect.fromLTWH(x, y, w, h), paint);
    }

    for (final p in [(6.0, 14.0, 12.0), (26.0, 8.0, 8.0), (46.0, 18.0, 10.0)]) {
      r(0xff3a3e4a, p.$1, p.$2, p.$3, 1);
      r(0xff2c2f37, p.$1, p.$2 + 1, p.$3, 4);
    }
    r(0xff3a3e4a, 0, 22, 60, 1);
    r(0xff2c2f37, 0, 23, 60, 7);
    r(0xff141518, 22, 22, 10, 8);
  }

  @override
  bool shouldRepaint(covariant _TgEmptyArt oldDelegate) => false;
}
