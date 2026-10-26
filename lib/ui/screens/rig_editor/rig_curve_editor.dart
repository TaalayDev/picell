import 'package:flutter/material.dart';

import '../../../data/models/rig/rig.dart';
import '../../../l10n/strings.dart';

/// Opens the easing curve editor; resolves to the chosen curve, or null when
/// cancelled.
Future<EasingCurve?> showEasingCurveDialog(BuildContext context, EasingCurve initial) {
  return showDialog<EasingCurve>(context: context, builder: (_) => _CurveDialog(initial: initial));
}

/// The curve a built-in easing stands for, as the starting point of an edit.
EasingCurve curveOfEasing(RigEasing easing) => switch (easing) {
      RigEasing.easeIn => EasingCurve.easeIn,
      RigEasing.easeOut => EasingCurve.easeOut,
      RigEasing.easeInOut => EasingCurve.easeInOut,
      _ => EasingCurve.linear,
    };

class _CurveDialog extends StatefulWidget {
  final EasingCurve initial;
  const _CurveDialog({required this.initial});

  @override
  State<_CurveDialog> createState() => _CurveDialogState();
}

class _CurveDialogState extends State<_CurveDialog> {
  late EasingCurve curve = widget.initial;
  int? _dragging;

  static const _yMin = -0.5, _yMax = 1.5;

  Offset _toCanvas(double x, double y, Size size) =>
      Offset(x * size.width, (1 - (y - _yMin) / (_yMax - _yMin)) * size.height);

  void _drag(Offset p, Size size) {
    final x = (p.dx / size.width).clamp(0.0, 1.0);
    final y = _yMin + (1 - p.dy / size.height) * (_yMax - _yMin);
    setState(() {
      curve = _dragging == 0 ? curve.copyWith(x1: x, y1: y) : curve.copyWith(x2: x, y2: y);
    });
  }

  void _start(Offset p, Size size) {
    final a = _toCanvas(curve.x1, curve.y1, size), b = _toCanvas(curve.x2, curve.y2, size);
    _dragging = (p - a).distance <= (p - b).distance ? 0 : 1;
    _drag(p, size);
  }

  @override
  Widget build(BuildContext context) {
    final strings = Strings.of(context);
    final theme = Theme.of(context);
    final presets = <(String, EasingCurve)>[
      (strings.rigEasingLinear, EasingCurve.linear),
      (strings.rigEasingIn, EasingCurve.easeIn),
      (strings.rigEasingOut, EasingCurve.easeOut),
      (strings.rigEasingInOut, EasingCurve.easeInOut),
      (strings.rigCurveStrongOut, EasingCurve(.16, 1, .3, 1)),
      (strings.rigCurveStrongInOut, EasingCurve(.83, 0, .17, 1)),
      (strings.rigCurveOvershoot, EasingCurve(.34, 1.56, .64, 1)),
      (strings.rigCurveAnticipate, EasingCurve(.36, 0, .66, -.56)),
    ];
    return AlertDialog(
      title: Text(strings.rigCurveTitle),
      content: SizedBox(
        width: 300,
        child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(strings.rigCurveHint, style: theme.textTheme.bodySmall),
          const SizedBox(height: 8),
          AspectRatio(
            aspectRatio: 1,
            child: LayoutBuilder(builder: (context, box) {
              final size = box.biggest;
              // Raw pointer events: a drag here must not scroll the dialog.
              return Listener(
                key: const Key('rigCurveArea'),
                onPointerDown: (e) => _start(e.localPosition, size),
                onPointerMove: (e) => _drag(e.localPosition, size),
                child: CustomPaint(
                  size: size,
                  painter: _CurvePainter(curve, theme.colorScheme, _yMin, _yMax),
                ),
              );
            }),
          ),
          const SizedBox(height: 4),
          Text(
            'cubic-bezier(${curve.x1.toStringAsFixed(2)}, ${curve.y1.toStringAsFixed(2)}, '
            '${curve.x2.toStringAsFixed(2)}, ${curve.y2.toStringAsFixed(2)})',
            key: const Key('rigCurveReadout'),
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Wrap(spacing: 6, runSpacing: 0, children: [
            for (final (name, preset) in presets)
              ActionChip(
                visualDensity: VisualDensity.compact,
                label: Text(name, style: theme.textTheme.labelSmall),
                onPressed: () => setState(() => curve = preset),
              ),
          ]),
        ])),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(strings.cancel)),
        FilledButton(onPressed: () => Navigator.pop(context, curve), child: Text(strings.apply)),
      ],
    );
  }
}

class _CurvePainter extends CustomPainter {
  final EasingCurve curve;
  final ColorScheme colors;
  final double yMin, yMax;
  _CurvePainter(this.curve, this.colors, this.yMin, this.yMax);

  Offset _p(double x, double y, Size s) => Offset(x * s.width, (1 - (y - yMin) / (yMax - yMin)) * s.height);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = colors.surfaceContainerHighest);
    final grid = Paint()
      ..color = colors.outlineVariant
      ..strokeWidth = 1;
    // The 0 and 1 value lines bound the unovershot range.
    for (final y in [0.0, 1.0]) {
      canvas.drawLine(_p(0, y, size), _p(1, y, size), grid);
    }
    canvas.drawLine(_p(0, 0, size), _p(1, 1, size), grid..color = colors.outlineVariant.withValues(alpha: .5));

    final a = _p(curve.x1, curve.y1, size), b = _p(curve.x2, curve.y2, size);
    final handle = Paint()
      ..color = colors.outline
      ..strokeWidth = 1.5;
    canvas.drawLine(_p(0, 0, size), a, handle);
    canvas.drawLine(_p(1, 1, size), b, handle);

    final path = Path()..moveTo(_p(0, 0, size).dx, _p(0, 0, size).dy);
    const steps = 48;
    for (var i = 1; i <= steps; i++) {
      final t = i / steps;
      final p = _p(t, curve.transform(t), size);
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = colors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
    for (final p in [a, b]) {
      canvas.drawCircle(p, 7, Paint()..color = colors.primary);
      canvas.drawCircle(
        p,
        7,
        Paint()
          ..color = colors.onPrimary
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  @override
  bool shouldRepaint(_CurvePainter old) => old.curve != curve || old.colors != colors;
}
