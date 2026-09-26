part of 'effects.dart';

/// An effect that procedurally transforms an image into traditional Japanese
/// kintsugi lacquerware or porcelain fractured with ceramic crack networks,
/// mended with raised impasto seams of pure 24k gold leaf and dusted powder.
class KintsugiLacquerEffect extends Effect {
  KintsugiLacquerEffect([Map<String, dynamic>? params])
      : super(
          EffectType.kintsugiLacquer,
          params ??
              {
                'fractureDensity': 0.5,
                'goldSeamWidth': 2.0,
                'seamImpastoRelief': 0.7,
                'lacquerSheen': 0.6,
                'goldDustSpatter': 0.45,
                'kintsugiStyle': 'goldUrushi',
                'preserveAlpha': true,
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() => {
        'fractureDensity': 0.5,
        'goldSeamWidth': 2.0,
        'seamImpastoRelief': 0.7,
        'lacquerSheen': 0.6,
        'goldDustSpatter': 0.45,
        'kintsugiStyle': 'goldUrushi',
        'preserveAlpha': true,
      };

  @override
  Map<String, dynamic> getMetadata() => {
        'fractureDensity': {
          'label': 'Fracture Crack Density',
          'description': 'Frequency and spiderweb network of broken porcelain shards.',
          'type': 'slider',
          'min': 0.2,
          'max': 1.0,
          'step': 0.05,
        },
        'goldSeamWidth': {
          'label': 'Gold Seam Width',
          'description': 'Thickness of mended 24k gold leaf or platinum lacquer seams.',
          'type': 'slider',
          'min': 1.0,
          'max': 4.0,
          'step': 0.2,
        },
        'seamImpastoRelief': {
          'label': 'Seam Impasto Relief',
          'description': 'Raised 3D tactile curvature of the mending lacquer bead.',
          'type': 'slider',
          'min': 0.2,
          'max': 1.0,
          'step': 0.05,
        },
        'lacquerSheen': {
          'label': 'Urushi Lacquer Sheen',
          'description': 'Smooth vitreous gloss and deep luster of the pottery substrate.',
          'type': 'slider',
          'min': 0.2,
          'max': 1.0,
          'step': 0.05,
        },
        'goldDustSpatter': {
          'label': 'Gold Dust Makie Spatter',
          'description': 'Density of dusted metallic powder flakes sprinkled along seam margins.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'step': 0.05,
        },
        'kintsugiStyle': {
          'label': 'Kintsugi Master Style',
          'description': 'Ceramic substrate material and precious metal mending formula.',
          'type': 'select',
          'options': {
            'goldUrushi': 'Black Urushi & 24K Pure Gold',
            'silverPlatinum': 'Slate Stoneware & Silver Platinum',
            'vermilionMend': 'Ivory Porcelain & Cinnabar Vermilion',
            'celadonCrackle': 'Jade Celadon & Golden Crazing',
          },
        },
        'preserveAlpha': {
          'label': 'Preserve Alpha',
          'description': 'Confine kintsugi cracks and gold seams strictly to sprite pixels.',
          'type': 'bool',
        },
      };

  @override
  List<UIField> getFields() => [
        SliderField(
          key: 'fractureDensity',
          label: 'Fracture Crack Density',
          description: 'Frequency and spiderweb network of broken porcelain shards.',
          min: 0.2,
          max: 1.0,
          divisions: 16,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        SliderField(
          key: 'goldSeamWidth',
          label: 'Gold Seam Width',
          description: 'Thickness of mended 24k gold leaf or platinum lacquer seams.',
          min: 1.0,
          max: 4.0,
          divisions: 15,
          formatLabel: (v) => '${v.toStringAsFixed(1)}px',
        ),
        SliderField(
          key: 'seamImpastoRelief',
          label: 'Seam Impasto Relief',
          description: 'Raised 3D tactile curvature of the mending lacquer bead.',
          min: 0.2,
          max: 1.0,
          divisions: 16,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        SliderField(
          key: 'lacquerSheen',
          label: 'Urushi Lacquer Sheen',
          description: 'Smooth vitreous gloss and deep luster of the pottery substrate.',
          min: 0.2,
          max: 1.0,
          divisions: 16,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        SliderField(
          key: 'goldDustSpatter',
          label: 'Gold Dust Makie Spatter',
          description: 'Density of dusted metallic powder flakes sprinkled along seam margins.',
          min: 0.0,
          max: 1.0,
          divisions: 20,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        const SelectField(
          key: 'kintsugiStyle',
          label: 'Kintsugi Master Style',
          description: 'Ceramic substrate material and precious metal mending formula.',
          options: {
            'goldUrushi': 'Black Urushi & 24K Pure Gold',
            'silverPlatinum': 'Slate Stoneware & Silver Platinum',
            'vermilionMend': 'Ivory Porcelain & Cinnabar Vermilion',
            'celadonCrackle': 'Jade Celadon & Golden Crazing',
          },
        ),
        const BoolField(
          key: 'preserveAlpha',
          label: 'Preserve Alpha',
          description: 'Confine kintsugi cracks and gold seams strictly to sprite pixels.',
        ),
      ];

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    final output = Uint32List(width * height);

    final double density = ((parameters['fractureDensity'] as num?)?.toDouble() ?? 0.5).clamp(0.1, 1.2);
    final double seamWidth = ((parameters['goldSeamWidth'] as num?)?.toDouble() ?? 2.0).clamp(0.5, 6.0);
    final double impasto = ((parameters['seamImpastoRelief'] as num?)?.toDouble() ?? 0.7).clamp(0.1, 1.2);
    final double sheen = ((parameters['lacquerSheen'] as num?)?.toDouble() ?? 0.6).clamp(0.1, 1.0);
    final double dust = ((parameters['goldDustSpatter'] as num?)?.toDouble() ?? 0.45).clamp(0.0, 1.0);
    final String styleKey = parameters['kintsugiStyle'] as String? ?? 'goldUrushi';
    final bool preserveAlpha = parameters['preserveAlpha'] as bool? ?? true;

    final style = _getKintsugiStyle(styleKey);

    // Light vector from top-left for 3D specular metallic seam relief
    const double lightDx = -0.6;
    const double lightDy = -0.6;
    const double lightDz = 0.53;

    final double cellScale = 16.0 / density;

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

        // Ceramic fracture network calculation
        final double nx = x / cellScale;
        final double ny = y / cellScale;

        // Jittered distance-field approximation for spiderweb crack fissures
        final double w1 = math.sin(nx * 3.14159 + math.sin(ny * 2.0)) * 0.5 + 0.5;
        final double w2 = math.cos(ny * 3.14159 - math.cos(nx * 2.5)) * 0.5 + 0.5;
        final double w3 = math.sin((nx + ny) * 2.2 + math.sin(nx * 4.0) * 0.4) * 0.5 + 0.5;

        // Distance to fracture boundary
        final double diff1 = (w1 - w2).abs();
        final double diff2 = (w2 - w3).abs();
        final double diff3 = (w3 - w1).abs();
        final double minCrackDist = math.min(diff1, math.min(diff2, diff3)) * cellScale * 0.65;

        final double halfSeam = seamWidth * 0.5;
        final bool isSeam = minCrackDist <= halfSeam;

        // Gold dust spatter flakes in halo outside the seam
        bool isGoldDustFlake = false;
        if (!isSeam && dust > 0.02 && minCrackDist <= halfSeam * 3.2) {
          final double flakeHash = _hash(x * 37 + y * 97);
          final double dustProb = dust * 0.28 * (1.0 - (minCrackDist - halfSeam) / (halfSeam * 2.2));
          isGoldDustFlake = flakeHash < dustProb;
        }

        _RGB outColor;

        if (isSeam) {
          // Inside 24k gold / precious metal repair seam
          final double seamT = (minCrackDist / halfSeam).clamp(0.0, 1.0);
          // Parabolic 3D height profile
          final double heightProfile = (1.0 - seamT * seamT);

          // Approximate normal gradient from crack distance
          final double normalZ = 1.0 - heightProfile * impasto * 0.6;
          // Directional slope vector
          final double normalX = (nx - ny) * (1.0 - seamT) * 0.5;
          final double normalY = (ny + nx) * (1.0 - seamT) * 0.5;

          // Lambertian + Specular reflection
          final double dotL = (normalX * lightDx + normalY * lightDy + normalZ * lightDz) /
              math.sqrt(normalX * normalX + normalY * normalY + normalZ * normalZ);
          final double diffuse = dotL.clamp(0.25, 1.15);
          final double spec = (dotL > 0.7) ? math.pow((dotL - 0.7) / 0.3, 2.5).toDouble() * 1.5 : 0.0;

          final _RGB goldTone = style.metalTone;
          final int rM = (goldTone.r * diffuse + 255 * spec * 0.8).clamp(0, 255).round();
          final int gM = (goldTone.g * diffuse + 245 * spec * 0.8).clamp(0, 255).round();
          final int bM = (goldTone.b * diffuse + 200 * spec * 0.8).clamp(0, 255).round();

          outColor = _RGB(rM, gM, bM);
        } else if (isGoldDustFlake) {
          // Sparkling dusted makie gold flakes
          final _RGB dustTone = style.metalTone;
          outColor = _RGB(
            math.min(255, (dustTone.r * 1.15).round()),
            math.min(255, (dustTone.g * 1.15).round()),
            math.min(255, (dustTone.b * 1.15).round()),
          );
        } else {
          // Substrate lacquer / porcelain pottery body
          final double substrateTexture = math.sin(x * 0.5) * math.cos(y * 0.5) * 0.04;
          final double glossShine = (math.sin(x * 0.05 + y * 0.05) * 0.5 + 0.5) * sheen * 0.25;

          final int rS = (style.lacquerBase.r * (0.95 + substrateTexture) + 255 * glossShine).clamp(0, 255).round();
          final int gS = (style.lacquerBase.g * (0.95 + substrateTexture) + 255 * glossShine).clamp(0, 255).round();
          final int bS = (style.lacquerBase.b * (0.95 + substrateTexture) + 255 * glossShine).clamp(0, 255).round();

          outColor = _RGB(rS, gS, bS);
        }

        if (preserveAlpha) {
          // Modulate original sprite with kintsugi lacquer & metallic seams
          if (isSeam) {
            // Metallic seam sits proudly on top of sprite surface
            output[idx] = (origA << 24) | (outColor.r << 16) | (outColor.g << 8) | outColor.b;
          } else if (isGoldDustFlake) {
            // Metallic gold dust spatter over sprite pixel
            final int rFlake = (origR * 0.2 + outColor.r * 0.8).clamp(0, 255).round();
            final int gFlake = (origG * 0.2 + outColor.g * 0.8).clamp(0, 255).round();
            final int bFlake = (origB * 0.2 + outColor.b * 0.8).clamp(0, 255).round();
            output[idx] = (origA << 24) | (rFlake << 16) | (gFlake << 8) | bFlake;
          } else {
            // Contact shadow next to raised seam
            double seamShadow = 1.0;
            if (minCrackDist <= halfSeam * 1.5) {
              final double st = (minCrackDist - halfSeam) / (halfSeam * 0.5);
              seamShadow = 0.72 + 0.28 * st;
            }

            // Ceramic lacquer vitreous surface gloss
            final double glossShine = (math.sin(x * 0.05 + y * 0.05) * 0.5 + 0.5) * sheen * 0.18;

            // Subtle porcelain/urushi substrate tone nuance (8% style tint, 92% original artwork)
            const double styleTint = 0.08;
            final double rT = origR * (1.0 - styleTint) + style.lacquerBase.r * styleTint;
            final double gT = origG * (1.0 - styleTint) + style.lacquerBase.g * styleTint;
            final double bT = origB * (1.0 - styleTint) + style.lacquerBase.b * styleTint;

            final int rOut = (rT * seamShadow + 255 * glossShine).clamp(0, 255).round();
            final int gOut = (gT * seamShadow + 255 * glossShine).clamp(0, 255).round();
            final int bOut = (bT * seamShadow + 255 * glossShine).clamp(0, 255).round();

            output[idx] = (origA << 24) | (rOut << 16) | (gOut << 8) | bOut;
          }
        } else {
          // Full kintsugi porcelain / lacquerware backdrop
          double rBase = outColor.r.toDouble();
          double gBase = outColor.g.toDouble();
          double bBase = outColor.b.toDouble();

          if (origA > 0) {
            final double alphaNorm = origA / 255.0;
            if (isSeam || isGoldDustFlake) {
              // Seams preserve pure metallic gold shine
              rBase = origR * 0.15 + rBase * 0.85;
              gBase = origG * 0.15 + gBase * 0.85;
              bBase = origB * 0.15 + bBase * 0.85;
            } else {
              // Underglaze painting on porcelain / lacquer
              rBase = rBase * (1.0 - alphaNorm) + origR * alphaNorm;
              gBase = gBase * (1.0 - alphaNorm) + origG * alphaNorm;
              bBase = bBase * (1.0 - alphaNorm) + origB * alphaNorm;
            }
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

  static double _hash(int n) {
    int x = (n << 13) ^ n;
    x = (x * (x * x * 15731 + 789221) + 1376312589) & 0x7fffffff;
    return (x & 0xffff) / 65535.0;
  }

  static _KintsugiStyle _getKintsugiStyle(String style) {
    switch (style) {
      case 'silverPlatinum':
        return const _KintsugiStyle(
          lacquerBase: _RGB(38, 40, 44),
          metalTone: _RGB(228, 234, 245),
        );
      case 'vermilionMend':
        return const _KintsugiStyle(
          lacquerBase: _RGB(238, 232, 220),
          metalTone: _RGB(220, 50, 35),
        );
      case 'celadonCrackle':
        return const _KintsugiStyle(
          lacquerBase: _RGB(165, 202, 188),
          metalTone: _RGB(235, 185, 45),
        );
      case 'goldUrushi':
      default:
        return const _KintsugiStyle(
          lacquerBase: _RGB(18, 18, 20),
          metalTone: _RGB(255, 212, 58),
        );
    }
  }
}

class _KintsugiStyle {
  final _RGB lacquerBase;
  final _RGB metalTone;

  const _KintsugiStyle({
    required this.lacquerBase,
    required this.metalTone,
  });
}
