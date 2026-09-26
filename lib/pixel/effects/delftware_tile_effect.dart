part of 'effects.dart';

/// An effect that procedurally transforms an image into a traditional Dutch
/// Delft blue-and-white tin-glazed pottery tile or Mediterranean Majolica enamel
/// featuring cobalt oxide pigment diffusion, porcelain crazing hairline fractures,
/// and a vitreous glazed specular bevel.
class DelftwareTileEffect extends Effect {
  DelftwareTileEffect([Map<String, dynamic>? params])
      : super(
          EffectType.delftwareTile,
          params ??
              {
                'cobaltBleed': 0.45,
                'crazingCrackDensity': 0.4,
                'enamelGloss': 0.5,
                'tileBevelDepth': 0.4,
                'porcelainWarmth': 0.3,
                'tilePalette': 'delftClassicBlue',
                'preserveAlpha': false,
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() => {
        'cobaltBleed': 0.45,
        'crazingCrackDensity': 0.4,
        'enamelGloss': 0.5,
        'tileBevelDepth': 0.4,
        'porcelainWarmth': 0.3,
        'tilePalette': 'delftClassicBlue',
        'preserveAlpha': false,
      };

  @override
  Map<String, dynamic> getMetadata() => {
        'cobaltBleed': {
          'label': 'Cobalt Pigment Bleed',
          'description': 'Diffusion of cobalt oxide wash into unfired raw tin glaze.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'step': 0.05,
        },
        'crazingCrackDensity': {
          'label': 'Porcelain Crazing',
          'description': 'Fine antique hairline crackle fractures across the glaze body.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'step': 0.05,
        },
        'enamelGloss': {
          'label': 'Vitreous Enamel Gloss',
          'description': 'Specular shine and candlelight reflections of glassy fired enamel.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'step': 0.05,
        },
        'tileBevelDepth': {
          'label': 'Tile Pillow Bevel',
          'description': 'Convex rounded curvature along hand-molded ceramic tile edges.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'step': 0.05,
        },
        'porcelainWarmth': {
          'label': 'Tin Glaze Warmth',
          'description': 'Ivory antique patina versus crisp cool tin-opacified white.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'step': 0.05,
        },
        'tilePalette': {
          'label': 'Ceramic Style',
          'description': 'Traditional European pottery style and glaze formulation.',
          'type': 'select',
          'options': {
            'delftClassicBlue': 'Delft Royal Cobalt Blue',
            'antiqueMutedCobalt': '17th-Century Weathered Cobalt',
            'majolicaPolychrome': 'Italian Renaissance Majolica',
            'terracottaGlaze': 'Warm Terracotta Earthenware',
          },
        },
        'preserveAlpha': {
          'label': 'Preserve Alpha',
          'description': 'Restrict ceramic tile glaze strictly to existing sprite silhouette.',
          'type': 'bool',
        },
      };

  @override
  List<UIField> getFields() => [
        SliderField(
          key: 'cobaltBleed',
          label: 'Cobalt Pigment Bleed',
          description: 'Diffusion of cobalt oxide wash into unfired raw tin glaze.',
          min: 0.0,
          max: 1.0,
          divisions: 20,
          formatLabel: (v) => v.toStringAsFixed(2),
        ),
        SliderField(
          key: 'crazingCrackDensity',
          label: 'Porcelain Crazing',
          description: 'Fine antique hairline crackle fractures across the glaze body.',
          min: 0.0,
          max: 1.0,
          divisions: 20,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        SliderField(
          key: 'enamelGloss',
          label: 'Vitreous Enamel Gloss',
          description: 'Specular shine and candlelight reflections of glassy fired enamel.',
          min: 0.0,
          max: 1.0,
          divisions: 20,
          formatLabel: (v) => v.toStringAsFixed(2),
        ),
        SliderField(
          key: 'tileBevelDepth',
          label: 'Tile Pillow Bevel',
          description: 'Convex rounded curvature along hand-molded ceramic tile edges.',
          min: 0.0,
          max: 1.0,
          divisions: 20,
          formatLabel: (v) => v.toStringAsFixed(2),
        ),
        SliderField(
          key: 'porcelainWarmth',
          label: 'Tin Glaze Warmth',
          description: 'Ivory antique patina versus crisp cool tin-opacified white.',
          min: 0.0,
          max: 1.0,
          divisions: 20,
          formatLabel: (v) => v.toStringAsFixed(2),
        ),
        const SelectField(
          key: 'tilePalette',
          label: 'Ceramic Style',
          description: 'Traditional European pottery style and glaze formulation.',
          options: {
            'delftClassicBlue': 'Delft Royal Cobalt Blue',
            'antiqueMutedCobalt': '17th-Century Weathered Cobalt',
            'majolicaPolychrome': 'Italian Renaissance Majolica',
            'terracottaGlaze': 'Warm Terracotta Earthenware',
          },
        ),
        const BoolField(
          key: 'preserveAlpha',
          label: 'Preserve Alpha',
          description: 'Restrict ceramic tile glaze strictly to existing sprite silhouette.',
        ),
      ];

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    final double bleed = ((parameters['cobaltBleed'] as num?)?.toDouble() ?? 0.45).clamp(0.0, 1.0);
    final double crackDensity = ((parameters['crazingCrackDensity'] as num?)?.toDouble() ?? 0.4).clamp(0.0, 1.0);
    final double gloss = ((parameters['enamelGloss'] as num?)?.toDouble() ?? 0.5).clamp(0.0, 1.0);
    final double bevel = ((parameters['tileBevelDepth'] as num?)?.toDouble() ?? 0.4).clamp(0.0, 1.0);
    final double warmth = ((parameters['porcelainWarmth'] as num?)?.toDouble() ?? 0.3).clamp(0.0, 1.0);
    final String palette = (parameters['tilePalette'] as String?) ?? 'delftClassicBlue';
    final bool preserveAlpha = parameters['preserveAlpha'] as bool? ?? false;

    final Uint32List result = Uint32List(width * height);

    // 1. Cobalt Pigment Diffusion (Blur pass to simulate liquid oxide bleed into tin glaze)
    final List<int> diffusedR = List<int>.filled(width * height, 0);
    final List<int> diffusedG = List<int>.filled(width * height, 0);
    final List<int> diffusedB = List<int>.filled(width * height, 0);

    final int bleedRadius = math.max(1, (bleed * 3.5).round());

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int idx = y * width + x;
        final int origCol = pixels[idx];
        final int origR = (origCol >> 16) & 0xFF;
        final int origG = (origCol >> 8) & 0xFF;
        final int origB = origCol & 0xFF;

        if (bleed <= 0.01) {
          diffusedR[idx] = origR;
          diffusedG[idx] = origG;
          diffusedB[idx] = origB;
          continue;
        }

        double sumR = 0.0, sumG = 0.0, sumB = 0.0, sumW = 0.0;
        for (int dy = -bleedRadius; dy <= bleedRadius; dy++) {
          final int sy = (y + dy).clamp(0, height - 1);
          for (int dx = -bleedRadius; dx <= bleedRadius; dx++) {
            final int sx = (x + dx).clamp(0, width - 1);
            final double distSq = (dx * dx + dy * dy).toDouble();
            final double w = math.exp(-distSq / (2.0 * bleedRadius * bleedRadius));
            final int c = pixels[sy * width + sx];
            sumR += ((c >> 16) & 0xFF) * w;
            sumG += ((c >> 8) & 0xFF) * w;
            sumB += (c & 0xFF) * w;
            sumW += w;
          }
        }

        final double mix = bleed * 0.65;
        diffusedR[idx] = ((1.0 - mix) * origR + mix * (sumR / sumW)).round().clamp(0, 255);
        diffusedG[idx] = ((1.0 - mix) * origG + mix * (sumG / sumW)).round().clamp(0, 255);
        diffusedB[idx] = ((1.0 - mix) * origB + mix * (sumB / sumW)).round().clamp(0, 255);
      }
    }

    // 2. Vitreous Glaze Porcelain Base & Lighting Constants
    // Base tin glaze color: milk white to warm ivory
    final double basePorcelainR = 246.0 - warmth * 15.0;
    final double basePorcelainG = 248.0 - warmth * 20.0;
    final double basePorcelainB = 252.0 - warmth * 42.0;

    const double lightX = -0.577;
    const double lightY = -0.577;
    const double lightZ = 0.577;

    final double bevelMargin = math.max(2.0, math.min(width, height) * 0.12 * bevel);

    // Crackle cell size (for crazing network)
    const double crackCellSize = 7.0;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int idx = y * width + x;
        final int origPixel = pixels[idx];
        final int origAlpha = (origPixel >> 24) & 0xFF;

        if (preserveAlpha && origAlpha == 0) {
          result[idx] = 0;
          continue;
        }

        // 3. Tile Pillow Bevel & Surface Normal calculation
        final double distLeft = x.toDouble();
        final double distRight = (width - 1 - x).toDouble();
        final double distTop = y.toDouble();
        final double distBottom = (height - 1 - y).toDouble();
        final double distEdge = math.min(math.min(distLeft, distRight), math.min(distTop, distBottom));

        double nx = 0.0;
        double ny = 0.0;
        double nz = 1.0;

        if (bevel > 0.01 && distEdge < bevelMargin) {
          final double t = (distEdge / bevelMargin).clamp(0.0, 1.0);
          final double slope = math.cos(t * math.pi * 0.5);

          if (distLeft < bevelMargin && distLeft <= distRight) nx -= slope;
          if (distRight < bevelMargin && distRight < distLeft) nx += slope;
          if (distTop < bevelMargin && distTop <= distBottom) ny -= slope;
          if (distBottom < bevelMargin && distBottom < distTop) ny += slope;

          final double nLen = math.sqrt(nx * nx + ny * ny + nz * nz);
          nx /= nLen;
          ny /= nLen;
          nz /= nLen;
        }

        // Lighting calculation (diffuse + vitreous enamel specular glint)
        final double nDotL = (nx * lightX + ny * lightY + nz * lightZ).clamp(0.0, 1.0);
        final double diffuse = 0.75 + 0.25 * nDotL;

        // Specular highlight: glassy reflection of overhead lamp / window
        const double hx = lightX;
        const double hy = lightY;
        const double hz = lightZ + 1.0;
        const double hLen = 1.732; // sqrt((-0.577)^2 + (-0.577)^2 + (1.577)^2) ~ 1.77
        final double nDotH = ((nx * hx + ny * hy + nz * hz) / hLen).clamp(0.0, 1.0);
        final double specular = math.pow(nDotH, 18.0).toDouble() * gloss;

        // 4. Palette pigment mapping
        final int dr = diffusedR[idx];
        final int dg = diffusedG[idx];
        final int db = diffusedB[idx];
        final double luma = (0.299 * dr + 0.587 * dg + 0.114 * db) / 255.0;

        int tileR;
        int tileG;
        int tileB;

        switch (palette) {
          case 'antiqueMutedCobalt':
            // Weathered 17th-Century Delft: Muted slate cobalt, antique tea-stained glaze
            final double cobaltFactor = (1.0 - luma).clamp(0.0, 1.0);
            // Cobalt core: #1D3254 (R:29, G:50, B:84)
            tileR = (basePorcelainR * (1.0 - cobaltFactor) + 29.0 * cobaltFactor).round().clamp(0, 255);
            tileG = (basePorcelainG * (1.0 - cobaltFactor) + 50.0 * cobaltFactor).round().clamp(0, 255);
            tileB = (basePorcelainB * (1.0 - cobaltFactor) + 84.0 * cobaltFactor).round().clamp(0, 255);
            break;

          case 'majolicaPolychrome':
            // Italian Renaissance Majolica: Cobalt, Antimony yellow, Copper green
            if (luma > 0.85) {
              tileR = basePorcelainR.round();
              tileG = basePorcelainG.round();
              tileB = basePorcelainB.round();
            } else {
              // Blend towards rich Majolica enamel tones
              final int h = _pixelHash(dr, dg, db);
              final int choice = (h % 3);
              if (choice == 0) {
                // Cobalt Blue
                tileR = (basePorcelainR * luma + 12.0 * (1.0 - luma)).round().clamp(0, 255);
                tileG = (basePorcelainG * luma + 50.0 * (1.0 - luma)).round().clamp(0, 255);
                tileB = (basePorcelainB * luma + 140.0 * (1.0 - luma)).round().clamp(0, 255);
              } else if (choice == 1) {
                // Antimony Ochre Yellow
                tileR = (basePorcelainR * luma + 215.0 * (1.0 - luma)).round().clamp(0, 255);
                tileG = (basePorcelainG * luma + 150.0 * (1.0 - luma)).round().clamp(0, 255);
                tileB = (basePorcelainB * luma + 28.0 * (1.0 - luma)).round().clamp(0, 255);
              } else {
                // Copper Oxide Green
                tileR = (basePorcelainR * luma + 40.0 * (1.0 - luma)).round().clamp(0, 255);
                tileG = (basePorcelainG * luma + 120.0 * (1.0 - luma)).round().clamp(0, 255);
                tileB = (basePorcelainB * luma + 75.0 * (1.0 - luma)).round().clamp(0, 255);
              }
            }
            break;

          case 'terracottaGlaze':
            // Warm Terracotta: Biscuit clay showing through creamy tin glaze
            final double edgeClay = (distEdge < bevelMargin * 0.7) ? 0.35 : 0.0;
            final double darkTone = (1.0 - luma).clamp(0.0, 1.0);
            tileR = (basePorcelainR * (1.0 - darkTone) + (160.0 * edgeClay + 20.0 * (1.0 - edgeClay)) * darkTone).round().clamp(0, 255);
            tileG = (basePorcelainG * (1.0 - darkTone) + (70.0 * edgeClay + 45.0 * (1.0 - edgeClay)) * darkTone).round().clamp(0, 255);
            tileB = (basePorcelainB * (1.0 - darkTone) + (45.0 * edgeClay + 110.0 * (1.0 - edgeClay)) * darkTone).round().clamp(0, 255);
            break;

          case 'delftClassicBlue':
          default:
            // Pure Royal Delft Cobalt Blue (#0B2868) on Tin-White
            final double cobalt = (1.0 - luma).clamp(0.0, 1.0);
            tileR = (basePorcelainR * (1.0 - cobalt) + 11.0 * cobalt).round().clamp(0, 255);
            tileG = (basePorcelainG * (1.0 - cobalt) + 40.0 * cobalt).round().clamp(0, 255);
            tileB = (basePorcelainB * (1.0 - cobalt) + 115.0 * cobalt).round().clamp(0, 255);
            break;
        }

        // Apply diffuse lighting and enamel specular gloss
        final double specBrightness = specular * 180.0;
        int finalR = (tileR * diffuse + specBrightness).round().clamp(0, 255);
        int finalG = (tileG * diffuse + specBrightness).round().clamp(0, 255);
        int finalB = (tileB * diffuse + specBrightness).round().clamp(0, 255);

        // 5. Porcelain Crazing (Hairline Crackle Network)
        if (crackDensity > 0.05) {
          final double crackVal = _crazingNoise(x.toDouble(), y.toDouble(), crackCellSize);
          if (crackVal < crackDensity * 0.085) {
            // Crazing hairline fracture: tea-stained hairline shadow
            final double crackDepth = (1.0 - (crackVal / (crackDensity * 0.085))).clamp(0.0, 1.0);
            final double shadowFactor = 1.0 - 0.45 * crackDepth;
            finalR = (finalR * shadowFactor).round().clamp(0, 255);
            finalG = (finalG * shadowFactor).round().clamp(0, 255);
            finalB = (finalB * shadowFactor).round().clamp(0, 255);
          }
        }

        final int outAlpha = preserveAlpha ? origAlpha : 255;
        result[idx] = (outAlpha << 24) | (finalR << 16) | (finalG << 8) | finalB;
      }
    }

    return result;
  }

  static double _crazingNoise(double x, double y, double cellSize) {
    final int cx = (x / cellSize).floor();
    final int cy = (y / cellSize).floor();

    double d1 = 1e9;
    double d2 = 1e9;

    for (int dy = -1; dy <= 1; dy++) {
      for (int dx = -1; dx <= 1; dx++) {
        final int gx = cx + dx;
        final int gy = cy + dy;
        final int h = _tileHash(gx, gy);
        final double jx = ((h & 0xFF) / 255.0);
        final double jy = (((h >> 8) & 0xFF) / 255.0);

        final double sx = (gx + jx) * cellSize;
        final double sy = (gy + jy) * cellSize;
        final double dist = math.sqrt((x - sx) * (x - sx) + (y - sy) * (y - sy));

        if (dist < d1) {
          d2 = d1;
          d1 = dist;
        } else if (dist < d2) {
          d2 = dist;
        }
      }
    }

    // Distance to Voronoi edge
    return (d2 - d1);
  }

  static int _tileHash(int x, int y) {
    int h = (x * 1619 + y * 31337) ^ 0x6e2b8349;
    h = (h ^ (h >> 13)) * 1274126177;
    return h ^ (h >> 16);
  }

  static int _pixelHash(int r, int g, int b) {
    return (r * 73856093 ^ g * 19349663 ^ b * 83492791).abs();
  }
}
