part of 'effects.dart';

/// Spawns sharp polygonal diamond and rhombus crystal shards hovering outside
/// the sprite silhouette, reflecting light with faceted shading and sparkle glints.
class CrystalShardReflectorEffect extends Effect {
  CrystalShardReflectorEffect([Map<String, dynamic>? params])
      : super(
          EffectType.crystalShardReflector,
          params ??
              {
                'shardCount': 7,
                'orbitDistance': 4.0,
                'shardSize': 4.0,
                'crystalPalette': 'prismaticDiamond',
                'sparkleGlints': true,
                'behindOnly': false,
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() => {
        'shardCount': 7,
        'orbitDistance': 4.0,
        'shardSize': 4.0,
        'crystalPalette': 'prismaticDiamond',
        'sparkleGlints': true,
        'behindOnly': false,
      };

  @override
  Map<String, dynamic> getMetadata() => {
        'shardCount': {
          'label': 'Crystal Shard Count',
          'description': 'Number of floating crystal facets hovering around the sprite.',
          'type': 'slider',
          'min': 3.0,
          'max': 16.0,
          'step': 1.0,
        },
        'orbitDistance': {
          'label': 'Hover Orbit Distance',
          'description': 'Distance from sprite contour to the crystal centers.',
          'type': 'slider',
          'min': 2.0,
          'max': 10.0,
          'step': 0.5,
        },
        'shardSize': {
          'label': 'Shard Scale',
          'description': 'Geometric size of each faceted diamond shard.',
          'type': 'slider',
          'min': 2.5,
          'max': 7.0,
          'step': 0.5,
        },
        'crystalPalette': {
          'label': 'Refraction Gem Palette',
          'description': 'Gemstone mineral type and prismatic light refraction theme.',
          'type': 'dropdown',
          'options': [
            {'value': 'prismaticDiamond', 'label': 'Prismatic Diamond (Ice Cyan / Crystal White / Azure)'},
            {'value': 'bloodRuby', 'label': 'Blood Ruby (Crimson / Magenta / Wine Red)'},
            {'value': 'abyssalObsidian', 'label': 'Abyssal Obsidian (Deep Violet / Neon Purple / Black)'},
            {'value': 'sacredTopaz', 'label': 'Sacred Topaz (Radiant Sun Gold / Amber / Honey)'},
          ],
        },
        'sparkleGlints': {
          'label': 'Apex Sparkle Glints',
          'description': 'Renders bright 1px cross-sparkles at shard vertices.',
          'type': 'bool',
        },
        'behindOnly': {
          'label': 'Render Behind Sprite',
          'description': 'When enabled, renders shards strictly behind existing sprite pixels.',
          'type': 'bool',
        },
      };

  @override
  List<UIField> getFields() => [
        SliderField(
          key: 'shardCount',
          label: 'Crystal Shard Count',
          description: 'Number of floating crystal facets hovering around the sprite.',
          min: 3.0,
          max: 16.0,
          divisions: 13,
          formatLabel: (v) => '${v.round()} shards',
        ),
        SliderField(
          key: 'orbitDistance',
          label: 'Hover Orbit Distance',
          description: 'Distance from sprite contour to the crystal centers.',
          min: 2.0,
          max: 10.0,
          divisions: 16,
          formatLabel: (v) => '${v.toStringAsFixed(1)}px',
        ),
        SliderField(
          key: 'shardSize',
          label: 'Shard Scale',
          description: 'Geometric size of each faceted diamond shard.',
          min: 2.5,
          max: 7.0,
          divisions: 9,
          formatLabel: (v) => '${v.toStringAsFixed(1)}px',
        ),
        const SelectField(
          key: 'crystalPalette',
          label: 'Refraction Gem Palette',
          description: 'Gemstone mineral type and prismatic light refraction theme.',
          options: {
            'prismaticDiamond': 'Prismatic Diamond (Ice Cyan / Azure)',
            'bloodRuby': 'Blood Ruby (Crimson / Wine Red)',
            'abyssalObsidian': 'Abyssal Obsidian (Violet / Neon Purple)',
            'sacredTopaz': 'Sacred Topaz (Sun Gold / Amber)',
          },
        ),
        const BoolField(
          key: 'sparkleGlints',
          label: 'Apex Sparkle Glints',
          description: 'Renders bright 1px cross-sparkles at shard vertices.',
        ),
        const BoolField(
          key: 'behindOnly',
          label: 'Render Behind Sprite',
          description: 'When enabled, renders shards strictly behind existing sprite pixels.',
        ),
      ];

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    final output = Uint32List(width * height);
    output.setAll(0, pixels);

    final shardCount = ((parameters['shardCount'] as num?)?.toInt() ?? 7).clamp(3, 16);
    final orbitDistance = ((parameters['orbitDistance'] as num?)?.toDouble() ?? 4.0).clamp(2.0, 10.0);
    final shardSize = ((parameters['shardSize'] as num?)?.toDouble() ?? 4.0).clamp(2.5, 7.0);
    final paletteKey = parameters['crystalPalette'] as String? ?? 'prismaticDiamond';
    final sparkleGlints = parameters['sparkleGlints'] as bool? ?? true;
    final behindOnly = parameters['behindOnly'] as bool? ?? false;

    // Scan sprite bounds and contour boundary pixels
    final contourPoints = <math.Point<int>>[];
    double sumX = 0, sumY = 0;
    int solidCount = 0;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final p = pixels[y * width + x];
        final a = (p >> 24) & 0xFF;
        if (a > 20) {
          sumX += x;
          sumY += y;
          solidCount++;

          // Check if boundary
          bool isBoundary = false;
          const dx = [0, 0, -1, 1];
          const dy = [-1, 1, 0, 0];
          for (int i = 0; i < 4; i++) {
            final nx = x + dx[i];
            final ny = y + dy[i];
            if (nx < 0 || nx >= width || ny < 0 || ny >= height) {
              isBoundary = true;
              break;
            }
            final na = (pixels[ny * width + nx] >> 24) & 0xFF;
            if (na <= 20) {
              isBoundary = true;
              break;
            }
          }
          if (isBoundary) {
            contourPoints.add(math.Point(x, y));
          }
        }
      }
    }

