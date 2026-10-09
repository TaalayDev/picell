part of 'effects.dart';

/// Shades a sprite the way a pixel artist would: edges facing the light get a
/// highlight, edges facing away get a shadow, quantized into a few clean tone
/// bands. Shadows and highlights can be hue-shifted (cool shadows, warm
/// highlights) instead of only getting darker or lighter.
class SmartShadingEffect extends Effect with UIFieldProvider {
  SmartShadingEffect([Map<String, dynamic>? params])
      : super(
          EffectType.smartShading,
          params ?? _defaults,
        );

  static const Map<String, dynamic> _defaults = {
    'lightAngle': 135.0,
    'depth': 2,
    'bands': 2,
    'highlightStrength': 0.35,
    'shadowStrength': 0.4,
    'hueShift': 12.0,
    'alphaThreshold': 0,
  };

  @override
  Map<String, dynamic> getDefaultParameters() => Map<String, dynamic>.of(_defaults);

  @override
  Map<String, dynamic> getMetadata() {
    return {
      'lightAngle': {
        'label': 'Light Direction',
        'description': 'Direction the light comes from (90° = top, 135° = top-left).',
        'type': 'slider',
        'min': 0.0,
        'max': 360.0,
        'divisions': 72,
      },
      'depth': {
        'label': 'Shading Depth',
        'description': 'How many pixels in from the edge the shading reaches.',
        'type': 'slider',
        'min': 1,
        'max': 6,
        'divisions': 5,
      },
      'bands': {
        'label': 'Tone Bands',
        'description': 'Number of distinct tones per side. 1 is flat, higher is smoother.',
        'type': 'slider',
        'min': 1,
        'max': 4,
        'divisions': 3,
      },
      'highlightStrength': {
        'label': 'Highlight',
        'description': 'How much lighter the lit edge becomes.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 20,
      },
      'shadowStrength': {
        'label': 'Shadow',
        'description': 'How much darker the shaded edge becomes.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 20,
      },
      'hueShift': {
        'label': 'Hue Shift',
        'description': 'Shadows shift toward cool hues and highlights toward warm ones by this many degrees.',
        'type': 'slider',
        'min': 0.0,
        'max': 40.0,
        'divisions': 40,
      },
      'alphaThreshold': {
        'label': 'Transparency Threshold',
        'description': 'Pixels with alpha at or below this value count as transparent.',
        'type': 'slider',
        'min': 0,
        'max': 128,
        'divisions': 32,
      },
    };
  }

  @override
  List<UIField> getFields() => [
        SliderField(
          key: 'lightAngle',
          label: 'Light Direction',
          description: 'Direction the light comes from (90° = top, 135° = top-left).',
          min: 0.0,
          max: 360.0,
          divisions: 72,
          formatLabel: (v) => '${v.round()}°',
        ),
        SliderField(
          key: 'depth',
          label: 'Shading Depth',
          description: 'How many pixels in from the edge the shading reaches.',
          min: 1,
          max: 6,
          divisions: 5,
          isInteger: true,
          formatLabel: (v) => '${v.toInt()}px',
        ),
        const SliderField(
          key: 'bands',
          label: 'Tone Bands',
          description: 'Number of distinct tones per side. 1 is flat, higher is smoother.',
          min: 1,
          max: 4,
          divisions: 3,
          isInteger: true,
        ),
        SliderField(
          key: 'highlightStrength',
          label: 'Highlight',
          description: 'How much lighter the lit edge becomes.',
          min: 0.0,
          max: 1.0,
          divisions: 20,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        SliderField(
          key: 'shadowStrength',
          label: 'Shadow',
          description: 'How much darker the shaded edge becomes.',
          min: 0.0,
          max: 1.0,
          divisions: 20,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        SliderField(
          key: 'hueShift',
          label: 'Hue Shift',
          description: 'Shadows shift toward cool hues and highlights toward warm ones by this many degrees.',
          min: 0.0,
          max: 40.0,
          divisions: 40,
          formatLabel: (v) => '${v.round()}°',
        ),
        const SliderField(
          key: 'alphaThreshold',
          label: 'Transparency Threshold',
          description: 'Pixels with alpha at or below this value count as transparent.',
          min: 0,
          max: 128,
          divisions: 32,
          isInteger: true,
        ),
      ];

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    if (width <= 0 || height <= 0 || pixels.length != width * height) return pixels;

    final p = parameters;
    final angle = ((p['lightAngle'] as num?)?.toDouble() ?? 135.0) * math.pi / 180.0;
    final depth = ((p['depth'] as num?)?.toInt() ?? 2).clamp(1, 6);
    final bands = ((p['bands'] as num?)?.toInt() ?? 2).clamp(1, 4);
    final highlight = ((p['highlightStrength'] as num?)?.toDouble() ?? 0.35).clamp(0.0, 1.0);
    final shadow = ((p['shadowStrength'] as num?)?.toDouble() ?? 0.4).clamp(0.0, 1.0);
    final hueShift = ((p['hueShift'] as num?)?.toDouble() ?? 12.0).clamp(0.0, 40.0);
    final threshold = ((p['alphaThreshold'] as num?)?.toInt() ?? 0).clamp(0, 128);

    final lx = math.cos(angle);
    final ly = -math.sin(angle);
    final toLight = <(int, int)>[
      if (lx.abs() > 0.38) (lx > 0 ? 1 : -1, 0),
      if (ly.abs() > 0.38) (0, ly > 0 ? 1 : -1),
    ];
    if (toLight.isEmpty) return pixels;
    final fromLight = [for (final (sx, sy) in toLight) (-sx, -sy)];

    bool solid(int x, int y) =>
        x >= 0 && y >= 0 && x < width && y < height && ((pixels[y * width + x] >> 24) & 0xFF) > threshold;

    // Edge proximity in [0, 1] looking along [steps]; 1 = at the edge.
    double proximity(int x, int y, List<(int, int)> steps) {
      var hit = 0;
      for (final (sx, sy) in steps) {
        for (var d = 1; d <= depth; d++) {
          if (hit != 0 && d >= hit) break;
          if (!solid(x + sx * d, y + sy * d)) {
            hit = d;
            break;
          }
        }
      }
      if (hit == 0) return 0;
      final raw = 1.0 - (hit - 1) / depth;
      // Snap to the requested number of tone bands.
      return (raw * bands).ceil() / bands;
    }

    final result = Uint32List.fromList(pixels);
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        if (!solid(x, y)) continue;

        final lit = proximity(x, y, toLight);
        final shaded = proximity(x, y, fromLight);
        // Where both sides are close (thin parts) the light side wins.
        final light = lit * highlight;
        final dark = lit > 0 ? 0.0 : shaded * shadow;
        if (light == 0 && dark == 0) continue;

        result[y * width + x] = _shadePixel(pixels[y * width + x], light, dark, hueShift);
      }
    }
    return result;
  }
}

