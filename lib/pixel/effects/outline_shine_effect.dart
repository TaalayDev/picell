part of 'effects.dart';

/// Adds a clean outline around the sprite and a light-facing shine on its edges.
///
/// The outline is only ever drawn on transparent pixels next to the sprite, so
/// existing art is never overwritten and an already-closed border stays as is.
/// The shine lightens sprite pixels that face the light; by default it is a
/// lighter version of each pixel's own color.
class OutlineShineEffect extends Effect with UIFieldProvider {
  OutlineShineEffect([Map<String, dynamic>? params])
      : super(
          EffectType.outlineShine,
          params ?? _defaults,
        );

  static const Map<String, dynamic> _defaults = {
    'outlineEnabled': true,
    'outlineColor': 0xFF000000,
    'outlineThickness': 1,
    'outlineCorners': 'rounded',
    'alphaThreshold': 0,
    'shineEnabled': true,
    'shineStyle': 'soft',
    'glossPosition': 0.3,
    'glossWidth': 2,
    'autoShineColor': true,
    'shineColor': 0xFFFFFFFF,
    'shineLighten': 0.5,
    'shineIntensity': 0.85,
    'shineDepth': 2,
    'lightAngle': 135.0,
    'glint': false,
  };

  static const Map<String, String> _styleOptions = {
    'soft': 'Soft (gradient fade from the edge)',
    'flat': 'Flat (single hard-edged band)',
    'bold': 'Bold (bright rim + softer inner band)',
    'gloss': 'Gloss (diagonal streak across the surface)',
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
      'outlineEnabled': {
        'label': 'Outline',
        'description': 'Draw an outline on transparent pixels bordering the sprite.',
        'type': 'bool',
      },
      'outlineColor': {
        'label': 'Outline Color',
        'description': 'Color of the outline (default black).',
        'type': 'color',
      },
      'outlineThickness': {
        'label': 'Outline Thickness',
        'description': 'Outline width in pixels.',
        'type': 'slider',
        'min': 1,
        'max': 4,
        'divisions': 3,
      },
      'outlineCorners': {
        'label': 'Outline Corners',
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
      'shineEnabled': {
        'label': 'Shine',
        'description': 'Highlight sprite edges that face the light.',
        'type': 'bool',
      },
      'shineStyle': {
        'label': 'Shine Style',
        'description': 'Soft fades out, flat is a single band, bold adds a bright rim, gloss is a diagonal streak.',
        'type': 'select',
        'options': _styleOptions,
      },
      'glossPosition': {
        'label': 'Gloss Position',
        'description': 'Where the gloss streak sits across the sprite, along the light direction.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 20,
      },
      'glossWidth': {
        'label': 'Gloss Width',
        'description': 'Width of the gloss streak in pixels.',
        'type': 'slider',
        'min': 1,
        'max': 8,
        'divisions': 7,
      },
      'autoShineColor': {
        'label': 'Auto Shine Color',
        'description': 'Use a lighter version of each pixel color instead of a fixed color.',
        'type': 'bool',
      },
      'shineColor': {
        'label': 'Shine Color',
        'description': 'Fixed shine color, used when Auto Shine Color is off.',
        'type': 'color',
      },
      'shineLighten': {
        'label': 'Shine Lightness',
        'description': 'How much lighter the auto shine is than the original color.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 20,
      },
      'shineIntensity': {
        'label': 'Shine Intensity',
        'description': 'Strength of the shine at the very edge.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 20,
      },
      'shineDepth': {
        'label': 'Shine Depth',
        'description': 'How many pixels the shine reaches into the sprite.',
        'type': 'slider',
        'min': 1,
        'max': 5,
        'divisions': 4,
      },
      'lightAngle': {
        'label': 'Light Direction',
        'description': 'Direction the light comes from (90° = top, 135° = top-left).',
        'type': 'slider',
        'min': 0.0,
        'max': 360.0,
        'divisions': 72,
      },
      'glint': {
        'label': 'Sparkle Glint',
        'description': 'Add a small cross-shaped sparkle on the spot closest to the light.',
        'type': 'bool',
      },
    };
  }

