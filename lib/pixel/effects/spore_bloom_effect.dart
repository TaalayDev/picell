part of 'effects.dart';

/// An effect that procedurally sprouts clusters of bioluminescent forest fungi
/// and vents swirling upward-drifting clouds of phosphorescent spores driven by curl noise.
class SporeBloomEffect extends Effect {
  SporeBloomEffect([Map<String, dynamic>? params])
      : super(
          EffectType.sporeBloom,
          params ??
              {
                'mushroomCount': 6,
                'bioluminescenceGlow': 0.7,
                'sporeCloudDensity': 0.5,
                'capPalette': 'mycenaCyan',
                'airDriftSpeed': 1.0,
                'time': 0.0,
                'preserveAlpha': false,
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() => {
        'mushroomCount': 6,
        'bioluminescenceGlow': 0.7,
        'sporeCloudDensity': 0.5,
        'capPalette': 'mycenaCyan',
        'airDriftSpeed': 1.0,
        'time': 0.0,
        'preserveAlpha': false,
      };

  @override
  Map<String, dynamic> getMetadata() => {
        'mushroomCount': {
          'label': 'Fungal Clusters',
          'description': 'Number of mushroom colonies sprouting across the floor or sprite.',
          'type': 'slider',
          'min': 3,
          'max': 12,
          'step': 1,
        },
        'bioluminescenceGlow': {
          'label': 'Bioluminescent Glow',
          'description': 'Radiant light emitted by mushroom gills and illuminating the loam.',
          'type': 'slider',
          'min': 0.2,
          'max': 1.0,
          'step': 0.05,
        },
        'sporeCloudDensity': {
          'label': 'Spore Particle Density',
          'description': 'Volume of phosphorescent spores vented continuously into the air.',
          'type': 'slider',
          'min': 0.1,
          'max': 1.0,
          'step': 0.05,
        },
        'capPalette': {
          'label': 'Mushroom Species',
          'description': 'Botanical species, cap pigmentation, and spore luminescence.',
          'type': 'select',
          'options': {
            'mycenaCyan': 'Bioluminescent Mycena (Electric Cyan)',
            'ghostFungusEmerald': 'Ghost Fungus (Spectral Emerald)',
            'scarletWaxcap': 'Scarlet Waxcap (Crimson & Amber)',
            'amethystDeceiver': 'Amethyst Deceiver (Luminous Violet)',
          },
        },
        'airDriftSpeed': {
          'label': 'Convection Drift Speed',
          'description': 'Velocity of ambient air currents and swirling spore eddies.',
          'type': 'slider',
          'min': 0.2,
          'max': 2.0,
          'step': 0.1,
        },
        'time': {
          'label': 'Animation Timeline',
          'description': 'Cyclic bio-fluorescent pulse and ascending spore travel.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'step': 0.01,
        },
        'preserveAlpha': {
          'label': 'Preserve Alpha',
          'description': 'Restrict mushrooms and spores strictly to existing sprite silhouette.',
          'type': 'bool',
        },
      };

  @override
  List<UIField> getFields() => [
        SliderField(
          key: 'mushroomCount',
          label: 'Fungal Clusters',
          description: 'Number of mushroom colonies sprouting across the floor or sprite.',
          min: 3,
          max: 12,
          divisions: 9,
          formatLabel: (v) => '${v.round()}',
        ),
        SliderField(
          key: 'bioluminescenceGlow',
          label: 'Bioluminescent Glow',
          description: 'Radiant light emitted by mushroom gills and illuminating the loam.',
          min: 0.2,
          max: 1.0,
          divisions: 16,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        SliderField(
          key: 'sporeCloudDensity',
          label: 'Spore Particle Density',
          description: 'Volume of phosphorescent spores vented continuously into the air.',
          min: 0.1,
          max: 1.0,
          divisions: 18,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        const SelectField(
          key: 'capPalette',
          label: 'Mushroom Species',
          description: 'Botanical species, cap pigmentation, and spore luminescence.',
          options: {
            'mycenaCyan': 'Bioluminescent Mycena (Electric Cyan)',
            'ghostFungusEmerald': 'Ghost Fungus (Spectral Emerald)',
            'scarletWaxcap': 'Scarlet Waxcap (Crimson & Amber)',
            'amethystDeceiver': 'Amethyst Deceiver (Luminous Violet)',
          },
        ),
        SliderField(
          key: 'airDriftSpeed',
          label: 'Convection Drift Speed',
          description: 'Velocity of ambient air currents and swirling spore eddies.',
          min: 0.2,
          max: 2.0,
          divisions: 18,
          formatLabel: (v) => '${v.toStringAsFixed(1)}x',
        ),
        SliderField(
          key: 'time',
          label: 'Animation Timeline',
          description: 'Cyclic bio-fluorescent pulse and ascending spore travel.',
          min: 0.0,
          max: 1.0,
          divisions: 100,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        const BoolField(
          key: 'preserveAlpha',
          label: 'Preserve Alpha',
          description: 'Restrict mushrooms and spores strictly to existing sprite silhouette.',
        ),
      ];

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    final int count = ((parameters['mushroomCount'] as num?)?.toInt() ?? 6).clamp(3, 12);
    final double glow = ((parameters['bioluminescenceGlow'] as num?)?.toDouble() ?? 0.7).clamp(0.2, 1.0);
    final double sporeDensity = ((parameters['sporeCloudDensity'] as num?)?.toDouble() ?? 0.5).clamp(0.1, 1.0);
    final String palette = (parameters['capPalette'] as String?) ?? 'mycenaCyan';
    final double speed = ((parameters['airDriftSpeed'] as num?)?.toDouble() ?? 1.0).clamp(0.2, 2.0);
    final double time = ((parameters['time'] as num?)?.toDouble() ?? 0.0).clamp(0.0, 1.0);
    final bool preserveAlpha = parameters['preserveAlpha'] as bool? ?? false;

    final Uint32List result = Uint32List.fromList(pixels);

    // Color definitions for chosen fungal palette
    final _RGB capBaseCol;
    final _RGB gillGlowCol;
    final _RGB sporeGlowCol;

    switch (palette) {
      case 'ghostFungusEmerald':
        capBaseCol = const _RGB(24, 52, 32);
        gillGlowCol = const _RGB(0, 240, 120);
        sporeGlowCol = const _RGB(160, 255, 190);
        break;

      case 'scarletWaxcap':
        capBaseCol = const _RGB(180, 20, 20);
        gillGlowCol = const _RGB(255, 200, 0);
        sporeGlowCol = const _RGB(255, 220, 110);
        break;

      case 'amethystDeceiver':
        capBaseCol = const _RGB(65, 20, 105);
        gillGlowCol = const _RGB(220, 60, 255);
        sporeGlowCol = const _RGB(235, 160, 255);
        break;

      case 'mycenaCyan':
      default:
        capBaseCol = const _RGB(10, 45, 60);
        gillGlowCol = const _RGB(0, 235, 255);
        sporeGlowCol = const _RGB(130, 255, 240);
        break;
    }

    // Deterministic mushroom cluster anchors along bottom 40% of canvas
    final List<double> mX = List<double>.filled(count, 0.0);
    final List<double> mY = List<double>.filled(count, 0.0);
    final List<double> mRadius = List<double>.filled(count, 0.0);
    final List<double> mStemHeight = List<double>.filled(count, 0.0);
    final List<double> mPulsePhase = List<double>.filled(count, 0.0);

    for (int k = 0; k < count; k++) {
      final double frac = (k + 0.5) / count;
      final int h = _clusterHash(k, 137);
      final double jx = ((h & 0xFF) / 255.0 - 0.5) * (0.8 / count);
      mX[k] = (frac + jx).clamp(0.08, 0.92) * width;
      mY[k] = (0.72 + (((h >> 8) & 0xFF) / 255.0) * 0.22).clamp(0.65, 0.95) * height;
      mRadius[k] = math.max(3.0, (width * (0.04 + (((h >> 16) & 0x7F) / 127.0) * 0.05)));
      mStemHeight[k] = mRadius[k] * (1.2 + (((h >> 4) & 0x3F) / 63.0) * 0.8);
      mPulsePhase[k] = ((h >> 20) & 0xFF) / 255.0;
    }

    // Step 1: Draw Mushroom Stems, Caps, and Radial Gills
    for (int k = 0; k < count; k++) {
      final double cx = mX[k];
      final double cy = mY[k];
      final double capR = mRadius[k];
      final double stemH = mStemHeight[k];
      final double capCenterY = cy - stemH;

      // Respiration pulse per cluster
      final double pulse = 0.75 + 0.25 * math.sin((time + mPulsePhase[k]) * 2.0 * math.pi);
      final double curGlow = glow * pulse;

      // Stalk curvature
      final double stalkWidth = math.max(1.0, capR * 0.28);
      final int stemBottom = cy.round().clamp(0, height - 1);
      final int stemTop = capCenterY.round().clamp(0, height - 1);

      for (int sy = stemTop; sy <= stemBottom; sy++) {
        final double progress = (sy - stemTop) / math.max(1, stemBottom - stemTop);
        final double stemCenterX = cx + math.sin(progress * math.pi * 0.5) * (capR * 0.25);

        for (int sx = (stemCenterX - stalkWidth).floor(); sx <= (stemCenterX + stalkWidth).ceil(); sx++) {
          if (sx < 0 || sx >= width || sy < 0 || sy >= height) continue;
          final int idx = sy * width + sx;
          final int origPixel = pixels[idx];
          final int origAlpha = (origPixel >> 24) & 0xFF;

          if (preserveAlpha && origAlpha == 0) continue;

          final double dx = (sx - stemCenterX).abs();
          if (dx <= stalkWidth) {
            final double stemShade = 0.5 + 0.5 * (1.0 - dx / stalkWidth);
            final int sr = (capBaseCol.r * 0.8 * stemShade + gillGlowCol.r * curGlow * 0.2).round().clamp(0, 255);
            final int sg = (capBaseCol.g * 0.8 * stemShade + gillGlowCol.g * curGlow * 0.2).round().clamp(0, 255);
            final int sb = (capBaseCol.b * 0.8 * stemShade + gillGlowCol.b * curGlow * 0.2).round().clamp(0, 255);
            final int outA = preserveAlpha ? origAlpha : 255;
            result[idx] = (outA << 24) | (sr << 16) | (sg << 8) | sb;
          }
        }
      }

      // Pileus (Cap dome) & Gill underside
      final int capMinX = (cx - capR * 1.3).floor().clamp(0, width - 1);
      final int capMaxX = (cx + capR * 1.3).ceil().clamp(0, width - 1);
      final int capMinY = (capCenterY - capR * 0.8).floor().clamp(0, height - 1);
      final int capMaxY = (capCenterY + capR * 0.6).ceil().clamp(0, height - 1);

      for (int py = capMinY; py <= capMaxY; py++) {
        for (int px = capMinX; px <= capMaxX; px++) {
          final int idx = py * width + px;
          final int origPixel = pixels[idx];
          final int origAlpha = (origPixel >> 24) & 0xFF;

          if (preserveAlpha && origAlpha == 0) continue;

          final double dx = (px - cx) / (capR * 1.15);
          final double dy = (py - capCenterY) / (capR * 0.7);

          // Upper cap dome (elliptical arc)
          if (dy <= 0.1 && (dx * dx + dy * dy <= 1.0)) {
            final double domeLuma = (1.0 - math.sqrt(dx * dx + dy * dy)).clamp(0.0, 1.0);
            final double capShade = 0.65 + 0.35 * domeLuma;

            final int cr = (capBaseCol.r * capShade + gillGlowCol.r * curGlow * 0.35 * (1.0 - domeLuma)).round().clamp(0, 255);
            final int cg = (capBaseCol.g * capShade + gillGlowCol.g * curGlow * 0.35 * (1.0 - domeLuma)).round().clamp(0, 255);
            final int cb = (capBaseCol.b * capShade + gillGlowCol.b * curGlow * 0.35 * (1.0 - domeLuma)).round().clamp(0, 255);
            final int outA = preserveAlpha ? origAlpha : 255;
            result[idx] = (outA << 24) | (cr << 16) | (cg << 8) | cb;
          } else if (dy > 0.0 && dy <= 0.45 && (dx * dx <= 0.85)) {
            // Underside gills (Bioluminescent radiator)
            final double angle = math.atan2(dy, dx);
            final double gillStriae = 0.5 + 0.5 * math.cos(angle * 16.0);
            final double gillIntensity = (curGlow * (0.8 + 0.2 * gillStriae)).clamp(0.0, 1.0);

            final int gr = (gillGlowCol.r * gillIntensity + capBaseCol.r * 0.2).round().clamp(0, 255);
            final int gg = (gillGlowCol.g * gillIntensity + capBaseCol.g * 0.2).round().clamp(0, 255);
            final int gb = (gillGlowCol.b * gillIntensity + capBaseCol.b * 0.2).round().clamp(0, 255);
            final int outA = preserveAlpha ? origAlpha : 255;
            result[idx] = (outA << 24) | (gr << 16) | (gg << 8) | gb;
          }
        }
      }
    }

    // Step 2: Ascending Spore Particles Venting with Curl Noise
    final int totalSpores = math.max(15, (width * height * 0.008 * sporeDensity).round());

    for (int p = 0; p < totalSpores; p++) {
      final int h = _sporeHash(p);
      final int clusterIdx = p % count;
      final double origX = mX[clusterIdx] + (((h & 0xFF) / 255.0 - 0.5) * mRadius[clusterIdx] * 1.5);
      final double origY = mY[clusterIdx] - mStemHeight[clusterIdx];

      // Vertical ascent with cyclic loop
      final double phase = (time * speed + (((h >> 8) & 0xFF) / 255.0)) % 1.0;
      final double travelY = phase * (height * 0.85);
      final double curY = origY - travelY;

      if (curY < 0 || curY >= height) continue;

      // 2D Curl noise horizontal drift: dNoise/dy
      final double curlDrift = (_noise2D(origX * 0.08, (curY * 0.08)) - 0.5) * (width * 0.22);
      final double curX = (origX + curlDrift).clamp(0.0, (width - 1).toDouble());

      final int spX = curX.round();
      final int spY = curY.round();
      final int idx = spY * width + spX;

      final int origPixel = pixels[idx];
      final int origAlpha = (origPixel >> 24) & 0xFF;
      if (preserveAlpha && origAlpha == 0) continue;

      // Life curve: fade in near cap, bright mid-height, fade out at top
      final double life = math.sin(phase * math.pi);
      final double emberLuma = (life * glow * (0.8 + 0.2 * math.sin(time * 12.0 + p))).clamp(0.0, 1.0);

      final int existing = result[idx];
      final int er = (existing >> 16) & 0xFF;
      final int eg = (existing >> 8) & 0xFF;
      final int eb = existing & 0xFF;

      // Additive phosphorescent blending
      final int finalR = math.min(255, er + (sporeGlowCol.r * emberLuma).round());
      final int finalG = math.min(255, eg + (sporeGlowCol.g * emberLuma).round());
      final int finalB = math.min(255, eb + (sporeGlowCol.b * emberLuma).round());
      final int outA = preserveAlpha ? origAlpha : 255;
      result[idx] = (outA << 24) | (finalR << 16) | (finalG << 8) | finalB;
    }

    return result;
  }

  static int _clusterHash(int k, int seed) {
    int h = (k * 374761393 + seed * 668265263) ^ 0x27d4eb2d;
    h = (h ^ (h >> 13)) * 1274126177;
    return h ^ (h >> 16);
  }

  static int _sporeHash(int p) {
    int h = (p * 1597334677) ^ 0x6e2b8349;
    h = (h ^ (h >> 15)) * 2246822519;
    return h ^ (h >> 13);
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
    int n = (x * 1619 + y * 31337) ^ 0x5a5a5a5a;
    n = (n ^ (n >> 13)) * 1073741824;
    return ((n & 0x7FFFFFFF) / 2147483647.0);
  }
}
