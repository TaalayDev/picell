part of 'effects.dart';

/// An effect that procedurally transforms an image into petrified fossil wood
/// with concentric banded chalcedony agate rings, quartz crystal druse geode
/// pockets, preserved xylem tracheid grain lines, and mineral oxide stains.
class PetrifiedAgateEffect extends Effect {
  PetrifiedAgateEffect([Map<String, dynamic>? params])
      : super(
          EffectType.petrifiedAgate,
          params ??
              {
                'ringFrequency': 6.0,
                'agateBanding': 0.75,
                'druseCavityScale': 0.4,
                'mineralOxide': 0.55,
                'woodFiberGrain': 0.5,
                'agatePalette': 'arizonaRainbow',
                'preserveAlpha': true,
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() => {
        'ringFrequency': 6.0,
        'agateBanding': 0.75,
        'druseCavityScale': 0.4,
        'mineralOxide': 0.55,
        'woodFiberGrain': 0.5,
        'agatePalette': 'arizonaRainbow',
        'preserveAlpha': true,
      };

  @override
  Map<String, dynamic> getMetadata() => {
        'ringFrequency': {
          'label': 'Growth Ring Frequency',
          'description': 'Number of fossilized annual growth rings and agate bands.',
          'type': 'slider',
          'min': 2.0,
          'max': 12.0,
          'step': 0.5,
        },
        'agateBanding': {
          'label': 'Agate Banding Contrast',
          'description': 'Sharpness and color stratification of silica chalcedony layers.',
          'type': 'slider',
          'min': 0.2,
          'max': 1.0,
          'step': 0.05,
        },
        'druseCavityScale': {
          'label': 'Quartz Geode Cavities',
          'description': 'Occurrence and size of sparkling crystalline druse pockets.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'step': 0.05,
        },
        'mineralOxide': {
          'label': 'Iron & Manganese Oxides',
          'description': 'Diffusion of vibrant mineral stains (hematite red and goethite gold).',
          'type': 'slider',
          'min': 0.1,
          'max': 1.0,
          'step': 0.05,
        },
        'woodFiberGrain': {
          'label': 'Xylem Tracheid Grain',
          'description': 'Fidelity of preserved radial wood fibers and cell ray structures.',
          'type': 'slider',
          'min': 0.1,
          'max': 1.0,
          'step': 0.05,
        },
        'agatePalette': {
          'label': 'Mineral Agate Palette',
          'description': 'Fossil gem coloration and chalcedony mineral assemblage.',
          'type': 'select',
          'options': {
            'arizonaRainbow': 'Arizona Rainbow Petrified Forest',
            'blueLace': 'Blue Lace Chalcedony',
            'carnelianFire': 'Carnelian Fire & Sardonyx',
            'blackOnyx': 'Banded Black Onyx & Quartz',
          },
        },
        'preserveAlpha': {
          'label': 'Preserve Alpha',
          'description': 'Confine petrified agate gemstone texture strictly to sprite pixels.',
          'type': 'bool',
        },
      };

  @override
  List<UIField> getFields() => [
        SliderField(
          key: 'ringFrequency',
          label: 'Growth Ring Frequency',
          description: 'Number of fossilized annual growth rings and agate bands.',
          min: 2.0,
          max: 12.0,
          divisions: 20,
          formatLabel: (v) => '${v.toStringAsFixed(1)}x',
        ),
        SliderField(
          key: 'agateBanding',
          label: 'Agate Banding Contrast',
          description: 'Sharpness and color stratification of silica chalcedony layers.',
          min: 0.2,
          max: 1.0,
          divisions: 16,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        SliderField(
          key: 'druseCavityScale',
          label: 'Quartz Geode Cavities',
          description: 'Occurrence and size of sparkling crystalline druse pockets.',
          min: 0.0,
          max: 1.0,
          divisions: 20,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        SliderField(
          key: 'mineralOxide',
          label: 'Iron & Manganese Oxides',
          description: 'Diffusion of vibrant mineral stains (hematite red and goethite gold).',
          min: 0.1,
          max: 1.0,
          divisions: 18,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        SliderField(
          key: 'woodFiberGrain',
          label: 'Xylem Tracheid Grain',
          description: 'Fidelity of preserved radial wood fibers and cell ray structures.',
          min: 0.1,
          max: 1.0,
          divisions: 18,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        const SelectField(
          key: 'agatePalette',
          label: 'Mineral Agate Palette',
          description: 'Fossil gem coloration and chalcedony mineral assemblage.',
          options: {
            'arizonaRainbow': 'Arizona Rainbow Petrified Forest',
            'blueLace': 'Blue Lace Chalcedony',
            'carnelianFire': 'Carnelian Fire & Sardonyx',
            'blackOnyx': 'Banded Black Onyx & Quartz',
          },
        ),
        const BoolField(
          key: 'preserveAlpha',
          label: 'Preserve Alpha',
          description: 'Confine petrified agate gemstone texture strictly to sprite pixels.',
        ),
      ];

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    final output = Uint32List(width * height);

    final double ringFreq = ((parameters['ringFrequency'] as num?)?.toDouble() ?? 6.0).clamp(1.0, 20.0);
    final double banding = ((parameters['agateBanding'] as num?)?.toDouble() ?? 0.75).clamp(0.1, 1.2);
    final double druseScale = ((parameters['druseCavityScale'] as num?)?.toDouble() ?? 0.4).clamp(0.0, 1.0);
    final double oxide = ((parameters['mineralOxide'] as num?)?.toDouble() ?? 0.55).clamp(0.05, 1.2);
    final double fibers = ((parameters['woodFiberGrain'] as num?)?.toDouble() ?? 0.5).clamp(0.05, 1.2);
    final String paletteKey = parameters['agatePalette'] as String? ?? 'arizonaRainbow';
    final bool preserveAlpha = parameters['preserveAlpha'] as bool? ?? true;

    final palette = _getAgatePalette(paletteKey);

    // Tree center coordinate
    final double cx = width * 0.48;
    final double cy = height * 0.52;
    final double maxR = math.sqrt(cx * cx + cy * cy);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int idx = y * width + x;
        final int origPixel = pixels[idx];
        final int origA = (origPixel >> 24) & 0xFF;
        final int origR = (origPixel >> 16) & 0xFF;
        final int origG = (origPixel >> 8) & 0xFF;
        final int origB = origPixel & 0xFF;

        if (preserveAlpha && origA == 0) {
          output[idx] = 0;
          continue;
        }

        final double dx = x - cx;
        final double dy = y - cy;
        final double r = math.sqrt(dx * dx + dy * dy);
        final double theta = math.atan2(dy, dx);

        // Deformed growth ring coordinates
        final double ringWobble = math.sin(theta * 3.0 + r * 0.05) * (r * 0.08) +
            math.cos(theta * 7.0 - r * 0.1) * (r * 0.04);
        final double distortedR = r + ringWobble;

        // Banding wave (micro-bands of chalcedony)
        final double normR = distortedR / maxR;
        final double rawBand = math.sin(normR * ringFreq * math.pi * 3.5);
        // Sharpened agate banding
        final double bandFactor = (rawBand * banding * 0.5 + 0.5).clamp(0.0, 1.0);

        // Radial xylem wood ray fibers
        final double radialFiber = math.sin(theta * 42.0 + distortedR * 0.3) * fibers * 0.18;

        // Dendritic mineral oxide staining
        final double oxideNoise = (math.sin(x * 0.18 + math.cos(y * 0.15) * 2.0) +
            math.cos(y * 0.22 - math.sin(x * 0.12) * 2.0)) * 0.5;
        final double oxidePresence = ((oxideNoise + 1.0) * 0.5 * oxide).clamp(0.0, 1.0);

        // Quartz crystal druse geode cavity check
        bool isDruse = false;
        double druseFacet = 0.0;
        if (druseScale > 0.05) {
          final double cavityCell = math.sin(x * 0.25) * math.cos(y * 0.25) +
              math.sin((x + y) * 0.15);
          if (cavityCell > 1.85 - druseScale * 0.65) {
            isDruse = true;
            // Faceted crystal reflections
            druseFacet = ((math.sin(x * 1.8) * math.cos(y * 1.8) + 1.0) * 0.5);
          }
        }

        _RGB gemColor;

        if (isDruse) {
          // Sparkling quartz crystal pocket
          final int rD = (palette.druseCrystal.r * (0.7 + druseFacet * 0.6)).clamp(0, 255).round();
          final int gD = (palette.druseCrystal.g * (0.7 + druseFacet * 0.6)).clamp(0, 255).round();
          final int bD = (palette.druseCrystal.b * (0.7 + druseFacet * 0.6)).clamp(0, 255).round();
          gemColor = _RGB(rD, gD, bD);
        } else {
          // Banded agate gemstone body
          final _RGB bandCol = _sampleBanding(palette, bandFactor, normR);

          // Add mineral oxide staining
          final int rOx = (bandCol.r * (1.0 - oxidePresence * 0.4) + palette.mineralStain.r * (oxidePresence * 0.4)).round();
          final int gOx = (bandCol.g * (1.0 - oxidePresence * 0.4) + palette.mineralStain.g * (oxidePresence * 0.4)).round();
          final int bOx = (bandCol.b * (1.0 - oxidePresence * 0.4) + palette.mineralStain.b * (oxidePresence * 0.4)).round();

          // Modulate with wood grain
          final int rFinal = (rOx * (1.0 + radialFiber)).clamp(0, 255).round();
          final int gFinal = (gOx * (1.0 + radialFiber)).clamp(0, 255).round();
          final int bFinal = (bOx * (1.0 + radialFiber)).clamp(0, 255).round();

          gemColor = _RGB(rFinal, gFinal, bFinal);
        }

        if (preserveAlpha) {
          if (isDruse) {
            // Sparkling quartz crystal pocket on sprite
            final int rOut = (origR * 0.35 + palette.druseCrystal.r * (0.65 + druseFacet * 0.35)).clamp(0, 255).round();
            final int gOut = (origG * 0.35 + palette.druseCrystal.g * (0.65 + druseFacet * 0.35)).clamp(0, 255).round();
            final int bOut = (origB * 0.35 + palette.druseCrystal.b * (0.65 + druseFacet * 0.35)).clamp(0, 255).round();
            output[idx] = (origA << 24) | (rOut << 16) | (gOut << 8) | bOut;
          } else {
            // Agate banding modulation across the sprite
            final double bandModulation = 1.0 + (bandFactor - 0.5) * 0.35 * banding;
            final double fiberModulation = 1.0 + radialFiber * 0.2 * fibers;

            // Mineral oxide stain tint (18% mineral tint, 82% original artwork)
            final double oxideTint = oxidePresence * 0.18;
            final double rTinted = origR * (1.0 - oxideTint) + palette.mineralStain.r * oxideTint;
            final double gTinted = origG * (1.0 - oxideTint) + palette.mineralStain.g * oxideTint;
            final double bTinted = origB * (1.0 - oxideTint) + palette.mineralStain.b * oxideTint;

            final int rOut = (rTinted * bandModulation * fiberModulation).clamp(0, 255).round();
            final int gOut = (gTinted * bandModulation * fiberModulation).clamp(0, 255).round();
            final int bOut = (bTinted * bandModulation * fiberModulation).clamp(0, 255).round();
            output[idx] = (origA << 24) | (rOut << 16) | (gOut << 8) | bOut;
          }
        } else {
          // Full petrified agate cross-section
          double rBase = gemColor.r.toDouble();
          double gBase = gemColor.g.toDouble();
          double bBase = gemColor.b.toDouble();

          if (origA > 0) {
            final double alphaNorm = origA / 255.0;
            rBase = rBase * (1.0 - alphaNorm * 0.5) + origR * (alphaNorm * 0.5);
            gBase = gBase * (1.0 - alphaNorm * 0.5) + origG * (alphaNorm * 0.5);
            bBase = bBase * (1.0 - alphaNorm * 0.5) + origB * (alphaNorm * 0.5);
          }

          final int r = rBase.clamp(0.0, 255.0).round();
          final int g = gBase.clamp(0.0, 255.0).round();
          final int b = bBase.clamp(0.0, 255.0).round();

          output[idx] = (0xFF << 24) | (r << 16) | (g << 8) | b;
        }
      }
    }

    return output;
  }

  static _RGB _sampleBanding(_AgatePalette palette, double factor, double normR) {
    if (factor < 0.5) {
      final double t = factor / 0.5;
      return _RGB(
        (palette.bandA.r + (palette.bandB.r - palette.bandA.r) * t).round(),
        (palette.bandA.g + (palette.bandB.g - palette.bandA.g) * t).round(),
        (palette.bandA.b + (palette.bandB.b - palette.bandA.b) * t).round(),
      );
    } else {
      final double t = (factor - 0.5) / 0.5;
      return _RGB(
        (palette.bandB.r + (palette.bandC.r - palette.bandB.r) * t).round(),
        (palette.bandB.g + (palette.bandC.g - palette.bandB.g) * t).round(),
        (palette.bandB.b + (palette.bandC.b - palette.bandB.b) * t).round(),
      );
    }
  }

  static _AgatePalette _getAgatePalette(String palette) {
    switch (palette) {
      case 'blueLace':
        return const _AgatePalette(
          bandA: _RGB(165, 195, 235),
          bandB: _RGB(220, 232, 248),
          bandC: _RGB(125, 150, 195),
          mineralStain: _RGB(85, 105, 145),
          druseCrystal: _RGB(250, 252, 255),
        );
      case 'carnelianFire':
        return const _AgatePalette(
          bandA: _RGB(235, 95, 30),
          bandB: _RGB(255, 185, 65),
          bandC: _RGB(160, 42, 18),
          mineralStain: _RGB(95, 24, 12),
          druseCrystal: _RGB(255, 245, 220),
        );
      case 'blackOnyx':
        return const _AgatePalette(
          bandA: _RGB(25, 25, 28),
          bandB: _RGB(245, 248, 250),
          bandC: _RGB(75, 78, 85),
          mineralStain: _RGB(45, 48, 55),
          druseCrystal: _RGB(255, 255, 255),
        );
      case 'arizonaRainbow':
      default:
        return const _AgatePalette(
          bandA: _RGB(215, 65, 45), // Jasper red
          bandB: _RGB(245, 195, 65), // Amber yellow
          bandC: _RGB(135, 55, 120), // Amethyst purple
          mineralStain: _RGB(65, 25, 20), // Iron oxide
          druseCrystal: _RGB(255, 250, 240), // Quartz white
        );
    }
  }
}

class _AgatePalette {
  final _RGB bandA;
  final _RGB bandB;
  final _RGB bandC;
  final _RGB mineralStain;
  final _RGB druseCrystal;

  const _AgatePalette({
    required this.bandA,
    required this.bandB,
    required this.bandC,
    required this.mineralStain,
    required this.druseCrystal,
  });
}
