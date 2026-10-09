part of 'effects.dart';

/// Sweeps a radiant specular sheen, metallic gleam, or holographic rainbow
/// shimmer across pixel art sprites and canvases.
class ShimmerEffect extends Effect with UIFieldProvider {
  ShimmerEffect([Map<String, dynamic>? params])
      : super(
          EffectType.shimmer,
          params ?? _defaults,
        );

  static const Map<String, dynamic> _defaults = {
    'shimmerColor': 0xFFFFFFFF,
    'intensity': 0.85,
    'width': 6.0,
    'angle': 45.0,
    'mode': 'specular',
    'sparkles': true,
    'sparkleDensity': 0.35,
    'holdDuration': 0.25,
    'cycles': 1,
    'time': 0.0,
    'preserveAlpha': true,
  };

  static const Map<String, String> _modeOptions = {
    'specular': 'Specular (crisp white gleam, preserves texture)',
    'metallic': 'Metallic (high-contrast gleam with bright core)',
    'rainbow': 'Rainbow (iridescent holographic spectral prism)',
    'dodge': 'Color Dodge (vibrant hyper-glow highlight)',
  };

  @override
  Map<String, dynamic> getDefaultParameters() => Map.of(_defaults);

  @override
  int? get preferredFrameCount => 16;

  @override
  bool get isSeamlessLoop => true;

  @override
  Map<String, dynamic> getMetadata() => {
        'shimmerColor': {
          'label': 'Shimmer Color',
          'description': 'Tint of the sweeping light beam.',
          'type': 'color',
        },
        'intensity': {
          'label': 'Shimmer Intensity',
          'description': 'Brightness and opacity of the sheen highlight.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 100,
        },
        'width': {
          'label': 'Beam Width',
          'description': 'Width of the sweeping shimmer light band.',
          'type': 'slider',
          'min': 2.0,
          'max': 24.0,
          'divisions': 22,
        },
        'angle': {
          'label': 'Sweep Angle',
          'description': 'Direction angle of the shimmer wave (45° = diagonal).',
          'type': 'slider',
          'min': 0.0,
          'max': 360.0,
          'divisions': 72,
        },
        'mode': {
          'label': 'Shimmer Mode',
          'description': 'Blending style of the specular sheen.',
          'type': 'select',
          'options': _modeOptions,
        },
        'sparkles': {
          'label': 'Diamond Sparkles',
          'description': 'Scatter twinkling glint specks along the wave crest.',
          'type': 'bool',
        },
        'sparkleDensity': {
          'label': 'Sparkle Density',
          'description': 'Frequency of twinkle glint specks.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 50,
        },
        'holdDuration': {
          'label': 'Hold Pause Ratio',
          'description': 'Pause duration between sweeping passes.',
          'type': 'slider',
          'min': 0.0,
          'max': 0.8,
          'divisions': 40,
        },
        'cycles': {
          'label': 'Cycles per Loop',
          'description': 'Number of sweep passes in one animation loop.',
          'type': 'slider',
          'min': 1,
          'max': 4,
          'divisions': 3,
        },
        'time': {
          'label': 'Animation Time',
          'description': 'Timeline progress through the sweep cycle.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 100,
        },
        'preserveAlpha': {
          'label': 'Preserve Transparency',
          'description': 'Restrict shimmer to sprite pixels.',
          'type': 'bool',
        },
      };

