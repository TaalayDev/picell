part of 'effects.dart';

/// Procedural frost glaze & crystal freeze effect.
///
/// Encodes geometric ice crystals and dendritic frost needles that propagate
/// upward across the sprite, encasing it in a translucent frosty sheen with
/// crystalline facet tinting and twinkling specular edge glints.
class FrostGlazeEffect extends Effect implements UIFieldProvider {
  FrostGlazeEffect([Map<String, dynamic>? parameters])
      : super(
          EffectType.frostGlaze,
          parameters ??
              const {
                'crystalDensity': 5,
                'iceTint': 0xFF80D8FF,
                'frostBranching': 0.7,
                'specularShimmer': 0.6,
                'time': 0.0,
                'preserveAlpha': true,
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() => {
        'crystalDensity': 5,
        'iceTint': 0xFF80D8FF,
        'frostBranching': 0.7,
        'specularShimmer': 0.6,
        'time': 0.0,
        'preserveAlpha': true,
      };

  @override
  Map<String, dynamic> getMetadata() => {
        'crystalDensity': {
          'label': 'Crystal Density',
          'description': 'Number of geometric ice crystal nucleation sites.',
          'type': 'slider',
          'min': 2,
          'max': 10,
          'step': 1,
        },
        'iceTint': {
          'label': 'Ice Tint Color',
          'description': 'Translucent glacial tint of the frost glaze.',
          'type': 'color',
        },
        'frostBranching': {
          'label': 'Dendritic Branching',
          'description': 'Spread and angularity of propagating frost needles.',
          'type': 'slider',
          'min': 0.2,
          'max': 1.0,
          'step': 0.05,
        },
        'specularShimmer': {
          'label': 'Specular Glints',
          'description': 'Twinkling brilliance on crystal facet edges.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'step': 0.05,
        },
        'time': {
          'label': 'Animation Time',
          'description': 'Timeline progress through the freeze and shimmer cycle.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'step': 0.01,
        },
        'preserveAlpha': {
          'label': 'Preserve Transparency',
          'description': 'Confine frost crystals within character silhouette.',
          'type': 'bool',
        },
      };

  @override
  List<UIField> getFields() => [
        SliderField(
          key: 'crystalDensity',
          label: 'Crystal Density',
          description: 'Number of ice crystal clusters.',
          min: 2,
          max: 10,
          divisions: 8,
          formatLabel: (v) => '${v.round()} clusters',
        ),
        const ColorField(
          key: 'iceTint',
          label: 'Ice Tint Color',
          description: 'Glacial translucent ice color.',
        ),
        SliderField(
          key: 'frostBranching',
          label: 'Frost Branching',
          description: 'Dendritic needle spread.',
          min: 0.2,
          max: 1.0,
          divisions: 16,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        SliderField(
          key: 'specularShimmer',
          label: 'Specular Shimmer',
          description: 'Crystalline edge glint flashes.',
          min: 0.0,
          max: 1.0,
          divisions: 20,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        SliderField(
          key: 'time',
          label: 'Animation Time',
          description: 'Timeline progress of freeze cycle.',
          min: 0.0,
          max: 1.0,
          divisions: 100,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        const BoolField(
          key: 'preserveAlpha',
          label: 'Preserve Transparency',
          description: 'Confine ice crystals to character bounds.',
        ),
      ];

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    final crystalDensity = (parameters['crystalDensity'] as num?)?.toInt() ?? 5;
    final iceTintInt = (parameters['iceTint'] as num?)?.toInt() ?? 0xFF80D8FF;
    final frostBranching = (parameters['frostBranching'] as num?)?.toDouble() ?? 0.7;
    final specularShimmer = (parameters['specularShimmer'] as num?)?.toDouble() ?? 0.6;
    final time = (parameters['time'] as num?)?.toDouble() ?? 0.0;
    final preserveAlpha = parameters['preserveAlpha'] as bool? ?? true;

    final output = Uint32List.fromList(pixels);

    final iA = (iceTintInt >> 24) & 0xFF;
    final iR = (iceTintInt >> 16) & 0xFF;
    final iG = (iceTintInt >> 8) & 0xFF;
    final iB = iceTintInt & 0xFF;

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

    // Calculate upward freeze front height
    // Starts at bottom (maxY + 4) and climbs to top (minY - 4)
    final freezeFrontY = (maxY + 4.0) - cycleTime * (boxH + 8.0);

    // 1. Generate dendritic crystal seeds
    final crystals = <math.Point<double>>[];
    for (int c = 0; c < crystalDensity; c++) {
      final fracX = 0.15 + 0.7 * math.sin(c * 29.3 + 1.7).abs();
      final fracY = 0.2 + 0.65 * math.cos(c * 43.1 + 0.5).abs();
      crystals.add(math.Point<double>(minX + fracX * boxW, minY + fracY * boxH));
    }

    void blendPixel(int px, int py, int r, int g, int b, double alpha, {bool isAdditive = false}) {
      if (px < 0 || px >= width || py < 0 || py >= height) return;
      final idx = py * width + px;
      final origPixel = pixels[idx];
      final origA = (origPixel >> 24) & 0xFF;

      if (preserveAlpha && origA == 0) return;

      final effA = alpha.clamp(0.0, 1.0);
      final oR = (origPixel >> 16) & 0xFF;
      final oG = (origPixel >> 8) & 0xFF;
      final oB = origPixel & 0xFF;

      int newR, newG, newB;
      if (isAdditive) {
        newR = (oR + r * effA).round().clamp(0, 255);
        newG = (oG + g * effA).round().clamp(0, 255);
        newB = (oB + b * effA).round().clamp(0, 255);
      } else {
        newR = (oR * (1.0 - effA) + r * effA).round().clamp(0, 255);
        newG = (oG * (1.0 - effA) + g * effA).round().clamp(0, 255);
        newB = (oB * (1.0 - effA) + b * effA).round().clamp(0, 255);
      }

      final targetA = (effA * iA).round();
      final newA = preserveAlpha ? origA : math.max(origA, targetA);

      output[idx] = (newA << 24) | (newR << 16) | (newG << 8) | newB;
    }

    // 2. Process base frost glaze and freeze progression
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final idx = y * width + x;
        final origPixel = pixels[idx];
        final origA = (origPixel >> 24) & 0xFF;

        if (preserveAlpha && origA == 0) continue;

        final oR = (origPixel >> 16) & 0xFF;
        final oG = (origPixel >> 8) & 0xFF;
        final oB = origPixel & 0xFF;

        // Is pixel below the upward freeze front?
        final yDiff = y - freezeFrontY;
        if (yDiff > -3.0) {
          final freezeIntensity = (yDiff / 5.0).clamp(0.0, 1.0);

          // Translucent glacial glaze (shift hue towards cyan-ice, boost lightness)
          final iceR = (oR * 0.4 + iR * 0.6).round().clamp(0, 255);
          final iceG = (oG * 0.4 + iG * 0.6).round().clamp(0, 255);
          final iceB = (oB * 0.3 + iB * 0.7).round().clamp(0, 255);

          final glazedR = (oR * (1.0 - freezeIntensity * 0.65) + iceR * (freezeIntensity * 0.65)).round();
          final glazedG = (oG * (1.0 - freezeIntensity * 0.65) + iceG * (freezeIntensity * 0.65)).round();
          final glazedB = (oB * (1.0 - freezeIntensity * 0.65) + iceB * (freezeIntensity * 0.65)).round();

          final newA = preserveAlpha ? origA : math.max(origA, (freezeIntensity * iA).round());
          output[idx] = (newA << 24) | (glazedR << 16) | (glazedG << 8) | glazedB;
        }
      }
    }

    // 3. Draw dendritic frost needle branches and hexagonal crystal clusters
    for (int c = 0; c < crystals.length; c++) {
      final seed = crystals[c];
      // Only draw crystals that have been frozen by the climbing front
      if (seed.y < freezeFrontY - 2.0) continue;

      final clusterAge = ((seed.y - freezeFrontY) / boxH).clamp(0.0, 1.0);
      final crystalSize = (3.0 + 4.0 * frostBranching * clusterAge).round();

      // Hexagonal arms (60 degree intervals)
      for (int a = 0; a < 6; a++) {
        final angle = a * (math.pi / 3.0);
        for (int step = 0; step <= crystalSize; step++) {
          final armX = seed.x + math.cos(angle) * step;
          final armY = seed.y + math.sin(angle) * step;
          final ax = armX.round();
          final ay = armY.round();

          final armAlpha = (1.0 - (step / (crystalSize + 1.0))) * 0.85;
          blendPixel(ax, ay, 240, 250, 255, armAlpha, isAdditive: true);

          // Sub-branch needle
          if (step > 1 && (step % 2 == 0)) {
            final branchAngle = angle + (math.pi / 4.0);
            final bx = (armX + math.cos(branchAngle) * 1.5).round();
            final by = (armY + math.sin(branchAngle) * 1.5).round();
            blendPixel(bx, by, iR, iG, iB, armAlpha * 0.6, isAdditive: true);
          }
        }
      }

      // Specular glint on crystal core
      if (specularShimmer > 0.05) {
        final shimmerWave = math.sin(cycleTime * 40.0 + c * 7.9);
        if (shimmerWave > 0.4) {
          final glintIntensity = ((shimmerWave - 0.4) / 0.6) * specularShimmer;
          final sx = seed.x.round();
          final sy = seed.y.round();

          blendPixel(sx, sy, 255, 255, 255, glintIntensity, isAdditive: true);
          blendPixel(sx - 1, sy, 255, 255, 255, glintIntensity * 0.6, isAdditive: true);
          blendPixel(sx + 1, sy, 255, 255, 255, glintIntensity * 0.6, isAdditive: true);
          blendPixel(sx, sy - 1, 255, 255, 255, glintIntensity * 0.6, isAdditive: true);
          blendPixel(sx, sy + 1, 255, 255, 255, glintIntensity * 0.6, isAdditive: true);
        }
      }
    }

    return output;
  }
}
