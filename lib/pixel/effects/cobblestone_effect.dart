part of 'effects.dart';

/// A seeded Voronoi pavement. Distances to cell bisectors keep mortar width
/// consistent even where differently sized stones meet.
class CobblestoneEffect extends Effect {
  CobblestoneEffect([Map<String, dynamic>? params]) : super(EffectType.cobblestone, {..._defaults, ...?params});

  static const _defaults = <String, dynamic>{
    'stoneSize': 12,
    'irregularity': 0.8,
    'roundness': 0.5,
    'mortarWidth': 1.0,
    'outlineWidth': 0.0,
    'outlineOpacity': 1.0,
    'outlineColor': 0xFF30322F,
    'relief': 0.65,
    'roughness': 0.35,
    'variation': 0.35,
    'moss': 0.15,
    'lightAngle': 225.0,
    'stoneColor': 0xFF92918A,
    'mortarColor': 0xFF48463E,
    'mossColor': 0xFF58673D,
    'seed': 42,
    'opacity': 1.0,
    'preserveAlpha': true,
  };

  @override
  Map<String, dynamic> getDefaultParameters() => Map.of(_defaults);

  @override
  Map<String, dynamic> getMetadata() => {
        for (final spec in [
          ('stoneSize', 'Stone Size', 4, 64),
          ('irregularity', 'Shape Irregularity', 0.0, 1.0),
          ('roundness', 'Rounded Corners', 0.0, 1.0),
          ('mortarWidth', 'Mortar Width', 0.0, 6.0),
          ('outlineWidth', 'Silhouette Outline Width', 0.0, 6.0),
          ('outlineOpacity', 'Outline Opacity', 0.0, 1.0),
          ('relief', 'Stone Relief', 0.0, 1.0),
          ('roughness', 'Surface Roughness', 0.0, 1.0),
          ('variation', 'Stone Color Variation', 0.0, 1.0),
          ('moss', 'Moss in Joints', 0.0, 1.0),
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
        'outlineColor': <String, dynamic>{
          'label': 'Outline Color',
          'type': 'color',
          'description':
              'Color along the inside edge of the original artwork, including transparent holes. Increase Silhouette Outline Width to show it.',
        },
        'stoneColor': <String, dynamic>{'label': 'Stone Color', 'type': 'color'},
        'mortarColor': <String, dynamic>{'label': 'Mortar Color', 'type': 'color'},
        'mossColor': <String, dynamic>{'label': 'Moss Color', 'type': 'color'},
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
    final size = _number('stoneSize', 4, 64);
    final jitter = _number('irregularity', 0, 1) * 0.35;
    final rounding = _number('roundness', 0, 1) * size * 0.22;
    final joint = math.min(_number('mortarWidth', 0, 6), size * 0.3) / 2;
    final outlineWidth = _number('outlineWidth', 0, 6);
    final outlineOpacity = _number('outlineOpacity', 0, 1);
    final outlineColor = (parameters['outlineColor'] as num).toInt();
    final relief = _number('relief', 0, 1);
    final roughness = _number('roughness', 0, 1);
    final variation = _number('variation', 0, 1);
    final moss = _number('moss', 0, 1);
    final angle = _number('lightAngle', 0, 360) * math.pi / 180;
    final lx = math.cos(angle), ly = math.sin(angle);
    final seed = _number('seed', 0, 9999).round();
    final stoneColor = (parameters['stoneColor'] as num).toInt();
    final mortarColor = (parameters['mortarColor'] as num).toInt();
    final mossColor = (parameters['mossColor'] as num).toInt();
    final preserve = parameters['preserveAlpha'] != false;

    // Measure the original alpha silhouette, before texture generation. A
    // capped chessboard distance gives crisp pixel-art outlines in linear time.
    final outlineDistances = Uint8List(width * height);
    if (outlineWidth > 0 && outlineOpacity > 0) {
      for (var y = 0; y < height; y++) {
        for (var x = 0; x < width; x++) {
          final i = y * width + x;
          if (pixels[i] >>> 24 == 0) continue;
          var distance = x == 0 || y == 0 || x == width - 1 || y == height - 1 ? 1 : 7;
          if (x > 0) distance = math.min(distance, outlineDistances[i - 1] + 1);
          if (y > 0) {
            distance = math.min(distance, outlineDistances[i - width] + 1);
            if (x > 0) distance = math.min(distance, outlineDistances[i - width - 1] + 1);
            if (x + 1 < width) distance = math.min(distance, outlineDistances[i - width + 1] + 1);
          }
          outlineDistances[i] = distance;
        }
      }
      for (var y = height - 1; y >= 0; y--) {
        for (var x = width - 1; x >= 0; x--) {
          final i = y * width + x;
          if (pixels[i] >>> 24 == 0) continue;
          var distance = outlineDistances[i];
          if (x + 1 < width) distance = math.min(distance, outlineDistances[i + 1] + 1);
          if (y + 1 < height) {
            distance = math.min(distance, outlineDistances[i + width] + 1);
            if (x > 0) distance = math.min(distance, outlineDistances[i + width - 1] + 1);
            if (x + 1 < width) distance = math.min(distance, outlineDistances[i + width + 1] + 1);
          }
          outlineDistances[i] = distance;
        }
      }
    }

    // Cache sites once; bounded jitter keeps the nearest site and all relevant
    // bisectors inside a 5x5 neighborhood, including beyond canvas edges.
    final cols = (width / size).ceil() + 6;
    final rows = (height / size).ceil() + 6;
    final sites = List.generate(cols * rows, (i) {
      final cx = i % cols - 3, cy = i ~/ cols - 3;
      return (
        x: (cx + 0.5 + (_textureHash(cx, cy, seed) * 2 - 1) * jitter) * size,
        y: (cy + 0.5 + (_textureHash(cx, cy, seed + 11) * 2 - 1) * jitter) * size,
        tint: (_textureHash(cx, cy, seed + 29) - 0.5) * variation * 0.7,
      );
    });
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final i = y * width + x, source = pixels[y * width + x];
        final alpha = source >>> 24;
        if (preserve && alpha == 0) continue;
        final px = x + 0.5, py = y + 0.5;
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
        var edge = double.infinity, secondEdge = double.infinity;
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
              secondEdge = edge;
              edge = distance;
              nx = dx / length;
              ny = dy / length;
            } else if (distance < secondEdge) {
              secondEdge = distance;
            }
          }
        }
        // Smooth minimum trims polygon corners without changing straight joints.
        if (rounding > 0) {
          final h = math.max(rounding - (secondEdge - edge), 0.0) / rounding;
          edge -= h * h * rounding * 0.25;
        }
        edge -= joint;
        final grain = _textureHash(x, y, seed + 53) - 0.5;
        final isMortar = edge < 0;
        var shade = isMortar ? 0.8 + grain * roughness * 0.18 : 1.0 + center.tint;
        if (!isMortar) {
          final bevel = (1 - edge / (size * 0.22)).clamp(0.0, 1.0);
          shade += relief * ((nx * lx + ny * ly) * bevel * 0.5 - bevel * 0.12);
          shade += grain * roughness * 0.25;
          shade += (_textureNoise(px * 0.2, py * 0.2, seed + 71) - 0.5) * roughness * 0.3;
        }
        var color = isMortar ? mortarColor : stoneColor;
        if (moss > 0 && edge < size * 0.12) {
          final patch = _textureNoise(px / size * 2, py / size * 2, seed + 97);
          final amount = ((patch - (1 - moss)) * 3).clamp(0.0, 1.0) * (1 - math.max(edge, 0.0) / (size * 0.12));
          color = _textureBlendColor(color, mossColor, amount, 255);
        }
        int channel(int shift) => (_textureChannel(color, shift) * shade).round().clamp(0, 255);
        var textured = 0xFF000000 | channel(16) << 16 | channel(8) << 8 | channel(0);
        // Inset outline of source pixels only, independent of stone boundaries.
        if (alpha > 0 && outlineWidth > 0 && outlineOpacity > 0) {
          final coverage = (outlineWidth - outlineDistances[i] + 1).clamp(0.0, 1.0);
          textured = _textureBlendColor(textured, outlineColor, outlineOpacity * coverage, 255);
        }
        final outAlpha = preserve ? alpha : (alpha + (255 - alpha) * opacity).round();
        output[i] = _textureBlendColor(source, textured, opacity, outAlpha);
      }
    }
    return output;
  }
}
