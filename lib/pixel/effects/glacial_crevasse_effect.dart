part of 'effects.dart';

/// An effect that procedurally renders cavernous glacial ice chasms
/// glowing with saturated interior sapphire and turquoise subsurface scattering,
/// sharp crystalline fracture walls, and drifting powder snow cornices.
class GlacialCrevasseEffect extends Effect {
  GlacialCrevasseEffect([Map<String, dynamic>? params])
      : super(
          EffectType.glacialCrevasse,
          params ??
              {
                'crevasseDepth': 0.7,
                'iceTurquoiseGlow': 0.75,
                'snowCorniceThickness': 3.5,
                'fractureFacetJitter': 0.45,
                'chasmWidth': 0.4,
                'icePalette': 'sapphireGlacier',
                'time': 0.0,
                'preserveAlpha': false,
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() => {
        'crevasseDepth': 0.7,
        'iceTurquoiseGlow': 0.75,
        'snowCorniceThickness': 3.5,
        'fractureFacetJitter': 0.45,
        'chasmWidth': 0.4,
        'icePalette': 'sapphireGlacier',
        'time': 0.0,
        'preserveAlpha': false,
      };

  @override
  Map<String, dynamic> getMetadata() => {
        'crevasseDepth': {
          'label': 'Crevasse Chasm Depth',
          'description': 'Vertical depth and perspective wall extrusion into the ice abyss.',
          'type': 'slider',
          'min': 0.3,
          'max': 1.0,
          'step': 0.05,
        },
        'iceTurquoiseGlow': {
          'label': 'Subsurface Ice Glow',
          'description': 'Radiant optical scattering and deep blue transmission intensity.',
          'type': 'slider',
          'min': 0.2,
          'max': 1.0,
          'step': 0.05,
        },
        'snowCorniceThickness': {
          'label': 'Snow Cornice Lip',
          'description': 'Width of wind-blown powder snow shelves along chasm rims.',
          'type': 'slider',
          'min': 1.0,
          'max': 8.0,
          'step': 0.5,
        },
        'fractureFacetJitter': {
          'label': 'Cleavage Facet Jitter',
          'description': 'Angular irregularity and serac pinnacles along fracture walls.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'step': 0.05,
        },
        'chasmWidth': {
          'label': 'Chasm Aperture Width',
          'description': 'Span of the glacial rift opening relative to canvas.',
          'type': 'slider',
          'min': 0.2,
          'max': 0.7,
          'step': 0.05,
        },
        'icePalette': {
          'label': 'Glacial Ice Palette',
          'description': 'Mineral purity and atmospheric light spectrum in the ice.',
          'type': 'select',
          'options': {
            'sapphireGlacier': 'Sapphire Glacial Ice',
            'emeraldArctic': 'Emerald Arctic Crevasse',
            'abyssalNavy': 'Abyssal Midnight Blue Ice',
            'antarcticRose': 'Antarctic Twilight Rose & Ice',
          },
        },
        'time': {
          'label': 'Animation Timeline',
          'description': 'Subsurface light shimmer, facet glints, and drifting powder snow.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'step': 0.01,
        },
        'preserveAlpha': {
          'label': 'Preserve Alpha',
          'description': 'Restrict glacial crevasse and ice glow strictly to sprite pixels.',
          'type': 'bool',
        },
      };

  @override
  List<UIField> getFields() => [
        SliderField(
          key: 'crevasseDepth',
          label: 'Crevasse Chasm Depth',
          description: 'Vertical depth and perspective wall extrusion into the ice abyss.',
          min: 0.3,
          max: 1.0,
          divisions: 14,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        SliderField(
          key: 'iceTurquoiseGlow',
          label: 'Subsurface Ice Glow',
          description: 'Radiant optical scattering and deep blue transmission intensity.',
          min: 0.2,
          max: 1.0,
          divisions: 16,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        SliderField(
          key: 'snowCorniceThickness',
          label: 'Snow Cornice Lip',
          description: 'Width of wind-blown powder snow shelves along chasm rims.',
          min: 1.0,
          max: 8.0,
          divisions: 14,
          formatLabel: (v) => '${v.toStringAsFixed(1)}px',
        ),
        SliderField(
          key: 'fractureFacetJitter',
          label: 'Cleavage Facet Jitter',
          description: 'Angular irregularity and serac pinnacles along fracture walls.',
          min: 0.0,
          max: 1.0,
          divisions: 20,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        SliderField(
          key: 'chasmWidth',
          label: 'Chasm Aperture Width',
          description: 'Span of the glacial rift opening relative to canvas.',
          min: 0.2,
          max: 0.7,
          divisions: 10,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        const SelectField(
          key: 'icePalette',
          label: 'Glacial Ice Palette',
          description: 'Mineral purity and atmospheric light spectrum in the ice.',
          options: {
            'sapphireGlacier': 'Sapphire Glacial Ice',
            'emeraldArctic': 'Emerald Arctic Crevasse',
            'abyssalNavy': 'Abyssal Midnight Blue Ice',
            'antarcticRose': 'Antarctic Twilight Rose & Ice',
          },
        ),
        SliderField(
          key: 'time',
          label: 'Animation Timeline',
          description: 'Subsurface light shimmer, facet glints, and drifting powder snow.',
          min: 0.0,
          max: 1.0,
          divisions: 100,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        const BoolField(
          key: 'preserveAlpha',
          label: 'Preserve Alpha',
          description: 'Restrict glacial crevasse and ice glow strictly to sprite pixels.',
        ),
      ];

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    final output = Uint32List(width * height);

    final double depth = ((parameters['crevasseDepth'] as num?)?.toDouble() ?? 0.7).clamp(0.1, 1.2);
    final double glow = ((parameters['iceTurquoiseGlow'] as num?)?.toDouble() ?? 0.75).clamp(0.1, 1.2);
    final double cornice = ((parameters['snowCorniceThickness'] as num?)?.toDouble() ?? 3.5).clamp(0.5, 12.0);
    final double facetJitter = ((parameters['fractureFacetJitter'] as num?)?.toDouble() ?? 0.45).clamp(0.0, 1.0);
    final double widthRatio = ((parameters['chasmWidth'] as num?)?.toDouble() ?? 0.4).clamp(0.15, 0.8);
    final String icePalette = parameters['icePalette'] as String? ?? 'sapphireGlacier';
    final double time = ((parameters['time'] as num?)?.toDouble() ?? 0.0).clamp(0.0, 1.0);
    final bool preserveAlpha = parameters['preserveAlpha'] as bool? ?? false;

    final tau = time * 2.0 * math.pi;
    final palette = _getIcePalette(icePalette);

    // 1. Precalculate drifting powder snow flakes (around 40 motes)
    const int snowCount = 40;
    final flakes = <_SnowFlake>[];
    for (int i = 0; i < snowCount; i++) {
      final double seedX = _hashToUnit(i * 23 + 5) * width;
      final double seedY = _hashToUnit(i * 37 + 11) * height;
      final double speed = 0.8 + _hashToUnit(i * 47 + 19) * 0.8;
      final double phase = _hashToUnit(i * 59 + 29) * 2.0 * math.pi;

      // Downward & downwind drift
      double fx = (seedX + time * width * 0.35 * speed + math.sin(tau * 2.0 + phase) * 6.0) % width;
      double fy = (seedY + time * height * 0.45 * speed) % height;
      flakes.add(_SnowFlake(fx, fy, 0.6 + _hashToUnit(i * 13 + 7) * 0.8));
    }

    // 2. Iterate pixels
    for (int y = 0; y < height; y++) {
      final double normY = y / height.toDouble();

      // Fissure center fault line with jagged serac angular wobble
      final double wobble = math.sin(y * 0.11 + 1.2) * (width * 0.12 * facetJitter) +
          math.sin(y * 0.28 + 0.4) * (width * 0.06 * facetJitter) +
          math.cos(y * 0.62) * (width * 0.025 * facetJitter);
      final double centerX = width * 0.5 + wobble;

      // Chasm width expands downwards in perspective
      final double currentSpan = width * widthRatio * (0.65 + 0.45 * math.pow(normY, 0.75));
      final double leftLip = centerX - currentSpan * 0.5;
      final double rightLip = centerX + currentSpan * 0.5;

      for (int x = 0; x < width; x++) {
        final int idx = y * width + x;
        final int origPixel = pixels[idx];
        final int origA = (origPixel >> 24) & 0xFF;
        final int origR = (origPixel >> 16) & 0xFF;
        final int origG = (origPixel >> 8) & 0xFF;
        final int origB = origPixel & 0xFF;

        // Inside chasm, lip, or outer plateau?
        final bool isInsideChasm = (x >= leftLip && x <= rightLip);
        final double distToLeftLip = (x - leftLip).abs();
        final double distToRightLip = (x - rightLip).abs();
        final double distToLip = math.min(distToLeftLip, distToRightLip);

        // Evaluate snow flake particles
        double flakeGlint = 0.0;
        for (int i = 0; i < flakes.length; i++) {
          final f = flakes[i];
          final double fdx = (x - f.x).abs();
          final double fdy = (y - f.y).abs();
          if (fdx <= 1.2 && fdy <= 1.2) {
            final double d = math.sqrt(fdx * fdx + fdy * fdy);
            if (d <= f.radius) {
              flakeGlint += (1.0 - d / f.radius) * 1.5;
            }
          }
        }
        flakeGlint = flakeGlint.clamp(0.0, 2.0);

        _RGB pixelColor;
        double effectAlpha = 0.0;

        if (isInsideChasm) {
          // Span across rift: 0 at left lip, 1 at right lip
          final double u = ((x - leftLip) / math.max(1.0, currentSpan)).clamp(0.0, 1.0);
          // Parabolic depth profile: deepest in center
          final double centerArch = 1.0 - 4.0 * (u - 0.5) * (u - 0.5);
          final double chasmDepthNorm = (centerArch.clamp(0.0, 1.0) * depth).clamp(0.0, 1.5);

          // Crystalline cleavage facet striations
          final double facetAngle = (x * 0.28 + y * 0.42);
          final double facetNoise = math.sin(facetAngle * 1.8 + tau + math.sin(u * 10.0) * 0.4) * 0.18 * facetJitter;
          final double totalDepth = (chasmDepthNorm + facetNoise).clamp(0.0, 1.5);

          // Rayleigh optical depth absorption: light transitions from white snow lip to glowing turquoise, then deep sapphire abyss
          final double absorption = 1.0 - math.exp(-2.6 * totalDepth);

          // Specular glint on ice facets facing light
          final double glintWave = math.sin(facetAngle * 3.5 - tau * 2.0 + u * 6.0);
          final double specular = (glintWave > 0.82) ? math.pow((glintWave - 0.82) / 0.18, 2.0).toDouble() * 1.4 : 0.0;

          pixelColor = _sampleChasmAbsorption(palette, absorption, glow, specular);
          effectAlpha = (0.7 + absorption * 0.3).clamp(0.0, 1.0);
        } else if (distToLip <= cornice) {
          // Snow cornice lip
          final double corniceNorm = distToLip / cornice;
          final double corniceFluff = math.sin(x * 0.8 + y * 0.6) * 0.12;
          final double snowFactor = (1.0 - corniceNorm + corniceFluff).clamp(0.0, 1.0);

          pixelColor = _RGB(
            (palette.snowWhite.r * snowFactor + palette.icePlateau.r * (1.0 - snowFactor)).round(),
            (palette.snowWhite.g * snowFactor + palette.icePlateau.g * (1.0 - snowFactor)).round(),
            (palette.snowWhite.b * snowFactor + palette.icePlateau.b * (1.0 - snowFactor)).round(),
          );
          effectAlpha = (snowFactor * 0.85).clamp(0.0, 1.0);
        } else {
          // Glacial firn plateau with subtle stress fractures
          final double stressCrack = math.sin(x * 0.25 - y * 0.15 + math.cos(x * 0.1) * 3.0);
          final double crackFactor = (stressCrack.abs() < 0.08) ? 0.35 : 0.0;

          pixelColor = _RGB(
            (palette.icePlateau.r * (1.0 - crackFactor) + palette.abyssDeep.r * crackFactor).round(),
            (palette.icePlateau.g * (1.0 - crackFactor) + palette.abyssDeep.g * crackFactor).round(),
            (palette.icePlateau.b * (1.0 - crackFactor) + palette.abyssDeep.b * crackFactor).round(),
          );
          effectAlpha = 0.5;
        }

        if (preserveAlpha) {
          if (origA == 0) {
            output[idx] = 0;
            continue;
          }

          // Screen/blend glacial ice color and glow over sprite
          final double blendRatio = (effectAlpha * 0.8).clamp(0.0, 0.95);
          final int rBlend = (origR * (1.0 - blendRatio) + pixelColor.r * blendRatio).round();
          final int gBlend = (origG * (1.0 - blendRatio) + pixelColor.g * blendRatio).round();
          final int bBlend = (origB * (1.0 - blendRatio) + pixelColor.b * blendRatio).round();

          // Add powder snow flurries
          final int rFinal = (rBlend + flakeGlint * 220.0).clamp(0.0, 255.0).round();
          final int gFinal = (gBlend + flakeGlint * 240.0).clamp(0.0, 255.0).round();
          final int bFinal = (bBlend + flakeGlint * 255.0).clamp(0.0, 255.0).round();

          output[idx] = (origA << 24) | (rFinal << 16) | (gFinal << 8) | bFinal;
        } else {
          // Full glacial panorama
          double baseR = pixelColor.r.toDouble();
          double baseG = pixelColor.g.toDouble();
          double baseB = pixelColor.b.toDouble();

          // Composite sprite if present
          if (origA > 0) {
            final double alphaNorm = origA / 255.0;
            baseR = baseR * (1.0 - alphaNorm) + origR * alphaNorm;
            baseG = baseG * (1.0 - alphaNorm) + origG * alphaNorm;
            baseB = baseB * (1.0 - alphaNorm) + origB * alphaNorm;
          }

          // Composite drifting snow flakes
          final int rFinal = (baseR + flakeGlint * 230.0).clamp(0.0, 255.0).round();
          final int gFinal = (baseG + flakeGlint * 245.0).clamp(0.0, 255.0).round();
          final int bFinal = (baseB + flakeGlint * 255.0).clamp(0.0, 255.0).round();

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

  static _RGB _sampleChasmAbsorption(_IcePalette palette, double absorption, double glow, double specular) {
    _RGB base;
    if (absorption < 0.4) {
      final double t = absorption / 0.4;
      base = _RGB(
        (palette.snowWhite.r + (palette.iceMid.r - palette.snowWhite.r) * t).round(),
        (palette.snowWhite.g + (palette.iceMid.g - palette.snowWhite.g) * t).round(),
        (palette.snowWhite.b + (palette.iceMid.b - palette.snowWhite.b) * t).round(),
      );
    } else {
      final double t = ((absorption - 0.4) / 0.6).clamp(0.0, 1.0);
      base = _RGB(
        (palette.iceMid.r + (palette.abyssDeep.r - palette.iceMid.r) * t).round(),
        (palette.iceMid.g + (palette.abyssDeep.g - palette.iceMid.g) * t).round(),
        (palette.iceMid.b + (palette.abyssDeep.b - palette.iceMid.b) * t).round(),
      );
    }

    // Add subsurface turquoise emission and facet specular
    final int r = (base.r * (1.0 + specular) + palette.glowHighlight.r * glow * 0.4).clamp(0.0, 255.0).round();
    final int g = (base.g * (1.0 + specular) + palette.glowHighlight.g * glow * 0.4).clamp(0.0, 255.0).round();
    final int b = (base.b * (1.0 + specular) + palette.glowHighlight.b * glow * 0.4).clamp(0.0, 255.0).round();

    return _RGB(r, g, b);
  }

  static _IcePalette _getIcePalette(String palette) {
    switch (palette) {
      case 'emeraldArctic':
        return const _IcePalette(
          snowWhite: _RGB(240, 255, 250),
          icePlateau: _RGB(180, 225, 220),
          iceMid: _RGB(20, 215, 185),
          abyssDeep: _RGB(5, 50, 48),
          glowHighlight: _RGB(70, 255, 220),
        );
      case 'abyssalNavy':
        return const _IcePalette(
          snowWhite: _RGB(235, 245, 255),
          icePlateau: _RGB(155, 185, 220),
          iceMid: _RGB(30, 110, 220),
          abyssDeep: _RGB(4, 12, 38),
          glowHighlight: _RGB(60, 170, 255),
        );
      case 'antarcticRose':
        return const _IcePalette(
          snowWhite: _RGB(255, 240, 248),
          icePlateau: _RGB(220, 180, 205),
          iceMid: _RGB(90, 160, 245),
          abyssDeep: _RGB(38, 14, 45),
          glowHighlight: _RGB(255, 160, 225),
        );
      case 'sapphireGlacier':
      default:
        return const _IcePalette(
          snowWhite: _RGB(242, 250, 255),
          icePlateau: _RGB(175, 210, 240),
          iceMid: _RGB(0, 195, 255),
          abyssDeep: _RGB(6, 28, 65),
          glowHighlight: _RGB(80, 235, 255),
        );
    }
  }
}

class _IcePalette {
  final _RGB snowWhite;
  final _RGB icePlateau;
  final _RGB iceMid;
  final _RGB abyssDeep;
  final _RGB glowHighlight;

  const _IcePalette({
    required this.snowWhite,
    required this.icePlateau,
    required this.iceMid,
    required this.abyssDeep,
    required this.glowHighlight,
  });
}

class _SnowFlake {
  final double x;
  final double y;
  final double radius;

  _SnowFlake(this.x, this.y, this.radius);
}
