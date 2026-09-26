part of 'effects.dart';

/// An effect that procedurally transforms an image into an ancient Byzantine
/// or Roman imperial mosaic composed of fractured stone, ceramic tiles, and
/// shimmering gold leaf smalti tesserae separated by dark mortar grout channels.
class ByzantineMosaicEffect extends Effect {
  ByzantineMosaicEffect([Map<String, dynamic>? params])
      : super(
          EffectType.byzantineMosaic,
          params ??
              {
                'tesseraeSize': 6.0,
                'groutThickness': 1.0,
                'groutColor': 'darkMortar',
                'goldLeafRatio': 0.25,
                'tileAngleJitter': 0.45,
                'preserveAlpha': false,
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() => {
        'tesseraeSize': 6.0,
        'groutThickness': 1.0,
        'groutColor': 'darkMortar',
        'goldLeafRatio': 0.25,
        'tileAngleJitter': 0.45,
        'preserveAlpha': false,
      };

  @override
  Map<String, dynamic> getMetadata() => {
        'tesseraeSize': {
          'label': 'Tesserae Size',
          'description': 'Dimension of individual hand-cut stone and glass mosaic cubes.',
          'type': 'slider',
          'min': 3.0,
          'max': 16.0,
          'step': 0.5,
        },
        'groutThickness': {
          'label': 'Grout Thickness',
          'description': 'Width of the mortar channels separating adjacent tesserae.',
          'type': 'slider',
          'min': 0.5,
          'max': 3.0,
          'step': 0.1,
        },
        'groutColor': {
          'label': 'Mortar Type',
          'description': 'Mineral composition and hue of the binder grout.',
          'type': 'select',
          'options': {
            'darkMortar': 'Roman Dark Mortar',
            'antiqueSand': 'Antique Travertine Sand',
            'terracottaGrout': 'Terracotta Pozzolana',
            'charcoalBlack': 'Charcoal Leaded Black',
          },
        },
        'goldLeafRatio': {
          'label': 'Gold Leaf Smalti',
          'description': 'Proportion of tiles gilded with shimmering 24k gold foil.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'step': 0.05,
        },
        'tileAngleJitter': {
          'label': 'Angle Jitter & Faceting',
          'description': 'Irregular surface tilt creating candlelight specular glints.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'step': 0.05,
        },
        'preserveAlpha': {
          'label': 'Preserve Alpha',
          'description': 'Restrict mosaic tesserae strictly to the existing sprite silhouette.',
          'type': 'bool',
        },
      };

  @override
  List<UIField> getFields() => [
        SliderField(
          key: 'tesseraeSize',
          label: 'Tesserae Size',
          description: 'Dimension of individual hand-cut stone and glass mosaic cubes.',
          min: 3.0,
          max: 16.0,
          divisions: 26,
          formatLabel: (v) => '${v.toStringAsFixed(1)}px',
        ),
        SliderField(
          key: 'groutThickness',
          label: 'Grout Thickness',
          description: 'Width of the mortar channels separating adjacent tesserae.',
          min: 0.5,
          max: 3.0,
          divisions: 25,
          formatLabel: (v) => '${v.toStringAsFixed(1)}px',
        ),
        const SelectField(
          key: 'groutColor',
          label: 'Mortar Type',
          description: 'Mineral composition and hue of the binder grout.',
          options: {
            'darkMortar': 'Roman Dark Mortar',
            'antiqueSand': 'Antique Travertine Sand',
            'terracottaGrout': 'Terracotta Pozzolana',
            'charcoalBlack': 'Charcoal Leaded Black',
          },
        ),
        SliderField(
          key: 'goldLeafRatio',
          label: 'Gold Leaf Smalti',
          description: 'Proportion of tiles gilded with shimmering 24k gold foil.',
          min: 0.0,
          max: 1.0,
          divisions: 20,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        SliderField(
          key: 'tileAngleJitter',
          label: 'Angle Jitter & Faceting',
          description: 'Irregular surface tilt creating candlelight specular glints.',
          min: 0.0,
          max: 1.0,
          divisions: 20,
          formatLabel: (v) => v.toStringAsFixed(2),
        ),
        const BoolField(
          key: 'preserveAlpha',
          label: 'Preserve Alpha',
          description: 'Restrict mosaic tesserae strictly to the existing sprite silhouette.',
        ),
      ];

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    final double rawSize = (parameters['tesseraeSize'] as num?)?.toDouble() ?? 6.0;
    final double cellSize = rawSize.clamp(3.0, 16.0);
    final double rawGrout = (parameters['groutThickness'] as num?)?.toDouble() ?? 1.0;
    final double groutThick = rawGrout.clamp(0.5, 3.0);
    final String mortarType = (parameters['groutColor'] as String?) ?? 'darkMortar';
    final double goldRatio = ((parameters['goldLeafRatio'] as num?)?.toDouble() ?? 0.25).clamp(0.0, 1.0);
    final double angleJitter = ((parameters['tileAngleJitter'] as num?)?.toDouble() ?? 0.45).clamp(0.0, 1.0);
    final bool preserveAlpha = parameters['preserveAlpha'] as bool? ?? false;

    final Uint32List result = Uint32List(width * height);

    // Mortar base color definition
    final int mortarR;
    final int mortarG;
    final int mortarB;
    switch (mortarType) {
      case 'antiqueSand':
        mortarR = 190;
        mortarG = 175;
        mortarB = 145;
        break;
      case 'terracottaGrout':
        mortarR = 125;
        mortarG = 60;
        mortarB = 45;
        break;
      case 'charcoalBlack':
        mortarR = 24;
        mortarG = 24;
        mortarB = 26;
        break;
      case 'darkMortar':
      default:
        mortarR = 48;
        mortarG = 45;
        mortarB = 42;
        break;
    }

    // Grid dimensions for Voronoi seeds
    final int gridCols = (width / cellSize).ceil() + 2;
    final int gridRows = (height / cellSize).ceil() + 2;

    // Precalculate Voronoi seed positions and attributes for grid cells
    final List<double> seedX = List<double>.filled(gridCols * gridRows, 0.0);
    final List<double> seedY = List<double>.filled(gridCols * gridRows, 0.0);
    final List<bool> isGold = List<bool>.filled(gridCols * gridRows, false);
    final List<double> normalX = List<double>.filled(gridCols * gridRows, 0.0);
    final List<double> normalY = List<double>.filled(gridCols * gridRows, 0.0);
    final List<int> tileBaseColor = List<int>.filled(gridCols * gridRows, 0);

    for (int gy = 0; gy < gridRows; gy++) {
      for (int gx = 0; gx < gridCols; gx++) {
        final int gIdx = gy * gridCols + gx;
        final double baseX = (gx - 0.5) * cellSize;
        final double baseY = (gy - 0.5) * cellSize;

        // Hash for deterministic tile variation
        final int h = _cellHash(gx, gy);
        final double jx = ((h & 0xFF) / 255.0 - 0.5) * 0.75 * angleJitter;
        final double jy = (((h >> 8) & 0xFF) / 255.0 - 0.5) * 0.75 * angleJitter;

        final double sx = baseX + (0.5 + jx) * cellSize;
        final double sy = baseY + (0.5 + jy) * cellSize;
        seedX[gIdx] = sx;
        seedY[gIdx] = sy;

        // Tile surface normal tilt for specular facet lighting
        final double nAngle = (((h >> 16) & 0xFF) / 255.0) * 2.0 * math.pi;
        final double nTilt = (((h >> 4) & 0x7F) / 127.0) * angleJitter * 0.6;
        normalX[gIdx] = math.cos(nAngle) * nTilt;
        normalY[gIdx] = math.sin(nAngle) * nTilt;

        // Sample source pixel color at or near seed
        final int samplePx = sx.round().clamp(0, width - 1);
        final int samplePy = sy.round().clamp(0, height - 1);
        final int sampledColor = pixels[samplePy * width + samplePx];
        tileBaseColor[gIdx] = sampledColor;

        final int r = (sampledColor >> 16) & 0xFF;
        final int g = (sampledColor >> 8) & 0xFF;
        final int b = sampledColor & 0xFF;
        final double luma = (0.299 * r + 0.587 * g + 0.114 * b) / 255.0;

        // Gold leaf probability: influenced by goldLeafRatio and boosted in brighter regions
        final double goldScore = (((h >> 12) & 0xFF) / 255.0);
        final double threshold = 1.0 - goldRatio * (0.6 + 0.4 * luma);
        isGold[gIdx] = (goldRatio > 0.0) && (goldScore >= threshold.clamp(0.0, 1.0));
      }
    }

    // Directional light vector pointing from top-left down onto the mosaic wall
    const double lightX = -0.577;
    const double lightY = -0.577;
    const double lightZ = 0.577;
    const double eyeX = 0.0;
    const double eyeY = 0.0;
    const double eyeZ = 1.0;
    const double hx = lightX + eyeX;
    const double hy = lightY + eyeY;
    const double hz = lightZ + eyeZ;
    final double hLen = math.sqrt(hx * hx + hy * hy + hz * hz);

    for (int y = 0; y < height; y++) {
      final int rowOffset = y * width;
      final int gy = ((y + 0.5 * cellSize) / cellSize).floor();

      for (int x = 0; x < width; x++) {
        final int idx = rowOffset + x;
        final int origPixel = pixels[idx];
        final int origAlpha = (origPixel >> 24) & 0xFF;

        if (preserveAlpha && origAlpha == 0) {
          result[idx] = 0;
          continue;
        }

        final int gx = ((x + 0.5 * cellSize) / cellSize).floor();

        // 9-neighbor Voronoi search for closest and 2nd closest seeds
        double d1 = 1e9;
        double d2 = 1e9;
        int bestGIdx = -1;

        for (int dy = -1; dy <= 1; dy++) {
          final int ngy = gy + dy;
          if (ngy < 0 || ngy >= gridRows) continue;
          final int ngyOffset = ngy * gridCols;

          for (int dx = -1; dx <= 1; dx++) {
            final int ngx = gx + dx;
            if (ngx < 0 || ngx >= gridCols) continue;

            final int testGIdx = ngyOffset + ngx;
            final double sx = seedX[testGIdx];
            final double sy = seedY[testGIdx];

            final double distSq = (x - sx) * (x - sx) + (y - sy) * (y - sy);
            final double dist = math.sqrt(distSq);

            if (dist < d1) {
              d2 = d1;
              d1 = dist;
              bestGIdx = testGIdx;
            } else if (dist < d2) {
              d2 = dist;
            }
          }
        }

        // Distance from pixel to nearest Voronoi border
        final double distToBorder = (d2 - d1) * 0.5;

        // Mortar channel evaluation
        final double halfGrout = groutThick * 0.5;
        if (distToBorder <= halfGrout) {
          // Inside mortar grout
          final double mortarNoise = (_noise2D(x * 0.5, y * 0.5) - 0.5) * 20.0;
          final int mr = (mortarR + mortarNoise).round().clamp(0, 255);
          final int mg = (mortarG + mortarNoise).round().clamp(0, 255);
          final int mb = (mortarB + mortarNoise).round().clamp(0, 255);
          final int finalAlpha = preserveAlpha ? origAlpha : 255;
          result[idx] = (finalAlpha << 24) | (mr << 16) | (mg << 8) | mb;
          continue;
        }

        // Inside a tessera tile
        final bool goldTile = bestGIdx >= 0 && isGold[bestGIdx];
        final int baseCol = bestGIdx >= 0 ? tileBaseColor[bestGIdx] : origPixel;
        final int tileAlpha = preserveAlpha ? origAlpha : 255;

        // Tile bevel: subtle edge darkening near grout border
        final double edgeDist = distToBorder - halfGrout;
        final double edgeShadow = (edgeDist / 1.5).clamp(0.0, 1.0);
        final double bevelMultiplier = 0.75 + 0.25 * edgeShadow;

        // Specular facet lighting
        final double nx = bestGIdx >= 0 ? normalX[bestGIdx] : 0.0;
        final double ny = bestGIdx >= 0 ? normalY[bestGIdx] : 0.0;
        final double nz = math.sqrt((1.0 - (nx * nx + ny * ny)).clamp(0.05, 1.0));

        // Diffuse lighting
        final double nDotL = (nx * lightX + ny * lightY + nz * lightZ).clamp(0.0, 1.0);
        final double diffuse = 0.65 + 0.35 * nDotL;

        // Specular reflection (Halfway vector)
        // Specular reflection (Halfway vector precomputed)
        final double nDotH = ((nx * hx + ny * hy + nz * hz) / hLen).clamp(0.0, 1.0);
        final double specular = math.pow(nDotH, goldTile ? 16.0 : 8.0).toDouble();

        int outR;
        int outG;
        int outB;

        if (goldTile) {
          // Byzantine Gold Leaf Smalti: 24k leaf, lustrous gold spectrum with metallic flecks
          final double foilGrain = (_noise2D(x * 1.8, y * 1.8) - 0.5) * 0.2;
          final double leafLuma = (0.75 + foilGrain + specular * 0.8) * bevelMultiplier;

          // Pure Imperial Gold base: R:245, G:195, B:60
          outR = (245.0 * leafLuma + specular * 80.0).round().clamp(0, 255);
          outG = (195.0 * leafLuma + specular * 70.0).round().clamp(0, 255);
          outB = (60.0 * leafLuma + specular * 30.0).round().clamp(0, 255);
        } else {
          // Glass / Ceramic Tessera: Enhances saturated jewel tones with vitreous sheen
          int r = (baseCol >> 16) & 0xFF;
          int g = (baseCol >> 8) & 0xFF;
          int b = baseCol & 0xFF;

          // Slight glass smalti saturation boost
          final double avg = (r + g + b) / 3.0;
          r = (avg + (r - avg) * 1.25).round().clamp(0, 255);
          g = (avg + (g - avg) * 1.25).round().clamp(0, 255);
          b = (avg + (b - avg) * 1.25).round().clamp(0, 255);

          // Subtle mineral texture within stone/glass
          final double stoneTooth = (_noise2D(x * 0.9, y * 0.9) - 0.5) * 12.0;

          final double lightFactor = diffuse * bevelMultiplier;
          outR = ((r + stoneTooth) * lightFactor + specular * 45.0).round().clamp(0, 255);
          outG = ((g + stoneTooth) * lightFactor + specular * 45.0).round().clamp(0, 255);
          outB = ((b + stoneTooth) * lightFactor + specular * 45.0).round().clamp(0, 255);
        }

        result[idx] = (tileAlpha << 24) | (outR << 16) | (outG << 8) | outB;
      }
    }

    return result;
  }

  static int _cellHash(int x, int y) {
    int h = (x * 374761393 + y * 668265263) ^ 0x5bf03635;
    h = (h ^ (h >> 13)) * 1274126177;
    return h ^ (h >> 16);
  }

  static double _noise2D(double x, double y) {
    final int xi = x.floor();
    final int yi = y.floor();
    final double xf = x - xi;
    final double yf = y - yi;

    final double u = xf * xf * (3.0 - 2.0 * xf);
    final double v = yf * yf * (3.0 - 2.0 * yf);

    final double n00 = _grad(xi, yi);
    final double n10 = _grad(xi + 1, yi);
    final double n01 = _grad(xi, yi + 1);
    final double n11 = _grad(xi + 1, yi + 1);

    final double x1 = n00 + u * (n10 - n00);
    final double x2 = n01 + u * (n11 - n01);
    return x1 + v * (x2 - x1);
  }

  static double _grad(int x, int y) {
    int n = (x * 1619 + y * 31337) ^ 0x6e2b8349;
    n = (n ^ (n >> 13)) * 1073741824;
    return ((n & 0x7FFFFFFF) / 2147483647.0);
  }
}
