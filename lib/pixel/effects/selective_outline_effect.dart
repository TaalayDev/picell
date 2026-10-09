part of 'effects.dart';

/// "Sel-out": an outline that takes a darker shade of the sprite color it
/// touches instead of one flat color, so the silhouette blends into the art.
/// Only transparent pixels next to the sprite are drawn; the sprite itself is
/// never changed.
class SelectiveOutlineEffect extends Effect with UIFieldProvider {
  SelectiveOutlineEffect([Map<String, dynamic>? params])
      : super(
          EffectType.selectiveOutline,
          params ?? _defaults,
        );

  static const Map<String, dynamic> _defaults = {
    'thickness': 1,
    'darkness': 0.55,
    'saturation': 1.1,
    'hueShift': 0.0,
    'lightBias': 0.3,
    'lightAngle': 135.0,
    'corners': 'rounded',
    'alphaThreshold': 0,
  };

  static const Map<String, String> _cornerOptions = {
    'rounded': 'Rounded (4-way)',
    'square': 'Square (8-way)',
  };

  @override
  Map<String, dynamic> getDefaultParameters() => Map<String, dynamic>.of(_defaults);

  @override
  Map<String, dynamic> getMetadata() {
    return {
      'thickness': {
        'label': 'Thickness',
        'description': 'Outline width in pixels.',
        'type': 'slider',
        'min': 1,
        'max': 3,
        'divisions': 2,
      },
      'darkness': {
        'label': 'Darkness',
        'description': 'How much darker the outline is than the color it touches.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 20,
      },
      'saturation': {
        'label': 'Saturation',
        'description': 'Scales the outline color saturation. Above 1 gives richer outlines.',
        'type': 'slider',
        'min': 0.0,
        'max': 2.0,
        'divisions': 20,
      },
      'hueShift': {
        'label': 'Hue Shift',
        'description': 'Rotates the outline hue, in degrees.',
        'type': 'slider',
        'min': -60.0,
        'max': 60.0,
        'divisions': 24,
      },
      'lightBias': {
        'label': 'Light Bias',
        'description': 'Makes the outline lighter on the lit side and darker on the shaded side.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 20,
      },
      'lightAngle': {
        'label': 'Light Direction',
        'description': 'Direction the light comes from (90° = top, 135° = top-left).',
        'type': 'slider',
        'min': 0.0,
        'max': 360.0,
        'divisions': 72,
      },
      'corners': {
        'label': 'Corners',
        'description': 'Rounded skips diagonal corners, square fills them.',
        'type': 'select',
        'options': _cornerOptions,
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
          key: 'thickness',
          label: 'Thickness',
          description: 'Outline width in pixels.',
          min: 1,
          max: 3,
          divisions: 2,
          isInteger: true,
          formatLabel: (v) => '${v.toInt()}px',
        ),
        SliderField(
          key: 'darkness',
          label: 'Darkness',
          description: 'How much darker the outline is than the color it touches.',
          min: 0.0,
          max: 1.0,
          divisions: 20,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        SliderField(
          key: 'saturation',
          label: 'Saturation',
          description: 'Scales the outline color saturation. Above 1 gives richer outlines.',
          min: 0.0,
          max: 2.0,
          divisions: 20,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        SliderField(
          key: 'hueShift',
          label: 'Hue Shift',
          description: 'Rotates the outline hue, in degrees.',
          min: -60.0,
          max: 60.0,
          divisions: 24,
          formatLabel: (v) => '${v.round()}°',
        ),
        SliderField(
          key: 'lightBias',
          label: 'Light Bias',
          description: 'Makes the outline lighter on the lit side and darker on the shaded side.',
          min: 0.0,
          max: 1.0,
          divisions: 20,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        SliderField(
          key: 'lightAngle',
          label: 'Light Direction',
          description: 'Direction the light comes from (90° = top, 135° = top-left).',
          min: 0.0,
          max: 360.0,
          divisions: 72,
          formatLabel: (v) => '${v.round()}°',
        ),
        const SelectField(
          key: 'corners',
          label: 'Corners',
          description: 'Rounded skips diagonal corners, square fills them.',
          options: _cornerOptions,
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
    final thickness = ((p['thickness'] as num?)?.toInt() ?? 1).clamp(1, 3);
    final darkness = ((p['darkness'] as num?)?.toDouble() ?? 0.55).clamp(0.0, 1.0);
    final saturation = ((p['saturation'] as num?)?.toDouble() ?? 1.1).clamp(0.0, 2.0);
    final hueShift = ((p['hueShift'] as num?)?.toDouble() ?? 0.0).clamp(-60.0, 60.0);
    final lightBias = ((p['lightBias'] as num?)?.toDouble() ?? 0.3).clamp(0.0, 1.0);
    final angle = ((p['lightAngle'] as num?)?.toDouble() ?? 135.0) * math.pi / 180.0;
    final square = (p['corners'] as String? ?? 'rounded') == 'square';
    final threshold = ((p['alphaThreshold'] as num?)?.toInt() ?? 0).clamp(0, 128);

    final lx = math.cos(angle);
    final ly = -math.sin(angle);

    bool solid(int i) => ((pixels[i] >> 24) & 0xFF) > threshold;

    // Source color for each outline pixel: the neighbouring pixel it grows
    // from. Rings are grown one at a time so thick outlines keep the color of
    // the nearest sprite pixel.
    final source = Int32List(width * height)..fillRange(0, width * height, -1);
    final isOutline = Uint8List(width * height);
    var frontier = <int>[
      for (var i = 0; i < pixels.length; i++)
        if (solid(i)) i,
    ];
    for (var i in frontier) {
      source[i] = pixels[i];
    }

    final dirs = <(int, int)>[
      (1, 0), (-1, 0), (0, 1), (0, -1),
      if (square) ...[(1, 1), (1, -1), (-1, 1), (-1, -1)],
    ];

    for (var ring = 0; ring < thickness; ring++) {
      final next = <int>[];
      final claimed = <int, List<int>>{};
      for (final idx in frontier) {
        final x = idx % width;
        final y = idx ~/ width;
        for (final (dx, dy) in dirs) {
          final nx = x + dx;
          final ny = y + dy;
          if (nx < 0 || ny < 0 || nx >= width || ny >= height) continue;
          final n = ny * width + nx;
          if (solid(n) || isOutline[n] == 1) continue;
          claimed.putIfAbsent(n, () => []).add(source[idx]);
        }
      }
      claimed.forEach((n, colors) {
        isOutline[n] = 1;
        source[n] = _averageColor(colors);
        next.add(n);
      });
      frontier = next;
    }

    final result = Uint32List.fromList(pixels);
    for (var i = 0; i < pixels.length; i++) {
      if (isOutline[i] == 0) continue;
      final x = i % width;
      final y = i ~/ width;

      // Lit-side outline pixels have the sprite on the side away from the
      // light; use the position relative to the sprite center of mass of the
      // source neighbourhood: approximate with the direction to the nearest
      // solid pixel.
      final facing = _facingLight(pixels, width, height, x, y, lx, ly, solid);
      final bias = 1.0 + lightBias * (-facing);
      final effectiveDarkness = (darkness * bias).clamp(0.0, 1.0);

      result[i] = _outlineColor(source[i], effectiveDarkness, saturation, hueShift);
    }
    return result;
  }

  /// +1 when the nearby sprite lies on the shaded side of this pixel (the
  /// outline faces the light), -1 when it lies on the lit side.
  static double _facingLight(
    Uint32List pixels,
    int width,
    int height,
    int x,
    int y,
    double lx,
    double ly,
    bool Function(int) solid,
  ) {
    var sumX = 0.0;
    var sumY = 0.0;
    var count = 0;
    for (var dy = -1; dy <= 1; dy++) {
      for (var dx = -1; dx <= 1; dx++) {
        final nx = x + dx;
        final ny = y + dy;
        if (nx < 0 || ny < 0 || nx >= width || ny >= height) continue;
        if (solid(ny * width + nx)) {
          sumX += dx;
          sumY += dy;
          count++;
        }
      }
    }
    if (count == 0) return 0.0;
    // Direction from this pixel toward the sprite.
    final toSprite = (sumX / count) * lx + (sumY / count) * ly;
    return toSprite.clamp(-1.0, 1.0) * -1.0;
  }

  static int _averageColor(List<int> colors) {
    if (colors.length == 1) return colors.first;
    var r = 0, g = 0, b = 0, a = 0;
    for (final c in colors) {
      a += (c >> 24) & 0xFF;
      r += (c >> 16) & 0xFF;
      g += (c >> 8) & 0xFF;
      b += c & 0xFF;
    }
    final n = colors.length;
    return ((a ~/ n) << 24) | ((r ~/ n) << 16) | ((g ~/ n) << 8) | (b ~/ n);
  }

  static int _outlineColor(int sourceColor, double darkness, double saturation, double hueShift) {
    final (h, s, l) = _rgbToHsl((sourceColor >> 16) & 0xFF, (sourceColor >> 8) & 0xFF, sourceColor & 0xFF);
    final nl = l * (1.0 - darkness);
    final ns = (s * saturation).clamp(0.0, 1.0);
    final nh = (h + hueShift + 360.0) % 360.0;
    final (r, g, b) = _hslToRgb(nh, ns, nl);
    return 0xFF000000 | (r << 16) | (g << 8) | b;
  }
}
