import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomSlider extends StatelessWidget {
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  const CustomSlider({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SliderTheme(
      data: SliderThemeData(
        trackHeight: 8,
        activeTrackColor: Colors.transparent,
        inactiveTrackColor: const Color(0xFFE2E8F0),
        thumbColor: Colors.white,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14),
        overlayColor: const Color(0xFF667EEA).withValues(alpha: 0.2),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 24),
        trackShape: const GradientRectSliderTrackShape(
          gradient: LinearGradient(
            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          ),
          darkenInactive: true,
        ),
      ),
      child: Slider(
        value: value,
        min: min,
        max: max,
        onChanged: onChanged,
      ),
    );
  }
}

class CustomRangeSlider extends StatelessWidget {
  final double start;
  final double end;
  final double min;
  final double max;
  final Function(double, double) onChanged;

  const CustomRangeSlider({
    Key? key,
    required this.start,
    required this.end,
    required this.min,
    required this.max,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SliderTheme(
      data: SliderThemeData(
        trackHeight: 8,
        activeTrackColor: Colors.transparent,
        inactiveTrackColor: const Color(0xFFE2E8F0),
        thumbColor: Colors.white,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14),
        overlayColor: const Color(0xFF48BB78).withValues(alpha: 0.2),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 24),
        rangeThumbShape: const RoundRangeSliderThumbShape(enabledThumbRadius: 14),
        rangeTrackShape: GradientRectRangeSliderTrackShape(
          gradient: const LinearGradient(
            colors: [Color(0xFF48BB78), Color(0xFF38B2AC)],
          ),
        ),
      ),
      child: RangeSlider(
        values: RangeValues(start, end),
        min: min,
        max: max,
        onChanged: (values) => onChanged(values.start, values.end),
      ),
    );
  }
}

class GradientRectSliderTrackShape extends SliderTrackShape {
  final Gradient gradient;
  final bool darkenInactive;

  const GradientRectSliderTrackShape({
    required this.gradient,
    this.darkenInactive = false,
  });

  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final double trackHeight = sliderTheme.trackHeight!;
    final double trackLeft = offset.dx;
    final double trackTop = offset.dy + (parentBox.size.height - trackHeight) / 2;
    final double trackWidth = parentBox.size.width;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isEnabled = false,
    bool isDiscrete = false,
    required TextDirection textDirection,
  }) {
    const additionalActiveTrackHeight = 2;
    final Rect trackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );

    final Paint inactivePaint = Paint()
      ..color = sliderTheme.inactiveTrackColor!
      ..style = PaintingStyle.fill;

    final Paint activePaint = Paint()
      ..shader = gradient.createShader(trackRect)
      ..style = PaintingStyle.fill;

    final double trackCenter = trackRect.center.dy;
    final RRect trackRRect = RRect.fromLTRBR(
      trackRect.left,
      trackCenter - sliderTheme.trackHeight! / 2,
      trackRect.right,
      trackCenter + sliderTheme.trackHeight! / 2,
      Radius.circular(sliderTheme.trackHeight! / 2),
    );

    context.canvas.drawRRect(trackRRect, inactivePaint);

    final RRect activeTrackRRect = RRect.fromLTRBR(
      trackRect.left,
      trackCenter - sliderTheme.trackHeight! / 2,
      thumbCenter.dx,
      trackCenter + sliderTheme.trackHeight! / 2,
      Radius.circular(sliderTheme.trackHeight! / 2),
    );

    context.canvas.drawRRect(activeTrackRRect, activePaint);
  }
}

class GradientRectRangeSliderTrackShape extends RangeSliderTrackShape {
  final Gradient gradient;

  const GradientRectRangeSliderTrackShape({required this.gradient});

  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final double trackHeight = sliderTheme.trackHeight!;
    final double trackLeft = offset.dx;
    final double trackTop = offset.dy + (parentBox.size.height - trackHeight) / 2;
    final double trackWidth = parentBox.size.width;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required Offset startThumbCenter,
    required Offset endThumbCenter,
    bool isEnabled = false,
    bool isDiscrete = false,
    required TextDirection textDirection,
    double additionalActiveTrackHeight = 2,
  }) {
    final Rect trackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );

    final Paint inactivePaint = Paint()
      ..color = sliderTheme.inactiveTrackColor!
      ..style = PaintingStyle.fill;

    final double trackCenter = trackRect.center.dy;
    final RRect trackRRect = RRect.fromLTRBR(
      trackRect.left,
      trackCenter - sliderTheme.trackHeight! / 2,
      trackRect.right,
      trackCenter + sliderTheme.trackHeight! / 2,
      Radius.circular(sliderTheme.trackHeight! / 2),
    );

    context.canvas.drawRRect(trackRRect, inactivePaint);

    final Rect activeRect = Rect.fromLTRB(
      startThumbCenter.dx,
      trackCenter - sliderTheme.trackHeight! / 2,
      endThumbCenter.dx,
      trackCenter + sliderTheme.trackHeight! / 2,
    );

    final Paint activePaint = Paint()
      ..shader = gradient.createShader(activeRect)
      ..style = PaintingStyle.fill;

    final RRect activeTrackRRect = RRect.fromRectAndRadius(
      activeRect,
      Radius.circular(sliderTheme.trackHeight! / 2),
    );

    context.canvas.drawRRect(activeTrackRRect, activePaint);
  }
}
