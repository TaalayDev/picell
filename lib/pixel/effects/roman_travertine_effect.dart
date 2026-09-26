part of 'effects.dart';

/// An effect that procedurally transforms an image into weathered Roman
/// travertine stone with ashlar masonry blocks, elongated karst pore cavities,
/// horizontal sedimentary bedding bands, and recessed crumbly mortar joints.
class RomanTravertineEffect extends Effect {
  RomanTravertineEffect([Map<String, dynamic>? params])
      : super(
          EffectType.romanTravertine,
          params ??
              {
                'blockScale': 6.0,
                'poreDensity': 0.45,
                'beddingBands': 0.6,
                'mortarWidth': 1.8,
                'stoneErosion': 0.5,
                'travertinePalette': 'classicIvory',
                'preserveAlpha': true,
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() => {
        'blockScale': 6.0,
        'poreDensity': 0.45,
        'beddingBands': 0.6,
        'mortarWidth': 1.8,
        'stoneErosion': 0.5,
        'travertinePalette': 'classicIvory',
        'preserveAlpha': true,
      };

  @override
  Map<String, dynamic> getMetadata() => {
        'blockScale': {
          'label': 'Ashlar Block Scale',
          'description': 'Dimensions and course height of cut stone masonry blocks.',
          'type': 'slider',
          'min': 2.0,
          'max': 12.0,
          'step': 0.5,
        },
        'poreDensity': {
          'label': 'Karst Pore Density',
          'description': 'Occurrence of dissolved mineral spring cavities and pitted voids.',
          'type': 'slider',
          'min': 0.1,
          'max': 1.0,
          'step': 0.05,
        },
        'beddingBands': {
          'label': 'Sedimentary Bedding Strata',
          'description': 'Contrast of horizontal calcite and travertine sedimentation layers.',
          'type': 'slider',
          'min': 0.1,
          'max': 1.0,
          'step': 0.05,
        },
        'mortarWidth': {
          'label': 'Lime Mortar Joint Width',
          'description': 'Thickness of recessed crumbly sand-lime mortar channels.',
          'type': 'slider',
          'min': 1.0,
          'max': 4.0,
          'step': 0.2,
        },
        'stoneErosion': {
          'label': 'Chiseled Edge Erosion',
          'description': 'Hand-hewn beveling, rounded block corners, and ancient wear.',
          'type': 'slider',
          'min': 0.1,
          'max': 1.0,
          'step': 0.05,
        },
        'travertinePalette': {
          'label': 'Travertine Stone Palette',
          'description': 'Mineral coloration and geological quarry origin.',
          'type': 'select',
          'options': {
            'classicIvory': 'Roman Classic Ivory',
            'tuscanyNoce': 'Tuscan Walnut Noce',
            'silverVein': 'Silver Vein Navona',
            'pompeiiOchre': 'Pompeian Volcanic Ochre',
          },
        },
        'preserveAlpha': {
          'label': 'Preserve Alpha',
          'description': 'Restrict stone texture strictly to existing sprite silhouette.',
          'type': 'bool',
        },
      };

  @override
  List<UIField> getFields() => [
        SliderField(
          key: 'blockScale',
          label: 'Ashlar Block Scale',
          description: 'Dimensions and course height of cut stone masonry blocks.',
          min: 2.0,
          max: 12.0,
          divisions: 20,
          formatLabel: (v) => '${v.toStringAsFixed(1)}x',
        ),
        SliderField(
          key: 'poreDensity',
          label: 'Karst Pore Density',
          description: 'Occurrence of dissolved mineral spring cavities and pitted voids.',
          min: 0.1,
          max: 1.0,
          divisions: 18,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        SliderField(
          key: 'beddingBands',
          label: 'Sedimentary Bedding Strata',
          description: 'Contrast of horizontal calcite and travertine sedimentation layers.',
          min: 0.1,
          max: 1.0,
          divisions: 18,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        SliderField(
          key: 'mortarWidth',
          label: 'Lime Mortar Joint Width',
          description: 'Thickness of recessed crumbly sand-lime mortar channels.',
          min: 1.0,
          max: 4.0,
          divisions: 15,
          formatLabel: (v) => '${v.toStringAsFixed(1)}px',
        ),
        SliderField(
          key: 'stoneErosion',
          label: 'Chiseled Edge Erosion',
          description: 'Hand-hewn beveling, rounded block corners, and ancient wear.',
          min: 0.1,
          max: 1.0,
          divisions: 18,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        const SelectField(
          key: 'travertinePalette',
          label: 'Travertine Stone Palette',
          description: 'Mineral coloration and geological quarry origin.',
          options: {
            'classicIvory': 'Roman Classic Ivory',
            'tuscanyNoce': 'Tuscan Walnut Noce',
            'silverVein': 'Silver Vein Navona',
            'pompeiiOchre': 'Pompeian Volcanic Ochre',
          },
        ),
        const BoolField(
          key: 'preserveAlpha',
          label: 'Preserve Alpha',
          description: 'Restrict stone texture strictly to existing sprite silhouette.',
        ),
      ];

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    final output = Uint32List(width * height);

    final double scale = ((parameters['blockScale'] as num?)?.toDouble() ?? 6.0).clamp(1.5, 20.0);
    final double pores = ((parameters['poreDensity'] as num?)?.toDouble() ?? 0.45).clamp(0.05, 1.0);
    final double bedding = ((parameters['beddingBands'] as num?)?.toDouble() ?? 0.6).clamp(0.05, 1.2);
    final double mortar = ((parameters['mortarWidth'] as num?)?.toDouble() ?? 1.8).clamp(0.5, 6.0);
    final double erosion = ((parameters['stoneErosion'] as num?)?.toDouble() ?? 0.5).clamp(0.05, 1.2);
    final String paletteKey = parameters['travertinePalette'] as String? ?? 'classicIvory';
    final bool preserveAlpha = parameters['preserveAlpha'] as bool? ?? true;

    final palette = _getTravertinePalette(paletteKey);

    final double courseHeight = scale * 3.2;
    final double blockWidth = scale * 6.5;

    for (int y = 0; y < height; y++) {
      final int courseIndex = (y / courseHeight).floor();
      final double yInCourse = y - courseIndex * courseHeight;
      // Stagger alternate courses by half a block width
      final double rowOffset = (courseIndex % 2 == 1) ? blockWidth * 0.5 : 0.0;

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

        final double shiftedX = x + rowOffset;
        final int blockIndex = (shiftedX / blockWidth).floor();
        final double xInBlock = shiftedX - blockIndex * blockWidth;

        // Distance to block edges (horizontal & vertical)
        final double distToHJoint = math.min(yInCourse, courseHeight - yInCourse);
        final double distToVJoint = math.min(xInBlock, blockWidth - xInBlock);
        final double distToJoint = math.min(distToHJoint, distToVJoint);

        // Irregular joint edge chipping / chiseled erosion
        final double chipNoise = math.sin(x * 0.75 + y * 0.5) * (erosion * 0.7) +
            math.cos(x * 1.6 - y * 1.1) * (erosion * 0.35);
        final double effectiveJointDist = distToJoint - chipNoise;

        final bool isMortar = effectiveJointDist <= mortar * 0.5;

        // Stone surface characteristics across block
        final double bandWobble = math.sin(x * 0.12 + courseIndex * 1.5) * 2.2;
        final double bandPhase = math.sin((y + bandWobble) * 0.45) * 0.5 + 0.5;
        final double bandFactor = (bandPhase * bedding).clamp(0.0, 1.0);

        final double poreX = (x * 0.55 + courseIndex * 13.0);
        final double poreY = (y * 1.25);
        final double rawPore = math.sin(poreX * 0.7) * math.cos(poreY * 0.5) +
            math.sin(poreX * 1.5 + poreY * 0.8) * 0.5;
        final double poreThreshold = 1.25 - pores * 0.75;
        final bool isCavity = rawPore > poreThreshold;
        final double cavityDepth = isCavity ? ((rawPore - poreThreshold) / 0.5).clamp(0.0, 1.0) : 0.0;

        final double bevelZone = mortar * 0.5 + erosion * 2.0;
        double bevelShade = 1.0;
        if (effectiveJointDist < bevelZone) {
          final double t = (effectiveJointDist / bevelZone).clamp(0.0, 1.0);
          bevelShade = 0.7 + 0.3 * math.sqrt(t);
        }

        _RGB stoneColor;

        if (isMortar) {
          // Crumbly lime mortar joint
          final double mortarGrain = math.sin(x * 2.1 + y * 1.7) * 0.12;
          final int rM = (palette.mortar.r * (0.9 + mortarGrain)).clamp(0, 255).round();
          final int gM = (palette.mortar.g * (0.9 + mortarGrain)).clamp(0, 255).round();
          final int bM = (palette.mortar.b * (0.9 + mortarGrain)).clamp(0, 255).round();
          stoneColor = _RGB(rM, gM, bM);
        } else {
          // Blend limestone body with sedimentary strata
          final _RGB stratified = _RGB(
            (palette.stoneLight.r * (1.0 - bandFactor * 0.35) + palette.stoneDark.r * (bandFactor * 0.35)).round(),
            (palette.stoneLight.g * (1.0 - bandFactor * 0.35) + palette.stoneDark.g * (bandFactor * 0.35)).round(),
            (palette.stoneLight.b * (1.0 - bandFactor * 0.35) + palette.stoneDark.b * (bandFactor * 0.35)).round(),
          );

          // Darken for pore cavities
          final double cavFactor = cavityDepth * 0.75;
          final int rPore = (stratified.r * (1.0 - cavFactor) + palette.cavity.r * cavFactor).round();
          final int gPore = (stratified.g * (1.0 - cavFactor) + palette.cavity.g * cavFactor).round();
          final int bPore = (stratified.b * (1.0 - cavFactor) + palette.cavity.b * cavFactor).round();

          // Apply 3D bevel relief
          final int rFinal = (rPore * bevelShade).clamp(0, 255).round();
          final int gFinal = (gPore * bevelShade).clamp(0, 255).round();
          final int bFinal = (bPore * bevelShade).clamp(0, 255).round();

          stoneColor = _RGB(rFinal, gFinal, bFinal);
        }

        if (preserveAlpha) {
          if (isMortar) {
            // Recessed sand-lime mortar channel carved into sprite pixels
            final double mortarGrain = (math.sin(x * 2.1 + y * 1.7) * 0.5 + 0.5) * 0.15;
            final double mortarDarken = 0.52 + mortarGrain;
            final int rOut = (origR * mortarDarken * 0.75 + palette.mortar.r * 0.25).clamp(0, 255).round();
            final int gOut = (origG * mortarDarken * 0.75 + palette.mortar.g * 0.25).clamp(0, 255).round();
            final int bOut = (origB * mortarDarken * 0.75 + palette.mortar.b * 0.25).clamp(0, 255).round();
            output[idx] = (origA << 24) | (rOut << 16) | (gOut << 8) | bOut;
          } else {
            // Inside cut ashlar block: apply bedding strata, karst pores, and edge bevel to sprite
            final double bandModulation = 1.0 + (bandFactor - 0.5) * 0.35 * bedding;
            final double cavityDarken = 1.0 - cavityDepth * 0.55;

            // Mineral tint from stone palette (15% tint, 85% original artwork)
            const double tintFactor = 0.15;
            final double rTinted = origR * (1.0 - tintFactor) + palette.stoneLight.r * tintFactor;
            final double gTinted = origG * (1.0 - tintFactor) + palette.stoneLight.g * tintFactor;
            final double bTinted = origB * (1.0 - tintFactor) + palette.stoneLight.b * tintFactor;

            final int rOut = (rTinted * bandModulation * cavityDarken * bevelShade).clamp(0, 255).round();
            final int gOut = (gTinted * bandModulation * cavityDarken * bevelShade).clamp(0, 255).round();
            final int bOut = (bTinted * bandModulation * cavityDarken * bevelShade).clamp(0, 255).round();
            output[idx] = (origA << 24) | (rOut << 16) | (gOut << 8) | bOut;
          }
        } else {
          // Full stone wall backdrop
          double rBase = stoneColor.r.toDouble();
          double gBase = stoneColor.g.toDouble();
          double bBase = stoneColor.b.toDouble();

          // If sprite exists, composite it into stone carving
          if (origA > 0) {
            final double alphaNorm = origA / 255.0;
            final double origLuma = (0.299 * origR + 0.587 * origG + 0.114 * origB) / 255.0;
            // Carved relief bas-relief blend
            final double reliefFactor = (origLuma - 0.5) * 0.4;
            rBase = (rBase * (1.0 + reliefFactor)).clamp(0.0, 255.0);
            gBase = (gBase * (1.0 + reliefFactor)).clamp(0.0, 255.0);
            bBase = (bBase * (1.0 + reliefFactor)).clamp(0.0, 255.0);

            // Subtle pigment staining from sprite
            rBase = rBase * (1.0 - alphaNorm * 0.35) + origR * (alphaNorm * 0.35);
            gBase = gBase * (1.0 - alphaNorm * 0.35) + origG * (alphaNorm * 0.35);
            bBase = bBase * (1.0 - alphaNorm * 0.35) + origB * (alphaNorm * 0.35);
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

  static _TravertinePalette _getTravertinePalette(String palette) {
    switch (palette) {
      case 'tuscanyNoce':
        return const _TravertinePalette(
          stoneLight: _RGB(198, 165, 130),
          stoneDark: _RGB(158, 120, 85),
          cavity: _RGB(82, 58, 40),
          mortar: _RGB(175, 165, 150),
        );
      case 'silverVein':
        return const _TravertinePalette(
          stoneLight: _RGB(222, 224, 228),
          stoneDark: _RGB(165, 172, 180),
          cavity: _RGB(72, 75, 82),
          mortar: _RGB(195, 198, 202),
        );
      case 'pompeiiOchre':
        return const _TravertinePalette(
          stoneLight: _RGB(218, 148, 96),
          stoneDark: _RGB(168, 95, 55),
          cavity: _RGB(68, 36, 25),
          mortar: _RGB(142, 132, 126),
        );
      case 'classicIvory':
      default:
        return const _TravertinePalette(
          stoneLight: _RGB(242, 232, 212),
          stoneDark: _RGB(198, 182, 155),
          cavity: _RGB(102, 88, 72),
          mortar: _RGB(162, 156, 146),
        );
    }
  }
}

class _TravertinePalette {
  final _RGB stoneLight;
  final _RGB stoneDark;
  final _RGB cavity;
  final _RGB mortar;

  const _TravertinePalette({
    required this.stoneLight,
    required this.stoneDark,
    required this.cavity,
    required this.mortar,
  });
}
