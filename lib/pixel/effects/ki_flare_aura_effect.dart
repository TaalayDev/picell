part of 'effects.dart';

/// Spawns a blazing combat energy aura enveloping the sprite with roaring
/// vertical heat plumes, glowing silhouette back-illumination, and floating Ki particles.
class KiFlareAuraEffect extends Effect {
  KiFlareAuraEffect([Map<String, dynamic>? params])
      : super(
          EffectType.kiFlareAura,
          params ??
              {
                'auraRadius': 6.0,
                'flameSway': 0.6,
                'auraPalette': 'superSaiyanGold',
                'innerRimIllumination': 0.5,
                'energyMotes': true,
                'behindOnly': false,
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() => {
        'auraRadius': 6.0,
        'flameSway': 0.6,
        'auraPalette': 'superSaiyanGold',
        'innerRimIllumination': 0.5,
        'energyMotes': true,
        'behindOnly': false,
      };

  @override
  Map<String, dynamic> getMetadata() => {
        'auraRadius': {
          'label': 'Aura Flame Reach',
          'description': 'Maximum distance of exterior blazing energy plumes.',
          'type': 'slider',
          'min': 2.0,
          'max': 12.0,
          'step': 0.5,
        },
        'flameSway': {
          'label': 'Aura Roar & Vertical Sway',
          'description': 'Turbulent upward flare and sinusoidal flame tongues.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'step': 0.05,
        },
        'auraPalette': {
          'label': 'Fighting Ki Palette',
          'description': 'Combustion energy and battle power tier coloration.',
          'type': 'dropdown',
          'options': [
            {'value': 'superSaiyanGold', 'label': 'Super Saiyan Gold (Pure White / Brilliant Gold / Amber)'},
            {'value': 'dragonRageRed', 'label': 'Kaioken Rage (White / Hot Pink / Crimson / Burgundy)'},
            {'value': 'ultraInstinctSilver', 'label': 'Ultra Instinct Silver (White / Silver / Platinum)'},
            {'value': 'spiritCyan', 'label': 'Spirit Ki God (White / Vivid Cyan / Cobalt / Violet)'},
          ],
        },
        'innerRimIllumination': {
          'label': 'Character Rim Glow',
          'description': 'Intensity of radiant light cast back onto the sprite contours.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'step': 0.05,
        },
        'energyMotes': {
          'label': 'Floating Energy Motes',
          'description': 'Luminous floating Ki sparks rising around the aura perimeter.',
          'type': 'bool',
        },
        'behindOnly': {
          'label': 'Render Behind Sprite',
          'description': 'Keep sprite in front; aura flames only burn behind in empty canvas space.',
          'type': 'bool',
        },
      };

  @override
  List<UIField> getFields() => [
        SliderField(
          key: 'auraRadius',
          label: 'Aura Flame Reach',
          description: 'Maximum distance of exterior blazing energy plumes.',
          min: 2.0,
          max: 12.0,
          divisions: 20,
          formatLabel: (v) => '${v.toStringAsFixed(1)}px',
        ),
        SliderField(
          key: 'flameSway',
          label: 'Aura Roar & Vertical Sway',
          description: 'Turbulent upward flare and sinusoidal flame tongues.',
          min: 0.0,
          max: 1.0,
          divisions: 20,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        const SelectField(
          key: 'auraPalette',
          label: 'Fighting Ki Palette',
          description: 'Combustion energy and battle power tier coloration.',
          options: {
            'superSaiyanGold': 'Super Saiyan Gold (Pure White / Brilliant Gold / Amber)',
            'dragonRageRed': 'Kaioken Rage (White / Hot Pink / Crimson / Burgundy)',
            'ultraInstinctSilver': 'Ultra Instinct Silver (White / Silver / Platinum)',
            'spiritCyan': 'Spirit Ki God (White / Vivid Cyan / Cobalt / Violet)',
          },
        ),
        SliderField(
          key: 'innerRimIllumination',
          label: 'Character Rim Glow',
          description: 'Intensity of radiant light cast back onto the sprite contours.',
          min: 0.0,
          max: 1.0,
          divisions: 20,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        const BoolField(
          key: 'energyMotes',
          label: 'Floating Energy Motes',
          description: 'Luminous floating Ki sparks rising around the aura perimeter.',
        ),
        const BoolField(
          key: 'behindOnly',
          label: 'Render Behind Sprite',
          description: 'Keep sprite in front; aura flames only burn behind in empty canvas space.',
        ),
      ];

  static const List<List<int>> _bayer4x4 = [
    [0, 8, 2, 10],
    [12, 4, 14, 6],
    [3, 11, 1, 9],
    [15, 7, 13, 5],
  ];

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    final output = Uint32List(width * height);
    output.setAll(0, pixels);

    final double radius = ((parameters['auraRadius'] as num?)?.toDouble() ?? 6.0).clamp(2.0, 12.0);
    final double sway = ((parameters['flameSway'] as num?)?.toDouble() ?? 0.6).clamp(0.0, 1.0);
    final String palette = parameters['auraPalette'] as String? ?? 'superSaiyanGold';
    final double rimGlow = ((parameters['innerRimIllumination'] as num?)?.toDouble() ?? 0.5).clamp(0.0, 1.0);
    final bool motes = parameters['energyMotes'] as bool? ?? true;
    final bool behindOnly = parameters['behindOnly'] as bool? ?? false;

    final colors = _getAuraColors(palette);

    // 1. Collect boundary pixels of sprite
    final List<math.Point<int>> boundary = [];
    final List<int> interiorEdges = [];

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int p = pixels[y * width + x];
        if (((p >> 24) & 0xFF) == 0) continue;

        bool hasTransparentNeighbor = false;
        for (int dy = -1; dy <= 1; dy++) {
          for (int dx = -1; dx <= 1; dx++) {
            if (dx == 0 && dy == 0) continue;
            final int nx = x + dx;
            final int ny = y + dy;
            if (nx < 0 || nx >= width || ny < 0 || ny >= height ||
                ((pixels[ny * width + nx] >> 24) & 0xFF) == 0) {
              hasTransparentNeighbor = true;
              break;
            }
          }
          if (hasTransparentNeighbor) break;
        }

        if (hasTransparentNeighbor) {
          boundary.add(math.Point(x, y));
          interiorEdges.add(y * width + x);
        }
      }
    }

    if (boundary.isEmpty) {
      return output;
    }

    // 2. Render Exterior Ki Aura Flames
    final double searchRad = radius * 1.5;
    final int searchInt = searchRad.ceil();

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int idx = y * width + x;
        final int p = pixels[idx];
        if (((p >> 24) & 0xFF) > 0) continue; // Skip sprite interior

        // Find distance to closest boundary pixel
        double minDistSq = double.infinity;
        for (final b in boundary) {
          final int dx = b.x - x;
          final int dy = b.y - y;
          if (dx.abs() > searchInt || dy.abs() > searchInt) continue;
          final double dsq = (dx * dx + dy * dy).toDouble();
          if (dsq < minDistSq) {
            minDistSq = dsq;
          }
        }

        final double d = math.sqrt(minDistSq);
        if (d > searchRad) continue;

        // Upward flame tongues modulation
        final double wave = math.sin(y * 0.45 + _hash(x * 47 + 13) * 3.5) * sway * 1.7;
        final double upwardStretch = 1.0 + 0.3 * (1.0 - y / height).clamp(0.0, 1.0);
        final double effectiveRadius = math.max(1.5, radius * upwardStretch + wave);

        if (d <= effectiveRadius) {
          final double t = (d / effectiveRadius).clamp(0.0, 1.0);

          // Bayer 4x4 dither near outer boundary
          if (t > 0.72) {
            final int bThreshold = _bayer4x4[y % 4][x % 4];
            if ((1.0 - t) * 16.0 < bThreshold * 0.45) {
              continue;
            }
          }

          final int col = t < 0.28
              ? 0xFFFFFFFF // Hot core
              : (t < 0.65 ? colors.core : colors.flame);

          final int alpha = ((1.0 - t * 0.65) * 230.0).round().clamp(0, 255);
          _blendPixel(output, idx, col, alpha);
        } else if (motes && d <= effectiveRadius + 3.0) {
          // Floating energy motes rising in aura outskirts
          final double mHash = _hash(x * 127 + y * 79 + 31);
          if (mHash > 0.94) {
            _blendPixel(output, idx, colors.core, 240);
          }
        }
      }
    }

