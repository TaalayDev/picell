part of 'effects.dart';

/// Simulates classic 8-bit/16-bit retro palette-cycling (Mark Ferrari style)
/// for dynamic waterfalls, flowing lava, neon marquees, and rainbow cycles.
class ColorCyclingEffect extends Effect with UIFieldProvider {
  ColorCyclingEffect([Map<String, dynamic>? params])
      : super(
          EffectType.colorCycling,
          params ??
              const {
                'mode': 'hueCycle',
                'speed': 1.0,
                'phase': 0.0,
                'time': 0.0,
                'preserveAlpha': true,
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() {
    return {
      'mode': 'hueCycle',
      'speed': 1.0,
      'phase': 0.0,
      'time': 0.0,
      'preserveAlpha': true,
    };
  }

  @override
  Map<String, dynamic> getMetadata() {
    return {
      'mode': {
        'label': 'Cycling Mode',
        'description': 'Palette shifting animation style.',
        'type': 'select',
        'options': {
          'hueCycle': 'Full Rainbow Spectrum',
          'waterfall': 'Flowing Waterfall (Cyan/Blue)',
          'fireLava': 'Living Fire & Lava (Orange/Red)',
          'neonPulse': 'Synthwave Neon (Pink/Cyan)',
        },
      },
      'speed': {
        'label': 'Cycle Speed',
        'description': 'Velocity of the color cycle shift.',
        'type': 'slider',
        'min': 0.1,
        'max': 4.0,
        'divisions': 39,
      },
      'phase': {
        'label': 'Cycle Phase Offset',
        'description': 'Manual offset along the color cycle loop.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
      'time': {
        'label': 'Animation Time',
        'description': 'Progress parameter updated automatically during animation generation.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
      'preserveAlpha': {
        'label': 'Preserve Transparency',
        'description': 'Leave transparent pixels untouched.',
        'type': 'bool',
      },
    };
  }

  @override
  List<UIField> getFields() => [
        const SelectField(
          key: 'mode',
          label: 'Cycling Mode',
          description: 'Palette shifting animation style.',
          options: {
            'hueCycle': 'Full Rainbow Spectrum',
            'waterfall': 'Flowing Waterfall (Cyan/Blue)',
            'fireLava': 'Living Fire & Lava (Orange/Red)',
            'neonPulse': 'Synthwave Neon (Pink/Cyan)',
          },
        ),
        SliderField(
          key: 'speed',
          label: 'Cycle Speed',
          description: 'Velocity of the color cycle shift.',
          min: 0.1,
          max: 4.0,
          divisions: 39,
          formatLabel: (v) => '${v.toStringAsFixed(1)}x',
        ),
        SliderField(
          key: 'phase',
          label: 'Cycle Phase Offset',
          description: 'Manual offset along the color cycle loop.',
          min: 0.0,
          max: 1.0,
          divisions: 100,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        SliderField(
          key: 'time',
          label: 'Animation Time',
          description: 'Progress parameter updated automatically during animation generation.',
          min: 0.0,
          max: 1.0,
          divisions: 100,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        const BoolField(
          key: 'preserveAlpha',
          label: 'Preserve Transparency',
          description: 'Leave transparent pixels untouched.',
        ),
      ];

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    if (width <= 0 || height <= 0 || pixels.isEmpty) return pixels;

    final mode = parameters['mode'] as String? ?? 'hueCycle';
    final speed = ((parameters['speed'] as num?)?.toDouble() ?? 1.0).clamp(0.1, 4.0);
    final phase = ((parameters['phase'] as num?)?.toDouble() ?? 0.0).clamp(0.0, 1.0);
    final time = ((parameters['time'] as num?)?.toDouble() ?? 0.0).clamp(0.0, 1.0);
    final preserveAlpha = parameters['preserveAlpha'] as bool? ?? true;

    final cycleProgress = (time * speed + phase) % 1.0;
    final result = Uint32List(width * height);

    for (int i = 0; i < width * height; i++) {
      final p = pixels[i];
      final a = (p >> 24) & 0xFF;

      if (a == 0 && preserveAlpha) {
        result[i] = 0;
        continue;
      }

      final r = (p >> 16) & 0xFF;
      final g = (p >> 8) & 0xFF;
      final b = p & 0xFF;

      int outR = r;
      int outG = g;
      int outB = b;

      final hsv = _rgbToHsv(r, g, b);
      final hue = hsv[0];
      final sat = hsv[1];
      final val = hsv[2];

      switch (mode) {
        case 'hueCycle':
          if (sat > 0.08) {
            final newHue = (hue + cycleProgress * 360.0) % 360.0;
            final rgb = _hsvToRgb(newHue, sat, val);
            outR = rgb[0];
            outG = rgb[1];
            outB = rgb[2];
          }
          break;

        case 'waterfall':
          // Cyan/Blue gradient flow driven by luminance + cycleProgress
          final t = (val + cycleProgress) % 1.0;
          final rgb = _evalWaterfall(t, sat);
          outR = rgb[0];
          outG = rgb[1];
          outB = rgb[2];
          break;

        case 'fireLava':
          // Fiery crimson/orange/yellow flow driven by luminance + cycleProgress
          final t = (val + cycleProgress) % 1.0;
          final rgb = _evalFireLava(t, sat);
          outR = rgb[0];
          outG = rgb[1];
          outB = rgb[2];
          break;

        case 'neonPulse':
          // Oscillating Synthwave neon hue shift
          final waveShift = math.sin(cycleProgress * 2 * math.pi) * 60.0;
          final newHue = (hue + waveShift + 360.0) % 360.0;
          final rgb = _hsvToRgb(newHue, math.max(sat, 0.6), val);
          outR = rgb[0];
          outG = rgb[1];
          outB = rgb[2];
          break;
      }

      final outA = a == 0 ? 255 : a;
      result[i] = (outA << 24) | (outR << 16) | (outG << 8) | outB;
    }

    return result;
  }

  static List<int> _evalWaterfall(double t, double originalSat) {
    // 0.0: Deep Navy -> 0.35: Vibrant Cyan -> 0.7: Sky Blue -> 0.9: White Foam -> 1.0: Deep Navy
    if (t < 0.35) {
      final f = t / 0.35;
      return [
        (10 + f * 10).round(),
        (30 + f * 170).round(),
        (80 + f * 175).round(),
      ];
    } else if (t < 0.7) {
      final f = (t - 0.35) / 0.35;
      return [
        (20 + f * 40).round(),
        (200 + f * 25).round(),
        255,
      ];
    } else if (t < 0.9) {
      final f = (t - 0.7) / 0.2;
      return [
        (60 + f * 195).round(),
        (225 + f * 30).round(),
        255,
      ];
    } else {
      final f = (t - 0.9) / 0.1;
      return [
        (255 - f * 245).round(),
        (255 - f * 225).round(),
        (255 - f * 175).round(),
      ];
    }
  }

  static List<int> _evalFireLava(double t, double originalSat) {
    // 0.0: Dark Maroon -> 0.35: Deep Crimson -> 0.65: Bright Orange -> 0.88: Gold Yellow -> 1.0: White
    if (t < 0.35) {
      final f = t / 0.35;
      return [
        (40 + f * 160).round(),
        (5 + f * 15).round(),
        0,
      ];
    } else if (t < 0.65) {
      final f = (t - 0.35) / 0.3;
      return [
        (200 + f * 55).round(),
        (20 + f * 120).round(),
        0,
      ];
    } else if (t < 0.88) {
      final f = (t - 0.65) / 0.23;
      return [
        255,
        (140 + f * 90).round(),
        (f * 40).round(),
      ];
    } else {
      final f = (t - 0.88) / 0.12;
      return [
        255,
        (230 + f * 25).round(),
        (40 + f * 215).round(),
      ];
    }
  }

  static List<double> _rgbToHsv(int r, int g, int b) {
    final rf = r / 255.0;
    final gf = g / 255.0;
    final bf = b / 255.0;

    final maxVal = math.max(rf, math.max(gf, bf));
    final minVal = math.min(rf, math.min(gf, bf));
    final delta = maxVal - minVal;

    double h = 0.0;
    if (delta > 0.00001) {
      if (maxVal == rf) {
        h = 60.0 * (((gf - bf) / delta) % 6);
      } else if (maxVal == gf) {
        h = 60.0 * (((bf - rf) / delta) + 2);
      } else {
        h = 60.0 * (((rf - gf) / delta) + 4);
      }
      if (h < 0) h += 360.0;
    }

    final s = maxVal > 0 ? delta / maxVal : 0.0;
    final v = maxVal;
    return [h, s, v];
  }

  static List<int> _hsvToRgb(double h, double s, double v) {
    final c = v * s;
    final x = c * (1.0 - (((h / 60.0) % 2) - 1.0).abs());
    final m = v - c;

    double rf = 0.0, gf = 0.0, bf = 0.0;
    if (h < 60) {
      rf = c;
      gf = x;
    } else if (h < 120) {
      rf = x;
      gf = c;
    } else if (h < 180) {
      gf = c;
      bf = x;
    } else if (h < 240) {
      gf = x;
      bf = c;
    } else if (h < 300) {
      rf = x;
      bf = c;
    } else {
      rf = c;
      bf = x;
    }

    return [
      ((rf + m) * 255.0).round().clamp(0, 255),
      ((gf + m) * 255.0).round().clamp(0, 255),
      ((bf + m) * 255.0).round().clamp(0, 255),
    ];
  }
}
