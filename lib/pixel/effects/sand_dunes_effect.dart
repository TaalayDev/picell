part of 'effects.dart';

/// An effect that procedurally renders sweeping crescent barchan and
/// longitudinal sand dunes with razor-sharp slipface crests, wind-sculpted
/// micro-ripples, and blowing golden sand plumes drifting off the ridge tops.
class SandDunesEffect extends Effect {
  SandDunesEffect([Map<String, dynamic>? params])
      : super(
          EffectType.sandDunes,
          params ??
              {
                'duneScale': 2.5,
                'windAngle': 20.0,
                'rippleFrequency': 5.0,
                'crestPlumeDensity': 0.6,
                'sandPalette': 'namibRed',
                'duneShadowContrast': 0.65,
                'time': 0.0,
                'preserveAlpha': false,
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() => {
        'duneScale': 2.5,
        'windAngle': 20.0,
        'rippleFrequency': 5.0,
        'crestPlumeDensity': 0.6,
        'sandPalette': 'namibRed',
        'duneShadowContrast': 0.65,
        'time': 0.0,
        'preserveAlpha': false,
      };

  @override
  Map<String, dynamic> getMetadata() => {
        'duneScale': {
          'label': 'Dune Ridge Scale',
          'description': 'Wave frequency and size of sweeping barchan dune ridges.',
          'type': 'slider',
          'min': 1.0,
          'max': 5.0,
          'step': 0.25,
        },
        'windAngle': {
          'label': 'Aeolian Wind Angle',
          'description': 'Direction of wind blowing ripples and saltating sand plumes.',
          'type': 'slider',
          'min': -45.0,
          'max': 45.0,
          'step': 1.0,
        },
        'rippleFrequency': {
          'label': 'Micro-Ripple Frequency',
          'description': 'Density of wind-sculpted sand ripples along windward slopes.',
          'type': 'slider',
          'min': 2.0,
          'max': 10.0,
          'step': 0.5,
        },
        'crestPlumeDensity': {
          'label': 'Crest Plume Density',
          'description': 'Volume of blowing dust particles swept off razor ridge crests.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'step': 0.05,
        },
        'sandPalette': {
          'label': 'Desert Erg Palette',
          'description': 'Geological mineral composition and sand coloration.',
          'type': 'select',
          'options': {
            'namibRed': 'Namib Sossusvlei Terracotta Red',
            'saharaGold': 'Sahara Erg Golden Sand',
            'gypsumWhite': 'White Sands Gypsum White',
            'rubAlKhaliAmber': 'Rub\' al Khali Deep Amber',
          },
        },
        'duneShadowContrast': {
          'label': 'Slipface Shadow Contrast',
          'description': 'Lighting contrast between sunlit windward face and shadowed lee.',
          'type': 'slider',
          'min': 0.2,
          'max': 1.0,
          'step': 0.05,
        },
        'time': {
          'label': 'Animation Timeline',
          'description': 'Wind plume drift, sand grain saltation, and heat shimmer.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'step': 0.01,
        },
        'preserveAlpha': {
          'label': 'Preserve Alpha',
          'description': 'Restrict dunes, ripples, and plumes strictly to sprite pixels.',
          'type': 'bool',
        },
      };

  @override
  List<UIField> getFields() => [
        SliderField(
          key: 'duneScale',
          label: 'Dune Ridge Scale',
          description: 'Wave frequency and size of sweeping barchan dune ridges.',
          min: 1.0,
          max: 5.0,
          divisions: 16,
          formatLabel: (v) => '${v.toStringAsFixed(1)}x',
        ),
        SliderField(
          key: 'windAngle',
          label: 'Aeolian Wind Angle',
          description: 'Direction of wind blowing ripples and saltating sand plumes.',
          min: -45.0,
          max: 45.0,
          divisions: 18,
          formatLabel: (v) => '${v.round()}°',
        ),
        SliderField(
          key: 'rippleFrequency',
          label: 'Micro-Ripple Frequency',
          description: 'Density of wind-sculpted sand ripples along windward slopes.',
          min: 2.0,
          max: 10.0,
          divisions: 16,
          formatLabel: (v) => '${v.toStringAsFixed(1)}x',
        ),
        SliderField(
          key: 'crestPlumeDensity',
          label: 'Crest Plume Density',
          description: 'Volume of blowing dust particles swept off razor ridge crests.',
          min: 0.0,
          max: 1.0,
          divisions: 20,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        const SelectField(
          key: 'sandPalette',
          label: 'Desert Erg Palette',
          description: 'Geological mineral composition and sand coloration.',
          options: {
            'namibRed': 'Namib Sossusvlei Terracotta Red',
            'saharaGold': 'Sahara Erg Golden Sand',
            'gypsumWhite': 'White Sands Gypsum White',
            'rubAlKhaliAmber': 'Rub\' al Khali Deep Amber',
          },
        ),
        SliderField(
          key: 'duneShadowContrast',
          label: 'Slipface Shadow Contrast',
          description: 'Lighting contrast between sunlit windward face and shadowed lee.',
          min: 0.2,
          max: 1.0,
          divisions: 16,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        SliderField(
          key: 'time',
          label: 'Animation Timeline',
          description: 'Wind plume drift, sand grain saltation, and heat shimmer.',
          min: 0.0,
          max: 1.0,
          divisions: 100,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        const BoolField(
          key: 'preserveAlpha',
          label: 'Preserve Alpha',
          description: 'Restrict dunes, ripples, and plumes strictly to sprite pixels.',
        ),
      ];

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    final output = Uint32List(width * height);

    final double duneScale = ((parameters['duneScale'] as num?)?.toDouble() ?? 2.5).clamp(0.5, 8.0);
    final double windAngle = (parameters['windAngle'] as num?)?.toDouble() ?? 20.0;
    final double rippleFreq = ((parameters['rippleFrequency'] as num?)?.toDouble() ?? 5.0).clamp(1.0, 15.0);
    final double plumeDensity = ((parameters['crestPlumeDensity'] as num?)?.toDouble() ?? 0.6).clamp(0.0, 1.0);
    final String sandPalette = parameters['sandPalette'] as String? ?? 'namibRed';
    final double shadowContrast = ((parameters['duneShadowContrast'] as num?)?.toDouble() ?? 0.65).clamp(0.1, 1.0);
    final double time = ((parameters['time'] as num?)?.toDouble() ?? 0.0).clamp(0.0, 1.0);
    final bool preserveAlpha = parameters['preserveAlpha'] as bool? ?? false;

    final tau = time * 2.0 * math.pi;
    final theta = windAngle * math.pi / 180.0;
    final cosW = math.cos(theta);
    final sinW = math.sin(theta);
    final palette = _getDunePalette(sandPalette);

    // 1. Precalculate 3 dune ridge paths
    const int ridgeCount = 3;
    final ridgeY = List<Float64List>.generate(ridgeCount, (_) => Float64List(width));
    for (int k = 0; k < ridgeCount; k++) {
      final double baseHeight = height * (0.28 + k * 0.26);
      for (int x = 0; x < width; x++) {
        final double nx = x / width.toDouble();
        // Asymmetric barchan parabolic wave
        final double crestOffset = math.sin(nx * 3.14159 * duneScale + k * 2.1) * (height * 0.11) +
            math.sin(nx * 6.28318 * duneScale * 0.6 - k * 1.5) * (height * 0.04);
        ridgeY[k][x] = (baseHeight + crestOffset).clamp(0.0, height.toDouble());
      }
    }

    // 2. Precalculate drifting sand particles for crest plumes (around 50 particles)
    const int plumeParticleCount = 50;
    final plumeGrains = <_PlumeGrain>[];
    if (plumeDensity > 0.02) {
      for (int i = 0; i < plumeParticleCount; i++) {
        final int ridgeIdx = i % ridgeCount;
        final double seedX = _hashToUnit(i * 17 + 3) * width;
        final int ix = seedX.floor().clamp(0, width - 1);
        final double startY = ridgeY[ridgeIdx][ix];

        final double speed = 0.8 + _hashToUnit(i * 31 + 7) * 0.8;
        final double driftDist = (time * width * 0.45 * speed) % (width * 0.5);

        final double px = (seedX + driftDist * cosW) % width;
        final double py = (startY - driftDist * sinW * 0.5 - math.sin(tau * 2.0 + i) * 3.0).clamp(0.0, height.toDouble());
        final double alpha = (1.0 - driftDist / (width * 0.5)).clamp(0.0, 1.0) * plumeDensity;

        plumeGrains.add(_PlumeGrain(px, py, alpha));
      }
    }

    // 3. Iterate pixels
    for (int y = 0; y < height; y++) {
      final double normY = y / height.toDouble();

      for (int x = 0; x < width; x++) {
        final int idx = y * width + x;
        final int origPixel = pixels[idx];
        final int origA = (origPixel >> 24) & 0xFF;
        final int origR = (origPixel >> 16) & 0xFF;
        final int origG = (origPixel >> 8) & 0xFF;
        final int origB = origPixel & 0xFF;

        // Determine which dune ridge owns this pixel
        // Find closest ridge crest above or below
        int activeRidge = 0;
        for (int k = 0; k < ridgeCount; k++) {
          if (y >= ridgeY[k][x] - 2) {
            activeRidge = k;
          }
        }

        final double crestY = ridgeY[activeRidge][x];
        final double distToCrest = y - crestY;

        double lighting;
        if (distToCrest >= 0) {
          // Lee slipface side (immediately below crest) - steep shadow zone
          final double shadowFalloff = (distToCrest / (height * 0.18)).clamp(0.0, 1.0);
          final double shadowFactor = (1.0 - shadowContrast) + shadowContrast * math.pow(shadowFalloff, 0.6);
          lighting = (0.45 + shadowFactor * 0.45).clamp(0.2, 1.0);
        } else {
          // Windward slope (above crest) - sun-drenched face
          final double slopeNorm = (-distToCrest / (height * 0.24)).clamp(0.0, 1.0);
          lighting = (0.85 + 0.15 * (1.0 - slopeNorm)).clamp(0.5, 1.0);
        }

        // Micro-ripple modulation aligned perpendicular to wind
        final double rippleCoord = (x * cosW + y * sinW) * (rippleFreq * 0.25);
        final double ripple = math.sin(rippleCoord + tau * 0.2) * 0.08;
        lighting = (lighting + ripple).clamp(0.15, 1.15);

        // Razor crest edge highlight
        if (distToCrest.abs() <= 1.2) {
          lighting = math.max(lighting, 1.1);
        }

        // Plume particles at this pixel
        double plumeContrib = 0.0;
        for (int i = 0; i < plumeGrains.length; i++) {
          final pg = plumeGrains[i];
          final double pdx = (x - pg.x).abs();
          final double pdy = (y - pg.y).abs();
          if (pdx <= 1.5 && pdy <= 1.5) {
            final double dist = math.sqrt(pdx * pdx + pdy * pdy);
            if (dist <= 1.4) {
              plumeContrib += (1.0 - dist / 1.4) * pg.alpha;
            }
          }
        }
        plumeContrib = plumeContrib.clamp(0.0, 1.5);

        // Base sand color shaded by lighting
        final _RGB sandColor = _shadeSand(palette, lighting, normY);

        if (preserveAlpha) {
          if (origA == 0) {
            output[idx] = 0;
            continue;
          }

          // Screen/blend sand over sprite silhouette
          final int rBlend = (origR * 0.25 + sandColor.r * 0.75).round();
          final int gBlend = (origG * 0.25 + sandColor.g * 0.75).round();
          final int bBlend = (origB * 0.25 + sandColor.b * 0.75).round();

          // Add blowing crest plume particles
          final int rFinal = (rBlend + palette.plumeDust.r * plumeContrib * 0.8).clamp(0.0, 255.0).round();
          final int gFinal = (gBlend + palette.plumeDust.g * plumeContrib * 0.8).clamp(0.0, 255.0).round();
          final int bFinal = (bBlend + palette.plumeDust.b * plumeContrib * 0.8).clamp(0.0, 255.0).round();

          output[idx] = (origA << 24) | (rFinal << 16) | (gFinal << 8) | bFinal;
        } else {
          // Full desert erg panorama
          double baseR = sandColor.r.toDouble();
          double baseG = sandColor.g.toDouble();
          double baseB = sandColor.b.toDouble();

          // Sky gradient at very top if y < ridgeY[0][x]
          if (y < ridgeY[0][x]) {
            final double skyNorm = (y / ridgeY[0][x]).clamp(0.0, 1.0);
            baseR = palette.skyDeep.r + (palette.sandSunlit.r * 0.8 - palette.skyDeep.r) * skyNorm;
            baseG = palette.skyDeep.g + (palette.sandSunlit.g * 0.8 - palette.skyDeep.g) * skyNorm;
            baseB = palette.skyDeep.b + (palette.sandSunlit.b * 0.8 - palette.skyDeep.b) * skyNorm;
          }

          // Composite sprite if present
          if (origA > 0) {
            final double alphaNorm = origA / 255.0;
            baseR = baseR * (1.0 - alphaNorm) + origR * alphaNorm;
            baseG = baseG * (1.0 - alphaNorm) + origG * alphaNorm;
            baseB = baseB * (1.0 - alphaNorm) + origB * alphaNorm;
          }

          // Composite blowing crest plume particles
          final int rFinal = (baseR + palette.plumeDust.r * plumeContrib * 0.85).clamp(0.0, 255.0).round();
          final int gFinal = (baseG + palette.plumeDust.g * plumeContrib * 0.85).clamp(0.0, 255.0).round();
          final int bFinal = (baseB + palette.plumeDust.b * plumeContrib * 0.85).clamp(0.0, 255.0).round();

          output[idx] = (0xFF << 24) | (rFinal << 16) | (gFinal << 8) | bFinal;
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

  static _RGB _shadeSand(_DunePalette palette, double lighting, double normY) {
    _RGB base;
    if (lighting <= 0.6) {
      final double t = (lighting / 0.6).clamp(0.0, 1.0);
      base = _RGB(
        (palette.sandShadow.r + (palette.sandMid.r - palette.sandShadow.r) * t).round(),
        (palette.sandShadow.g + (palette.sandMid.g - palette.sandShadow.g) * t).round(),
        (palette.sandShadow.b + (palette.sandMid.b - palette.sandShadow.b) * t).round(),
      );
    } else {
      final double t = ((lighting - 0.6) / 0.4).clamp(0.0, 1.0);
      base = _RGB(
        (palette.sandMid.r + (palette.sandSunlit.r - palette.sandMid.r) * t).round(),
        (palette.sandMid.g + (palette.sandSunlit.g - palette.sandMid.g) * t).round(),
        (palette.sandMid.b + (palette.sandSunlit.b - palette.sandMid.b) * t).round(),
      );
    }

    return base;
  }

  static _DunePalette _getDunePalette(String palette) {
    switch (palette) {
      case 'saharaGold':
        return const _DunePalette(
          sandSunlit: _RGB(255, 220, 130),
          sandMid: _RGB(220, 170, 75),
          sandShadow: _RGB(135, 90, 35),
          plumeDust: _RGB(255, 235, 170),
          skyDeep: _RGB(45, 65, 115),
        );
      case 'gypsumWhite':
        return const _DunePalette(
          sandSunlit: _RGB(252, 252, 255),
          sandMid: _RGB(215, 220, 230),
          sandShadow: _RGB(135, 145, 160),
          plumeDust: _RGB(255, 255, 255),
          skyDeep: _RGB(25, 45, 95),
        );
      case 'rubAlKhaliAmber':
        return const _DunePalette(
          sandSunlit: _RGB(255, 175, 75),
          sandMid: _RGB(210, 120, 45),
          sandShadow: _RGB(115, 50, 22),
          plumeDust: _RGB(255, 200, 120),
          skyDeep: _RGB(40, 30, 60),
        );
      case 'namibRed':
      default:
        return const _DunePalette(
          sandSunlit: _RGB(235, 130, 80),
          sandMid: _RGB(190, 85, 45),
          sandShadow: _RGB(110, 38, 22),
          plumeDust: _RGB(250, 175, 130),
          skyDeep: _RGB(35, 55, 105),
        );
    }
  }
}

class _DunePalette {
  final _RGB sandSunlit;
  final _RGB sandMid;
  final _RGB sandShadow;
  final _RGB plumeDust;
  final _RGB skyDeep;

  const _DunePalette({
    required this.sandSunlit,
    required this.sandMid,
    required this.sandShadow,
    required this.plumeDust,
    required this.skyDeep,
  });
}

class _PlumeGrain {
  final double x;
  final double y;
  final double alpha;

  _PlumeGrain(this.x, this.y, this.alpha);
}