    // 3. Apply Inner Rim Illumination onto character contours
    if (rimGlow > 0.05 && !behindOnly) {
      for (final edgeIdx in interiorEdges) {
        final int origP = pixels[edgeIdx];
        final int srcA = (origP >> 24) & 0xFF;
        if (srcA == 0) continue;

        final int rimAlpha = (rimGlow * 160.0).round().clamp(0, 255);
        final int rimCol = colors.core;

        final double rA = rimAlpha / 255.0;
        final int sr = (origP >> 16) & 0xFF;
        final int sg = (origP >> 8) & 0xFF;
        final int sb = origP & 0xFF;

        final int rr = (rimCol >> 16) & 0xFF;
        final int rg = (rimCol >> 8) & 0xFF;
        final int rb = rimCol & 0xFF;

        final int outR = (rr * rA + sr * (1.0 - rA)).round().clamp(0, 255);
        final int outG = (rg * rA + sg * (1.0 - rA)).round().clamp(0, 255);
        final int outB = (rb * rA + sb * (1.0 - rA)).round().clamp(0, 255);

        output[edgeIdx] = (srcA << 24) | (outR << 16) | (outG << 8) | outB;
      }
    }

    return output;
  }

  static _AuraPalette _getAuraColors(String palette) {
    switch (palette) {
      case 'dragonRageRed':
        return const _AuraPalette(
          core: 0xFFFF1744, // Intense Kaioken hot pink / red
          flame: 0xFFB71C1C, // Deep crimson burgundy
        );
      case 'ultraInstinctSilver':
        return const _AuraPalette(
          core: 0xFFE0F7FA, // Platinum silver blue
          flame: 0xFF90A4AE, // Shimmering silver mist
        );
      case 'spiritCyan':
        return const _AuraPalette(
          core: 0xFF00E5FF, // Radiant cyan
          flame: 0xFF2979FF, // Cobalt blue
        );
      case 'superSaiyanGold':
      default:
        return const _AuraPalette(
          core: 0xFFFFD700, // Brilliant gold
          flame: 0xFFFF6D00, // Fiery amber glow
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

class _AuraPalette {
  final int core;
  final int flame;

  const _AuraPalette({
    required this.core,
    required this.flame,
  });
}
