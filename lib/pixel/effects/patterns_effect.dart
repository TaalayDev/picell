part of 'effects.dart';

/// Analytic pixel patterns: no bitmap scaling, with deterministic cell variation.
class PatternsEffect extends Effect {
  PatternsEffect([Map<String, dynamic>? params]) : super(EffectType.patterns, {..._defaults, ...?params});

  static const patternOptions = <String, String>{
    'checker': 'Checkerboard',
    'stripes': 'Stripes',
    'diagonal': 'Diagonal Stripes',
    'grid': 'Grid',
    'dots': 'Polka Dots',
    'rings': 'Rings',
    'squares': 'Square Frames',
    'diamonds': 'Diamonds',
    'crosses': 'Crosses',
    'triangles': 'Triangles',
    'stars': 'Stars',
    'waves': 'Waves',
    'chevron': 'Chevron',
    'scallops': 'Scallops',
    'weave': 'Woven Threads',
    'basket': 'Basket Weave',
    'hexagons': 'Honeycomb',
    'truchet': 'Truchet Arcs',
    'maze': 'Diagonal Maze',
    'confetti': 'Confetti',
  };

  static const _defaults = <String, dynamic>{
    'pattern': 'checker',
    'scale': 12,
    'spacing': 0.0,
    'thickness': 0.3,
    'rotation': 0.0,
    'stretch': 1.0,
    'offsetX': 0.0,
    'offsetY': 0.0,
    'pixelSize': 1,
    'variation': 0.0,
    'seed': 42,
    'invert': false,
    'foregroundColor': 0xFFE1C99A,
    'backgroundColor': 0xFF50435E,
    'sourceBlend': 0.0,
    'opacity': 1.0,
    'preserveAlpha': true,
  };

  @override
  Map<String, dynamic> getDefaultParameters() => Map.of(_defaults);