  @override
  List<UIField> getFields() => [
        const BoolField(
          key: 'outlineEnabled',
          label: 'Outline',
          description: 'Draw an outline on transparent pixels bordering the sprite.',
        ),
        const ColorField(
          key: 'outlineColor',
          label: 'Outline Color',
          description: 'Color of the outline (default black).',
        ),
        SliderField(
          key: 'outlineThickness',
          label: 'Outline Thickness',
          description: 'Outline width in pixels.',
          min: 1,
          max: 4,
          divisions: 3,
          isInteger: true,
          formatLabel: (v) => '${v.toInt()}px',
        ),
        const SelectField(
          key: 'outlineCorners',
          label: 'Outline Corners',
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
        const BoolField(
          key: 'shineEnabled',
          label: 'Shine',
          description: 'Highlight sprite edges that face the light.',
        ),
        const SelectField(
          key: 'shineStyle',
          label: 'Shine Style',
          description: 'Soft fades out, flat is a single band, bold adds a bright rim, gloss is a diagonal streak.',
          options: _styleOptions,
        ),
        SliderField(
          key: 'glossPosition',
          label: 'Gloss Position',
          description: 'Where the gloss streak sits across the sprite, along the light direction.',
          min: 0.0,
          max: 1.0,
          divisions: 20,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        SliderField(
          key: 'glossWidth',
          label: 'Gloss Width',
          description: 'Width of the gloss streak in pixels.',
          min: 1,
          max: 8,
          divisions: 7,
          isInteger: true,
          formatLabel: (v) => '${v.toInt()}px',
        ),
        const BoolField(
          key: 'autoShineColor',
          label: 'Auto Shine Color',
          description: 'Use a lighter version of each pixel color instead of a fixed color.',
        ),
        const ColorField(
          key: 'shineColor',
          label: 'Shine Color',
          description: 'Fixed shine color, used when Auto Shine Color is off.',
        ),
        SliderField(
          key: 'shineLighten',
          label: 'Shine Lightness',
          description: 'How much lighter the auto shine is than the original color.',
          min: 0.0,
          max: 1.0,
          divisions: 20,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        SliderField(
          key: 'shineIntensity',
          label: 'Shine Intensity',
          description: 'Strength of the shine at the very edge.',
          min: 0.0,
          max: 1.0,
          divisions: 20,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        SliderField(
          key: 'shineDepth',
          label: 'Shine Depth',
          description: 'How many pixels the shine reaches into the sprite.',
          min: 1,
          max: 5,
          divisions: 4,
          isInteger: true,
          formatLabel: (v) => '${v.toInt()}px',
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
        const BoolField(
          key: 'glint',
          label: 'Sparkle Glint',
          description: 'Add a small cross-shaped sparkle on the spot closest to the light.',
        ),
      ];

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    if (width <= 0 || height <= 0 || pixels.length != width * height) return pixels;

    final p = parameters;
    final threshold = ((p['alphaThreshold'] as num?)?.toInt() ?? 0).clamp(0, 128);
    bool solid(int i) => ((pixels[i] >> 24) & 0xFF) > threshold;

    final result = Uint32List.fromList(pixels);

    if (p['shineEnabled'] as bool? ?? true) {
      _applyShine(pixels, result, width, height, solid);
    }
    if (p['outlineEnabled'] as bool? ?? true) {
      _applyOutline(pixels, result, width, height, solid);
    }
    return result;
  }

  void _applyShine(
    Uint32List src,
    Uint32List dst,
    int width,
    int height,
    bool Function(int) solid,
  ) {
    final p = parameters;
    final style = p['shineStyle'] as String? ?? 'soft';
    final auto = p['autoShineColor'] as bool? ?? true;
    final fixed = (p['shineColor'] as int?) ?? 0xFFFFFFFF;
    final lighten = ((p['shineLighten'] as num?)?.toDouble() ?? 0.5).clamp(0.0, 1.0);
    final intensity = ((p['shineIntensity'] as num?)?.toDouble() ?? 0.85).clamp(0.0, 1.0);
    final depth = ((p['shineDepth'] as num?)?.toInt() ?? 2).clamp(1, 5);
    final angle = ((p['lightAngle'] as num?)?.toDouble() ?? 135.0) * math.pi / 180.0;

    final lx = math.cos(angle);
    final ly = -math.sin(angle); // screen y grows downward
    final steps = <(int, int)>[
      if (lx.abs() > 0.38) (lx > 0 ? 1 : -1, 0),
      if (ly.abs() > 0.38) (0, ly > 0 ? 1 : -1),
    ];
    if (steps.isEmpty || intensity == 0) return;

    final isGloss = style == 'gloss';
    final glossPos = ((p['glossPosition'] as num?)?.toDouble() ?? 0.3).clamp(0.0, 1.0);
    final glossWidth = ((p['glossWidth'] as num?)?.toInt() ?? 2).clamp(1, 8);

    // Gloss: extent of the sprite measured against the light direction.
    var minProj = double.infinity;
    var maxProj = -double.infinity;
    if (isGloss) {
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          if (!solid(y * width + x)) continue;
          final proj = -(x * lx + y * ly);
          if (proj < minProj) minProj = proj;
          if (proj > maxProj) maxProj = proj;
        }
      }
    }
    final glossStart = minProj + (maxProj - minProj) * glossPos;

    // Bold keeps a brighter rim than the inner band.
    final rimLighten = style == 'bold' ? lighten + (1.0 - lighten) * 0.5 : lighten;

    int bestIdx = -1;
    double bestProjection = double.infinity;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final i = y * width + x;
        if (!solid(i)) continue;

        final proj = -(x * lx + y * ly);
        double strength;
        var pixelLighten = lighten;

        if (isGloss) {
          if (proj < glossStart || proj >= glossStart + glossWidth) continue;
          strength = intensity;
        } else {
          // Distance to the nearest transparent pixel toward the light.
          int hit = 0;
          for (final (sx, sy) in steps) {
            for (int d = 1; d <= depth; d++) {
              if (hit != 0 && d >= hit) break;
              final nx = x + sx * d;
              final ny = y + sy * d;
              if (nx < 0 || ny < 0 || nx >= width || ny >= height || !solid(ny * width + nx)) {
                hit = d;
                break;
              }
            }
          }
          if (hit == 0) continue;

          switch (style) {
            case 'flat':
              strength = intensity;
            case 'bold':
              if (hit == 1) {
                strength = intensity;
                pixelLighten = rimLighten;
              } else {
                strength = intensity * 0.55;
              }
            default:
              strength = intensity * (1.0 - (hit - 1) / depth);
          }
        }

        final base = src[i];
        final target = auto ? _lighten(base, pixelLighten) : fixed;
        final t = auto ? strength : strength * (((fixed >> 24) & 0xFF) / 255.0);
        dst[i] = _mix(base, target, t);

        if (proj < bestProjection) {
          bestProjection = proj;
          bestIdx = i;
        }
      }
    }

    if (p['glint'] as bool? ?? false) {
      _applyGlint(dst, width, height, bestIdx, solid, auto ? 0xFFFFFFFF : fixed);
    }
  }

