part of 'effects.dart';

/// Procedural pixel beam teleport and mega spawn effect.
///
/// Simulates classic retro platformer and arcade teleportation entries.
/// Features a descending incandescent laser beam with ground impact dust puffs
/// ('beamDown' mode) or vertical streaming digital pixel capsules ('digitizeBlocks' mode).
class BeamTeleportEffect extends Effect implements UIFieldProvider {
  BeamTeleportEffect([Map<String, dynamic>? parameters])
      : super(
          EffectType.beamTeleport,
          parameters ??
              const {
                'teleportMode': 'beamDown',
                'beamWidth': 6,
                'laserColor': 0xFF00E5FF,
                'impactDust': true,
                'time': 0.0,
                'preserveAlpha': true,
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() => {
        'teleportMode': 'beamDown',
        'beamWidth': 6,
        'laserColor': 0xFF00E5FF,
        'impactDust': true,
        'time': 0.0,
        'preserveAlpha': true,
      };

  @override
  Map<String, dynamic> getMetadata() => {
        'teleportMode': {
          'label': 'Teleport Mode',
          'description': 'Style of retro teleportation.',
          'type': 'select',
          'options': {
            'beamDown': 'Vertical Beam Down',
            'digitizeBlocks': 'Digital Block Stream',
          },
        },
        'beamWidth': {
          'label': 'Beam Width',
          'description': 'Horizontal thickness of the vertical teleport column.',
          'type': 'slider',
          'min': 2,
          'max': 24,
          'step': 1,
        },
        'laserColor': {
          'label': 'Laser Core Color',
          'description': 'Color of the energy beam or digital particles.',
          'type': 'color',
        },
        'impactDust': {
          'label': 'Impact Ground Dust',
          'description': 'Spawn kinetic dust particles when the beam strikes ground.',
          'type': 'bool',
        },
        'time': {
          'label': 'Animation Time',
          'description': 'Timeline progress through the teleport spawn cycle.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'step': 0.01,
        },
        'preserveAlpha': {
          'label': 'Preserve Transparency',
          'description': 'Confine teleport visuals within original character silhouette.',
          'type': 'bool',
        },
      };

  @override
  List<UIField> getFields() => [
        const SelectField(
          key: 'teleportMode',
          label: 'Teleport Mode',
          description: 'Style of retro teleportation.',
          options: {
            'beamDown': 'Vertical Beam Down',
            'digitizeBlocks': 'Digital Block Stream',
          },
        ),
        SliderField(
          key: 'beamWidth',
          label: 'Beam Width',
          description: 'Horizontal thickness of the vertical teleport beam.',
          min: 2,
          max: 24,
          divisions: 22,
          formatLabel: (v) => '${v.round()} px',
        ),
        const ColorField(
          key: 'laserColor',
          label: 'Laser Color',
          description: 'Luminescent color of the laser column.',
        ),
        const BoolField(
          key: 'impactDust',
          label: 'Impact Ground Dust',
          description: 'Emit dust puffs upon ground landing.',
        ),
        SliderField(
          key: 'time',
          label: 'Animation Time',
          description: 'Timeline progress of teleport sequence.',
          min: 0.0,
          max: 1.0,
          divisions: 100,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        const BoolField(
          key: 'preserveAlpha',
          label: 'Preserve Transparency',
          description: 'Restrict effects to character boundaries.',
        ),
      ];

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    final teleportMode = parameters['teleportMode'] as String? ?? 'beamDown';
    final beamWidth = (parameters['beamWidth'] as num?)?.toInt() ?? 6;
    final laserColorInt = (parameters['laserColor'] as num?)?.toInt() ?? 0xFF00E5FF;
    final impactDust = parameters['impactDust'] as bool? ?? true;
    final time = (parameters['time'] as num?)?.toDouble() ?? 0.0;
    final preserveAlpha = parameters['preserveAlpha'] as bool? ?? true;

    final output = Uint32List.fromList(pixels);

    final lA = (laserColorInt >> 24) & 0xFF;
    final lR = (laserColorInt >> 16) & 0xFF;
    final lG = (laserColorInt >> 8) & 0xFF;
    final lB = laserColorInt & 0xFF;

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

    final spriteW = (maxX - minX + 1).toDouble();
    final cx = minX + spriteW / 2.0;
    final groundY = maxY.toDouble();

    void blendPixel(
      int px,
      int py,
      int colorR,
      int colorG,
      int colorB,
      double alphaFrac, {
      bool isAdditive = false,
    }) {
      if (px < 0 || px >= width || py < 0 || py >= height) return;
      final idx = py * width + px;
      final origPixel = pixels[idx];
      final origA = (origPixel >> 24) & 0xFF;

      if (preserveAlpha && origA == 0) return;

      final effAlpha = alphaFrac.clamp(0.0, 1.0);
      final oR = (origPixel >> 16) & 0xFF;
      final oG = (origPixel >> 8) & 0xFF;
      final oB = origPixel & 0xFF;

      int newR, newG, newB;
      if (isAdditive) {
        newR = (oR + colorR * effAlpha).round().clamp(0, 255);
        newG = (oG + colorG * effAlpha).round().clamp(0, 255);
        newB = (oB + colorB * effAlpha).round().clamp(0, 255);
      } else {
        newR = (oR * (1.0 - effAlpha) + colorR * effAlpha).round().clamp(0, 255);
        newG = (oG * (1.0 - effAlpha) + colorG * effAlpha).round().clamp(0, 255);
        newB = (oB * (1.0 - effAlpha) + colorB * effAlpha).round().clamp(0, 255);
      }

      final targetA = (effAlpha * lA).round();
      final newA = preserveAlpha ? origA : math.max(origA, targetA);

      output[idx] = (newA << 24) | (newR << 16) | (newG << 8) | newB;
    }

    final cycleTime = time - time.floorToDouble();

    if (teleportMode == 'beamDown') {
      // Phase 1: Beam descending from sky to ground (0.0 to 0.35)
      // Phase 2: Beam full blast & sprite materialization (0.35 to 0.70)
      // Phase 3: Beam narrows & dissipates upwards, dust settles (0.70 to 1.0)

      double beamTipY;
      double beamIntensity;
      double currentBeamWidth = beamWidth.toDouble();

      if (cycleTime < 0.35) {
        final tNorm = cycleTime / 0.35;
        beamTipY = tNorm * groundY;
        beamIntensity = 0.85 + 0.15 * math.sin(cycleTime * 40.0);
      } else if (cycleTime < 0.70) {
        beamTipY = groundY;
        final tNorm = (cycleTime - 0.35) / 0.35;
        beamIntensity = 1.0;
        // Jitter width during full blast
        currentBeamWidth += math.sin(cycleTime * 60.0) * 1.5;

        // Modulate sprite materialization brightness
        final matGlow = (1.0 - tNorm) * 0.4;
        for (int py = minY; py <= maxY; py++) {
          for (int px = minX; px <= maxX; px++) {
            blendPixel(px, py, lR, lG, lB, matGlow, isAdditive: true);
          }
        }
      } else {
        final tNorm = (cycleTime - 0.70) / 0.30;
        beamTipY = groundY;
        beamIntensity = (1.0 - tNorm);
        currentBeamWidth = math.max(1.0, currentBeamWidth * (1.0 - tNorm));
      }

      final halfW = currentBeamWidth / 2.0;

      // Draw vertical laser beam column
      if (beamIntensity > 0.01) {
        final startX = (cx - halfW).floor();
        final endX = (cx + halfW).ceil();
        final maxScanY = math.min(height - 1, beamTipY.round());

        for (int py = 0; py <= maxScanY; py++) {
          // Horizontal scanline beam oscillation
          final lineJitter = math.sin(py * 0.8 + cycleTime * 50.0) * 0.6;
          for (int px = startX; px <= endX; px++) {
            final distFromCenter = (px - (cx + lineJitter)).abs();
            if (distFromCenter > halfW + 1) continue;

            final normDist = (distFromCenter / (halfW + 0.001)).clamp(0.0, 1.0);
            final isCore = normDist < 0.35;

            final colAlpha = (1.0 - normDist * 0.6) * beamIntensity;

            if (isCore) {
              // Incandescent white laser core
              blendPixel(px, py, 255, 255, 255, colAlpha, isAdditive: true);
            } else {
              // Colored laser aura
              blendPixel(px, py, lR, lG, lB, colAlpha * 0.85, isAdditive: true);
            }
          }
        }
      }

      // Ground impact dust shockwave puffs
      if (impactDust && cycleTime >= 0.30) {
        final dustTime = (cycleTime - 0.30) / 0.70;
        final dustAlpha = (1.0 - dustTime).clamp(0.0, 1.0);
        const dustCount = 8;
        final baseFloor = groundY.round();

        for (int i = 0; i < dustCount; i++) {
          final dir = (i % 2 == 0) ? 1 : -1;
          final speed = 1.0 + (i ~/ 2) * 0.6;
          final dX = (cx + dir * (dustTime * spriteW * 0.6 * speed)).round();
          final dY = (baseFloor - math.sin(dustTime * math.pi) * (4.0 + (i % 3) * 2.0)).round();

          blendPixel(dX, dY, 230, 235, 245, dustAlpha * 0.8, isAdditive: true);
          blendPixel(dX + dir, dY, lR, lG, lB, dustAlpha * 0.5, isAdditive: true);
        }
      }
    } else {
      // 'digitizeBlocks': Vertical streaming digital capsules
      final columnWidth = math.max(2, beamWidth ~/ 2);
      final numCols = (width / columnWidth).ceil();

      for (int c = 0; c < numCols; c++) {
        final colStartX = c * columnWidth;
        // Pseudo-random staggered timing per column
        final colPhase = math.sin(c * 23.7).abs();
        final colTime = (cycleTime + colPhase * 0.4) % 1.0;

        // Streaming block capsule position
        final blockHeadY = (1.0 - colTime) * (height + 12) - 6;

        for (int k = 0; k < 6; k++) {
          final py = (blockHeadY + k * 2).round();
          if (py < 0 || py >= height) continue;

          final frac = 1.0 - (k / 6.0);
          final isTip = (k == 0);

          for (int dx = 0; dx < columnWidth; dx++) {
            final px = colStartX + dx;
            if (px >= width) continue;

            if (isTip) {
              blendPixel(px, py, 255, 255, 255, frac, isAdditive: true);
            } else {
              blendPixel(px, py, lR, lG, lB, frac * 0.8, isAdditive: true);
            }
          }
        }
      }

      // Digital shimmer scanlines over sprite
      final shimmerY = ((1.0 - cycleTime) * height).round();
      for (int px = minX; px <= maxX; px++) {
        blendPixel(px, shimmerY, 255, 255, 255, 0.7, isAdditive: true);
        blendPixel(px, shimmerY - 1, lR, lG, lB, 0.4, isAdditive: true);
      }
    }

    return output;
  }
}
