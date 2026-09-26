part of 'effects.dart';

/// Spawns jagged, branching electric lightning arcs that hug and dance across
/// the sprite's silhouette contour, leaping between extremities with glowing core sparks.
class ArcLightningEffect extends Effect {
  ArcLightningEffect([Map<String, dynamic>? params])
      : super(
          EffectType.arcLightning,
          params ??
              {
                'arcDensity': 0.6,
                'boltThickness': 1.5,
                'branchingProbability': 0.35,
                'electricPalette': 'teslaCyan',
                'crackleJitter': 1.5,
                'behindOnly': false,
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() => {
        'arcDensity': 0.6,
        'boltThickness': 1.5,
        'branchingProbability': 0.35,
        'electricPalette': 'teslaCyan',
        'crackleJitter': 1.5,
        'behindOnly': false,
      };

  @override
  Map<String, dynamic> getMetadata() => {
        'arcDensity': {
          'label': 'Arc Frequency & Density',
          'description': 'Number of active electric arc streams wrapping the contour.',
          'type': 'slider',
          'min': 0.2,
          'max': 1.0,
          'step': 0.05,
        },
        'boltThickness': {
          'label': 'Bolt Thickness & Glow',
          'description': 'Width of the luminous core bolt and outer voltage halo.',
          'type': 'slider',
          'min': 1.0,
          'max': 2.5,
          'step': 0.25,
        },
        'branchingProbability': {
          'label': 'Fork Branching Rate',
          'description': 'Chance of secondary lightning forks shooting outward from main arcs.',
          'type': 'slider',
          'min': 0.0,
          'max': 0.8,
          'step': 0.05,
        },
        'electricPalette': {
          'label': 'Voltage Energy Palette',
          'description': 'Coloration of the supercharged electric aura and outer glow.',
          'type': 'dropdown',
          'options': [
            {'value': 'teslaCyan', 'label': 'Tesla High-Voltage (Pure White / Electric Cyan / Cobalt)'},
            {'value': 'goldenThunder', 'label': 'Golden Thunder (Pure White / Brilliant Gold / Amber)'},
            {'value': 'darkPlasma', 'label': 'Dark Plasma (Pure White / Neon Magenta / Cyber Violet)'},
            {'value': 'jadeVolt', 'label': 'Toxic EMP (Pure White / Radioactive Lime / Emerald)'},
          ],
        },
        'crackleJitter': {
          'label': 'Crackle Jaggedness',
          'description': 'Midpoint displacement deviation and high-frequency arc jitter.',
          'type': 'slider',
          'min': 0.5,
          'max': 3.0,
          'step': 0.25,
        },
        'behindOnly': {
          'label': 'Render Behind Sprite',
          'description': 'Keep sprite in front; lightning arcs only leap through empty canvas space.',
          'type': 'bool',
        },
      };

  @override
  List<UIField> getFields() => [
        SliderField(
          key: 'arcDensity',
          label: 'Arc Frequency & Density',
          description: 'Number of active electric arc streams wrapping the contour.',
          min: 0.2,
          max: 1.0,
          divisions: 16,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        SliderField(
          key: 'boltThickness',
          label: 'Bolt Thickness & Glow',
          description: 'Width of the luminous core bolt and outer voltage halo.',
          min: 1.0,
          max: 2.5,
          divisions: 6,
          formatLabel: (v) => '${v.toStringAsFixed(2)}px',
        ),
        SliderField(
          key: 'branchingProbability',
          label: 'Fork Branching Rate',
          description: 'Chance of secondary lightning forks shooting outward from main arcs.',
          min: 0.0,
          max: 0.8,
          divisions: 16,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        const SelectField(
          key: 'electricPalette',
          label: 'Voltage Energy Palette',
          description: 'Coloration of the supercharged electric aura and outer glow.',
          options: {
            'teslaCyan': 'Tesla High-Voltage (Pure White / Electric Cyan / Cobalt)',
            'goldenThunder': 'Golden Thunder (Pure White / Brilliant Gold / Amber)',
            'darkPlasma': 'Dark Plasma (Pure White / Neon Magenta / Cyber Violet)',
            'jadeVolt': 'Toxic EMP (Pure White / Radioactive Lime / Emerald)',
          },
        ),
        SliderField(
          key: 'crackleJitter',
          label: 'Crackle Jaggedness',
          description: 'Midpoint displacement deviation and high-frequency arc jitter.',
          min: 0.5,
          max: 3.0,
          divisions: 10,
          formatLabel: (v) => v.toStringAsFixed(1),
        ),
        const BoolField(
          key: 'behindOnly',
          label: 'Render Behind Sprite',
          description: 'Keep sprite in front; lightning arcs only leap through empty canvas space.',
        ),
      ];

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    final output = Uint32List(width * height);
    output.setAll(0, pixels);

    final double density = ((parameters['arcDensity'] as num?)?.toDouble() ?? 0.6).clamp(0.2, 1.0);
    final double thickness = ((parameters['boltThickness'] as num?)?.toDouble() ?? 1.5).clamp(1.0, 2.5);
    final double branchProb = ((parameters['branchingProbability'] as num?)?.toDouble() ?? 0.35).clamp(0.0, 0.8);
    final String palette = parameters['electricPalette'] as String? ?? 'teslaCyan';
    final double jitter = ((parameters['crackleJitter'] as num?)?.toDouble() ?? 1.5).clamp(0.5, 3.0);
    final bool behindOnly = parameters['behindOnly'] as bool? ?? false;

    final colors = _getPaletteColors(palette);

    // 1. Locate boundary pixels and detect sharp extremities / corners
    final List<math.Point<int>> extremities = [];
    final List<math.Point<int>> allBoundary = [];

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int p = pixels[y * width + x];
        if (((p >> 24) & 0xFF) == 0) continue;

        // Count opaque neighbors among 8-neighborhood
        int opaqueNeighbors = 0;
        bool hasTransparentNeighbor = false;

        for (int dy = -1; dy <= 1; dy++) {
          for (int dx = -1; dx <= 1; dx++) {
            if (dx == 0 && dy == 0) continue;
            final int nx = x + dx;
            final int ny = y + dy;
            if (nx >= 0 && nx < width && ny >= 0 && ny < height) {
              if (((pixels[ny * width + nx] >> 24) & 0xFF) > 0) {
                opaqueNeighbors++;
              } else {
                hasTransparentNeighbor = true;
              }
            } else {
              hasTransparentNeighbor = true;
            }
          }
        }

        if (hasTransparentNeighbor) {
          final pt = math.Point(x, y);
          allBoundary.add(pt);

          // Protruding tips or sharp convex corners have <= 4 opaque neighbors
          if (opaqueNeighbors <= 4) {
            bool tooClose = false;
            for (final ex in extremities) {
              if ((ex.x - x).abs() <= 2 && (ex.y - y).abs() <= 2) {
                tooClose = true;
                break;
              }
            }
            if (!tooClose) {
              extremities.add(pt);
            }
          }
        }
      }
    }

    if (allBoundary.isEmpty) {
      return output;
    }

    // Fall back to sampled boundary pixels if few extremities found
    final List<math.Point<int>> nodes = extremities.length >= 3 ? extremities : allBoundary;
    if (nodes.length > 14) {
      // Keep a well-distributed subset
      final step = (nodes.length / 12).ceil();
      final filtered = <math.Point<int>>[];
      for (int i = 0; i < nodes.length; i += step) {
        filtered.add(nodes[i]);
      }
      nodes.clear();
      nodes.addAll(filtered);
    }

    // 2. Generate electric arcs connecting nodes
    final int arcCount = (nodes.length * density * 1.5).round().clamp(2, nodes.length * 2);

    for (int a = 0; a < arcCount; a++) {
      final int idx1 = (a * 3) % nodes.length;
      final int idx2 = (idx1 + 1 + ((_hash(a * 43) * (nodes.length - 2)).round())) % nodes.length;
      if (idx1 == idx2) continue;

      final p1 = nodes[idx1];
      final p2 = nodes[idx2];

      _drawFractalBolt(
        output,
        pixels,
        width,
        height,
        p1.x.toDouble(),
        p1.y.toDouble(),
        p2.x.toDouble(),
        p2.y.toDouble(),
        jitter,
        branchProb,
        thickness,
        colors,
        behindOnly,
        depth: 0,
      );
    }

    // 3. Draw luminous spark nodes at extremities
    for (final ex in extremities) {
      if (behindOnly && ((pixels[ex.y * width + ex.x] >> 24) & 0xFF) > 0) continue;
      _blendPixel(output, ex.y * width + ex.x, 0xFFFFFFFF, 255);
      if (thickness >= 1.5) {
        for (int dy = -1; dy <= 1; dy++) {
          for (int dx = -1; dx <= 1; dx++) {
            if (dx == 0 && dy == 0) continue;
            final int sx = ex.x + dx;
            final int sy = ex.y + dy;
            if (sx >= 0 && sx < width && sy >= 0 && sy < height) {
              final int sIdx = sy * width + sx;
              if (!behindOnly || ((pixels[sIdx] >> 24) & 0xFF) == 0) {
                _blendPixel(output, sIdx, colors.coreGlow, 180);
              }
            }
          }
        }
      }
    }

    return output;
  }

  static void _drawFractalBolt(
    Uint32List output,
    Uint32List originalPixels,
    int width,
    int height,
    double x1,
    double y1,
    double x2,
    double y2,
    double jitter,
    double branchProb,
    double thickness,
    _LightningPalette colors,
    bool behindOnly, {
    required int depth,
  }) {
    final double dx = x2 - x1;
    final double dy = y2 - y1;
    final double dist = math.sqrt(dx * dx + dy * dy);

    if (dist <= 2.0 || depth >= 4) {
      // Rasterize segment line
      final int steps = dist.ceil().clamp(1, 3);
      for (int s = 0; s <= steps; s++) {
        final double t = s / steps;
        final int px = (x1 + dx * t).round();
        final int py = (y1 + dy * t).round();

        if (px >= 0 && px < width && py >= 0 && py < height) {
          final int idx = py * width + px;
          if (!behindOnly || ((originalPixels[idx] >> 24) & 0xFF) == 0) {
            // Intense white core
            _blendPixel(output, idx, 0xFFFFFFFF, 255);

            // Voltage halo glow
            if (thickness >= 1.25) {
              const offsets = [
                [-1, 0],
                [1, 0],
                [0, -1],
                [0, 1]
              ];
              for (final o in offsets) {
                final int gx = px + o[0];
                final int gy = py + o[1];
                if (gx >= 0 && gx < width && gy >= 0 && gy < height) {
                  final int gIdx = gy * width + gx;
                  if (!behindOnly || ((originalPixels[gIdx] >> 24) & 0xFF) == 0) {
                    _blendPixel(output, gIdx, colors.coreGlow, 160);
                  }
                }
              }
            }
          }
        }
      }
      return;
    }

    // Midpoint displacement perpendicular to segment
    final double midX = (x1 + x2) * 0.5;
    final double midY = (y1 + y2) * 0.5;

    // Normal vector
    final double nx = -dy / dist;
    final double ny = dx / dist;

    final double seed = _hash((x1.round() * 73 + y1.round() * 37 + depth * 13));
    final double displacement = (seed - 0.5) * jitter * dist * 0.35;

    final double displacedX = midX + nx * displacement;
    final double displacedY = midY + ny * displacement;

    // Recurse first half
    _drawFractalBolt(
      output,
      originalPixels,
      width,
      height,
      x1,
      y1,
      displacedX,
      displacedY,
      jitter,
      branchProb,
      thickness,
      colors,
      behindOnly,
      depth: depth + 1,
    );

    // Recurse second half
    _drawFractalBolt(
      output,
      originalPixels,
      width,
      height,
      displacedX,
      displacedY,
      x2,
      y2,
      jitter,
      branchProb,
      thickness,
      colors,
      behindOnly,
      depth: depth + 1,
    );

    // Random fork branch offshoot
    if (depth <= 2 && _hash(x1.round() * 101 + y1.round() * 179 + depth) < branchProb) {
      final double branchAngle = (_hash(depth * 97) - 0.5) * 1.2;
      final double cosA = math.cos(branchAngle);
      final double sinA = math.sin(branchAngle);

      final double branchLen = dist * 0.5;
      final double bdx = (dx * cosA - dy * sinA) / dist * branchLen;
      final double bdy = (dx * sinA + dy * cosA) / dist * branchLen;

      _drawFractalBolt(
        output,
        originalPixels,
        width,
        height,
        displacedX,
        displacedY,
        displacedX + bdx,
        displacedY + bdy,
        jitter * 0.8,
        0.0,
        1.0,
        colors,
        behindOnly,
        depth: depth + 2,
      );
    }
  }

  static _LightningPalette _getPaletteColors(String palette) {
    switch (palette) {
      case 'goldenThunder':
        return const _LightningPalette(
          coreGlow: 0xFFFFD700, // Brilliant gold
          outerAura: 0xFFFF9100, // Amber
        );
      case 'darkPlasma':
        return const _LightningPalette(
          coreGlow: 0xFFFF007F, // Hot neon magenta
          outerAura: 0xFF7C4DFF, // Cyber violet
        );
      case 'jadeVolt':
        return const _LightningPalette(
          coreGlow: 0xFF76FF03, // Radioactive lime
          outerAura: 0xFF00C853, // Emerald green
        );
      case 'teslaCyan':
      default:
        return const _LightningPalette(
          coreGlow: 0xFF00E5FF, // Electric cyan
          outerAura: 0xFF0066FF, // Deep cobalt
        );
    }
  }

  static void _blendPixel(Uint32List buffer, int idx, int color, int a) {
    final int curP = buffer[idx];
    final int curA = (curP >> 24) & 0xFF;

    final int r = (color >> 16) & 0xFF;
    final int g = (color >> 8) & 0xFF;
    final int b = color & 0xFF;

    if (curA == 0) {
      buffer[idx] = (a << 24) | (r << 16) | (g << 8) | b;
    } else {
      final double na = a / 255.0;
      final int curR = (curP >> 16) & 0xFF;
      final int curG = (curP >> 8) & 0xFF;
      final int curB = curP & 0xFF;

      final int outR = math.max(curR, (r * na).round());
      final int outG = math.max(curG, (g * na).round());
      final int outB = math.max(curB, (b * na).round());
      final int outA = math.max(curA, a);

      buffer[idx] = (outA << 24) | (outR << 16) | (outG << 8) | outB;
    }
  }

  static double _hash(int n) {
    int x = (n << 13) ^ n;
    x = (x * (x * x * 15731 + 789221) + 1376312589) & 0x7fffffff;
    return x / 2147483647.0;
  }
}

class _LightningPalette {
  final int coreGlow;
  final int outerAura;

  const _LightningPalette({
    required this.coreGlow,
    required this.outerAura,
  });
}
