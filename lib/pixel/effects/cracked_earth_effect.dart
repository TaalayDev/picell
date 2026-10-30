part of 'effects.dart';

/// Quantized dry-earth plates with recessed fissures and chipped, sunlit rims.
class CrackedEarthEffect extends Effect {
  CrackedEarthEffect([Map<String, dynamic>? params]) : super(EffectType.crackedEarth, {..._defaults, ...?params});

  static const _defaults = <String, dynamic>{
    'plateSize': 11,
    'pixelSize': 1,
    'irregularity': 0.85,
    'crackWidth': 0.8,
    'rimWidth': 1.0,
    'rimBreakup': 0.35,
    'variation': 0.25,
    'roughness': 0.15,
    'relief': 0.65,
    'lightAngle': 225.0,
    'soilColor': 0xFF60422E,
    'rimColor': 0xFFCAA477,
    'crackColor': 0xFF493321,
    'seed': 42,
    'opacity': 1.0,
    'preserveAlpha': true,
  };

  @override
  Map<String, dynamic> getDefaultParameters() => Map.of(_defaults);

  @override
  Map<String, dynamic> getMetadata() => {
        for (final spec in [
          ('plateSize', 'Soil Plate Size', 4, 64),
          ('pixelSize', 'Pixel Size', 1, 8),
          ('irregularity', 'Plate Irregularity', 0.0, 1.0),
          ('crackWidth', 'Crack Width', 0.0, 6.0),
          ('rimWidth', 'Sandy Rim Width', 0.0, 4.0),
          ('rimBreakup', 'Broken Rim Amount', 0.0, 1.0),
          ('variation', 'Plate Color Variation', 0.0, 1.0),
          ('roughness', 'Soil Grain', 0.0, 1.0),
          ('relief', 'Edge Relief', 0.0, 1.0),
          ('lightAngle', 'Light Direction', 0.0, 360.0),
          ('seed', 'Random Seed', 0, 9999),
          ('opacity', 'Opacity', 0.0, 1.0),
        ])
          spec.$1: <String, dynamic>{
            'label': spec.$2,
            'type': 'slider',
            'min': spec.$3,
            'max': spec.$4,
            'divisions': spec.$3 is int ? (spec.$4 - spec.$3).toInt() : 100,
          },
        'soilColor': <String, dynamic>{'label': 'Soil Color', 'type': 'color'},
        'rimColor': <String, dynamic>{'label': 'Sandy Rim Color', 'type': 'color'},
        'crackColor': <String, dynamic>{'label': 'Crack Color', 'type': 'color'},
        'preserveAlpha': <String, dynamic>{
          'label': 'Preserve Alpha',
          'type': 'bool',
          'description': 'Keep the existing artwork silhouette; disable to fill the canvas.'
        },
      };

