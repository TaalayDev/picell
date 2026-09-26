part of 'effects.dart';

/// Procedural molten magma fissures & heat haze effect.
///
/// Features glowing subterranean lava cracks that spread through the sprite silhouette,
/// pulsating with incandescent heat and charred crust margins, while vertical refractive
/// heat-shimmer waves warp the air directly above.
class MagmaFissuresEffect extends Effect implements UIFieldProvider {
  MagmaFissuresEffect([Map<String, dynamic>? parameters])
      : super(
          EffectType.magmaFissures,
          parameters ??
              const {
                'fissureDensity': 4,
                'magmaColor': 0xFFFF3D00,
                'heatHazeDistortion': 0.6,
                'pulseSpeed': 1.2,
                'crustDarkening': 0.45,
                'time': 0.0,
                'preserveAlpha': true,
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() => {
        'fissureDensity': 4,
        'magmaColor': 0xFFFF3D00,
        'heatHazeDistortion': 0.6,
        'pulseSpeed': 1.2,
        'crustDarkening': 0.45,
        'time': 0.0,
        'preserveAlpha': true,
      };

  @override
  Map<String, dynamic> getMetadata() => {
        'fissureDensity': {
          'label': 'Fissure Density',
          'description': 'Number of subterranean molten lava cracks.',
          'type': 'slider',
          'min': 2,
          'max': 8,
          'step': 1,
        },
        'magmaColor': {
          'label': 'Magma Color',
          'description': 'Incandescent glowing color of the molten lava seam.',
          'type': 'color',
        },
        'heatHazeDistortion': {
          'label': 'Heat Haze Refraction',
          'description': 'Intensity of vertical shimmering air distortion.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'step': 0.05,
        },
        'pulseSpeed': {
          'label': 'Pulse Speed',
          'description': 'Rate of thermal expansion and incandescent breathing.',
          'type': 'slider',
          'min': 0.5,
          'max': 3.0,
          'step': 0.1,
        },
        'crustDarkening': {
          'label': 'Charred Crust Darkening',
          'description': 'Darkening of rock margins along fracture boundaries.',
          'type': 'slider',
          'min': 0.0,
          'max': 0.9,
          'step': 0.05,
        },
        'time': {
          'label': 'Animation Time',
          'description': 'Timeline progress through the heat breathing cycle.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'step': 0.01,
        },
        'preserveAlpha': {
          'label': 'Preserve Transparency',
          'description': 'Confine molten cracks and haze within character silhouette.',
          'type': 'bool',
        },
      };

  @override
  List<UIField> getFields() => [
        SliderField(
          key: 'fissureDensity',
          label: 'Fissure Density',
          description: 'Number of molten lava crack networks.',
          min: 2,
          max: 8,
          divisions: 6,
          formatLabel: (v) => '${v.round()} cracks',
        ),
        const ColorField(
          key: 'magmaColor',
          label: 'Magma Color',
          description: 'Incandescent glow color of the subterranean lava.',
        ),
        SliderField(
          key: 'heatHazeDistortion',
          label: 'Heat Haze Refraction',
          description: 'Refractive thermal shimmering waves.',
          min: 0.0,
          max: 1.0,
          divisions: 20,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        SliderField(
          key: 'pulseSpeed',
          label: 'Pulse Speed',
          description: 'Thermal pulse expansion rate.',
          min: 0.5,
          max: 3.0,
          divisions: 25,
          formatLabel: (v) => '${v.toStringAsFixed(1)}x',
        ),
        SliderField(
          key: 'crustDarkening',
          label: 'Charred Crust',
          description: 'Darkening around fissure edges.',
          min: 0.0,
          max: 0.9,
          divisions: 18,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        SliderField(
          key: 'time',
          label: 'Animation Time',
          description: 'Timeline progress of the thermal cycle.',
          min: 0.0,
          max: 1.0,
          divisions: 100,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        const BoolField(
          key: 'preserveAlpha',
          label: 'Preserve Transparency',
          description: 'Restrict lava fissures to character bounds.',
        ),
      ];

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    final fissureDensity = (parameters['fissureDensity'] as num?)?.toInt() ?? 4;
    final magmaColorInt = (parameters['magmaColor'] as num?)?.toInt() ?? 0xFFFF3D00;
    final heatHazeDistortion = (parameters['heatHazeDistortion'] as num?)?.toDouble() ?? 0.6;
    final pulseSpeed = (parameters['pulseSpeed'] as num?)?.toDouble() ?? 1.2;
    final crustDarkening = (parameters['crustDarkening'] as num?)?.toDouble() ?? 0.45;
    final time = (parameters['time'] as num?)?.toDouble() ?? 0.0;
    final preserveAlpha = parameters['preserveAlpha'] as bool? ?? true;

    final output = Uint32List.fromList(pixels);

    final mA = (magmaColorInt >> 24) & 0xFF;
    final mR = (magmaColorInt >> 16) & 0xFF;
    final mG = (magmaColorInt >> 8) & 0xFF;
    final mB = magmaColorInt & 0xFF;

    // Detect subject bounding box
    int minX = width;
    int minY = height;
    int maxX = -1;
    int maxY = -1;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final pixel = pixels[y * width + x];
        if (((pixel >> 24) & 0xFF) > 10) {
          if (x < minX) minX = x;
          if (x > maxX) maxX = x;
          if (y < minY) minY = y;
          if (y > maxY) maxY = y;
        }
      }
    }

    if (maxX < minX || maxY < minY) {
      minX = 0;
      minY = 0;
      maxX = width - 1;
      maxY = height - 1;
    }

    final boxW = (maxX - minX + 1).toDouble();
    final boxH = (maxY - minY + 1).toDouble();
    final cycleTime = time - time.floorToDouble();

    // 1. Generate procedural fissure lines
    final fissurePoints = <math.Point<double>>[];
    for (int k = 0; k < fissureDensity; k++) {
      final startFracX = 0.2 + 0.6 * math.sin(k * 13.7 + 1.2).abs();
      final startFracY = 0.15 + 0.7 * math.cos(k * 19.3 + 0.8).abs();
      final endFracX = 0.1 + 0.8 * math.cos(k * 31.1 + 2.5).abs();
      final endFracY = 0.2 + 0.75 * math.sin(k * 27.4 + 4.1).abs();

      final x0 = minX + startFracX * boxW;
      final y0 = minY + startFracY * boxH;
      final x1 = minX + endFracX * boxW;
      final y1 = minY + endFracY * boxH;

      final dist = math.sqrt((x1 - x0) * (x1 - x0) + (y1 - y0) * (y1 - y0));
      final steps = math.max(6, dist.round() * 2);

      for (int s = 0; s <= steps; s++) {
        final t = s / steps;
        final baseLX = x0 + (x1 - x0) * t;
        final baseLY = y0 + (y1 - y0) * t;

        // Jagged fracture perturbation
        final jx = math.sin(t * 14.0 + k * 5.3) * 2.4 + math.cos(t * 31.0) * 1.0;
        final jy = math.cos(t * 12.0 + k * 4.7) * 2.0;

        fissurePoints.add(math.Point<double>(baseLX + jx, baseLY + jy));
      }
    }

    // 2. Build heat pulse modulation ($0.0 \to 1.0$)
    final thermalPulse = 0.7 + 0.3 * math.sin(cycleTime * math.pi * 2.0 * pulseSpeed);

    // 3. Process image with heat haze, fissures, and charred crust
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final origIdx = y * width + x;
        final origPixel = pixels[origIdx];
        final origA = (origPixel >> 24) & 0xFF;

        if (preserveAlpha && origA == 0) continue;

        // Heat haze refractive warping
        int srcX = x;
        int srcY = y;
        if (heatHazeDistortion > 0.01) {
          final hazeOffsetX = math.sin((y * 0.45) - (cycleTime * 28.0 * pulseSpeed)) * (heatHazeDistortion * 1.8);
          final hazeOffsetY = -math.cos((x * 0.35) - (cycleTime * 22.0 * pulseSpeed)) * (heatHazeDistortion * 1.2);
          srcX = (x + hazeOffsetX).round().clamp(0, width - 1);
          srcY = (y + hazeOffsetY).round().clamp(0, height - 1);
        }

        final samplePixel = pixels[srcY * width + srcX];
        final sA = (samplePixel >> 24) & 0xFF;
        if (preserveAlpha && sA == 0) continue;

        final oR = (samplePixel >> 16) & 0xFF;
        final oG = (samplePixel >> 8) & 0xFF;
        final oB = samplePixel & 0xFF;

        // Find distance to closest fissure node
        double minD = 999.0;
        for (int p = 0; p < fissurePoints.length; p++) {
          final pt = fissurePoints[p];
          final dx = (x - pt.x).abs();
          if (dx > 4.0) continue;
          final dy = (y - pt.y).abs();
          if (dy > 4.0) continue;
          final d = math.sqrt(dx * dx + dy * dy);
          if (d < minD) minD = d;
          if (minD < 0.6) break;
        }

        int finalR = oR;
        int finalG = oG;
        int finalB = oB;
        double finalAlpha = preserveAlpha ? (origA / 255.0) : 1.0;

        if (minD <= 1.2) {
          // Inner molten core
          final coreFrac = (1.0 - minD / 1.2).clamp(0.0, 1.0) * thermalPulse;
          // Incandescent white/yellow core blending
          final isWhiteHot = minD < 0.6;
          final coreR = isWhiteHot ? 255 : (mR * 0.75 + 255 * 0.25).round();
          final coreG = isWhiteHot ? 255 : (mG * 0.75 + 240 * 0.25).round();
          final coreB = isWhiteHot ? 220 : mB;

          finalR = (oR + coreR * coreFrac).round().clamp(0, 255);
          finalG = (oG + coreG * coreFrac).round().clamp(0, 255);
          finalB = (oB + coreB * coreFrac).round().clamp(0, 255);
        } else if (minD <= 3.2) {
          // Outer fissure glow and charred rock crust
          final glowFrac = (1.0 - (minD - 1.2) / 2.0).clamp(0.0, 1.0);
          final charIntensity = glowFrac * crustDarkening;

          // Darken base rock around the crack
          final charredR = (oR * (1.0 - charIntensity)).round();
          final charredG = (oG * (1.0 - charIntensity)).round();
          final charredB = (oB * (1.0 - charIntensity)).round();

          // Additive warm ambient lava glow
          final warmGlow = glowFrac * 0.5 * thermalPulse;
          finalR = (charredR + mR * warmGlow).round().clamp(0, 255);
          finalG = (charredG + mG * warmGlow).round().clamp(0, 255);
          finalB = (charredB + mB * warmGlow).round().clamp(0, 255);
        }

        final targetA = (finalAlpha * (preserveAlpha ? origA : mA)).round().clamp(0, 255);
        output[origIdx] = (targetA << 24) | (finalR << 16) | (finalG << 8) | finalB;
      }
    }

    // 4. Rising incandescent embers above fissures
    const emberCount = 6;
    for (int e = 0; e < emberCount; e++) {
      final ePhase = (cycleTime + e * (1.0 / emberCount)) % 1.0;
      final eX = minX + (0.2 + 0.6 * math.sin(e * 71.3).abs()) * boxW + math.sin(ePhase * 15.0 + e) * 2.0;
      final eY = maxY - ePhase * (boxH * 1.1);

      final ix = eX.round();
      final iy = eY.round();

      if (ix >= 0 && ix < width && iy >= 0 && iy < height) {
        final idx = iy * width + ix;
        final origPixel = pixels[idx];
        final origA = (origPixel >> 24) & 0xFF;

        if (!preserveAlpha || origA > 0) {
          final sparkAlpha = (1.0 - ePhase).clamp(0.0, 1.0);
          final oR = (output[idx] >> 16) & 0xFF;
          final oG = (output[idx] >> 8) & 0xFF;
          final oB = output[idx] & 0xFF;

          final nR = (oR + 255 * sparkAlpha).round().clamp(0, 255);
          final nG = (oG + 200 * sparkAlpha).round().clamp(0, 255);
          final nB = (oB + 60 * sparkAlpha).round().clamp(0, 255);
          final nA = preserveAlpha ? origA : math.max(origA, (sparkAlpha * 255).round());

          output[idx] = (nA << 24) | (nR << 16) | (nG << 8) | nB;
        }
      }
    }

    return output;
  }
}