  void _applyGlint(
    Uint32List dst,
    int width,
    int height,
    int centerIdx,
    bool Function(int) solid,
    int color,
  ) {
    if (centerIdx < 0) return;
    final cx = centerIdx % width;
    final cy = centerIdx ~/ width;
    final white = 0xFF000000 | (color & 0x00FFFFFF);
    for (final (dx, dy, t) in const [(0, 0, 1.0), (1, 0, 0.6), (-1, 0, 0.6), (0, 1, 0.6), (0, -1, 0.6)]) {
      final x = cx + dx;
      final y = cy + dy;
      if (x < 0 || y < 0 || x >= width || y >= height) continue;
      final i = y * width + x;
      if (!solid(i)) continue;
      dst[i] = _mix(dst[i], white, t);
    }
  }

  void _applyOutline(
    Uint32List src,
    Uint32List dst,
    int width,
    int height,
    bool Function(int) solid,
  ) {
    final p = parameters;
    final color = (p['outlineColor'] as int?) ?? 0xFF000000;
    final thickness = ((p['outlineThickness'] as num?)?.toInt() ?? 1).clamp(1, 4);
    final square = (p['outlineCorners'] as String? ?? 'rounded') == 'square';
    if ((color >> 24) == 0) return;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        if (solid(y * width + x)) continue;

        var touches = false;
        for (int dy = -thickness; dy <= thickness && !touches; dy++) {
          final ny = y + dy;
          if (ny < 0 || ny >= height) continue;
          for (int dx = -thickness; dx <= thickness; dx++) {
            final nx = x + dx;
            if (nx < 0 || nx >= width) continue;
            if (!square && dx.abs() + dy.abs() > thickness) continue;
            if (solid(ny * width + nx)) {
              touches = true;
              break;
            }
          }
        }
        if (touches) dst[y * width + x] = color;
      }
    }
  }

  static int _lighten(int argb, double amount) {
    final r = (argb >> 16) & 0xFF;
    final g = (argb >> 8) & 0xFF;
    final b = argb & 0xFF;
    int ch(int c) => (c + (255 - c) * amount).round().clamp(0, 255);
    return (argb & 0xFF000000) | (ch(r) << 16) | (ch(g) << 8) | ch(b);
  }

  /// Blends the RGB of [from] toward [to] by [t], keeping [from]'s alpha.
  static int _mix(int from, int to, double t) {
    if (t <= 0) return from;
    final k = t.clamp(0.0, 1.0);
    int ch(int shift) {
      final a = (from >> shift) & 0xFF;
      final b = (to >> shift) & 0xFF;
      return (a + (b - a) * k).round().clamp(0, 255);
    }

    return (from & 0xFF000000) | (ch(16) << 16) | (ch(8) << 8) | ch(0);
  }
}
