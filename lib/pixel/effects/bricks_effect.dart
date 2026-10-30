part of 'effects.dart';

/// Pixel-centered masonry with stable per-brick firing variation and relief.
class BricksEffect extends Effect {
  BricksEffect([Map<String, dynamic>? params]) : super(EffectType.bricks, {..._defaults, ...?params});

  static const _defaults = <String, dynamic>{
    'brickWidth': 16,
    'brickHeight': 8,
    'bond': 'running',
    'stagger': 0.5,
    'mortarWidth': 1.0,
    'bevel': 1.0,
    'cornerRadius': 0.0,
    'borderWidth': 0.0,
    'borderColor': 0xFF66382B,
    'variation': 0.3,
    'roughness': 0.3,
    'weathering': 0.15,
    'lightAngle': 225.0,
    'brickColor': 0xFFB65C42,
    'mortarColor': 0xFF82796C,
    'seed': 42,
    'opacity': 1.0,
    'preserveAlpha': true,
  };

  @override
  Map<String, dynamic> getDefaultParameters() => Map.of(_defaults);

  @override
  Map<String, dynamic> getMetadata() => {
        for (final spec in [
          ('brickWidth', 'Brick Width', 4, 128),
          ('brickHeight', 'Brick Height', 3, 64),
          ('stagger', 'Row Stagger', 0.0, 1.0),
          ('mortarWidth', 'Mortar Width', 0.0, 8.0),
          ('bevel', 'Edge Bevel', 0.0, 4.0),
          ('cornerRadius', 'Corner Radius', 0.0, 16.0),
          ('borderWidth', 'Border Width', 0.0, 8.0),
          ('variation', 'Brick Color Variation', 0.0, 1.0),
          ('roughness', 'Surface Roughness', 0.0, 1.0),
          ('weathering', 'Edge Weathering', 0.0, 1.0),
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
        'bond': <String, dynamic>{
          'label': 'Bond Pattern',
          'type': 'select',
          'options': {'running': 'Running Bond', 'stack': 'Stack Bond', 'english': 'English Bond'}
        },
        'brickColor': <String, dynamic>{'label': 'Brick Color', 'type': 'color'},
        'borderColor': <String, dynamic>{'label': 'Border Color', 'type': 'color'},
        'mortarColor': <String, dynamic>{'label': 'Mortar Color', 'type': 'color'},
        'preserveAlpha': <String, dynamic>{
          'label': 'Preserve Alpha',
          'type': 'bool',
          'description': 'Keep the sprite silhouette; disable to fill the canvas.'
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
    final bw = _number('brickWidth', 4, 128);
    final bh = _number('brickHeight', 3, 64);
    final mortar = _number('mortarWidth', 0, 8);
    final bevel = _number('bevel', 0, 4);
    final cornerRadius = _number('cornerRadius', 0, 16);
    final borderWidth = _number('borderWidth', 0, 8);
    final borderColor = (parameters['borderColor'] as num).toInt();
    final stagger = _number('stagger', 0, 1);
    final variation = _number('variation', 0, 1);
    final roughness = _number('roughness', 0, 1);
    final weathering = _number('weathering', 0, 1);
    final angle = _number('lightAngle', 0, 360) * math.pi / 180;
    final lx = math.cos(angle), ly = math.sin(angle);
    final seed = _number('seed', 0, 9999).round();
    final brick = (parameters['brickColor'] as num).toInt();
    final grout = (parameters['mortarColor'] as num).toInt();
    final preserve = parameters['preserveAlpha'] != false;
    final bond = parameters['bond'];
    for (var y = 0; y < height; y++) {
      final row = (y / bh).floor();
      final cellWidth = bond == 'english' && row.isOdd ? bw / 2 : bw;
      final offset = bond == 'stack' ? 0.0 : (row.isOdd ? cellWidth * stagger : 0.0);
      // Limit joints and bevels so even very small bricks retain a face.
      final joint = math.min(mortar, math.min(cellWidth, bh) * 0.45) / 2;
      final bevelSize = math.min(bevel, math.min(cellWidth, bh) * 0.25);
      final halfFace = math.min(cellWidth, bh) / 2 - joint;
      final radius = math.min(cornerRadius, halfFace);
      final border = math.min(borderWidth, halfFace * 0.75);
      for (var x = 0; x < width; x++) {
        final i = y * width + x;
        final source = pixels[i], alpha = pixels[i] >>> 24;
        if (preserve && alpha == 0) continue;
        final col = ((x + 0.5 + offset) / cellWidth).floor();
        final u = x + 0.5 + offset - col * cellWidth;
        final v = y + 0.5 - row * bh;
        final dx = math.min(u, cellWidth - u);
        final dy = math.min(v, bh - v);
        final grain = _textureHash(x, y, seed + 17);
        final chip = weathering * _textureNoise(x * 0.8, y * 0.8, seed + 31) * 1.5;
        // Signed distance to a rounded brick: the same contour drives the
        // mortar cutout, inset border, and bevel, including curved corners.
        final qx = radius + joint - dx;
        final qy = radius + joint - dy;
        final cx = math.max(qx, 0.0), cy = math.max(qy, 0.0);
        final cornerDistance = math.sqrt(cx * cx + cy * cy);
        final edge = radius - cornerDistance - math.min(math.max(qx, qy), 0.0) - chip;
        final isMortar = edge < 0;
        var shade = 1.0;
        if (isMortar) {
          shade = 0.78 + (grain - 0.5) * roughness * 0.2;
        } else {
          shade += (_textureHash(col, row, seed) - 0.5) * variation * 0.7;
          shade += (grain - 0.5) * roughness * 0.22;
          shade += (_textureNoise(x * 0.18, y * 0.3, seed) - 0.5) * roughness * 0.25;
          if (bevelSize > 0 && edge < bevelSize) {
            final nx = u < cellWidth / 2 ? -lx : lx;
            final ny = v < bh / 2 ? -ly : ly;
            final normal = cornerDistance > 0 ? (cx * nx + cy * ny) / cornerDistance : (dx < dy ? nx : ny);
            shade += normal * 0.38 * (1 - edge / bevelSize);
          }
          if (grain < weathering * 0.06) shade *= 0.65;
        }
        final color = isMortar ? grout : (edge < border ? borderColor : brick);
        int channel(int shift) => (_textureChannel(color, shift) * shade).round().clamp(0, 255);
        final textured = 0xFF000000 | channel(16) << 16 | channel(8) << 8 | channel(0);
        final outAlpha = preserve ? alpha : (alpha + (255 - alpha) * opacity).round();
        output[i] = _textureBlendColor(source, textured, opacity, outAlpha);
      }
    }
    return output;
  }
}
