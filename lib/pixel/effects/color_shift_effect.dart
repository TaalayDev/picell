part of 'effects.dart';

/// Rotates hues, creates animated rainbow cycles, chromatic waves,
/// RGB channel splits, and stylized palette color shifting for pixel art sprites.
class ColorShiftEffect extends Effect with UIFieldProvider {
  ColorShiftEffect([Map<String, dynamic>? params])
      : super(
          EffectType.colorShift,
          params ?? _defaults,
        );

  static const Map<String, dynamic> _defaults = {
    'shiftMode': 'full',
    'hueShift': 90.0,
    'saturation': 1.0,
    'brightness': 1.0,
    'channelSplit': 0.0,
    'tintColor': 0xFFFF4081,
    'tintAmount': 0.5,
    'waveDirection': 'diagonal',
    'waveFrequency': 1.5,
    'paletteSteps': 8,
    'time': 0.0,
    'preserveAlpha': true,
  };

  static const Map<String, String> _modeOptions = {
    'full': 'Full Hue Shift (rotates entire palette uniformly)',
    'cycle': 'Rainbow Cycle (continuous 360° color loop over time)',
    'wave': 'Chromatic Wave (flowing color spectrum bands across sprite)',
    'channelSplit': 'RGB Prism Split (displaces Red, Green, and Blue channels)',
    'tint': 'Color Tint (harmonizes sprite colors towards target tint)',
    'paletteStep': 'Retro Stepped Shift (quantized 8/16-step retro palette shift)',
  };

  static const Map<String, String> _directionOptions = {
    'diagonal': 'Diagonal (top-left to bottom-right)',
    'vertical': 'Vertical (top to bottom)',
    'horizontal': 'Horizontal (left to right)',
  };

  @override
  Map<String, dynamic> getDefaultParameters() => Map.of(_defaults);

  @override
  int? get preferredFrameCount => 16;

  @override
  bool get isSeamlessLoop => true;

  @override
  Map<String, dynamic> getMetadata() => {
        'shiftMode': {
          'label': 'Shift Mode',
          'description': 'How colors are transformed and animated.',
          'type': 'select',
          'options': _modeOptions,
        },
        'hueShift': {
          'label': 'Hue Rotation Angle',
          'description': 'Base hue angle rotation in degrees.',
          'type': 'slider',
          'min': 0.0,
          'max': 360.0,
          'divisions': 72,
        },
        'saturation': {
          'label': 'Saturation Multiplier',
          'description': 'Color vibrance and intensity.',
          'type': 'slider',
          'min': 0.0,
          'max': 2.0,
          'divisions': 40,
        },
        'brightness': {
          'label': 'Brightness Multiplier',
          'description': 'Overall color lightness and value.',
          'type': 'slider',
          'min': 0.5,
          'max': 2.0,
          'divisions': 30,
        },
        'channelSplit': {
          'label': 'RGB Channel Split',
          'description': 'Prism displacement distance in pixels.',
          'type': 'slider',
          'min': 0.0,
          'max': 8.0,
          'divisions': 8,
        },
        'tintColor': {
          'label': 'Tint Target Color',
          'description': 'Target harmonizing color for Tint mode.',
          'type': 'color',
        },
        'tintAmount': {
          'label': 'Tint Strength',
          'description': 'Intensity of the target color tint.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 50,
        },
        'waveDirection': {
          'label': 'Wave Direction',
          'description': 'Orientation of color bands in Wave mode.',
          'type': 'select',
          'options': _directionOptions,
        },
        'waveFrequency': {
          'label': 'Wave Frequency',
          'description': 'Density of color ripples across sprite.',
          'type': 'slider',
          'min': 0.5,
          'max': 4.0,
          'divisions': 35,
        },
        'paletteSteps': {
          'label': 'Stepped Palette Quantization',
          'description': 'Number of discrete color steps in Stepped mode.',
          'type': 'slider',
          'min': 4,
          'max': 32,
          'divisions': 7,
        },
        'time': {
          'label': 'Animation Time',
          'description': 'Timeline progress through the color shift loop.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 100,
        },
        'preserveAlpha': {
          'label': 'Preserve Transparency',
          'description': 'Keep background transparent.',
          'type': 'bool',
        },
      };

