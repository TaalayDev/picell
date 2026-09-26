part of 'effects.dart';

/// An effect that procedurally renders undulating ribbons of Aurora Borealis
/// polar geomagnetic plasma curtains with harmonic wave deformation,
/// vertical field-line ray striations, altitude atmospheric excitation gradients,
/// and twinkling arctic stars.
class AuroraCurtainsEffect extends Effect {
  AuroraCurtainsEffect([Map<String, dynamic>? params])
      : super(
          EffectType.auroraCurtains,
          params ??
              {
                'curtainWaveSpeed': 1.5,
                'auroraBrightness': 0.8,
                'verticalRayDetail': 0.65,
                'curtainCount': 2,
                'auroraPalette': 'arcticEmerald',
                'starsVisibility': 0.65,
                'time': 0.0,
                'preserveAlpha': false,
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() => {
        'curtainWaveSpeed': 1.5,
        'auroraBrightness': 0.8,
        'verticalRayDetail': 0.65,
        'curtainCount': 2,
        'auroraPalette': 'arcticEmerald',
        'starsVisibility': 0.65,
        'time': 0.0,
        'preserveAlpha': false,
      };

  @override
  Map<String, dynamic> getMetadata() => {
        'curtainWaveSpeed': {
          'label': 'Curtain Wave Velocity',
          'description': 'Harmonic undulation and drift speed of folding plasma ribbons.',
          'type': 'slider',
          'min': 0.5,
          'max': 3.0,
          'step': 0.1,
        },
        'auroraBrightness': {
          'label': 'Aurora Emission Brightness',
          'description': 'Luminescent radiance and intensity of the geomagnetic arc.',
          'type': 'slider',
          'min': 0.3,
          'max': 1.0,
          'step': 0.05,
        },
        'verticalRayDetail': {
          'label': 'Field-Line Ray Striations',
          'description': 'Density and sharpness of vertical geomagnetic field-line pillars.',
          'type': 'slider',
          'min': 0.2,
          'max': 1.0,
          'step': 0.05,
        },
        'curtainCount': {
          'label': 'Curtain Ribbon Layers',
          'description': 'Number of layered, folding auroral curtains across the sky.',
          'type': 'slider',
          'min': 1,
          'max': 4,
          'step': 1,
        },
        'auroraPalette': {
          'label': 'Atmospheric Aurora Palette',
          'description': 'Altitude excitation gas ionization spectrum.',
          'type': 'select',
          'options': {
            'arcticEmerald': 'Arctic Emerald & Violet Crown',
            'solarStormViolet': 'Solar Storm Neon Violet & Crimson',
            'celestialAzure': 'Celestial Cyan & Deep Azure',
            'deepAuroraRainbow': 'Full Spectrum Polar Rainbow',
          },
        },
        'starsVisibility': {
          'label': 'Arctic Starfield Visibility',
          'description': 'Density and twinkle brilliance of polar night backdrop stars.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'step': 0.05,
        },
        'time': {
          'label': 'Animation Timeline',
          'description': 'Cyclic time progress driving wave ripple and geomagnetic pulsing.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'step': 0.01,
        },
        'preserveAlpha': {
          'label': 'Preserve Alpha',
          'description': 'Restrict aurora curtains and glow strictly to sprite silhouette.',
          'type': 'bool',
        },
      };

  @override
  List<UIField> getFields() => [
        SliderField(
          key: 'curtainWaveSpeed',
          label: 'Curtain Wave Velocity',
          description: 'Harmonic undulation and drift speed of folding plasma ribbons.',
          min: 0.5,
          max: 3.0,
          divisions: 25,
          formatLabel: (v) => '${v.toStringAsFixed(1)}x',
        ),
        SliderField(
          key: 'auroraBrightness',
          label: 'Aurora Emission Brightness',
          description: 'Luminescent radiance and intensity of the geomagnetic arc.',
          min: 0.3,
          max: 1.0,
          divisions: 14,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        SliderField(
          key: 'verticalRayDetail',
          label: 'Field-Line Ray Striations',
          description: 'Density and sharpness of vertical geomagnetic field-line pillars.',
          min: 0.2,
          max: 1.0,
          divisions: 16,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        SliderField(
          key: 'curtainCount',
          label: 'Curtain Ribbon Layers',
          description: 'Number of layered, folding auroral curtains across the sky.',
          min: 1,
          max: 4,
          divisions: 3,
          formatLabel: (v) => '${v.round()}',
        ),
        const SelectField(
          key: 'auroraPalette',
          label: 'Atmospheric Aurora Palette',
          description: 'Altitude excitation gas ionization spectrum.',
          options: {
            'arcticEmerald': 'Arctic Emerald & Violet Crown',
            'solarStormViolet': 'Solar Storm Neon Violet & Crimson',
            'celestialAzure': 'Celestial Cyan & Deep Azure',
            'deepAuroraRainbow': 'Full Spectrum Polar Rainbow',
          },
        ),
        SliderField(
          key: 'starsVisibility',
          label: 'Arctic Starfield Visibility',
          description: 'Density and twinkle brilliance of polar night backdrop stars.',
          min: 0.0,
          max: 1.0,
          divisions: 20,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        SliderField(
          key: 'time',
          label: 'Animation Timeline',
          description: 'Cyclic time progress driving wave ripple and geomagnetic pulsing.',
          min: 0.0,
          max: 1.0,
          divisions: 100,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        const BoolField(
          key: 'preserveAlpha',
          label: 'Preserve Alpha',
          description: 'Restrict aurora curtains and glow strictly to sprite silhouette.',
        ),
      ];

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    final output = Uint32List(width * height);

    final double speed = ((parameters['curtainWaveSpeed'] as num?)?.toDouble() ?? 1.5).clamp(0.2, 5.0);
    final double brightness = ((parameters['auroraBrightness'] as num?)?.toDouble() ?? 0.8).clamp(0.1, 1.2);
    final double rayDetail = ((parameters['verticalRayDetail'] as num?)?.toDouble() ?? 0.65).clamp(0.1, 1.5);
    final int curtainCount = ((parameters['curtainCount'] as num?)?.toInt() ?? 2).clamp(1, 4);
    final String auroraPalette = parameters['auroraPalette'] as String? ?? 'arcticEmerald';
    final double starsVis = ((parameters['starsVisibility'] as num?)?.toDouble() ?? 0.65).clamp(0.0, 1.0);
    final double time = ((parameters['time'] as num?)?.toDouble() ?? 0.0).clamp(0.0, 1.0);
    final bool preserveAlpha = parameters['preserveAlpha'] as bool? ?? false;

    final tau = time * 2.0 * math.pi;
    final palette = _getAuroraPalette(auroraPalette);

    // 1. Precalculate star coordinates (around 55 stars)
    const int starCount = 55;
    final stars = <_PolarStar>[];
    if (starsVis > 0.01) {
      for (int i = 0; i < starCount; i++) {
        final double sx = _hashToUnit(i * 17 + 3) * width;
        // Stars are distributed mostly in the sky region
        final double sy = _hashToUnit(i * 31 + 7) * (height * 0.88);
        final double baseTwinkle = 0.5 + 0.5 * math.sin(tau * 3.0 + i * 2.1);
        final double starAlpha = (0.5 + 0.5 * _hashToUnit(i * 43 + 13)) * starsVis * baseTwinkle;
        stars.add(_PolarStar(sx, sy, starAlpha));
      }
    }

    // 2. Iterate pixels
    for (int y = 0; y < height; y++) {
      final double normY = y / height.toDouble();

      for (int x = 0; x < width; x++) {
        final int idx = y * width + x;
        final int origPixel = pixels[idx];
        final int origA = (origPixel >> 24) & 0xFF;
        final int origR = (origPixel >> 16) & 0xFF;
        final int origG = (origPixel >> 8) & 0xFF;
        final int origB = origPixel & 0xFF;

        // Background night sky color (Deep arctic midnight navy)
        final double skyR = palette.skyDeep.r + (palette.skyZenith.r - palette.skyDeep.r) * (1.0 - normY);
        final double skyG = palette.skyDeep.g + (palette.skyZenith.g - palette.skyDeep.g) * (1.0 - normY);
        final double skyB = palette.skyDeep.b + (palette.skyZenith.b - palette.skyDeep.b) * (1.0 - normY);

        // Starfield contribution on this pixel
        double starIntensity = 0.0;
        if (!preserveAlpha && starsVis > 0.01) {
          for (int i = 0; i < stars.length; i++) {
            final s = stars[i];
            final double dx = (x - s.x).abs();
            final double dy = (y - s.y).abs();
            if (dx <= 1.2 && dy <= 1.2) {
              final double dist = math.sqrt(dx * dx + dy * dy);
              if (dist <= 1.1) {
                starIntensity += (1.0 - dist / 1.1) * s.brightness;
              }
            }
          }
        }
        starIntensity = starIntensity.clamp(0.0, 1.0);

        // 3. Evaluate multi-layer auroral curtains
        double totalEmissionR = 0.0;
        double totalEmissionG = 0.0;
        double totalEmissionB = 0.0;
        double maxCurtainAlpha = 0.0;

        for (int c = 0; c < curtainCount; c++) {
          final double curtainPhase = c * 1.57;
          // Base vertical shelf for this curtain
          final double baseShelf = height * (0.38 + c * 0.16);

          // Harmonic wave deformation across width
          final double nx = x / width.toDouble();
          final double wave1 = math.sin(nx * 3.14159 * 2.0 + tau * speed + curtainPhase) * (height * 0.12);
          final double wave2 = math.sin(nx * 3.14159 * 4.0 - tau * speed * 0.7 + curtainPhase * 1.3) * (height * 0.06);
          final double wave3 = math.cos(nx * 3.14159 * 7.0 + tau * speed * 1.4) * (height * 0.025);

          // Lower curtain boundary
          final double curtainBottomY = baseShelf + wave1 + wave2 + wave3;
          // Vertical extent of curtain (stretches upward towards sky)
          final double curtainHeight = height * (0.42 + c * 0.08);

          // Altitude ratio: 0 at base, 1 at top fringe
          final double altNorm = (curtainBottomY - y) / curtainHeight;

          if (altNorm >= 0.0 && altNorm <= 1.0) {
            // Fold enhancement: local wave slope produces folding pleats where line of sight is tangent
            final double slope = math.cos(nx * 6.28318 + tau * speed + curtainPhase) * 0.6 +
                math.cos(nx * 12.566 - tau * speed * 0.7) * 0.4;
            final double foldEnhancement = 1.0 + 1.6 * slope.abs();

            // Vertical geomagnetic field-line ray striations
            final double rayNoise = math.sin(x * rayDetail * 0.45 + tau * speed * 1.8 + c * 2.0) * 0.5 +
                math.cos(x * rayDetail * 0.95 - tau * speed * 1.2 + curtainPhase) * 0.35 +
                math.sin(x * rayDetail * 1.9 + tau * speed * 2.5) * 0.15;
            final double rayFactor = (0.5 + 0.5 * ((rayNoise + 1.0) * 0.5)).clamp(0.3, 1.2);

            // Vertical envelope: crisp lower border, glowing body, soft diffuse upper fringe
            final double envelope = math.pow(math.sin(altNorm * math.pi), 0.85).toDouble() *
                (1.0 + 0.4 * (1.0 - altNorm));

            final double layerAlpha = (envelope * foldEnhancement * rayFactor * brightness).clamp(0.0, 1.5);
            maxCurtainAlpha = math.max(maxCurtainAlpha, layerAlpha);

            // Sample altitude excitation color gradient
            final _RGB layerColor = _sampleAuroraGradient(palette, altNorm);

            totalEmissionR += layerColor.r * layerAlpha;
            totalEmissionG += layerColor.g * layerAlpha;
            totalEmissionB += layerColor.b * layerAlpha;
          }
        }

        if (preserveAlpha) {
          if (origA == 0) {
            output[idx] = 0;
            continue;
          }

          // Screen/additive auroral glow over sprite silhouette
          final int finalR = (origR + totalEmissionR * 0.85).clamp(0.0, 255.0).round();
          final int finalG = (origG + totalEmissionG * 0.85).clamp(0.0, 255.0).round();
          final int finalB = (origB + totalEmissionB * 0.85).clamp(0.0, 255.0).round();

          output[idx] = (origA << 24) | (finalR << 16) | (finalG << 8) | finalB;
        } else {
          // Full arctic sky scene
          // Stars shine through background, partially dimmed by dense auroral curtains
          final double starDim = math.max(0.0, 1.0 - maxCurtainAlpha * 0.65);
          final double baseR = skyR + starIntensity * 230.0 * starDim;
          final double baseG = skyG + starIntensity * 240.0 * starDim;
          final double baseB = skyB + starIntensity * 255.0 * starDim;

          // Composite sprite if present
          double compR = baseR;
          double compG = baseG;
          double compB = baseB;
          if (origA > 0) {
            final double alphaNorm = origA / 255.0;
            compR = compR * (1.0 - alphaNorm) + origR * alphaNorm;
            compG = compG * (1.0 - alphaNorm) + origG * alphaNorm;
            compB = compB * (1.0 - alphaNorm) + origB * alphaNorm;
          }

          // Additive auroral emission
          final int r = (compR + totalEmissionR).clamp(0.0, 255.0).round();
          final int g = (compG + totalEmissionG).clamp(0.0, 255.0).round();
          final int b = (compB + totalEmissionB).clamp(0.0, 255.0).round();

          output[idx] = (0xFF << 24) | (r << 16) | (g << 8) | b;
        }
      }
    }

    return output;
  }

  static double _hashToUnit(int n) {
    int x = (n << 13) ^ n;
    x = (x * (x * x * 15731 + 789221) + 1376312589) & 0x7fffffff;
    return (x & 0xffff) / 65535.0;
  }

  static _RGB _sampleAuroraGradient(_AuroraPalette palette, double altNorm) {
    if (altNorm <= 0.45) {
      final double t = altNorm / 0.45;
      return _RGB(
        (palette.baseColor.r + (palette.midColor.r - palette.baseColor.r) * t).round(),
        (palette.baseColor.g + (palette.midColor.g - palette.baseColor.g) * t).round(),
        (palette.baseColor.b + (palette.midColor.b - palette.baseColor.b) * t).round(),
      );
    } else {
      final double t = (altNorm - 0.45) / 0.55;
      return _RGB(
        (palette.midColor.r + (palette.apexColor.r - palette.midColor.r) * t).round(),
        (palette.midColor.g + (palette.apexColor.g - palette.midColor.g) * t).round(),
        (palette.midColor.b + (palette.apexColor.b - palette.midColor.b) * t).round(),
      );
    }
  }

  static _AuroraPalette _getAuroraPalette(String palette) {
    switch (palette) {
      case 'solarStormViolet':
        return const _AuroraPalette(
          baseColor: _RGB(165, 45, 255),
          midColor: _RGB(255, 35, 175),
          apexColor: _RGB(255, 60, 95),
          skyZenith: _RGB(12, 6, 26),
          skyDeep: _RGB(24, 10, 42),
        );
      case 'celestialAzure':
        return const _AuroraPalette(
          baseColor: _RGB(45, 235, 255),
          midColor: _RGB(25, 135, 255),
          apexColor: _RGB(95, 75, 240),
          skyZenith: _RGB(6, 12, 28),
          skyDeep: _RGB(12, 22, 48),
        );
      case 'deepAuroraRainbow':
        return const _AuroraPalette(
          baseColor: _RGB(60, 255, 75),
          midColor: _RGB(0, 230, 230),
          apexColor: _RGB(255, 45, 160),
          skyZenith: _RGB(8, 10, 25),
          skyDeep: _RGB(15, 20, 45),
        );
      case 'arcticEmerald':
      default:
        return const _AuroraPalette(
          baseColor: _RGB(35, 255, 125),
          midColor: _RGB(10, 225, 205),
          apexColor: _RGB(185, 55, 225),
          skyZenith: _RGB(5, 10, 25),
          skyDeep: _RGB(10, 18, 40),
        );
    }
  }
}

class _AuroraPalette {
  final _RGB baseColor;
  final _RGB midColor;
  final _RGB apexColor;
  final _RGB skyZenith;
  final _RGB skyDeep;

  const _AuroraPalette({
    required this.baseColor,
    required this.midColor,
    required this.apexColor,
    required this.skyZenith,
    required this.skyDeep,
  });
}

class _PolarStar {
  final double x;
  final double y;
  final double brightness;

  _PolarStar(this.x, this.y, this.brightness);
}
