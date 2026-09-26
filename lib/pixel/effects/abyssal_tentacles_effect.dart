part of 'effects.dart';

/// Procedural eldritch eye swarm and abyssal tentacles effect featuring writhing
/// shadow tendrils, undulating kinematic splines, and animated blinking arcane eyeballs.
class AbyssalTentaclesEffect extends Effect implements UIFieldProvider {
  AbyssalTentaclesEffect([Map<String, dynamic>? parameters])
      : super(
          EffectType.abyssalTentacles,
          parameters ??
              const {
                'tentacleCount': 5,
                'tentacleLength': 18,
                'wriggleSpeed': 1.5,
                'eyeBlinkRate': 1.2,
                'eyeColor': 0xFFFF1744,
                'tentacleColor': 0xFF1B002B,
                'time': 0.0,
                'preserveAlpha': true,
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() => {
        'tentacleCount': 5,
        'tentacleLength': 18,
        'wriggleSpeed': 1.5,
        'eyeBlinkRate': 1.2,
        'eyeColor': 0xFFFF1744,
        'tentacleColor': 0xFF1B002B,
        'time': 0.0,
        'preserveAlpha': true,
      };

  @override
  Map<String, dynamic> getMetadata() => {
        'tentacleCount': {
          'label': 'Tentacle Appendages',
          'description': 'Number of shadowy tendrils crawling from the creature.',
          'type': 'slider',
          'min': 3,
          'max': 12,
          'divisions': 9,
        },
        'tentacleLength': {
          'label': 'Tentacle Reach',
          'description': 'Length and extension range of the writhing appendages.',
          'type': 'slider',
          'min': 8,
          'max': 35,
          'divisions': 27,
        },
        'wriggleSpeed': {
          'label': 'Wriggle Undulation Rate',
          'description': 'Sinusoidal writhing and whipping frequency of the tentacles.',
          'type': 'slider',
          'min': 0.5,
          'max': 3.0,
          'divisions': 50,
        },
        'eyeBlinkRate': {
          'label': 'Arcane Eye Blink Rate',
          'description': 'Frequency of eyelid blinks and pupil glances.',
          'type': 'slider',
          'min': 0.5,
          'max': 3.0,
          'divisions': 50,
        },
        'eyeColor': {
          'label': 'Eldritch Iris Color',
          'description': 'Color of the glaring demonic iris and arcane glow.',
          'type': 'color',
        },
        'tentacleColor': {
          'label': 'Shadow Flesh Color',
          'description': 'Color of the abyssal void tentacles and suckers.',
          'type': 'color',
        },
        'time': {
          'label': 'Animation Time',
          'description': 'Timeline progress parameter for tentacle wriggling and blinking.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 100,
        },
        'preserveAlpha': {
          'label': 'Preserve Transparency',
          'description': 'Confine tentacles to original sprite silhouette.',
          'type': 'bool',
        },
      };

  @override
  List<UIField> getFields() => [
        SliderField(
          key: 'tentacleCount',
          label: 'Tentacle Count',
          description: 'Number of writhing tentacles.',
          min: 3,
          max: 12,
          divisions: 9,
          formatLabel: (v) => '${v.round()} tentacles',
        ),
        SliderField(
          key: 'tentacleLength',
          label: 'Tentacle Reach',
          description: 'Extension reach of the tentacles.',
          min: 8,
          max: 35,
          divisions: 27,
          formatLabel: (v) => '${v.round()} px',
        ),
        SliderField(
          key: 'wriggleSpeed',
          label: 'Wriggle Speed',
          description: 'Speed of undulating tentacle motion.',
          min: 0.5,
          max: 3.0,
          divisions: 50,
          formatLabel: (v) => '${v.toStringAsFixed(1)}x',
        ),
        SliderField(
          key: 'eyeBlinkRate',
          label: 'Blink Rate',
          description: 'Frequency of eye blinking cycles.',
          min: 0.5,
          max: 3.0,
          divisions: 50,
          formatLabel: (v) => '${v.toStringAsFixed(1)}x',
        ),
        const ColorField(
          key: 'eyeColor',
          label: 'Eye Iris Color',
          description: 'Color of the glowing eldritch eyes.',
        ),
        const ColorField(
          key: 'tentacleColor',
          label: 'Tentacle Color',
          description: 'Dark shadow hue of the tentacles.',
        ),
        SliderField(
          key: 'time',
          label: 'Animation Time',
          description: 'Timeline progress of the wriggle cycle.',
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
    final tentacleCount = (parameters['tentacleCount'] as num?)?.toInt() ?? 5;
    final tentacleLength = (parameters['tentacleLength'] as num?)?.toInt() ?? 18;
    final wriggleSpeed = (parameters['wriggleSpeed'] as num?)?.toDouble() ?? 1.5;
    final eyeBlinkRate = (parameters['eyeBlinkRate'] as num?)?.toDouble() ?? 1.2;
    final eyeColorInt = (parameters['eyeColor'] as num?)?.toInt() ?? 0xFFFF1744;
    final tentacleColorInt = (parameters['tentacleColor'] as num?)?.toInt() ?? 0xFF1B002B;
    final time = (parameters['time'] as num?)?.toDouble() ?? 0.0;
    final preserveAlpha = parameters['preserveAlpha'] as bool? ?? true;

    final output = Uint32List.fromList(pixels);

    final tA = (tentacleColorInt >> 24) & 0xFF;
    final tR = (tentacleColorInt >> 16) & 0xFF;
    final tG = (tentacleColorInt >> 8) & 0xFF;
    final tB = tentacleColorInt & 0xFF;

    final eR = (eyeColorInt >> 16) & 0xFF;
    final eG = (eyeColorInt >> 8) & 0xFF;
    final eB = eyeColorInt & 0xFF;

    final cx = width / 2.0;
    final cy = height / 2.0;
    final cycleTime = time - time.floorToDouble();
    final timeRad = cycleTime * math.pi * 2.0;

    void blendPixel(int px, int py, int color, {double alphaMul = 1.0}) {
      if (px < 0 || px >= width || py < 0 || py >= height) return;
      final idx = py * width + px;
      final origPixel = pixels[idx];
      final origA = (origPixel >> 24) & 0xFF;

      if (preserveAlpha && origA == 0) return;

      final cA = ((color >> 24) & 0xFF) * alphaMul;
      final cR = (color >> 16) & 0xFF;
      final cG = (color >> 8) & 0xFF;
      final cB = color & 0xFF;

      final oR = (origPixel >> 16) & 0xFF;
      final oG = (origPixel >> 8) & 0xFF;
      final oB = origPixel & 0xFF;

      final frac = (cA / 255.0).clamp(0.0, 1.0);
      final newR = (oR * (1.0 - frac) + cR * frac).round().clamp(0, 255);
      final newG = (oG * (1.0 - frac) + cG * frac).round().clamp(0, 255);
      final newB = (oB * (1.0 - frac) + cB * frac).round().clamp(0, 255);
      final newA = preserveAlpha ? origA : math.max(origA, cA.round().clamp(0, 255));

      output[idx] = (newA << 24) | (newR << 16) | (newG << 8) | newB;
    }

    for (int i = 0; i < tentacleCount; i++) {
      // Angular fan around the lower and lateral perimeter of sprite
      final angle = (i / tentacleCount) * math.pi * 1.6 + 0.2 * math.pi;
      final normalX = math.cos(angle);
      final normalY = math.sin(angle);
      final perpX = -normalY;
      final perpY = normalX;

      // Base root position
      final rootRadius = math.min(width, height) * 0.25;
      final rootX = cx + normalX * rootRadius;
      final rootY = cy + normalY * rootRadius;

      // Eye placement along the tentacle
      final eyeSegment = (tentacleLength * 0.45).round();
      final blinkVal = math.sin(timeRad * eyeBlinkRate + i * 2.1);
      final isEyeOpen = blinkVal > -0.5;

      int eyeX = 0;
      int eyeY = 0;

      // Render tentacle spine
      for (int s = 0; s <= tentacleLength; s++) {
        final progress = s / tentacleLength;

        // Dual-frequency wriggle wave
        final wave1 = math.sin(timeRad * wriggleSpeed + s * 0.35 + i * 1.5);
        final wave2 = math.cos(timeRad * wriggleSpeed * 1.5 + s * 0.2 + i);
        final wiggle = (wave1 * 0.7 + wave2 * 0.3) * (progress * 8.0);

        final curX = rootX + normalX * s + perpX * wiggle;
        final curY = rootY + normalY * s + perpY * wiggle;

        final ix = curX.round();
        final iy = curY.round();

        if (s == eyeSegment) {
          eyeX = ix;
          eyeY = iy;
        }

        // Tapering tentacle thickness
        final thickness = progress < 0.3 ? 2 : (progress < 0.7 ? 1 : 0);
        final shadowColor = (tA << 24) | (tR << 16) | (tG << 8) | tB;

        blendPixel(ix, iy, shadowColor);
        if (thickness >= 1) {
          blendPixel((curX + perpX).round(), (curY + perpY).round(), shadowColor, alphaMul: 0.85);
        }
        if (thickness >= 2) {
          blendPixel((curX - perpX).round(), (curY - perpY).round(), shadowColor, alphaMul: 0.85);
        }
      }

      // Draw arcane eyeball at node
      if (isEyeOpen && eyeX > 0 && eyeY > 0) {
        final glanceOffset = math.cos(timeRad + i * 1.3) > 0 ? 1 : -1;
        final irisColor = (255 << 24) | (eR << 16) | (eG << 8) | eB;
        const pupilColor = (255 << 24) | (0 << 16) | (0 << 8) | 0;
        const scleraColor = (255 << 24) | (240 << 16) | (230 << 8) | 245;

        // Eyeball 3x3 socket
        blendPixel(eyeX - 1, eyeY - 1, scleraColor);
        blendPixel(eyeX + 1, eyeY - 1, scleraColor);
        blendPixel(eyeX - 1, eyeY + 1, scleraColor);
        blendPixel(eyeX + 1, eyeY + 1, scleraColor);

        // Iris ring
        blendPixel(eyeX, eyeY - 1, irisColor);
        blendPixel(eyeX, eyeY + 1, irisColor);
        blendPixel(eyeX - 1, eyeY, irisColor);
        blendPixel(eyeX + 1, eyeY, irisColor);

        // Pupil center with dynamic glance
        blendPixel(eyeX + glanceOffset, eyeY, pupilColor);
      } else if (!isEyeOpen && eyeX > 0 && eyeY > 0) {
        // Closed eye crease slit
        final creaseColor = (255 << 24) | ((tR * 0.5).round() << 16) | ((tG * 0.5).round() << 8) | (tB * 0.5).round();
        blendPixel(eyeX - 1, eyeY, creaseColor);
        blendPixel(eyeX, eyeY, creaseColor);
        blendPixel(eyeX + 1, eyeY, creaseColor);
      }
    }

    return output;
  }
}