/// Lightens by [light] and darkens by [dark] (both 0..1) with an optional
/// hue shift: highlights drift toward yellow (60°), shadows toward blue (240°).
int _shadePixel(int argb, double light, double dark, double hueShift) {
  final (h, s, l) = _rgbToHsl((argb >> 16) & 0xFF, (argb >> 8) & 0xFF, argb & 0xFF);
  var nh = h;
  var nl = l;
  if (light > 0) {
    nl = l + (1.0 - l) * light;
    nh = _hueToward(h, 60.0, hueShift * light);
  } else if (dark > 0) {
    nl = l * (1.0 - dark);
    nh = _hueToward(h, 240.0, hueShift * dark);
  }
  final (r, g, b) = _hslToRgb(nh, s, nl);
  return (argb & 0xFF000000) | (r << 16) | (g << 8) | b;
}

/// Moves hue [from] toward [target] along the shorter arc by at most [maxStep].
double _hueToward(double from, double target, double maxStep) {
  var diff = (target - from) % 360.0;
  if (diff > 180.0) diff -= 360.0;
  if (diff < -180.0) diff += 360.0;
  final step = diff.abs() < maxStep ? diff : maxStep * diff.sign;
  return (from + step + 360.0) % 360.0;
}

(double, double, double) _rgbToHsl(int r, int g, int b) {
  final rf = r / 255.0;
  final gf = g / 255.0;
  final bf = b / 255.0;
  final maxC = math.max(rf, math.max(gf, bf));
  final minC = math.min(rf, math.min(gf, bf));
  final l = (maxC + minC) / 2.0;
  final delta = maxC - minC;
  if (delta == 0) return (0.0, 0.0, l);

  final s = l > 0.5 ? delta / (2.0 - maxC - minC) : delta / (maxC + minC);
  double h;
  if (maxC == rf) {
    h = ((gf - bf) / delta) % 6.0;
  } else if (maxC == gf) {
    h = (bf - rf) / delta + 2.0;
  } else {
    h = (rf - gf) / delta + 4.0;
  }
  return ((h * 60.0 + 360.0) % 360.0, s, l);
}

(int, int, int) _hslToRgb(double h, double s, double l) {
  final c = (1.0 - (2.0 * l - 1.0).abs()) * s;
  final x = c * (1.0 - ((h / 60.0) % 2.0 - 1.0).abs());
  final m = l - c / 2.0;
  final (r, g, b) = switch ((h / 60.0).floor() % 6) {
    0 => (c, x, 0.0),
    1 => (x, c, 0.0),
    2 => (0.0, c, x),
    3 => (0.0, x, c),
    4 => (x, 0.0, c),
    _ => (c, 0.0, x),
  };
  int ch(double v) => ((v + m) * 255.0).round().clamp(0, 255);
  return (ch(r), ch(g), ch(b));
}