  @override
  List<UIField> getFields() => [
        const ColorField(
          key: 'shimmerColor',
          label: 'Shimmer Color',
          description: 'Tint of the sweeping light beam.',
        ),
        SliderField(
          key: 'intensity',
          label: 'Shimmer Intensity',
          description: 'Brightness and opacity of the sheen highlight.',
          min: 0.0,
          max: 1.0,
          divisions: 100,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        SliderField(
          key: 'width',
          label: 'Beam Width',
          description: 'Width of the sweeping shimmer light band in pixels.',
          min: 2.0,
          max: 24.0,
          divisions: 22,
          isInteger: true,
          formatLabel: (v) => '${v.toInt()}px',
        ),
        SliderField(
          key: 'angle',
          label: 'Sweep Angle',
          description: 'Direction angle of the shimmer wave in degrees.',
          min: 0.0,
          max: 360.0,
          divisions: 72,
          formatLabel: (v) => '${v.round()}°',
        ),
        const SelectField(
          key: 'mode',
          label: 'Shimmer Mode',
          description: 'Blending style of the specular sheen.',
          options: _modeOptions,
        ),
        const BoolField(
          key: 'sparkles',
          label: 'Diamond Sparkles',
          description: 'Scatter twinkling glint specks along the wave crest.',
        ),
        SliderField(
          key: 'sparkleDensity',
          label: 'Sparkle Density',
          description: 'Frequency of twinkle glint specks.',
          min: 0.0,
          max: 1.0,
          divisions: 50,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        SliderField(
          key: 'holdDuration',
          label: 'Hold Pause Ratio',
          description: 'Pause duration between sweeping passes.',
          min: 0.0,
          max: 0.8,
          divisions: 40,
          formatLabel: (v) => '${(v * 100).round()}% pause',
        ),
        SliderField(
          key: 'cycles',
          label: 'Cycles per Loop',
          description: 'Number of sweep passes in one animation loop.',
          min: 1,
          max: 4,
          divisions: 3,
          isInteger: true,
        ),
        SliderField(
          key: 'time',
          label: 'Animation Time',
          description: 'Timeline progress through the sweep cycle.',
          min: 0.0,
          max: 1.0,
          divisions: 100,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        const BoolField(
          key: 'preserveAlpha',
          label: 'Preserve Transparency',
          description: 'Restrict shimmer to sprite pixels.',
        ),
      ];

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    if (width <= 0 || height <= 0 || pixels.isEmpty) return pixels;

    final shimmerColor = (parameters['shimmerColor'] as num?)?.toInt() ?? 0xFFFFFFFF;
    final intensity = ((parameters['intensity'] as num?)?.toDouble() ?? 0.85).clamp(0.0, 1.0);
    final beamWidth = ((parameters['width'] as num?)?.toDouble() ?? 6.0).clamp(2.0, 48.0);
    final angle = ((parameters['angle'] as num?)?.toDouble() ?? 45.0) % 360.0;
    final mode = parameters['mode'] as String? ?? 'specular';
    final sparkles = parameters['sparkles'] as bool? ?? true;
    final sparkleDensity = ((parameters['sparkleDensity'] as num?)?.toDouble() ?? 0.35).clamp(0.0, 1.0);
    final holdDuration = ((parameters['holdDuration'] as num?)?.toDouble() ?? 0.25).clamp(0.0, 0.85);
    final cycles = ((parameters['cycles'] as num?)?.toInt() ?? 1).clamp(1, 4);
    final time = ((parameters['time'] as num?)?.toDouble() ?? 0.0).clamp(0.0, 1.0);
    final preserveAlpha = parameters['preserveAlpha'] as bool? ?? true;

    if (intensity <= 0.0) return Uint32List.fromList(pixels);

    // Compute bounding box
    int minX = width;
    int maxX = 0;
    int minY = height;
    int maxY = 0;
    bool hasOpaque = false;

    if (preserveAlpha) {
      for (int y = 0; y < height; y++) {
        final row = y * width;
        for (int x = 0; x < width; x++) {
          final a = (pixels[row + x] >> 24) & 0xFF;
          if (a > 0) {
            if (x < minX) minX = x;
            if (x > maxX) maxX = x;
            if (y < minY) minY = y;
            if (y > maxY) maxY = y;
            hasOpaque = true;
          }
        }
      }
    } else {
      minX = 0;
      maxX = width - 1;
      minY = 0;
      maxY = height - 1;
      hasOpaque = true;
    }

    if (!hasOpaque) return Uint32List.fromList(pixels);

    // Projection along normal vector
    final rad = angle * math.pi / 180.0;
    final dirX = math.cos(rad);
    final dirY = math.sin(rad);

    double d0 = minX * dirX + minY * dirY;
    double d1 = maxX * dirX + minY * dirY;
    double d2 = minX * dirX + maxY * dirY;
    double d3 = maxX * dirX + maxY * dirY;

    final minD = math.min(math.min(d0, d1), math.min(d2, d3));
    final maxD = math.max(math.max(d0, d1), math.max(d2, d3));
    final span = maxD - minD + beamWidth * 2.5;

    // Cycle progress
    final cycleFraction = (time * cycles) % 1.0;
    final activePortion = 1.0 - holdDuration;

    double? waveCenter;
    if (cycleFraction <= activePortion) {
      final sweepProgress = activePortion > 0.0 ? cycleFraction / activePortion : 0.0;
      waveCenter = (minD - beamWidth * 1.25) + span * sweepProgress;
    }

    final result = Uint32List(width * height);
    final sheenR = (shimmerColor >> 16) & 0xFF;
    final sheenG = (shimmerColor >> 8) & 0xFF;
    final sheenB = shimmerColor & 0xFF;

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

        if (waveCenter == null) {
          result[idx] = p;
          continue;
        }

        final proj = x * dirX + y * dirY;
        final dist = (proj - waveCenter).abs();

        if (dist > beamWidth) {
          result[idx] = p;
          continue;
        }

        final normDist = dist / beamWidth;
        double falloff = (1.0 + math.cos(normDist * math.pi)) * 0.5;

        final origR = (p >> 16) & 0xFF;
        final origG = (p >> 8) & 0xFF;
        final origB = p & 0xFF;

        int blendR = sheenR;
        int blendG = sheenG;
        int blendB = sheenB;

        if (mode == 'rainbow') {
          final rainbowHue = ((normDist * 280.0) + (time * 180.0)) % 360.0;
          final rgb = _hsvToRgb(rainbowHue, 0.9, 1.0);
          blendR = rgb[0];
          blendG = rgb[1];
          blendB = rgb[2];
        }

        double shineAlpha = falloff * intensity;

        // Sharp metallic core spike
        if (mode == 'metallic' && dist < 1.5) {
          shineAlpha = (shineAlpha * 1.4).clamp(0.0, 1.0);
          blendR = math.min(255, (blendR * 1.3).round());
          blendG = math.min(255, (blendG * 1.3).round());
          blendB = math.min(255, (blendB * 1.3).round());
        }

        int outR, outG, outB;

        if (mode == 'dodge') {
          final factor = (shineAlpha * 200).round();
          outR = factor >= 255 ? 255 : math.min(255, (origR * 256) ~/ (256 - factor));
          outG = factor >= 255 ? 255 : math.min(255, (origG * 256) ~/ (256 - factor));
          outB = factor >= 255 ? 255 : math.min(255, (origB * 256) ~/ (256 - factor));
        } else {
          // Specular / Metallic / Rainbow additive & screen blend
          outR = math.min(255, origR + (blendR * shineAlpha).round());
          outG = math.min(255, origG + (blendG * shineAlpha).round());
          outB = math.min(255, origB + (blendB * shineAlpha).round());
        }

        // Diamond twinkle glints along wave crest
        if (sparkles && dist < beamWidth * 0.7) {
          final hash = ((x * 73856093) ^ (y * 19349663) ^ ((cycleFraction * 24).floor() * 83492791)) & 0xFFFF;
          if (hash < (sparkleDensity * 0.12 * 65535)) {
            final glintIntensity = (1.0 - dist / (beamWidth * 0.7)) * 220;
            outR = math.min(255, outR + glintIntensity.round());
            outG = math.min(255, outG + glintIntensity.round());
            outB = math.min(255, outB + glintIntensity.round());
          }
        }

        result[idx] = (a << 24) | (outR << 16) | (outG << 8) | outB;
      }
    }

    return result;
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
