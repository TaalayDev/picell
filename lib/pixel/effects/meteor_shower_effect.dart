part of 'effects.dart';

/// Procedural meteor shower and falling shooting stars effect featuring incandescent
/// bolide heads, atmospheric smoke trails, staggered shower lanes, and terminal bursts.
class MeteorShowerEffect extends Effect implements UIFieldProvider {
  MeteorShowerEffect([Map<String, dynamic>? parameters])
      : super(
          EffectType.meteorShower,
          parameters ??
              const {
                'meteorAngle': -45.0,
                'showerDensity': 12,
                'trailLength': 12,
                'meteorSpeed': 1.5,
                'burnColor': 0xFFFFF59D,
                'burstFlashes': true,
                'time': 0.0,
                'preserveAlpha': true,
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() => {
        'meteorAngle': -45.0,
        'showerDensity': 12,
        'trailLength': 12,
        'meteorSpeed': 1.5,
        'burnColor': 0xFFFFF59D,
        'burstFlashes': true,
        'time': 0.0,
        'preserveAlpha': true,
      };

  @override
  Map<String, dynamic> getMetadata() => {
        'meteorAngle': {
          'label': 'Meteor Trajectory Angle',
          'description': 'Falling flight angle of the shooting stars in degrees.',
          'type': 'slider',
          'min': -80.0,
          'max': -10.0,
          'divisions': 35,
        },
        'showerDensity': {
          'label': 'Shower Density',
          'description': 'Number of active shooting star lanes in the sky.',
          'type': 'slider',
          'min': 4,
          'max': 30,
          'divisions': 26,
        },
        'trailLength': {
          'label': 'Ionized Trail Length',
          'description': 'Length of the glowing smoke and plasma tail.',
          'type': 'slider',
          'min': 4,
          'max': 25,
          'divisions': 21,
        },
        'meteorSpeed': {
          'label': 'Supersonic Velocity',
          'description': 'Entry flight speed of the falling meteors.',
          'type': 'slider',
          'min': 0.5,
          'max': 3.0,
          'divisions': 50,
        },
        'burnColor': {
          'label': 'Incandescent Burn Color',
          'description': 'Color of the burning mineral ionization and smoke tail.',
          'type': 'color',
        },
        'burstFlashes': {
          'label': 'Atmospheric Detonation',
          'description': 'Occasional bolide bursting flashes and fragment sparks.',
          'type': 'bool',
        },
        'time': {
          'label': 'Animation Time',
          'description': 'Timeline progress parameter for shower cycling.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 100,
        },
        'preserveAlpha': {
          'label': 'Preserve Transparency',
          'description': 'Confine meteors to original sprite silhouette.',
          'type': 'bool',
        },
      };

  @override
  List<UIField> getFields() => [
        SliderField(
          key: 'meteorAngle',
          label: 'Trajectory Angle',
          description: 'Descent inclination of the shooting stars.',
          min: -80.0,
          max: -10.0,
          divisions: 35,
          formatLabel: (v) => '${v.round()}°',
        ),
        SliderField(
          key: 'showerDensity',
          label: 'Shower Density',
          description: 'Quantity of meteors passing through.',
          min: 4,
          max: 30,
          divisions: 26,
          formatLabel: (v) => '${v.round()} meteors',
        ),
        SliderField(
          key: 'trailLength',
          label: 'Trail Length',
          description: 'Length of the glowing ionized plasma tail.',
          min: 4,
          max: 25,
          divisions: 21,
          formatLabel: (v) => '${v.round()} px',
        ),
        SliderField(
          key: 'meteorSpeed',
          label: 'Velocity',
          description: 'Speed of shooting star descent.',
          min: 0.5,
          max: 3.0,
          divisions: 50,
          formatLabel: (v) => '${v.toStringAsFixed(1)}x',
        ),
        const ColorField(
          key: 'burnColor',
          label: 'Meteor Color',
          description: 'Color of the burning plasma head and trail.',
        ),
        const BoolField(
          key: 'burstFlashes',
          label: 'Terminal Bursts',
          description: 'Occasional atmospheric explosion bursts.',
        ),
        SliderField(
          key: 'time',
          label: 'Animation Time',
          description: 'Timeline progress of the meteor shower.',
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
    final meteorAngleDeg = (parameters['meteorAngle'] as num?)?.toDouble() ?? -45.0;
    final showerDensity = (parameters['showerDensity'] as num?)?.toInt() ?? 12;
    final trailLength = (parameters['trailLength'] as num?)?.toDouble() ?? 12.0;
    final meteorSpeed = (parameters['meteorSpeed'] as num?)?.toDouble() ?? 1.5;
    final burnColorInt = (parameters['burnColor'] as num?)?.toInt() ?? 0xFFFFF59D;
    final burstFlashes = parameters['burstFlashes'] as bool? ?? true;
    final time = (parameters['time'] as num?)?.toDouble() ?? 0.0;
    final preserveAlpha = parameters['preserveAlpha'] as bool? ?? true;

    final output = Uint32List.fromList(pixels);

    final bA = (burnColorInt >> 24) & 0xFF;
    final bR = (burnColorInt >> 16) & 0xFF;
    final bG = (burnColorInt >> 8) & 0xFF;
    final bB = burnColorInt & 0xFF;

    final angleRad = meteorAngleDeg.abs() * (math.pi / 180.0);
    final vx = math.cos(angleRad);
    final vy = math.sin(angleRad);

    void blendPixel(int px, int py, double intensity, {bool isWhiteHot = false}) {
      if (px < 0 || px >= width || py < 0 || py >= height) return;
      final idx = py * width + px;
      final origPixel = pixels[idx];
      final origA = (origPixel >> 24) & 0xFF;

      if (preserveAlpha && origA == 0) return;

      final oR = (origPixel >> 16) & 0xFF;
      final oG = (origPixel >> 8) & 0xFF;
      final oB = origPixel & 0xFF;

      final targetR = isWhiteHot ? 255 : (bR * 0.7 + 255 * 0.3).round();
      final targetG = isWhiteHot ? 255 : (bG * 0.7 + 255 * 0.3).round();
      final targetB = isWhiteHot ? 255 : (bB * 0.7 + 255 * 0.3).round();

      final effIntensity = intensity.clamp(0.0, 1.0);
      final newR = (oR + targetR * effIntensity).round().clamp(0, 255);
      final newG = (oG + targetG * effIntensity).round().clamp(0, 255);
      final newB = (oB + targetB * effIntensity).round().clamp(0, 255);
      final newA = preserveAlpha ? origA : math.max(origA, (effIntensity * bA).round().clamp(0, 255));

      output[idx] = (newA << 24) | (newR << 16) | (newG << 8) | newB;
    }

    final totalFlightDist = (width + height) * 1.5 + trailLength * 2.0;

    for (int i = 0; i < showerDensity; i++) {
      // Staggered entry lanes along top and top-left border
      final laneSpread = width + height * 0.8;
      final laneX = ((i * 137.5) % laneSpread) - height * 0.4;
      final speedFactor = 0.8 + 0.5 * (((i * 53 + 19) % 100) / 100.0);
      final phaseOffset = ((i * 79 + 31) % 100) / 100.0;

      final rawProgress = (time * meteorSpeed * speedFactor + phaseOffset);
      final progress = rawProgress - rawProgress.floorToDouble();

      // Current distance along trajectory
      final dist = progress * totalFlightDist;
      final headX = laneX + vx * dist;
      final headY = -trailLength + vy * dist;

      // Check if meteor is near canvas bounds
      if (headX < -30 || headX > width + 30 || headY < -30 || headY > height + 30) {
        continue;
      }

      // Detonation burst check
      final willBurst = burstFlashes && (i % 3 == 0);
      final isBurstTime = willBurst && progress >= 0.7 && progress <= 0.85;

      if (isBurstTime) {
        // Atmospheric burst explosion
        final burstProgress = (progress - 0.7) / 0.15;
        final burstFade = 1.0 - burstProgress;
        final burstRadius = burstProgress * 6.0;

        for (int s = 0; s < 8; s++) {
          final sAngle = (s * math.pi / 4.0) + (i * 0.7);
          final spx = (headX + math.cos(sAngle) * burstRadius).round();
          final spy = (headY + math.sin(sAngle) * burstRadius).round();
          blendPixel(spx, spy, burstFade * 0.9, isWhiteHot: true);
        }
        blendPixel(headX.round(), headY.round(), burstFade * 1.2, isWhiteHot: true);
        continue;
      }

      // Draw incandescent bolide head
      final hix = headX.round();
      final hiy = headY.round();
      blendPixel(hix, hiy, 1.0, isWhiteHot: true);
      blendPixel(hix + 1, hiy, 0.7, isWhiteHot: true);
      blendPixel(hix - 1, hiy, 0.7, isWhiteHot: true);
      blendPixel(hix, hiy + 1, 0.7, isWhiteHot: true);
      blendPixel(hix, hiy - 1, 0.7, isWhiteHot: true);

      // Draw plasma and dust trail
      final steps = (trailLength * 1.5).round();
      for (int k = 1; k <= steps; k++) {
        final t = k / steps;
        final tx = headX - vx * (k * (trailLength / steps));
        final ty = headY - vy * (k * (trailLength / steps));
        final trailIntensity = (1.0 - t) * (1.0 - t);

        blendPixel(tx.round(), ty.round(), trailIntensity * 0.85);

        // Thin halo glow on sides of thick trail
        if (trailLength > 10 && k < steps * 0.5) {
          final perpX = -vy;
          final perpY = vx;
          blendPixel((tx + perpX).round(), (ty + perpY).round(), trailIntensity * 0.35);
          blendPixel((tx - perpX).round(), (ty - perpY).round(), trailIntensity * 0.35);
        }
      }
    }

    return output;
  }
}