  @override
  Map<String, dynamic> getMetadata() => {
        'pattern': <String, dynamic>{'label': 'Pattern', 'type': 'select', 'options': patternOptions},
        for (final spec in [
          ('scale', 'Pattern Size', 4, 64),
          ('spacing', 'Extra Spacing', 0.0, 16.0),
          ('thickness', 'Line / Shape Thickness', 0.05, 0.95),
          ('rotation', 'Rotation', 0.0, 360.0),
          ('stretch', 'Horizontal Stretch', 0.25, 4.0),
          ('offsetX', 'Horizontal Offset', -64.0, 64.0),
          ('offsetY', 'Vertical Offset', -64.0, 64.0),
          ('pixelSize', 'Pixel Size', 1, 8),
          ('variation', 'Color Variation', 0.0, 1.0),
          ('seed', 'Random Seed', 0, 9999),
          ('sourceBlend', 'Original Artwork Colors', 0.0, 1.0),
          ('opacity', 'Opacity', 0.0, 1.0),
        ])
          spec.$1: <String, dynamic>{
            'label': spec.$2,
            'type': 'slider',
            'min': spec.$3,
            'max': spec.$4,
            'divisions': spec.$3 is int ? (spec.$4 - spec.$3).toInt() : 100,
          },
        'foregroundColor': <String, dynamic>{'label': 'Pattern Color', 'type': 'color'},
        'backgroundColor': <String, dynamic>{'label': 'Background Color', 'type': 'color'},
        'invert': <String, dynamic>{'label': 'Invert Pattern', 'type': 'bool'},
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

  static double _fract(double v) => v - v.floor();
  static double _line(double v) => (_fract(v + 0.5) - 0.5).abs();

  static bool _mask(String pattern, double x, double y, double thickness, double fill, int seed) {
    final col = x.floor(), row = y.floor();
    final u = _fract(x), v = _fract(y);
    final ax = (u - 0.5).abs(), ay = (v - 0.5).abs();
    final t = thickness * fill * 0.5;
    final radius = (0.18 + thickness * 0.3) * fill;
    switch (pattern) {
      case 'stripes':
        return ax < t;
      case 'diagonal':
        return _line(x + y) < t;
      case 'grid':
        return ax < t || ay < t;
      case 'dots':
        return ax * ax + ay * ay < radius * radius;
      case 'rings':
        return (math.sqrt(ax * ax + ay * ay) - fill * 0.34).abs() < t * 0.5;
      case 'squares':
        return (math.max(ax, ay) - fill * 0.32).abs() < t * 0.5;
      case 'diamonds':
        return ax + ay < radius * 1.4;
      case 'crosses':
        return (ax < t && ay < fill * 0.4) || (ay < t && ax < fill * 0.4);
      case 'triangles':
        return v > 0.5 - radius && v < 0.5 + radius && ax < (v - 0.5 + radius) * 0.5;
      case 'stars':
        final angle = math.atan2(v - 0.5, u - 0.5);
        final starRadius = radius * (0.68 + 0.32 * math.cos(5 * (angle + math.pi / 2)));
        return ax * ax + ay * ay < starRadius * starRadius;
      case 'waves':
        return _line(y + math.sin(x * math.pi * 2) * 0.22) < t;
      case 'chevron':
        return _line(y - (_fract(x) - 0.5).abs() * 1.4) < t;
      case 'scallops':
        for (var dy = 0; dy <= 1; dy++) {
          final r = (y * 2).floor() - dy;
          final sx = x + (r.isOdd ? 0.5 : 0.0);
          final dx = _fract(sx) - 0.5, py = y - r * 0.5;
          if ((math.sqrt(dx * dx + py * py) - fill * 0.5).abs() < t * 0.6) return true;
        }
        return false;
      case 'weave':
        return (col + row).isEven ? ax < radius : ay < radius;
      case 'basket':
        return (col + row).isEven ? ax < fill * 0.43 && _line(v * 3) < t : ay < fill * 0.43 && _line(u * 3) < t;
      case 'hexagons':
        // Distance to nearest hex center on a staggered triangular lattice.
        var best = double.infinity;
        for (var dy = -1; dy <= 1; dy++) {
          final r = (y / 0.8660254).floor() + dy;
          final cx = (x - (r.isOdd ? 0.5 : 0.0)).round() + (r.isOdd ? 0.5 : 0.0);
          final dx = (x - cx).abs(), py = (y - r * 0.8660254).abs();
          best = math.min(best, math.max(dx, dx * 0.5 + py * 0.8660254));
        }
        return best > fill * 0.5 - t && best < fill * 0.5;
      case 'truchet':
        final flipped = _textureHash(col, row, seed) > 0.5;
        final px = flipped ? 1 - u : u;
        return (math.sqrt(px * px + v * v) - 0.5).abs() < t ||
            (math.sqrt((1 - px) * (1 - px) + (1 - v) * (1 - v)) - 0.5).abs() < t;
      case 'maze':
        return (_textureHash(col, row, seed) > 0.5 ? (u - v).abs() : (u + v - 1).abs()) < t;
      case 'confetti':
        final angle = _textureHash(col, row, seed) * math.pi;
        final dx = u - 0.5 - (_textureHash(col, row, seed + 7) - 0.5) * 0.3;
        final dy = v - 0.5 - (_textureHash(col, row, seed + 17) - 0.5) * 0.3;
        return (dx * math.cos(angle) + dy * math.sin(angle)).abs() < radius &&
            (-dx * math.sin(angle) + dy * math.cos(angle)).abs() < t;
      case 'checker':
      default:
        return (col + row).isEven && ax < fill * 0.5 && ay < fill * 0.5;
    }
  }

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    final output = Uint32List.fromList(pixels);
    if (width <= 0 || height <= 0) return output;
    final opacity = _number('opacity', 0, 1);
    if (opacity == 0) return output;
    final scale = _number('scale', 4, 64);
    final pitch = scale + _number('spacing', 0, 16);
    final fill = scale / pitch;
    final thickness = _number('thickness', 0.05, 0.95);
    final stretch = _number('stretch', 0.25, 4);
    final angle = _number('rotation', 0, 360) * math.pi / 180;
    final cosine = math.cos(angle), sine = math.sin(angle);
    final offsetX = _number('offsetX', -64, 64), offsetY = _number('offsetY', -64, 64);
    final pixelSize = _number('pixelSize', 1, 8).round();
    final variation = _number('variation', 0, 1);
    final seed = _number('seed', 0, 9999).round();
    final sourceBlend = _number('sourceBlend', 0, 1);
    final foreground = (parameters['foregroundColor'] as num).toInt();
    final background = (parameters['backgroundColor'] as num).toInt();
    final pattern = parameters['pattern'] as String? ?? 'checker';
    final invert = parameters['invert'] == true;
    final preserve = parameters['preserveAlpha'] != false;
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final i = y * width + x, source = pixels[y * width + x];
        final alpha = source >>> 24;
        if (preserve && alpha == 0) continue;
        final px = (x ~/ pixelSize) * pixelSize + pixelSize / 2 - offsetX;
        final py = (y ~/ pixelSize) * pixelSize + pixelSize / 2 - offsetY;
        final u = (px * cosine + py * sine) / (pitch * stretch);
        final v = (-px * sine + py * cosine) / pitch;
        final mask = _mask(pattern, u, v, thickness, fill, seed) != invert;
        final base = mask ? foreground : background;
        final shade = 1 + (_textureHash(u.floor(), v.floor(), seed + 31) - 0.5) * variation * 0.6;
        int channel(int shift) => (_textureChannel(base, shift) * shade).round().clamp(0, 255);
        var texture = 0xFF000000 | channel(16) << 16 | channel(8) << 8 | channel(0);
        texture = _textureBlendColor(texture, source, sourceBlend * alpha / 255, 255);
        final outAlpha = preserve ? alpha : (alpha + (255 - alpha) * opacity).round();
        output[i] = _textureBlendColor(source, texture, opacity, outAlpha);
      }
    }
    return output;
  }
}
