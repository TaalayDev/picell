part of 'effects.dart';

/// An effect that procedurally renders a swirling cyclonic dust devil
/// or desert sandstorm haboob with cylindrical vortex orbital velocity physics,
/// particulate sand grains in 3D projection, and billowing ground skirts.
class DustDevilEffect extends Effect {
  DustDevilEffect([Map<String, dynamic>? params])
      : super(
          EffectType.dustDevil,
          params ??
              {
                'vortexRadius': 0.32,
                'sandstormDensity': 0.7,
                'orbitSpeed': 2.0,
                'funnelWobble': 0.4,
                'dustPalette': 'saharaOchre',
                'heatMirageDistortion': 0.35,
                'groundSkirtScale': 0.5,
                'time': 0.0,
                'preserveAlpha': false,
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() => {
        'vortexRadius': 0.32,
        'sandstormDensity': 0.7,
        'orbitSpeed': 2.0,
        'funnelWobble': 0.4,
        'dustPalette': 'saharaOchre',
        'heatMirageDistortion': 0.35,
        'groundSkirtScale': 0.5,
        'time': 0.0,
        'preserveAlpha': false,
      };

  @override
  Map<String, dynamic> getMetadata() => {
        'vortexRadius': {
          'label': 'Vortex Radius',
          'description': 'Mean radius and horizontal girth of the cyclonic funnel.',
          'type': 'slider',
          'min': 0.15,
          'max': 0.6,
          'step': 0.05,
        },
        'sandstormDensity': {
          'label': 'Sandstorm Density',
          'description': 'Volumetric opacity and particulate thickness of the dust wall.',
          'type': 'slider',
          'min': 0.2,
          'max': 1.0,
          'step': 0.05,
        },
        'orbitSpeed': {
          'label': 'Vortex Orbital Velocity',
          'description': 'Rotational angular velocity of swirling sand grains.',
          'type': 'slider',
          'min': 0.5,
          'max': 4.0,
          'step': 0.1,
        },
        'funnelWobble': {
          'label': 'Funnel Axis Wobble',
          'description': 'Chaotic precession and dynamic serpentine tilt of the column.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'step': 0.05,
        },
        'dustPalette': {
          'label': 'Desert Dust Palette',
          'description': 'Mineral composition and planetary terrain biome.',
          'type': 'select',
          'options': {
            'saharaOchre': 'Sahara Desert Ochre',
            'marsCrimson': 'Mars Oxide Crimson',
            'saltFlatsWhite': 'Salt Flats Gypsum White',
            'gobiDune': 'Gobi Desert Dune Gold',
          },
        },
        'heatMirageDistortion': {
          'label': 'Heat Mirage Convection',
          'description': 'Thermal shimmer wave distortion radiating from ground bedrock.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'step': 0.05,
        },
        'groundSkirtScale': {
          'label': 'Ground Dust Skirt',
          'description': 'Diameter of billowing dust clouds expanding at bedrock contact.',
          'type': 'slider',
          'min': 0.2,
          'max': 1.0,
          'step': 0.05,
        },
        'time': {
          'label': 'Animation Timeline',
          'description': 'Cyclic time progress driving cyclonic vortex and dust rotation.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'step': 0.01,
        },
        'preserveAlpha': {
          'label': 'Preserve Alpha',
          'description': 'Restrict sandstorm funnel and dust particles to sprite pixels.',
          'type': 'bool',
        },
      };

  @override
  List<UIField> getFields() => [
        SliderField(
          key: 'vortexRadius',
          label: 'Vortex Radius',
          description: 'Mean radius and horizontal girth of the cyclonic funnel.',
          min: 0.15,
          max: 0.6,
          divisions: 18,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        SliderField(
          key: 'sandstormDensity',
          label: 'Sandstorm Density',
          description: 'Volumetric opacity and particulate thickness of the dust wall.',
          min: 0.2,
          max: 1.0,
          divisions: 16,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        SliderField(
          key: 'orbitSpeed',
          label: 'Vortex Orbital Velocity',
          description: 'Rotational angular velocity of swirling sand grains.',
          min: 0.5,
          max: 4.0,
          divisions: 14,
          formatLabel: (v) => '${v.toStringAsFixed(1)}x',
        ),
        SliderField(
          key: 'funnelWobble',
          label: 'Funnel Axis Wobble',
          description: 'Chaotic precession and dynamic serpentine tilt of the column.',
          min: 0.0,
          max: 1.0,
          divisions: 20,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        const SelectField(
          key: 'dustPalette',
          label: 'Desert Dust Palette',
          description: 'Mineral composition and planetary terrain biome.',
          options: {
            'saharaOchre': 'Sahara Desert Ochre',
            'marsCrimson': 'Mars Oxide Crimson',
            'saltFlatsWhite': 'Salt Flats Gypsum White',
            'gobiDune': 'Gobi Desert Dune Gold',
          },
        ),
        SliderField(
          key: 'heatMirageDistortion',
          label: 'Heat Mirage Convection',
          description: 'Thermal shimmer wave distortion radiating from ground bedrock.',
          min: 0.0,
          max: 1.0,
          divisions: 20,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        SliderField(
          key: 'groundSkirtScale',
          label: 'Ground Dust Skirt',
          description: 'Diameter of billowing dust clouds expanding at bedrock contact.',
          min: 0.2,
          max: 1.0,
          divisions: 16,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        SliderField(
          key: 'time',
          label: 'Animation Timeline',
          description: 'Cyclic time progress driving cyclonic vortex and dust rotation.',
          min: 0.0,
          max: 1.0,
          divisions: 100,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        const BoolField(
          key: 'preserveAlpha',
          label: 'Preserve Alpha',
          description: 'Restrict sandstorm funnel and dust particles to sprite pixels.',
        ),
      ];

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    final output = Uint32List(width * height);

    final double vortexRadius = ((parameters['vortexRadius'] as num?)?.toDouble() ?? 0.32).clamp(0.1, 0.8);
    final double sandstormDensity = ((parameters['sandstormDensity'] as num?)?.toDouble() ?? 0.7).clamp(0.1, 1.0);
    final double orbitSpeed = ((parameters['orbitSpeed'] as num?)?.toDouble() ?? 2.0).clamp(0.2, 5.0);
    final double funnelWobble = ((parameters['funnelWobble'] as num?)?.toDouble() ?? 0.4).clamp(0.0, 1.0);
    final String dustPalette = parameters['dustPalette'] as String? ?? 'saharaOchre';
    final double heatMirage = ((parameters['heatMirageDistortion'] as num?)?.toDouble() ?? 0.35).clamp(0.0, 1.0);
    final double groundSkirt = ((parameters['groundSkirtScale'] as num?)?.toDouble() ?? 0.5).clamp(0.1, 1.0);
    final double time = ((parameters['time'] as num?)?.toDouble() ?? 0.0).clamp(0.0, 1.0);
    final bool preserveAlpha = parameters['preserveAlpha'] as bool? ?? false;

    final tau = time * 2.0 * math.pi;
    final palette = _getDustPalette(dustPalette);

    // 1. Precalculate 3D orbiting sand grains (around 70 particles)
    const int grainCount = 70;
    final grains = <_SandGrain>[];
    for (int i = 0; i < grainCount; i++) {
      final double seedH = _hashToUnit(i * 19 + 5);
      final double seedRad = 0.45 + 0.55 * _hashToUnit(i * 31 + 11);
      final double seedAngle = _hashToUnit(i * 47 + 17) * 2.0 * math.pi;

      // Particle height cycles upward from ground (1.0 -> 0.0)
      final double normH = (seedH + time * orbitSpeed * 0.35) % 1.0;
      final double gy = (1.0 - normH) * height;

      // Funnel center at gy
      final double altitudeRatio = 1.0 - gy / height;
      final double centerX = width * 0.5 +
          math.sin(tau * orbitSpeed * 0.4 + altitudeRatio * 2.5) * (width * 0.16 * funnelWobble);

      // Funnel radius expands aloft
      final double currentR = width * vortexRadius * (0.32 + 0.85 * math.pow(altitudeRatio, 1.15));
      final double r = currentR * seedRad;

      // Tangential velocity ~ 1 / sqrt(r)
      final double angSpeed = orbitSpeed * 3.5 / (0.4 + r / (width * 0.5));
      final double curAngle = seedAngle + tau * angSpeed;

      final double gx = centerX + r * math.cos(curAngle);
      final double depthZ = math.sin(curAngle); // +1 front, -1 back

      grains.add(_SandGrain(gx, gy, depthZ, 0.7 + _hashToUnit(i * 13 + 3) * 0.6));
    }

    // 2. Iterate pixels
    for (int y = 0; y < height; y++) {
      final double normY = y / height.toDouble();
      final double altitudeRatio = 1.0 - normY; // 0 at bottom, 1 at top

      // Heat mirage shimmer displacement (strongest near bottom bedrock)
      double mirageDx = 0.0;
      if (heatMirage > 0.01 && normY > 0.55) {
        final double mirageStrength = ((normY - 0.55) / 0.45) * heatMirage * 3.8;
        mirageDx = math.sin(y * 0.55 + tau * 4.5) * mirageStrength;
      }

      // Funnel axis center with dynamic serpentine wobble
      final double wobbleOffset = math.sin(tau * orbitSpeed * 0.4 + altitudeRatio * 2.5) *
          (width * 0.16 * funnelWobble);
      final double funnelCenterX = width * 0.5 + wobbleOffset;

      // Funnel radius at this altitude
      final double funnelRadius = width * vortexRadius * (0.32 + 0.85 * math.pow(altitudeRatio, 1.15));

      // Ground skirt expansion near bedrock (normY > 0.72)
      double skirtRadius = 0.0;
      if (normY > 0.72) {
        final double skirtProg = (normY - 0.72) / 0.28;
        skirtRadius = width * groundSkirt * 0.75 * skirtProg;
      }

      for (int x = 0; x < width; x++) {
        final int idx = y * width + x;
        final int origPixel = pixels[idx];
        final int origA = (origPixel >> 24) & 0xFF;
        final int origR = (origPixel >> 16) & 0xFF;
        final int origG = (origPixel >> 8) & 0xFF;
        final int origB = origPixel & 0xFF;

        // Position relative to funnel axis with mirage distortion
        final double dx = (x + mirageDx) - funnelCenterX;
        final double absDx = dx.abs();

        // Vortex wall profile calculation
        final double distFunnelNorm = absDx / math.max(1.0, funnelRadius);
        // Wall density peaks in the rotating sheath (distFunnelNorm ~ 0.5 to 1.1)
        final double wallPeak = math.exp(-3.5 * (distFunnelNorm - 0.75) * (distFunnelNorm - 0.75));
        final double coreDust = math.exp(-1.8 * distFunnelNorm * distFunnelNorm) * 0.45;

        // High-speed shear striations within the cyclonic wall
        final double shearNoise = math.sin(dx / math.max(1.0, funnelRadius) * 5.5 +
            tau * orbitSpeed * 2.8 -
            altitudeRatio * 9.0) * 0.28;

        double dustVolume = (wallPeak + coreDust + shearNoise).clamp(0.0, 1.5) * sandstormDensity;

        // Ground skirt puffing billows
        if (skirtRadius > 1.0) {
          final double skirtDistNorm = absDx / skirtRadius;
          if (skirtDistNorm < 1.2) {
            final double billowPhase = math.sin(absDx * 0.22 - tau * 3.5 + normY * 8.0) * 0.2;
            final double skirtDensity = (1.0 - skirtDistNorm / 1.2).clamp(0.0, 1.0) * (0.8 + billowPhase);
            dustVolume = math.max(dustVolume, skirtDensity * sandstormDensity * 1.1);
          }
        }

        // Evaluate sand grain particles
        double grainSpecular = 0.0;
        for (int i = 0; i < grains.length; i++) {
          final g = grains[i];
          final double gdx = (x - g.x).abs();
          final double gdy = (y - g.y).abs();
          if (gdx <= 1.4 && gdy <= 1.4) {
            final double dist = math.sqrt(gdx * gdx + gdy * gdy);
            if (dist <= g.radius) {
              final double falloff = 1.0 - dist / g.radius;
              // Front-facing grains (z > 0) are intensely illuminated; back grains are shadowed
              final double lighting = (g.depthZ > 0) ? (1.0 + g.depthZ * 1.6) : (0.35 + (1.0 + g.depthZ) * 0.25);
              grainSpecular += falloff * lighting;
            }
          }
        }
        grainSpecular = grainSpecular.clamp(0.0, 2.5);

        if (preserveAlpha) {
          if (origA == 0) {
            output[idx] = 0;
            continue;
          }

          // Blend dust color over sprite silhouette
          final double dustAlpha = (dustVolume * 0.85).clamp(0.0, 0.95);
          final double rBlend = origR * (1.0 - dustAlpha) + palette.dustWall.r * dustAlpha;
          final double gBlend = origG * (1.0 - dustAlpha) + palette.dustWall.g * dustAlpha;
          final double bBlend = origB * (1.0 - dustAlpha) + palette.dustWall.b * dustAlpha;

          // Add sharp specular sand grains
          final int rFinal = (rBlend + palette.grainHighlight.r * grainSpecular * 0.7).clamp(0.0, 255.0).round();
          final int gFinal = (gBlend + palette.grainHighlight.g * grainSpecular * 0.7).clamp(0.0, 255.0).round();
          final int bFinal = (bBlend + palette.grainHighlight.b * grainSpecular * 0.7).clamp(0.0, 255.0).round();

          output[idx] = (origA << 24) | (rFinal << 16) | (gFinal << 8) | bFinal;
        } else {
          // Full desert atmospheric background
          // Gradient from sun-baked arid sky (top) to hot bedrock ground (bottom)
          final double skyBedrockR = palette.skyTop.r + (palette.bedrockGround.r - palette.skyTop.r) * normY;
          final double skyBedrockG = palette.skyTop.g + (palette.bedrockGround.g - palette.skyTop.g) * normY;
          final double skyBedrockB = palette.skyTop.b + (palette.bedrockGround.b - palette.skyTop.b) * normY;

          // Composite sprite if present
          double baseR = skyBedrockR;
          double baseG = skyBedrockG;
          double baseB = skyBedrockB;
          if (origA > 0) {
            final double alphaNorm = origA / 255.0;
            baseR = baseR * (1.0 - alphaNorm) + origR * alphaNorm;
            baseG = baseG * (1.0 - alphaNorm) + origG * alphaNorm;
            baseB = baseB * (1.0 - alphaNorm) + origB * alphaNorm;
          }

          // Composite dense dust cloud & vortex wall
          final double dustAlpha = dustVolume.clamp(0.0, 0.95);
          final double rDust = baseR * (1.0 - dustAlpha) + palette.dustWall.r * dustAlpha;
          final double gDust = baseG * (1.0 - dustAlpha) + palette.dustWall.g * dustAlpha;
          final double bDust = baseB * (1.0 - dustAlpha) + palette.dustWall.b * dustAlpha;

          // Composite sharp specular sand grains
          final int rFinal = (rDust + palette.grainHighlight.r * grainSpecular * 0.8).clamp(0.0, 255.0).round();
          final int gFinal = (gDust + palette.grainHighlight.g * grainSpecular * 0.8).clamp(0.0, 255.0).round();
          final int bFinal = (bDust + palette.grainHighlight.b * grainSpecular * 0.8).clamp(0.0, 255.0).round();

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

  static _DustDevilPalette _getDustPalette(String palette) {
    switch (palette) {
      case 'marsCrimson':
        return const _DustDevilPalette(
          dustWall: _RGB(205, 78, 52),
          grainHighlight: _RGB(255, 160, 130),
          skyTop: _RGB(65, 24, 20),
          bedrockGround: _RGB(130, 42, 28),
        );
      case 'saltFlatsWhite':
        return const _DustDevilPalette(
          dustWall: _RGB(228, 234, 240),
          grainHighlight: _RGB(255, 255, 255),
          skyTop: _RGB(45, 60, 75),
          bedrockGround: _RGB(155, 165, 175),
        );
      case 'gobiDune':
        return const _DustDevilPalette(
          dustWall: _RGB(208, 158, 92),
          grainHighlight: _RGB(250, 220, 160),
          skyTop: _RGB(52, 40, 28),
          bedrockGround: _RGB(138, 98, 54),
        );
      case 'saharaOchre':
      default:
        return const _DustDevilPalette(
          dustWall: _RGB(224, 168, 102),
          grainHighlight: _RGB(255, 232, 175),
          skyTop: _RGB(58, 42, 30),
          bedrockGround: _RGB(145, 96, 52),
        );
    }
  }
}

class _DustDevilPalette {
  final _RGB dustWall;
  final _RGB grainHighlight;
  final _RGB skyTop;
  final _RGB bedrockGround;

  const _DustDevilPalette({
    required this.dustWall,
    required this.grainHighlight,
    required this.skyTop,
    required this.bedrockGround,
  });
}

class _SandGrain {
  final double x;
  final double y;
  final double depthZ;
  final double radius;

  _SandGrain(this.x, this.y, this.depthZ, this.radius);
}
