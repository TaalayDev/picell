part of 'effects.dart';

/// Procedural radial shockwave and impact blast ring effect featuring rapidly
/// expanding pressure waves, isometric ground discs, optical refraction, and flying debris.
class RadialShockwaveEffect extends Effect implements UIFieldProvider {
  RadialShockwaveEffect([Map<String, dynamic>? parameters])
      : super(
          EffectType.radialShockwave,
          parameters ??
              const {
                'waveThickness': 2,
                'expansionSpeed': 1.5,
                'ringShape': 'circular',
                'shockwaveColor': 0xFFFFFFFF,
                'dustDebris': true,
                'debrisCount': 30,
                'time': 0.0,
                'preserveAlpha': true,
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() => {
        'waveThickness': 2,
        'expansionSpeed': 1.5,
        'ringShape': 'circular',
        'shockwaveColor': 0xFFFFFFFF,
        'dustDebris': true,
        'debrisCount': 30,
        'time': 0.0,
        'preserveAlpha': true,
      };

  @override
  Map<String, dynamic> getMetadata() => {
        'waveThickness': {
          'label': 'Wave Thickness',
          'description': 'Width of the expanding shockwave compression front.',
          'type': 'slider',
          'min': 1,
          'max': 6,
          'divisions': 5,
        },
        'expansionSpeed': {
          'label': 'Expansion Velocity',
          'description': 'Rate at which the blast ring expands across the canvas.',
          'type': 'slider',
          'min': 0.5,
          'max': 3.0,
          'divisions': 50,
        },
        'ringShape': {
          'label': 'Ring Geometry',
          'description': 'Shape profile of the pressure wave front.',
          'type': 'select',
          'options': {
            'circular': 'Circular Sonic Sphere',
            'isometricDisc': 'Isometric Ground Disc',
          },
        },
        'shockwaveColor': {
          'label': 'Shockwave Energy Color',
          'description': 'Primary illumination color of the blast wave.',
          'type': 'color',
        },
        'dustDebris': {
          'label': 'Flying Dust & Debris',
          'description': 'Eject high-speed ballistic debris particles outwards.',
          'type': 'bool',
        },
        'debrisCount': {
          'label': 'Debris Density',
          'description': 'Number of flying dust and rock particles.',
          'type': 'slider',
          'min': 10,
          'max': 60,
          'divisions': 50,
        },
        'time': {
          'label': 'Animation Time',
          'description': 'Timeline progress parameter for blast expansion.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 100,
        },
        'preserveAlpha': {
          'label': 'Preserve Transparency',
          'description': 'Confine blast ring and particles over original sprite silhouette.',
          'type': 'bool',
        },
      };

  @override
  List<UIField> getFields() => [
        SliderField(
          key: 'waveThickness',
          label: 'Wave Thickness',
          description: 'Width of the expanding shockwave compression front.',
          min: 1,
          max: 6,
          divisions: 5,
          formatLabel: (v) => '${v.round()} px',
        ),
        SliderField(
          key: 'expansionSpeed',
          label: 'Expansion Velocity',
          description: 'Rate of blast wavefront propagation.',
          min: 0.5,
          max: 3.0,
          divisions: 50,
          formatLabel: (v) => '${v.toStringAsFixed(1)}x',
        ),
        const SelectField(
          key: 'ringShape',
          label: 'Ring Shape',
          description: 'Shape geometry of the shockwave ring.',
          options: {
            'circular': 'Circular Sonic Sphere',
            'isometricDisc': 'Isometric Ground Disc',
          },
        ),
        const ColorField(
          key: 'shockwaveColor',
          label: 'Shockwave Color',
          description: 'Energy color of the compression wavefront.',
        ),
        const BoolField(
          key: 'dustDebris',
          label: 'Flying Dust & Debris',
          description: 'Eject high-speed debris motes with the blast.',
        ),
        SliderField(
          key: 'debrisCount',
          label: 'Debris Density',
          description: 'Quantity of ejected dust motes.',
          min: 10,
          max: 60,
          divisions: 50,
          formatLabel: (v) => '${v.round()} particles',
        ),
        SliderField(
          key: 'time',
          label: 'Animation Time',
          description: 'Timeline progress parameter from initiation to dissipation.',
          min: 0.0,
          max: 1.0,
          divisions: 100,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        const BoolField(
          key: 'preserveAlpha',
          label: 'Preserve Transparency',
          description: 'Keep transparency around sprite bounds.',
        ),
      ];

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    final waveThickness = (parameters['waveThickness'] as num?)?.toDouble() ?? 2.0;
    final expansionSpeed = (parameters['expansionSpeed'] as num?)?.toDouble() ?? 1.5;
    final ringShape = parameters['ringShape']?.toString() ?? 'circular';
    final shockwaveColorInt = (parameters['shockwaveColor'] as num?)?.toInt() ?? 0xFFFFFFFF;
    final dustDebris = parameters['dustDebris'] as bool? ?? true;
    final debrisCount = (parameters['debrisCount'] as num?)?.toInt() ?? 30;
    final time = (parameters['time'] as num?)?.toDouble() ?? 0.0;
    final preserveAlpha = parameters['preserveAlpha'] as bool? ?? true;

    final output = Uint32List.fromList(pixels);

    final cx = width / 2.0;
    final isIso = ringShape == 'isometricDisc';
    // For ground disc, center blast slightly lower on sprite
    final cy = isIso ? height * 0.65 : height / 2.0;

    final maxDim = math.max(width, height).toDouble();
    final maxRadius = maxDim * 0.85;

    // Progression cycle: 0.0 -> 1.0
    final rawProgress = (time * expansionSpeed);
    final progress = rawProgress - rawProgress.floorToDouble();
    // Fade out as the shockwave reaches maximum radius
    final blastFade = math.max(0.0, 1.0 - progress);
    final currentRadius = progress * maxRadius;

    final sA = (shockwaveColorInt >> 24) & 0xFF;
    final sR = (shockwaveColorInt >> 16) & 0xFF;
    final sG = (shockwaveColorInt >> 8) & 0xFF;
    final sB = shockwaveColorInt & 0xFF;

    // 1. Draw expanding shockwave ring
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final idx = y * width + x;
        final origPixel = pixels[idx];
        final origA = (origPixel >> 24) & 0xFF;

        if (preserveAlpha && origA == 0) {
          continue;
        }

        final dx = x - cx;
        final dy = isIso ? (y - cy) * 2.0 : (y - cy).toDouble();
        final dist = math.sqrt(dx * dx + dy * dy);

        // Distance relative to shockwave front
        final distFromFront = (dist - currentRadius).abs();

        if (distFromFront <= waveThickness) {
          // Sharp crest intensity at the leading wavefront
          final waveT = 1.0 - (distFromFront / waveThickness);
          final waveIntensity = waveT * waveT * blastFade;

          if (waveIntensity > 0.01) {
            final oR = (origPixel >> 16) & 0xFF;
            final oG = (origPixel >> 8) & 0xFF;
            final oB = origPixel & 0xFF;

            // Core crest glows hot white, outer halo glows shockwaveColor
            final crestMix = waveT > 0.7 ? (waveT - 0.7) / 0.3 : 0.0;
            final targetR = (sR * (1.0 - crestMix) + 255 * crestMix).round().clamp(0, 255);
            final targetG = (sG * (1.0 - crestMix) + 255 * crestMix).round().clamp(0, 255);
            final targetB = (sB * (1.0 - crestMix) + 255 * crestMix).round().clamp(0, 255);

            final newR = (oR + targetR * waveIntensity).round().clamp(0, 255);
            final newG = (oG + targetG * waveIntensity).round().clamp(0, 255);
            final newB = (oB + targetB * waveIntensity).round().clamp(0, 255);
            final newA = preserveAlpha ? origA : math.max(origA, (waveIntensity * sA).round().clamp(0, 255));

            output[idx] = (newA << 24) | (newR << 16) | (newG << 8) | newB;
          }
        }
      }
    }

    // 2. Flying dust motes & debris particles
    if (dustDebris && debrisCount > 0) {
      for (int i = 0; i < debrisCount; i++) {
        // Deterministic pseudo-random trajectory per particle
        final seedAngle = (i * 137.508) * (math.pi / 180.0);
        final speedVar = 0.5 + 0.8 * (((i * 73 + 19) % 100) / 100.0);
        final pDist = progress * maxRadius * speedVar;

        final px = (cx + math.cos(seedAngle) * pDist).round();
        final py = (cy + (isIso ? math.sin(seedAngle) * pDist * 0.5 : math.sin(seedAngle) * pDist)).round();

        if (px >= 0 && px < width && py >= 0 && py < height) {
          final pIdx = py * width + px;
          final origPixel = pixels[pIdx];
          final origA = (origPixel >> 24) & 0xFF;

          if (preserveAlpha && origA == 0) {
            continue;
          }

          final pFade = (blastFade * (1.0 - (pDist / (maxRadius * 1.3)))).clamp(0.0, 1.0);
          if (pFade > 0.05) {
            final oR = (origPixel >> 16) & 0xFF;
            final oG = (origPixel >> 8) & 0xFF;
            final oB = origPixel & 0xFF;

            // Debris is slightly warmer / dust-colored
            final dR = (sR * 0.9 + 40).round().clamp(0, 255);
            final dG = (sG * 0.8 + 20).round().clamp(0, 255);
            final dB = (sB * 0.7).round().clamp(0, 255);

            final newR = (oR * (1.0 - pFade) + dR * pFade).round().clamp(0, 255);
            final newG = (oG * (1.0 - pFade) + dG * pFade).round().clamp(0, 255);
            final newB = (oB * (1.0 - pFade) + dB * pFade).round().clamp(0, 255);
            final newA = preserveAlpha ? origA : math.max(origA, (pFade * 255).round().clamp(0, 255));

            output[pIdx] = (newA << 24) | (newR << 16) | (newG << 8) | newB;
          }
        }
      }
    }

    return output;
  }
}