  double _number(String key, double min, double max) {
    final value = (parameters[key] as num?)?.toDouble();
    return (value != null && value.isFinite ? value : (_defaults[key] as num).toDouble()).clamp(min, max);
  }

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    final output = Uint32List.fromList(pixels);
    if (width <= 0 || height <= 0) return output;
    final opacity = _number('opacity', 0, 1);
    if (opacity == 0) return output;
    final pixelSize = _number('pixelSize', 1, 8).round();
    // Keep at least four logical pixels per plate as pixelation increases.
    final size = math.max(_number('plateSize', 4, 64), pixelSize * 4.0);
    final jitter = _number('irregularity', 0, 1) * 0.35;
    final joint = math.min(_number('crackWidth', 0, 6) * pixelSize, size * 0.3) / 2;
    final rim = math.min(_number('rimWidth', 0, 4) * pixelSize, size * 0.22);
    final breakup = _number('rimBreakup', 0, 1);
    final variation = _number('variation', 0, 1);
    final roughness = _number('roughness', 0, 1);
    final relief = _number('relief', 0, 1);
    final angle = _number('lightAngle', 0, 360) * math.pi / 180;
    final lx = math.cos(angle), ly = math.sin(angle);
    final seed = _number('seed', 0, 9999).round();
    final soil = (parameters['soilColor'] as num).toInt();
    final rimColor = (parameters['rimColor'] as num).toInt();
    final crackColor = (parameters['crackColor'] as num).toInt();
    final preserve = parameters['preserveAlpha'] != false;
    // Cache sites once; bounded jitter keeps the nearest site and all relevant
    // bisectors inside a 5x5 neighborhood, including beyond canvas edges.
    final cols = ((width + pixelSize) / size).ceil() + 6;
    final rows = ((height + pixelSize) / size).ceil() + 6;
    final sites = List.generate(cols * rows, (i) {
      final cx = i % cols - 3, cy = i ~/ cols - 3;
      return (
        x: (cx + 0.5 + (_textureHash(cx, cy, seed) * 2 - 1) * jitter) * size,
        y: (cy + 0.5 + (_textureHash(cx, cy, seed + 11) * 2 - 1) * jitter) * size,
        tint: (_textureHash(cx, cy, seed + 29) - 0.5) * variation * 0.6,
      );
    });
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final i = y * width + x, source = pixels[y * width + x];
        final alpha = source >>> 24;
        if (preserve && alpha == 0) continue;
        final px = (x ~/ pixelSize) * pixelSize + pixelSize / 2;
        final py = (y ~/ pixelSize) * pixelSize + pixelSize / 2;
        final gx = (px / size).floor() + 3, gy = (py / size).floor() + 3;
        var nearest = double.infinity;
        var winner = 0;
        for (var oy = -2; oy <= 2; oy++) {
          for (var ox = -2; ox <= 2; ox++) {
            final index = (gy + oy) * cols + gx + ox;
            final site = sites[index];
            final dx = px - site.x, dy = py - site.y;
            final distance = dx * dx + dy * dy;
            if (distance < nearest) {
              nearest = distance;
              winner = index;
            }
          }
        }
        final center = sites[winner];
        var edge = double.infinity;
        var nx = 0.0, ny = 0.0;
        for (var oy = -2; oy <= 2; oy++) {
          for (var ox = -2; ox <= 2; ox++) {
            final index = (gy + oy) * cols + gx + ox;
            if (index == winner) continue;
            final site = sites[index];
            final dx = site.x - center.x, dy = site.y - center.y;
            final length = math.sqrt(dx * dx + dy * dy);
            final distance =
                ((site.x + center.x) / 2 - px) * dx / length + ((site.y + center.y) / 2 - py) * dy / length;
            if (distance < edge) {
              edge = distance;
              nx = dx / length;
              ny = dy / length;
            }
          }
        }
        final grain = _textureHash(x ~/ pixelSize, y ~/ pixelSize, seed + 53);
        // Coherent chips interrupt the pale rim instead of producing a uniform
        // outline. Geometry and noise share the logical pixel grid.
        final wear = _textureNoise(px / pixelSize * 0.65, py / pixelSize * 0.65, seed + 71);
        final inside = edge - joint;
        final isCrack = inside < 0;
        final isRim = !isCrack && inside < rim && wear >= breakup * 0.85;
        final base = isCrack ? crackColor : (isRim ? rimColor : soil);
        var shade = 1.0 + center.tint;
        if (isRim) {
          // Discrete warm highlights and shaded rims match a small pixel palette.
          final light = nx * lx + ny * ly;
          shade = 1.0 - relief * (light > 0.25 ? 0.0 : (light < -0.25 ? 0.4 : 0.2));
        } else if (!isCrack) {
          shade += ((grain * 4).floor() / 3 - 0.5) * roughness * 0.25;
        } else {
          shade = 0.95 + (grain - 0.5) * roughness * 0.12;
        }
        int channel(int shift) => (_textureChannel(base, shift) * shade).round().clamp(0, 255);
        final texture = 0xFF000000 | channel(16) << 16 | channel(8) << 8 | channel(0);
        final outAlpha = preserve ? alpha : (alpha + (255 - alpha) * opacity).round();
        output[i] = _textureBlendColor(source, texture, opacity, outAlpha);
      }
    }
    return output;
  }
}