    if (contourPoints.isEmpty || solidCount == 0) {
      return output;
    }

    final centerX = sumX / solidCount;
    final centerY = sumY / solidCount;
    final colors = _getCrystalColors(paletteKey);

    // Group contour points into radial shards
    final stepAngle = (2.0 * math.pi) / math.max(1, shardCount);

    for (int i = 0; i < shardCount; i++) {
      final targetAngle = i * stepAngle;
      final targetCos = math.cos(targetAngle);
      final targetSin = math.sin(targetAngle);

      // Find contour point furthest in direction of targetAngle
      math.Point<int>? bestPoint;
      double maxProj = -double.infinity;

      for (final p in contourPoints) {
        final proj = (p.x - centerX) * targetCos + (p.y - centerY) * targetSin;
        if (proj > maxProj) {
          maxProj = proj;
          bestPoint = p;
        }
      }

      if (bestPoint == null) continue;

      // Normal vector pointing outward from center
      double nx = bestPoint.x - centerX;
      double ny = bestPoint.y - centerY;
      final len = math.sqrt(nx * nx + ny * ny);
      if (len > 0.001) {
        nx /= len;
        ny /= len;
      } else {
        nx = targetCos;
        ny = targetSin;
      }

      // Shard center position
      final sx = bestPoint.x + nx * orbitDistance;
      final sy = bestPoint.y + ny * orbitDistance;

      // Tangent vector
      final tx = -ny;
      final ty = nx;

      // Draw faceted diamond shard
      final halfLen = shardSize;
      final halfWidth = shardSize * 0.55;

      // Diamond bounds
      final minBoundX = (sx - shardSize - 2).floor().clamp(0, width - 1);
      final maxBoundX = (sx + shardSize + 2).ceil().clamp(0, width - 1);
      final minBoundY = (sy - shardSize - 2).floor().clamp(0, height - 1);
      final maxBoundY = (sy + shardSize + 2).ceil().clamp(0, height - 1);

      for (int py = minBoundY; py <= maxBoundY; py++) {
        for (int px = minBoundX; px <= maxBoundX; px++) {
          final idx = py * width + px;
          final origPixel = pixels[idx];
          final origAlpha = (origPixel >> 24) & 0xFF;
          if (behindOnly && origAlpha > 30) {
            continue;
          }

          // Local coordinates aligned with normal and tangent
          final relX = px - sx;
          final relY = py - sy;

          final u = relX * nx + relY * ny; // Along normal (length)
          final v = relX * tx + relY * ty; // Along tangent (width)

          // Rhombus diamond interior condition: |u| / halfLen + |v| / halfWidth <= 1.0
          final d = (u.abs() / halfLen) + (v.abs() / halfWidth);

          if (d <= 1.0) {
            int shardColor;

            // Specular ridge along central normal line
            if (v.abs() <= 0.65) {
              shardColor = colors.specular;
            } else if (u >= 0 && v > 0) {
              shardColor = colors.highlight;
            } else if (u >= 0 && v < 0) {
              shardColor = colors.primary;
            } else if (u < 0 && v > 0) {
              shardColor = colors.primary;
            } else {
              shardColor = colors.shadow;
            }

            output[idx] = _blendPixel(output[idx], shardColor);
          }
        }
      }

      // Sparkle cross glints at outer apex
      if (sparkleGlints) {
        final apexX = (sx + nx * halfLen).round();
        final apexY = (sy + ny * halfLen).round();

        _drawSparkle(output, pixels, width, height, apexX, apexY, colors.sparkle, behindOnly);
      }
    }

