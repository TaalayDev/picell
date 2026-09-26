part of 'effects.dart';

/// An effect that procedurally renders concentric 3D stair-stepped cubic hopper crystals
/// with thin-film rainbow oxidation interference colors, hollow square terraces, and sharp 90-degree facets.
class BismuthCrystalsEffect extends Effect {
  BismuthCrystalsEffect([Map<String, dynamic>? params])
      : super(
          EffectType.bismuthCrystals,
          params ??
              {
                'hopperStepCount': 6,
                'iridescencePalette': 'rainbowOxide',
                'hollowCoreRatio': 0.4,
                'specularEdge': 0.7,
                'time': 0.0,
                'preserveAlpha': false,
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() => {
        'hopperStepCount': 6,
        'iridescencePalette': 'rainbowOxide',
        'hollowCoreRatio': 0.4,
        'specularEdge': 0.7,
        'time': 0.0,
        'preserveAlpha': false,
      };

  @override
  Map<String, dynamic> getMetadata() => {
        'hopperStepCount': {
          'label': 'Hopper Step Count',
          'description': 'Number of concentric stepped cubic terraces.',
          'type': 'slider',
          'min': 3,
          'max': 12,
          'step': 1,
        },
        'iridescencePalette': {
          'label': 'Iridescence Palette',
          'description': 'Thin-film rainbow oxidation harmonic.',
          'type': 'select',
          'options': {
            'rainbowOxide': 'Full Spectrum Rainbow Oxide',
            'amethystOpal': 'Amethyst & Opal Violet',
            'solarAura': 'Solar Flame Gold & Amber',
            'peacockCyan': 'Peacock Cyan & Emerald',
          },
        },
        'hollowCoreRatio': {
          'label': 'Hollow Cavity Ratio',
          'description': 'Depth ratio of the central hollow hopper chamber.',
          'type': 'slider',
          'min': 0.1,
          'max': 0.8,
          'step': 0.05,
        },
        'specularEdge': {
          'label': 'Specular Facet Glint',
          'description': 'Intensity of bright metallic 90-degree edge reflections.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'step': 0.05,
        },
        'time': {
          'label': 'Animation Time',
          'description': 'Thin-film chromatic wavelength shift and specular rotation.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'step': 0.01,
        },
        'preserveAlpha': {
          'label': 'Preserve Transparency',
          'description': 'Restrict crystal geometry to existing sprite silhouette.',
          'type': 'bool',
        },
      };

  @override
  List<UIField> getFields() => [
        const SliderField(
          key: 'hopperStepCount',
          label: 'Hopper Step Count',
          description: 'Stepped cubic terraces.',
          min: 3,
          max: 12,
          divisions: 9,
          isInteger: true,
        ),
        const SelectField(
          key: 'iridescencePalette',
          label: 'Iridescence Palette',
          description: 'Thin-film oxide harmonic.',
          options: {
            'rainbowOxide': 'Full Spectrum Rainbow Oxide',
            'amethystOpal': 'Amethyst & Opal Violet',
            'solarAura': 'Solar Flame Gold & Amber',
            'peacockCyan': 'Peacock Cyan & Emerald',
          },
        ),
        const SliderField(
          key: 'hollowCoreRatio',
          label: 'Hollow Cavity Ratio',
          description: 'Hollow chamber depth.',
          min: 0.1,
          max: 0.8,
          divisions: 14,
        ),
        const SliderField(
          key: 'specularEdge',
          label: 'Specular Facet Glint',
          description: 'Metallic edge reflection.',
          min: 0.0,
          max: 1.0,
          divisions: 20,
        ),
        const SliderField(
          key: 'time',
          label: 'Animation Time',
          description: 'Chromatic wavelength cycle.',
          min: 0.0,
          max: 1.0,
          divisions: 100,
        ),
        const BoolField(
          key: 'preserveAlpha',
          label: 'Preserve Transparency',
          description: 'Restrict to existing sprite silhouette.',
        ),
      ];

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    if (width <= 0 || height <= 0) return pixels;

    final hopperStepCount = (parameters['hopperStepCount'] as num?)?.toInt() ?? 6;
    final iridescencePalette = parameters['iridescencePalette'] as String? ?? 'rainbowOxide';
    final hollowCoreRatio = (parameters['hollowCoreRatio'] as num?)?.toDouble() ?? 0.4;
    final specularEdge = (parameters['specularEdge'] as num?)?.toDouble() ?? 0.7;
    final time = (parameters['time'] as num?)?.toDouble() ?? 0.0;
    final preserveAlpha = parameters['preserveAlpha'] as bool? ?? false;

    final output = Uint32List(width * height);
    final cycleTime = time - time.floorToDouble();

    // Center of crystal growth
    final cx = width / 2.0;
    final cy = height / 2.0;
    final maxDim = math.min(width, height) / 2.0;

    // Thin-film interference color generator based on oxide thickness
    List<int> getOxideColor(double phase) {
      final p = (phase + cycleTime) % 1.0;
      switch (iridescencePalette) {
        case 'amethystOpal':
          // Magenta, violet, electric blue, soft rose
          final r = (180 + 75 * math.sin(p * math.pi * 2.0)).round().clamp(0, 255);
          final g = (60 + 55 * math.cos(p * math.pi * 2.0)).round().clamp(0, 255);
          final b = (220 + 35 * math.sin((p + 0.3) * math.pi * 2.0)).round().clamp(0, 255);
          return [r, g, b];
        case 'solarAura':
          // Crimson, gold, incandescent amber, solar white
          final r = (230 + 25 * math.sin(p * math.pi * 2.0)).round().clamp(0, 255);
          final g = (140 + 100 * math.sin(p * math.pi * 2.0)).round().clamp(0, 255);
          final b = (25 + 25 * math.cos(p * math.pi * 2.0)).round().clamp(0, 255);
          return [r, g, b];
        case 'peacockCyan':
          // Deep teal, emerald green, peacock cyan, royal blue
          final r = (20 + 40 * math.sin(p * math.pi * 2.0)).round().clamp(0, 255);
          final g = (175 + 75 * math.sin(p * math.pi * 2.0)).round().clamp(0, 255);
          final b = (210 + 45 * math.cos(p * math.pi * 2.0)).round().clamp(0, 255);
          return [r, g, b];
        case 'rainbowOxide':
        default:
          // Classic Newton thin-film spectrum: Gold -> Magenta -> Cyan -> Emerald -> Violet
          final angle = p * math.pi * 2.0;
          final r = (127.5 + 127.5 * math.sin(angle)).round().clamp(0, 255);
          final g = (127.5 + 127.5 * math.sin(angle + 2.094)).round().clamp(0, 255);
          final b = (127.5 + 127.5 * math.sin(angle + 4.188)).round().clamp(0, 255);
          return [r, g, b];
      }
    }

    for (int y = 0; y < height; y++) {
      final dy = y - cy;
      for (int x = 0; x < width; x++) {
        final dx = x - cx;
        final idx = y * width + x;
        final origA = (pixels[idx] >> 24) & 0xFF;

        if (preserveAlpha && origA == 0) continue;

        // Chebyshev distance for concentric 90-degree square cubic hopper terraces
        final chebDist = math.max(dx.abs(), dy.abs());
        final normDist = chebDist / maxDim;

        // Terrace level (quantized step)
        final rawStep = (normDist * hopperStepCount);
        final stepIndex = rawStep.floor();
        final stepFrac = rawStep - stepIndex;

        // Central hollow cavity check
        final isHollowCenter = normDist < (hollowCoreRatio / hopperStepCount);

        int r, g, b;

        if (isHollowCenter) {
          // Dark metallic cavity core with deep specular abyss
          r = 18;
          g = 15;
          b = 24;
        } else {
          // Oxide layer interference color based on step height terrace
          final oxideColor = getOxideColor(stepIndex / hopperStepCount.toDouble());

          // Staircase facet shading:
          // Top horizontal treads are illuminated, vertical riser faces are shaded
          final isRiserEdge = (stepFrac < 0.22);
          final isTread = !isRiserEdge;

          // Directional lighting from top-left (-0.7, -0.7)
          final isTopLeftFacet = (dx <= 0 && dy <= 0);
          final isBottomRightFacet = (dx > 0 || dy > 0);

          double lightFactor = 1.0;
          if (isTopLeftFacet) {
            lightFactor = isTread ? 1.25 : 0.95;
          } else if (isBottomRightFacet) {
            lightFactor = isTread ? 0.85 : 0.60;
          }

          r = (oxideColor[0] * lightFactor).round().clamp(0, 255);
          g = (oxideColor[1] * lightFactor).round().clamp(0, 255);
          b = (oxideColor[2] * lightFactor).round().clamp(0, 255);

          // Sharp 90-degree corner facet glint
          final isCorner = (dx.abs() - dy.abs()).abs() <= 1.0;
          final isStepRidge = (stepFrac < 0.12 || stepFrac > 0.88);

          if ((isCorner || isStepRidge) && specularEdge > 0.1) {
            // Specular metallic sheen glint traveling along corners
            final cornerPhase = (chebDist * 0.15 - cycleTime * 2.0).abs();
            final glintIntensity = math.max(0.0, 1.0 - (cornerPhase % 1.0) * 3.0);

            final specularBoost = (255 * specularEdge * glintIntensity).round();
            r = (r + specularBoost).clamp(0, 255);
            g = (g + specularBoost).clamp(0, 255);
            b = (b + specularBoost).clamp(0, 255);
          }
        }

        final targetA = preserveAlpha ? origA : 255;
        output[idx] = (targetA << 24) | (r << 16) | (g << 8) | b;
      }
    }

    return output;
  }
}
