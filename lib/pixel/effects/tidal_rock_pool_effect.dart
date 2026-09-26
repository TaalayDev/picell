part of 'effects.dart';

/// An effect that procedurally renders a low-tide granite rock pool basin
/// holding crystal-clear saltwater with swaying sea kelp, waving anemone tentacles,
/// white evaporated salt rims, and shimmering surface water caustics.
class TidalRockPoolEffect extends Effect {
  TidalRockPoolEffect([Map<String, dynamic>? params])
      : super(
          EffectType.tidalRockPool,
          params ??
              {
                'poolDepth': 0.65,
                'causticShimmer': 0.7,
                'kelpWaveSpeed': 1.4,
                'biomassColor': 'anemonePink',
                'saltRimCrust': 0.45,
                'waterClarity': 0.8,
                'time': 0.0,
                'preserveAlpha': false,
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() => {
        'poolDepth': 0.65,
        'causticShimmer': 0.7,
        'kelpWaveSpeed': 1.4,
        'biomassColor': 'anemonePink',
        'saltRimCrust': 0.45,
        'waterClarity': 0.8,
        'time': 0.0,
        'preserveAlpha': false,
      };

  @override
  Map<String, dynamic> getMetadata() => {
        'poolDepth': {
          'label': 'Rock Basin Depth',
          'description': 'Saltwater optical absorption and submerged pool depth.',
          'type': 'slider',
          'min': 0.2,
          'max': 1.0,
          'step': 0.05,
        },
        'causticShimmer': {
          'label': 'Water Surface Caustics',
          'description': 'Intensity of illuminated solar refraction webs dancing on pebbles.',
          'type': 'slider',
          'min': 0.1,
          'max': 1.0,
          'step': 0.05,
        },
        'kelpWaveSpeed': {
          'label': 'Swaying Wave Velocity',
          'description': 'Tidal current harmonic undulation of sea kelp and anemones.',
          'type': 'slider',
          'min': 0.5,
          'max': 3.0,
          'step': 0.1,
        },
        'biomassColor': {
          'label': 'Marine Flora & Fauna',
          'description': 'Species coloration of anemones, kelp fronds, and coralline algae.',
          'type': 'select',
          'options': {
            'anemonePink': 'Pink Giant Anemone & Sea Kelp',
            'seaEmerald': 'Emerald Green Anemone & Sea Lettuce',
            'corallineViolet': 'Coralline Algae Violet & Purple Urchin',
            'goldenSargassum': 'Golden Sargassum & Amber Weed',
          },
        },
        'saltRimCrust': {
          'label': 'High-Tide Salt Crust',
          'description': 'Thickness of crystalline white mineral crust ringing the basin lip.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'step': 0.05,
        },
        'waterClarity': {
          'label': 'Saltwater Clarity',
          'description': 'Transparency index revealing pebbles and anemones beneath caustics.',
          'type': 'slider',
          'min': 0.3,
          'max': 1.0,
          'step': 0.05,
        },
        'time': {
          'label': 'Animation Timeline',
          'description': 'Harmonic wave surge driving dancing caustics and kelp motion.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'step': 0.01,
        },
        'preserveAlpha': {
          'label': 'Preserve Alpha',
          'description': 'Restrict tide pool water and caustics strictly to sprite pixels.',
          'type': 'bool',
        },
      };

  @override
  List<UIField> getFields() => [
        SliderField(
          key: 'poolDepth',
          label: 'Rock Basin Depth',
          description: 'Saltwater optical absorption and submerged pool depth.',
          min: 0.2,
          max: 1.0,
          divisions: 16,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        SliderField(
          key: 'causticShimmer',
          label: 'Water Surface Caustics',
          description: 'Intensity of illuminated solar refraction webs dancing on pebbles.',
          min: 0.1,
          max: 1.0,
          divisions: 18,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        SliderField(
          key: 'kelpWaveSpeed',
          label: 'Swaying Wave Velocity',
          description: 'Tidal current harmonic undulation of sea kelp and anemones.',
          min: 0.5,
          max: 3.0,
          divisions: 25,
          formatLabel: (v) => '${v.toStringAsFixed(1)}x',
        ),
        const SelectField(
          key: 'biomassColor',
          label: 'Marine Flora & Fauna',
          description: 'Species coloration of anemones, kelp fronds, and coralline algae.',
          options: {
            'anemonePink': 'Pink Giant Anemone & Sea Kelp',
            'seaEmerald': 'Emerald Green Anemone & Sea Lettuce',
            'corallineViolet': 'Coralline Algae Violet & Purple Urchin',
            'goldenSargassum': 'Golden Sargassum & Amber Weed',
          },
        ),
        SliderField(
          key: 'saltRimCrust',
          label: 'High-Tide Salt Crust',
          description: 'Thickness of crystalline white mineral crust ringing the basin lip.',
          min: 0.0,
          max: 1.0,
          divisions: 20,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        SliderField(
          key: 'waterClarity',
          label: 'Saltwater Clarity',
          description: 'Transparency index revealing pebbles and anemones beneath caustics.',
          min: 0.3,
          max: 1.0,
          divisions: 14,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        SliderField(
          key: 'time',
          label: 'Animation Timeline',
          description: 'Harmonic wave surge driving dancing caustics and kelp motion.',
          min: 0.0,
          max: 1.0,
          divisions: 100,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        const BoolField(
          key: 'preserveAlpha',
          label: 'Preserve Alpha',
          description: 'Restrict tide pool water and caustics strictly to sprite pixels.',
        ),
      ];

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    final output = Uint32List(width * height);

    final double depth = ((parameters['poolDepth'] as num?)?.toDouble() ?? 0.65).clamp(0.1, 1.2);
    final double caustics = ((parameters['causticShimmer'] as num?)?.toDouble() ?? 0.7).clamp(0.05, 1.2);
    final double waveSpeed = ((parameters['kelpWaveSpeed'] as num?)?.toDouble() ?? 1.4).clamp(0.2, 4.0);
    final String biomass = parameters['biomassColor'] as String? ?? 'anemonePink';
    final double saltCrust = ((parameters['saltRimCrust'] as num?)?.toDouble() ?? 0.45).clamp(0.0, 1.0);
    final double clarity = ((parameters['waterClarity'] as num?)?.toDouble() ?? 0.8).clamp(0.1, 1.0);
    final double time = ((parameters['time'] as num?)?.toDouble() ?? 0.0).clamp(0.0, 1.0);
    final bool preserveAlpha = parameters['preserveAlpha'] as bool? ?? false;

    final tau = time * 2.0 * math.pi;
    final palette = _getTidalPalette(biomass);

    // Basin center & dimensions
    final double centerX = width * 0.5;
    final double centerY = height * 0.52;
    final double radiusX = width * 0.42;
    final double radiusY = height * 0.38;

    // Kelp frond anchors (2 waving ribbons)
    final double kelpAnchor1X = centerX - width * 0.14;
    final double kelpAnchor2X = centerX + width * 0.16;

    // Anemone center
    final double anemoneX = centerX + width * 0.04;
    final double anemoneY = centerY + height * 0.08;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int idx = y * width + x;
        final int origPixel = pixels[idx];
        final int origA = (origPixel >> 24) & 0xFF;
        final int origR = (origPixel >> 16) & 0xFF;
        final int origG = (origPixel >> 8) & 0xFF;
        final int origB = origPixel & 0xFF;

        // Organic basin boundary with rock perimeter jitter
        final double nx = (x - centerX) / radiusX;
        final double ny = (y - centerY) / radiusY;
        final double angle = math.atan2(ny, nx);
        final double perimeterNoise = math.sin(angle * 5.0) * 0.06 + math.cos(angle * 8.0) * 0.03;
        final double normDist = math.sqrt(nx * nx + ny * ny) - perimeterNoise;

        // Dynamic water caustics (dancing dual-wave Voronoi approximation)
        final double cWave1 = math.sin(x * 0.38 + tau * waveSpeed + math.sin(y * 0.28)) * 0.5 + 0.5;
        final double cWave2 = math.cos(y * 0.35 - tau * waveSpeed * 0.8 + math.cos(x * 0.31)) * 0.5 + 0.5;
        final double cWave3 = math.sin((x + y) * 0.25 + tau * waveSpeed * 1.2) * 0.5 + 0.5;
        final double rawCaustic = math.max(0.0, 1.0 - (cWave1 * 0.5 + cWave2 * 0.3 + cWave3 * 0.2 - 0.45).abs() * 3.5);
        final double causticIntensity = math.pow(rawCaustic, 2.2).toDouble() * caustics;

        _RGB surfaceColor;

        if (normDist <= 1.0) {
          // Inside the saltwater basin
          final double depthNorm = (1.0 - normDist).clamp(0.0, 1.0) * depth;

          // Pebble substrate pattern
          final double pebbleGrid = (math.sin(x * 0.8) * math.cos(y * 0.8) + 1.0) * 0.5;
          final _RGB pebbleColor = _RGB(
            (palette.sandFloor.r * (0.8 + pebbleGrid * 0.4)).clamp(0, 255).round(),
            (palette.sandFloor.g * (0.8 + pebbleGrid * 0.4)).clamp(0, 255).round(),
            (palette.sandFloor.b * (0.8 + pebbleGrid * 0.4)).clamp(0, 255).round(),
          );

          // Check Kelp ribbons swaying in wave surge
          double kelpAlpha = 0.0;
          // Kelp ribbon 1
          final double kelpSway1 = math.sin(tau * waveSpeed + y * 0.18) * (width * 0.08);
          final double distKelp1 = (x - (kelpAnchor1X + kelpSway1)).abs();
          if (distKelp1 <= 1.4 && y >= centerY - height * 0.24 && y <= centerY + height * 0.3) {
            kelpAlpha = math.max(kelpAlpha, 1.0 - distKelp1 / 1.4);
          }

          // Kelp ribbon 2
          final double kelpSway2 = math.cos(tau * waveSpeed * 0.9 + y * 0.22) * (width * 0.07);
          final double distKelp2 = (x - (kelpAnchor2X + kelpSway2)).abs();
          if (distKelp2 <= 1.4 && y >= centerY - height * 0.18 && y <= centerY + height * 0.32) {
            kelpAlpha = math.max(kelpAlpha, 1.0 - distKelp2 / 1.4);
          }

          // Check Sea Anemone tentacles radiating from center
          double anemoneAlpha = 0.0;
          final double adx = (x - anemoneX);
          final double ady = (y - anemoneY);
          final double aDist = math.sqrt(adx * adx + ady * ady);
          if (aDist <= width * 0.14) {
            final double aAngle = math.atan2(ady, adx);
            final double tentacleWave = math.sin(aAngle * 12.0 + tau * waveSpeed * 2.0);
            if (tentacleWave > 0.4) {
              anemoneAlpha = (1.0 - aDist / (width * 0.14)) * 0.9;
            }
          }

          // Base substrate + organisms
          _RGB substrate = pebbleColor;
          if (anemoneAlpha > 0.1) {
            substrate = _blendRGB(substrate, palette.anemoneColor, anemoneAlpha);
          }
          if (kelpAlpha > 0.1) {
            substrate = _blendRGB(substrate, palette.kelpColor, kelpAlpha);
          }

          // Saltwater optical transmission & depth absorption
          final _RGB waterTinge = palette.waterColor;
          final double waterOpacity = (depthNorm * (1.0 - clarity * 0.4)).clamp(0.15, 0.85);
          final _RGB submerged = _blendRGB(substrate, waterTinge, waterOpacity);

          // Add dancing caustics network
          final int rCaustic = (submerged.r + palette.causticLight.r * causticIntensity * 0.85).clamp(0, 255).round();
          final int gCaustic = (submerged.g + palette.causticLight.g * causticIntensity * 0.85).clamp(0, 255).round();
          final int bCaustic = (submerged.b + palette.causticLight.b * causticIntensity * 0.85).clamp(0, 255).round();

          surfaceColor = _RGB(rCaustic, gCaustic, bCaustic);
        } else if (normDist <= 1.08 && saltCrust > 0.05) {
          // White crystalline salt rim crust along rock edge
          final double saltNorm = ((normDist - 1.0) / 0.08).clamp(0.0, 1.0);
          final double crystalNoise = math.sin(x * 1.5 + y * 1.2) * 0.2;
          final double saltDensity = (1.0 - saltNorm + crystalNoise).clamp(0.0, 1.0) * saltCrust;

          surfaceColor = _blendRGB(palette.graniteRock, palette.saltWhite, saltDensity);
        } else {
          // Surrounding weathered granite rock shelf
          final double rockTexture = math.sin(x * 0.4) * math.cos(y * 0.4) * 0.15;
          final int rRock = (palette.graniteRock.r * (0.85 + rockTexture)).clamp(0, 255).round();
          final int gRock = (palette.graniteRock.g * (0.85 + rockTexture)).clamp(0, 255).round();
          final int bRock = (palette.graniteRock.b * (0.85 + rockTexture)).clamp(0, 255).round();

          surfaceColor = _RGB(rRock, gRock, bRock);
        }

        if (preserveAlpha) {
          if (origA == 0) {
            output[idx] = 0;
            continue;
          }

          // Composite tidepool water, caustics, and marine flora over sprite
          final int rFinal = (origR * 0.35 + surfaceColor.r * 0.65).clamp(0, 255).round();
          final int gFinal = (origG * 0.35 + surfaceColor.g * 0.65).clamp(0, 255).round();
          final int bFinal = (origB * 0.35 + surfaceColor.b * 0.65).clamp(0, 255).round();

          output[idx] = (origA << 24) | (rFinal << 16) | (gFinal << 8) | bFinal;
        } else {
          // Full tidepool backdrop
          double baseR = surfaceColor.r.toDouble();
          double baseG = surfaceColor.g.toDouble();
          double baseB = surfaceColor.b.toDouble();

          if (origA > 0 && normDist <= 1.0) {
            // Inside pool: sprite submerged under water with caustics washing over it
            final double alphaNorm = (origA / 255.0) * 0.5;
            baseR = baseR * (1.0 - alphaNorm) + origR * alphaNorm;
            baseG = baseG * (1.0 - alphaNorm) + origG * alphaNorm;
            baseB = baseB * (1.0 - alphaNorm) + origB * alphaNorm;
            // Caustic highlight on submerged sprite
            baseR += palette.causticLight.r * causticIntensity * 0.6;
            baseG += palette.causticLight.g * causticIntensity * 0.6;
            baseB += palette.causticLight.b * causticIntensity * 0.6;
          } else if (origA > 0) {
            // Outside pool: rock shelf
            baseR = baseR * 0.4 + origR * 0.6;
            baseG = baseG * 0.4 + origG * 0.6;
            baseB = baseB * 0.4 + origB * 0.6;
          }

          final int r = baseR.clamp(0.0, 255.0).round();
          final int g = baseG.clamp(0.0, 255.0).round();
          final int b = baseB.clamp(0.0, 255.0).round();

          output[idx] = (0xFF << 24) | (r << 16) | (g << 8) | b;
        }
      }
    }

    return output;
  }

  static _RGB _blendRGB(_RGB a, _RGB b, double factor) {
    final double f = factor.clamp(0.0, 1.0);
    return _RGB(
      (a.r * (1.0 - f) + b.r * f).round(),
      (a.g * (1.0 - f) + b.g * f).round(),
      (a.b * (1.0 - f) + b.b * f).round(),
    );
  }

  static _TidalPalette _getTidalPalette(String biomass) {
    switch (biomass) {
      case 'seaEmerald':
        return const _TidalPalette(
          waterColor: _RGB(15, 185, 170),
          causticLight: _RGB(220, 255, 245),
          kelpColor: _RGB(25, 140, 50),
          anemoneColor: _RGB(50, 235, 140),
          sandFloor: _RGB(190, 180, 145),
          saltWhite: _RGB(255, 255, 255),
          graniteRock: _RGB(55, 58, 62),
        );
      case 'corallineViolet':
        return const _TidalPalette(
          waterColor: _RGB(20, 140, 210),
          causticLight: _RGB(215, 240, 255),
          kelpColor: _RGB(75, 45, 120),
          anemoneColor: _RGB(225, 60, 200),
          sandFloor: _RGB(210, 195, 180),
          saltWhite: _RGB(255, 255, 255),
          graniteRock: _RGB(52, 50, 58),
        );
      case 'goldenSargassum':
        return const _TidalPalette(
          waterColor: _RGB(30, 165, 155),
          causticLight: _RGB(255, 250, 220),
          kelpColor: _RGB(180, 125, 30),
          anemoneColor: _RGB(245, 175, 50),
          sandFloor: _RGB(225, 205, 155),
          saltWhite: _RGB(255, 255, 255),
          graniteRock: _RGB(62, 58, 52),
        );
      case 'anemonePink':
      default:
        return const _TidalPalette(
          waterColor: _RGB(0, 180, 205),
          causticLight: _RGB(230, 255, 255),
          kelpColor: _RGB(45, 125, 60),
          anemoneColor: _RGB(255, 110, 170),
          sandFloor: _RGB(215, 195, 160),
          saltWhite: _RGB(255, 255, 255),
          graniteRock: _RGB(58, 60, 65),
        );
    }
  }
}

class _TidalPalette {
  final _RGB waterColor;
  final _RGB causticLight;
  final _RGB kelpColor;
  final _RGB anemoneColor;
  final _RGB sandFloor;
  final _RGB saltWhite;
  final _RGB graniteRock;

  const _TidalPalette({
    required this.waterColor,
    required this.causticLight,
    required this.kelpColor,
    required this.anemoneColor,
    required this.sandFloor,
    required this.saltWhite,
    required this.graniteRock,
  });
}