    return output;
  }

  void _drawSparkle(
    Uint32List output,
    Uint32List original,
    int width,
    int height,
    int cx,
    int cy,
    int color,
    bool behindOnly,
  ) {
    void setSparklePixel(int x, int y, int alpha) {
      if (x < 0 || x >= width || y < 0 || y >= height) return;
      final idx = y * width + x;
      if (behindOnly && ((original[idx] >> 24) & 0xFF) > 30) return;
      final tinted = (alpha << 24) | (color & 0x00FFFFFF);
      output[idx] = _blendPixel(output[idx], tinted);
    }

    // Center core
    setSparklePixel(cx, cy, 255);
    // 1px cross arms
    setSparklePixel(cx - 1, cy, 180);
    setSparklePixel(cx + 1, cy, 180);
    setSparklePixel(cx, cy - 1, 180);
    setSparklePixel(cx, cy + 1, 180);
  }

  int _blendPixel(int dst, int src) {
    final sa = (src >> 24) & 0xFF;
    if (sa == 0) return dst;
    if (sa == 255) return src;
    final da = (dst >> 24) & 0xFF;
    if (da == 0) return src;

    final sf = sa / 255.0;
    final df = (da / 255.0) * (1.0 - sf);
    final outA = sf + df;
    if (outA <= 0.0) return 0;

    final sr = (src >> 16) & 0xFF;
    final sg = (src >> 8) & 0xFF;
    final sb = src & 0xFF;

    final dr = (dst >> 16) & 0xFF;
    final dg = (dst >> 8) & 0xFF;
    final db = dst & 0xFF;

    final r = ((sr * sf + dr * df) / outA).round().clamp(0, 255);
    final g = ((sg * sf + dg * df) / outA).round().clamp(0, 255);
    final b = ((sb * sf + db * df) / outA).round().clamp(0, 255);
    final a = (outA * 255.0).round().clamp(0, 255);

    return (a << 24) | (r << 16) | (g << 8) | b;
  }

  _CrystalColors _getCrystalColors(String key) {
    switch (key) {
      case 'bloodRuby':
        return const _CrystalColors(
          specular: 0xFFFF80AB,
          highlight: 0xFFFF1744,
          primary: 0xFFC2185B,
          shadow: 0xFF880E4F,
          sparkle: 0xFFFFF0F5,
        );
      case 'abyssalObsidian':
        return const _CrystalColors(
          specular: 0xFFE1BEE7,
          highlight: 0xFFAA00FF,
          primary: 0xFF4A148C,
          shadow: 0xFF1A1A2E,
          sparkle: 0xFFFFFFFF,
        );
      case 'sacredTopaz':
        return const _CrystalColors(
          specular: 0xFFFFF9C4,
          highlight: 0xFFFFD700,
          primary: 0xFFFFA000,
          shadow: 0xFFE65100,
          sparkle: 0xFFFFFFFF,
        );
      case 'prismaticDiamond':
      default:
        return const _CrystalColors(
          specular: 0xFFFFFFFF,
          highlight: 0xFFE0F7FA,
          primary: 0xFF80DEEA,
          shadow: 0xFF0097A7,
          sparkle: 0xFFFFFFFF,
        );
    }
  }
}

class _CrystalColors {
  final int specular;
  final int highlight;
  final int primary;
  final int shadow;
  final int sparkle;

  const _CrystalColors({
    required this.specular,
    required this.highlight,
    required this.primary,
    required this.shadow,
    required this.sparkle,
  });
}