  @override
  List<UIField> getFields() => [
        const SelectField(
          key: 'shiftMode',
          label: 'Shift Mode',
          description: 'How colors are transformed and animated.',
          options: _modeOptions,
        ),
        SliderField(
          key: 'hueShift',
          label: 'Hue Rotation Angle',
          description: 'Base hue angle rotation in degrees.',
          min: 0.0,
          max: 360.0,
          divisions: 72,
          formatLabel: (v) => '${v.round()}°',
        ),
        SliderField(
          key: 'saturation',
          label: 'Saturation Multiplier',
          description: 'Color vibrance and intensity.',
          min: 0.0,
          max: 2.0,
          divisions: 40,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        SliderField(
          key: 'brightness',
          label: 'Brightness Multiplier',
          description: 'Overall color lightness and value.',
          min: 0.5,
          max: 2.0,
          divisions: 30,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        SliderField(
          key: 'channelSplit',
          label: 'RGB Channel Split',
          description: 'Prism displacement distance in pixels.',
          min: 0.0,
          max: 8.0,
          divisions: 8,
          isInteger: true,
          formatLabel: (v) => '${v.toInt()}px',
        ),
        const ColorField(
          key: 'tintColor',
          label: 'Tint Target Color',
          description: 'Target harmonizing color for Tint mode.',
        ),
        SliderField(
          key: 'tintAmount',
          label: 'Tint Strength',
          description: 'Intensity of the target color tint.',
          min: 0.0,
          max: 1.0,
          divisions: 50,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        const SelectField(
          key: 'waveDirection',
          label: 'Wave Direction',
          description: 'Orientation of color bands in Wave mode.',
          options: _directionOptions,
        ),
        SliderField(
          key: 'waveFrequency',
          label: 'Wave Frequency',
          description: 'Density of color ripples across sprite.',
          min: 0.5,
          max: 4.0,
          divisions: 35,
        ),
        SliderField(
          key: 'paletteSteps',
          label: 'Stepped Palette Quantization',
          description: 'Number of discrete color steps in Stepped mode.',
          min: 4,
          max: 32,
          divisions: 7,
          isInteger: true,
          formatLabel: (v) => '${v.toInt()} steps',
        ),
        SliderField(
          key: 'time',
          label: 'Animation Time',
          description: 'Timeline progress through the color shift loop.',
          min: 0.0,
          max: 1.0,
          divisions: 100,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        const BoolField(
          key: 'preserveAlpha',
          label: 'Preserve Transparency',
          description: 'Keep background transparent.',
        ),
      ];

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    if (width <= 0 || height <= 0 || pixels.isEmpty) return pixels;

    final shiftMode = parameters['shiftMode'] as String? ?? 'full';
    final hueShift = ((parameters['hueShift'] as num?)?.toDouble() ?? 90.0) % 360.0;
    final saturation = ((parameters['saturation'] as num?)?.toDouble() ?? 1.0).clamp(0.0, 2.0);
    final brightness = ((parameters['brightness'] as num?)?.toDouble() ?? 1.0).clamp(0.0, 2.5);
    final channelSplit = ((parameters['channelSplit'] as num?)?.toDouble() ?? 0.0).clamp(0.0, 12.0);
    final tintColor = (parameters['tintColor'] as num?)?.toInt() ?? 0xFFFF4081;
    final tintAmount = ((parameters['tintAmount'] as num?)?.toDouble() ?? 0.5).clamp(0.0, 1.0);
    final waveDirection = parameters['waveDirection'] as String? ?? 'diagonal';
    final waveFrequency = ((parameters['waveFrequency'] as num?)?.toDouble() ?? 1.5).clamp(0.1, 8.0);
    final paletteSteps = ((parameters['paletteSteps'] as num?)?.toInt() ?? 8).clamp(2, 64);
    final time = ((parameters['time'] as num?)?.toDouble() ?? 0.0).clamp(0.0, 1.0);
    final preserveAlpha = parameters['preserveAlpha'] as bool? ?? true;

    final tintHsv = _rgbToHsv((tintColor >> 16) & 0xFF, (tintColor >> 8) & 0xFF, tintColor & 0xFF);
    final tintHue = tintHsv[0];

    final splitOffset = channelSplit.round();
    final result = Uint32List(width * height);

    for (int y = 0; y < height; y++) {
      final rowOffset = y * width;
      for (int x = 0; x < width; x++) {
        final idx = rowOffset + x;
        final p = pixels[idx];
        final a = (p >> 24) & 0xFF;

        if (a == 0 && preserveAlpha) {
          result[idx] = 0;
          continue;
        }

        int r, g, b;

        if (splitOffset > 0 || shiftMode == 'channelSplit') {
          final split = splitOffset > 0 ? splitOffset : 2;
          final leftX = math.max(0, x - split);
          final rightX = math.min(width - 1, x + split);
          final leftPixel = pixels[rowOffset + leftX];
          final rightPixel = pixels[rowOffset + rightX];
          r = (leftPixel >> 16) & 0xFF;
          g = (p >> 8) & 0xFF;
          b = rightPixel & 0xFF;
        } else {
          r = (p >> 16) & 0xFF;
          g = (p >> 8) & 0xFF;
          b = p & 0xFF;
        }

        final hsv = _rgbToHsv(r, g, b);
        double curHue = hsv[0];
        double curSat = hsv[1];
        double curVal = hsv[2];

        double deltaH = 0.0;

        switch (shiftMode) {
          case 'full':
            deltaH = hueShift;
            break;
          case 'cycle':
            deltaH = hueShift + (time * 360.0);
            break;
          case 'wave':
            double pos;
            if (waveDirection == 'vertical') {
              pos = height > 1 ? y / (height - 1) : 0.0;
            } else if (waveDirection == 'horizontal') {
              pos = width > 1 ? x / (width - 1) : 0.0;
            } else {
              pos = ((width > 1 ? x / (width - 1) : 0.0) + (height > 1 ? y / (height - 1) : 0.0)) * 0.5;
            }
            deltaH = hueShift + ((pos * waveFrequency + time) * 360.0);
            break;
          case 'paletteStep':
            final stepSize = 360.0 / paletteSteps;
            final continuousH = (hueShift + time * 360.0) % 360.0;
            deltaH = (continuousH / stepSize).floor() * stepSize;
            break;
          case 'channelSplit':
            deltaH = hueShift + (time * 180.0);
            break;
          case 'tint':
            if (curSat > 0.05) {
              // Blend hue towards target tint
              final diff = (tintHue - curHue + 540.0) % 360.0 - 180.0;
              curHue = (curHue + diff * tintAmount) % 360.0;
            } else {
              curHue = tintHue;
            }
            curSat = math.min(1.0, curSat + tintAmount * 0.4);
            break;
        }

        if (shiftMode != 'tint') {
          curHue = (curHue + deltaH) % 360.0;
          if (curHue < 0) curHue += 360.0;
        }

        curSat = (curSat * saturation).clamp(0.0, 1.0);
        curVal = (curVal * brightness).clamp(0.0, 1.0);

        final rgb = _hsvToRgb(curHue, curSat, curVal);
        result[idx] = (a << 24) | (rgb[0] << 16) | (rgb[1] << 8) | rgb[2];
      }
    }

    return result;
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
