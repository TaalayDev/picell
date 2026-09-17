part of 'effects.dart';

/// Procedural pixel portal and vortex rift with event horizon absorption,
/// polar swirl coordinate warping, glowing photon accretion rings, and spiral arms.
class PortalVortexEffect extends Effect implements UIFieldProvider {
  PortalVortexEffect([Map<String, dynamic>? parameters])
      : super(
          EffectType.portalVortex,
          parameters ??
              const {
                'spinSpeed': 1.5,
                'swirlTwist': 1.5,
                'coreRadius': 0.25,
                'glowColor': 0xFFD500F9,
                'particlePull': 0.7,
                'portalMode': 'warpSprite',
                'time': 0.0,
                'preserveAlpha': true,
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() => {
        'spinSpeed': 1.5,
        'swirlTwist': 1.5,
        'coreRadius': 0.25,
        'glowColor': 0xFFD500F9,
        'particlePull': 0.7,
        'portalMode': 'warpSprite',
        'time': 0.0,
        'preserveAlpha': true,
      };

  @override
  Map<String, dynamic> getMetadata() => {
        'spinSpeed': {
          'label': 'Vortex Rotation Speed',
          'description': 'Speed of the swirling accretion ring rotation.',
          'type': 'slider',
          'min': 0.5,
          'max': 3.0,
          'divisions': 50,
        },
        'swirlTwist': {
          'label': 'Spacetime Swirl Twist',
          'description': 'Angular warping curvature towards the center.',
          'type': 'slider',
          'min': 0.0,
          'max': 3.0,
          'divisions': 60,
        },
        'coreRadius': {
          'label': 'Event Horizon Size',
          'description': 'Radius of the central singularity absorption core.',
          'type': 'slider',
          'min': 0.05,
          'max': 0.5,
          'divisions': 45,
        },
        'glowColor': {
          'label': 'Portal Energy Color',
          'description': 'Luminescent color of the photon ring and spiral arms.',
          'type': 'color',
        },
        'particlePull': {
          'label': 'Accretion Pull',
          'description': 'Density and pull strength of spiraling matter particles.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 20,
        },
        'portalMode': {
          'label': 'Portal Mode',
          'description': 'Warp existing sprite pixels or render an independent portal gate.',
          'type': 'select',
          'options': {
            'warpSprite': 'Warp Sprite into Vortex',
            'portalOverlay': 'Independent Portal Gate',
          },
        },
        'time': {
          'label': 'Animation Time',
          'description': 'Timeline progress parameter for animated portal rotation.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 100,
        },
        'preserveAlpha': {
          'label': 'Preserve Transparency',
          'description': 'Allow vortex energy to float over transparent background.',
          'type': 'bool',
        },
      };

  @override
  List<UIField> getFields() => [
        SliderField(
          key: 'spinSpeed',
          label: 'Spin Speed',
          description: 'Rotational speed of the swirling event horizon.',
          min: 0.5,
          max: 3.0,
          divisions: 50,
          formatLabel: (v) => '${v.toStringAsFixed(1)}x',
        ),
        SliderField(
          key: 'swirlTwist',
          label: 'Swirl Twist',
          description: 'Intensity of spacetime curvature twisting around the core.',
          min: 0.0,
          max: 3.0,
          divisions: 60,
          formatLabel: (v) => '${v.toStringAsFixed(1)} rad',
        ),
        SliderField(
          key: 'coreRadius',
          label: 'Event Horizon Radius',
          description: 'Size of the central black void singularity.',
          min: 0.05,
          max: 0.5,
          divisions: 45,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        const ColorField(
          key: 'glowColor',
          label: 'Portal Glow Tint',
          description: 'Color of the glowing photon ring and swirling accretion matter.',
        ),
        SliderField(
          key: 'particlePull',
          label: 'Accretion Pull',
          description: 'Concentration of inward-spiraling luminous particles.',
          min: 0.0,
          max: 1.0,
          divisions: 20,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        const SelectField(
          key: 'portalMode',
          label: 'Portal Mode',
          description: 'Warp sprite pixels or project an independent portal ring.',
          options: {
            'warpSprite': 'Warp Sprite into Vortex',
            'portalOverlay': 'Independent Portal Gate',
          },
        ),
        SliderField(
          key: 'time',
          label: 'Animation Time',
          description: 'Timeline progress parameter for frame generation.',
          min: 0.0,
          max: 1.0,
          divisions: 100,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        const BoolField(
          key: 'preserveAlpha',
          label: 'Preserve Transparency',
          description: 'When enabled, vortex energy floats over transparent canvas.',
        ),
      ];

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    if (width <= 0 || height <= 0 || pixels.isEmpty) return pixels;

    final spinSpeed = ((parameters['spinSpeed'] as num?)?.toDouble() ?? 1.5).clamp(0.5, 3.0);
    final swirlTwist = ((parameters['swirlTwist'] as num?)?.toDouble() ?? 1.5).clamp(0.0, 3.0);
    final coreRadius = ((parameters['coreRadius'] as num?)?.toDouble() ?? 0.25).clamp(0.05, 0.5);
    final glowColorInt = (parameters['glowColor'] as int?) ?? 0xFFD500F9;
    final particlePull = ((parameters['particlePull'] as num?)?.toDouble() ?? 0.7).clamp(0.0, 1.0);
    final portalMode = (parameters['portalMode'] as String?) ?? 'warpSprite';
    final time = ((parameters['time'] as num?)?.toDouble() ?? 0.0).clamp(0.0, 1.0);
    final preserveAlpha = parameters['preserveAlpha'] as bool? ?? true;

    final glowR = (glowColorInt >> 16) & 0xFF;
    final glowG = (glowColorInt >> 8) & 0xFF;
    final glowB = glowColorInt & 0xFF;

    final result = Uint32List(width * height);
    final cx = (width - 1) / 2.0;
    final cy = (height - 1) / 2.0;
    final maxR = math.max(1.0, math.min(cx, cy));
    final angleOffset = time * 2.0 * math.pi * spinSpeed;

    for (int y = 0; y < height; y++) {
      final dy = y - cy;
      for (int x = 0; x < width; x++) {
        final dx = x - cx;
        final idx = y * width + x;
        final dist = math.sqrt(dx * dx + dy * dy);
        final normR = dist / maxR;

        int srcPixel = pixels[idx];

        // 1. Spacetime Coordinate Warp
        if (normR < 1.0 && portalMode == 'warpSprite') {
          final angle = math.atan2(dy, dx);
          final twist = swirlTwist * math.pi * (1.0 - normR);
          final sampleAngle = angle - twist - angleOffset;

          // Inward suction compression towards the core
          final sampleR = dist * (1.0 + (1.0 - normR) * 0.4);
          final sx = (cx + math.cos(sampleAngle) * sampleR).round();
          final sy = (cy + math.sin(sampleAngle) * sampleR).round();

          if (sx >= 0 && sx < width && sy >= 0 && sy < height) {
            srcPixel = pixels[sy * width + sx];
          } else {
            srcPixel = 0x00000000;
          }

          // Darken towards event horizon
          if (normR < coreRadius) {
            final voidFactor = (normR / coreRadius).clamp(0.0, 1.0);
            final a = ((srcPixel >> 24) & 0xFF);
            final r = (((srcPixel >> 16) & 0xFF) * voidFactor).round();
            final g = (((srcPixel >> 8) & 0xFF) * voidFactor).round();
            final b = ((srcPixel & 0xFF) * voidFactor).round();
            srcPixel = (a << 24) | (r << 16) | (g << 8) | b;
          }
        }

        var curA = (srcPixel >> 24) & 0xFF;
        var curR = (srcPixel >> 16) & 0xFF;
        var curG = (srcPixel >> 8) & 0xFF;
        var curB = srcPixel & 0xFF;

        if (curA == 0 && !preserveAlpha) {
          curA = 255;
          curR = 5;
          curG = 2;
          curB = 15;
        }

        // 2. Glowing Photon Ring (Event Horizon Boundary)
        if (normR < 1.0) {
          final ringDist = (normR - coreRadius).abs();
          if (ringDist < 0.18) {
            final ringGlow = math.pow(1.0 - (ringDist / 0.18), 2.0).toDouble();
            final ringA = (ringGlow * 240).round().clamp(0, 255);

            // Additive glow with white-hot core
            final isCoreEdge = ringDist < 0.05;
            final addR = isCoreEdge ? 255 : glowR;
            final addG = isCoreEdge ? 255 : glowG;
            final addB = isCoreEdge ? 255 : glowB;

            final na = ringA / 255.0;
            curR = math.min(255, curR + (addR * na).round());
            curG = math.min(255, curG + (addG * na).round());
            curB = math.min(255, curB + (addB * na).round());
            curA = math.max(curA, ringA);
          }

          // 3. Accretion Spiral Arms
          if (particlePull > 0.05 && normR >= coreRadius && normR < 0.95) {
            final angle = math.atan2(dy, dx);
            // 2-arm logarithmic spiral
            final spiralAngle = angle + angleOffset * 1.5 + (1.0 - normR) * 6.28;
            final armFactor = math.pow(math.cos(spiralAngle), 8.0).toDouble();

            if (armFactor > 0.15) {
              final armIntensity = armFactor * particlePull * (1.0 - normR);
              final armA = (armIntensity * 200).round().clamp(0, 255);
              final na = armA / 255.0;

              curR = math.min(255, curR + (glowR * na).round());
              curG = math.min(255, curG + (glowG * na).round());
              curB = math.min(255, curB + (glowB * na).round());
              curA = math.max(curA, armA);
            }
          }
        }

        result[idx] = (curA << 24) | (curR << 16) | (curG << 8) | curB;
      }
    }

    return result;
  }
}
