part of 'effects.dart';

/// Procedural necromantic soul wisps and spirit spiral effect featuring spectral souls
/// orbiting in 3D double-helix spirals, hollow eye sockets, ethereal vapor trails, and whisper jitter.
class SoulWispsEffect extends Effect implements UIFieldProvider {
  SoulWispsEffect([Map<String, dynamic>? parameters])
      : super(
          EffectType.soulWisps,
          parameters ??
              const {
                'soulCount': 3,
                'orbitRadius': 0.38,
                'orbitSpeed': 1.2,
                'wispColor': 0xFF00E676,
                'trailLength': 8,
                'whisperJitter': 0.4,
                'time': 0.0,
                'preserveAlpha': true,
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() => {
        'soulCount': 3,
        'orbitRadius': 0.38,
        'orbitSpeed': 1.2,
        'wispColor': 0xFF00E676,
        'trailLength': 8,
        'whisperJitter': 0.4,
        'time': 0.0,
        'preserveAlpha': true,
      };

  @override
  Map<String, dynamic> getMetadata() => {
        'soulCount': {
          'label': 'Spirit Count',
          'description': 'Number of orbiting necromantic soul wisps.',
          'type': 'slider',
          'min': 2,
          'max': 8,
          'divisions': 6,
        },
        'orbitRadius': {
          'label': 'Orbit Boundary Radius',
          'description': 'Distance of the orbiting spirits from the sprite core.',
          'type': 'slider',
          'min': 0.2,
          'max': 0.7,
          'divisions': 25,
        },
        'orbitSpeed': {
          'label': 'Spiritual Orbital Velocity',
          'description': 'Angular rotation rate around the soul helix.',
          'type': 'slider',
          'min': 0.5,
          'max': 3.0,
          'divisions': 50,
        },
        'wispColor': {
          'label': 'Spectral Soul Hue',
          'description': 'Color of the ethereal ghost souls and spectral mist.',
          'type': 'color',
        },
        'trailLength': {
          'label': 'Ectoplasmic Vapor Trail',
          'description': 'Length of trailing spirit mist left behind each soul.',
          'type': 'slider',
          'min': 4,
          'max': 16,
          'divisions': 12,
        },
        'whisperJitter': {
          'label': 'Whisper Micro-Flutter',
          'description': 'Chaotic turbulent tremor and jitter of the spirits.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 20,
        },
        'time': {
          'label': 'Animation Time',
          'description': 'Timeline progress parameter for the helical spirit orbit.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 100,
        },
        'preserveAlpha': {
          'label': 'Preserve Transparency',
          'description': 'Confine spirits over the original character silhouette.',
          'type': 'bool',
        },
      };

  @override
  List<UIField> getFields() => [
        SliderField(
          key: 'soulCount',
          label: 'Spirit Count',
          description: 'Number of orbiting souls.',
          min: 2,
          max: 8,
          divisions: 6,
          formatLabel: (v) => '${v.round()} souls',
        ),
        SliderField(
          key: 'orbitRadius',
          label: 'Orbit Radius',
          description: 'Distance from character center.',
          min: 0.2,
          max: 0.7,
          divisions: 25,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        SliderField(
          key: 'orbitSpeed',
          label: 'Orbit Speed',
          description: 'Speed of helical rotation.',
          min: 0.5,
          max: 3.0,
          divisions: 50,
          formatLabel: (v) => '${v.toStringAsFixed(1)}x',
        ),
        const ColorField(
          key: 'wispColor',
          label: 'Soul Color',
          description: 'Ethereal glow color of the spirits.',
        ),
        SliderField(
          key: 'trailLength',
          label: 'Trail Length',
          description: 'Length of the vapor tail.',
          min: 4,
          max: 16,
          divisions: 12,
          formatLabel: (v) => '${v.round()} px',
        ),
        SliderField(
          key: 'whisperJitter',
          label: 'Whisper Jitter',
          description: 'Chaotic micro-flutter amplitude.',
          min: 0.0,
          max: 1.0,
          divisions: 20,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        SliderField(
          key: 'time',
          label: 'Animation Time',
          description: 'Timeline progress of the soul orbit.',
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
    final soulCount = (parameters['soulCount'] as num?)?.toInt() ?? 3;
    final orbitRadius = (parameters['orbitRadius'] as num?)?.toDouble() ?? 0.38;
    final orbitSpeed = (parameters['orbitSpeed'] as num?)?.toDouble() ?? 1.2;
    final wispColorInt = (parameters['wispColor'] as num?)?.toInt() ?? 0xFF00E676;
    final trailLength = (parameters['trailLength'] as num?)?.toInt() ?? 8;
    final whisperJitter = (parameters['whisperJitter'] as num?)?.toDouble() ?? 0.4;
    final time = (parameters['time'] as num?)?.toDouble() ?? 0.0;
    final preserveAlpha = parameters['preserveAlpha'] as bool? ?? true;

    final output = Uint32List.fromList(pixels);

    final wA = (wispColorInt >> 24) & 0xFF;
    final wR = (wispColorInt >> 16) & 0xFF;
    final wG = (wispColorInt >> 8) & 0xFF;
    final wB = wispColorInt & 0xFF;

    final cx = width / 2.0;
    final cy = height / 2.0;
    final maxDim = math.max(width, height).toDouble();
    final rBase = maxDim * orbitRadius;

    void blendPoint(int px, int py, double intensity, {bool isWhiteCore = false, bool isEyeSocket = false}) {
      if (px < 0 || px >= width || py < 0 || py >= height) return;
      final idx = py * width + px;
      final origPixel = pixels[idx];
      final origA = (origPixel >> 24) & 0xFF;

      if (preserveAlpha && origA == 0) return;

      final oR = (origPixel >> 16) & 0xFF;
      final oG = (origPixel >> 8) & 0xFF;
      final oB = origPixel & 0xFF;

      if (isEyeSocket) {
        // Dark hollow eye socket
        final shade = (1.0 - intensity * 0.75).clamp(0.1, 1.0);
        final newR = (oR * shade).round().clamp(0, 255);
        final newG = (oG * shade).round().clamp(0, 255);
        final newB = (oB * shade).round().clamp(0, 255);
        output[idx] = (origA << 24) | (newR << 16) | (newG << 8) | newB;
        return;
      }

      final effIntensity = intensity.clamp(0.0, 1.0);
      final tR = isWhiteCore ? 255 : (wR * 0.8 + 255 * 0.2).round();
      final tG = isWhiteCore ? 255 : (wG * 0.8 + 255 * 0.2).round();
      final tB = isWhiteCore ? 255 : (wB * 0.8 + 255 * 0.2).round();

      final newR = (oR + tR * effIntensity).round().clamp(0, 255);
      final newG = (oG + tG * effIntensity).round().clamp(0, 255);
      final newB = (oB + tB * effIntensity).round().clamp(0, 255);
      final newA = preserveAlpha ? origA : math.max(origA, (effIntensity * wA).round().clamp(0, 255));

      output[idx] = (newA << 24) | (newR << 16) | (newG << 8) | newB;
    }

    final cycleTime = time - time.floorToDouble();

    for (int i = 0; i < soulCount; i++) {
      final phase = i * (math.pi * 2.0 / soulCount);
      final theta = cycleTime * math.pi * 2.0 * orbitSpeed + phase;

      // Double-helix 3D coordinates
      final isAlternateHelix = (i % 2 == 1);
      final helixPhase = isAlternateHelix ? math.pi : 0.0;
      final depthZ = math.sin(theta);
      final depthBrightness = depthZ < -0.2 ? 0.7 : 1.0;

      // Jitter tremor
      final jitterX = math.sin(cycleTime * 47.1 + i * 13.7) * whisperJitter * 2.5;
      final jitterY = math.cos(cycleTime * 53.3 + i * 17.1) * whisperJitter * 2.5;

      final headX = cx + math.cos(theta) * rBase + jitterX;
      final headY = cy + math.sin(theta * 2.0 + helixPhase) * (rBase * 0.55) + math.sin(theta) * (rBase * 0.2) + jitterY;

      // 1. Draw vapor tail
      for (int k = 1; k <= trailLength; k++) {
        final tFrac = k / trailLength;
        final trailTheta = theta - k * 0.14;
        final trailJitterX = jitterX * (1.0 - tFrac);
        final trailJitterY = jitterY * (1.0 - tFrac);

        final tx = cx + math.cos(trailTheta) * rBase + trailJitterX;
        final ty = cy + math.sin(trailTheta * 2.0 + helixPhase) * (rBase * 0.55) + math.sin(trailTheta) * (rBase * 0.2) + trailJitterY - k * 0.5;

        final tailAlpha = (1.0 - tFrac) * (1.0 - tFrac) * 0.65 * depthBrightness;
        final tix = tx.round();
        final tiy = ty.round();

        blendPoint(tix, tiy, tailAlpha);
        if (k <= trailLength ~/ 2) {
          blendPoint(tix + 1, tiy, tailAlpha * 0.4);
          blendPoint(tix, tiy + 1, tailAlpha * 0.4);
        }
      }

      // 2. Draw soul head (3x3 skull wisp)
      final hix = headX.round();
      final hiy = headY.round();
      final coreIntensity = depthBrightness;

      // Outer aura
      blendPoint(hix - 1, hiy, coreIntensity * 0.6);
      blendPoint(hix + 1, hiy, coreIntensity * 0.6);
      blendPoint(hix, hiy - 1, coreIntensity * 0.7);
      blendPoint(hix, hiy + 1, coreIntensity * 0.6);

      // White incandescent core
      blendPoint(hix, hiy, coreIntensity, isWhiteCore: true);

      // Hollow eye sockets if facing front (depthZ > 0)
      if (depthZ > 0.0) {
        final eyeDirX = math.cos(theta).sign.round();
        blendPoint(hix - 1, hiy, 0.85, isEyeSocket: true);
        blendPoint(hix + (eyeDirX >= 0 ? 0 : 1), hiy, 0.85, isEyeSocket: true);
      }
    }

    return output;
  }
}
