part of 'effects.dart';

/// An effect that physically fractures the drawing into Voronoi polygon glass
/// or ceramic shards, displacing each shard outward from an impact point with
/// rotational spin, transparent fracture gaps, and specular edge bevels.
class VoronoiShatterEffect extends Effect {
  VoronoiShatterEffect([Map<String, dynamic>? params])
      : super(
          EffectType.voronoiShatter,
          params ??
              {
                'impactCenterX': 0.5,
                'impactCenterY': 0.5,
                'shardCount': 16.0,
                'explosionForce': 3.5,
                'fractureGap': 1.2,
                'shardRotation': 0.3,
                'specularBevel': 0.5,
                'preserveAlpha': true,
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() => {
        'impactCenterX': 0.5,
        'impactCenterY': 0.5,
        'shardCount': 16.0,
        'explosionForce': 3.5,
        'fractureGap': 1.2,
        'shardRotation': 0.3,
        'specularBevel': 0.5,
        'preserveAlpha': true,
      };

  @override
  Map<String, dynamic> getMetadata() => {
        'impactCenterX': {
          'label': 'Impact Center X',
          'description': 'Horizontal epicenter coordinate of the shatter blast.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'step': 0.05,
        },
        'impactCenterY': {
          'label': 'Impact Center Y',
          'description': 'Vertical epicenter coordinate of the shatter blast.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'step': 0.05,
        },
        'shardCount': {
          'label': 'Shard Count',
          'description': 'Number of fractured Voronoi polygon shards.',
          'type': 'slider',
          'min': 4.0,
          'max': 36.0,
          'step': 2.0,
        },
        'explosionForce': {
          'label': 'Explosion Force',
          'description': 'Distance shards are displaced outward from the blast center.',
          'type': 'slider',
          'min': 0.0,
          'max': 15.0,
          'step': 0.5,
        },
        'fractureGap': {
          'label': 'Fracture Gap',
          'description': 'Width of transparent void channels separating adjacent shards.',
          'type': 'slider',
          'min': 0.0,
          'max': 4.0,
          'step': 0.2,
        },
        'shardRotation': {
          'label': 'Shard Rotation',
          'description': 'Rotational spin and tumbling angle of individual shards.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'step': 0.05,
        },
        'specularBevel': {
          'label': 'Glass Specular Bevel',
          'description': 'Edge highlight sheen and facet lighting along fracture lips.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'step': 0.05,
        },
        'preserveAlpha': {
          'label': 'Preserve Alpha',
          'description': 'Confine shards strictly to layer pixels and keep empty space transparent.',
          'type': 'bool',
        },
      };

  @override
  List<UIField> getFields() => [
        SliderField(
          key: 'impactCenterX',
          label: 'Impact Center X',
          description: 'Horizontal epicenter coordinate of the shatter blast.',
          min: 0.0,
          max: 1.0,
          divisions: 20,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        SliderField(
          key: 'impactCenterY',
          label: 'Impact Center Y',
          description: 'Vertical epicenter coordinate of the shatter blast.',
          min: 0.0,
          max: 1.0,
          divisions: 20,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        SliderField(
          key: 'shardCount',
          label: 'Shard Count',
          description: 'Number of fractured Voronoi polygon shards.',
          min: 4.0,
          max: 36.0,
          divisions: 16,
          formatLabel: (v) => '${v.round()}',
        ),
        SliderField(
          key: 'explosionForce',
          label: 'Explosion Force',
          description: 'Distance shards are displaced outward from the blast center.',
          min: 0.0,
          max: 15.0,
          divisions: 30,
          formatLabel: (v) => '${v.toStringAsFixed(1)}px',
        ),
        SliderField(
          key: 'fractureGap',
          label: 'Fracture Gap',
          description: 'Width of transparent void channels separating adjacent shards.',
          min: 0.0,
          max: 4.0,
          divisions: 20,
          formatLabel: (v) => '${v.toStringAsFixed(1)}px',
        ),
        SliderField(
          key: 'shardRotation',
          label: 'Shard Rotation',
          description: 'Rotational spin and tumbling angle of individual shards.',
          min: 0.0,
          max: 1.0,
          divisions: 20,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        SliderField(
          key: 'specularBevel',
          label: 'Glass Specular Bevel',
          description: 'Edge highlight sheen and facet lighting along fracture lips.',
          min: 0.0,
          max: 1.0,
          divisions: 20,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        const BoolField(
          key: 'preserveAlpha',
          label: 'Preserve Alpha',
          description: 'Confine shards strictly to layer pixels and keep empty space transparent.',
        ),
      ];

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    final output = Uint32List(width * height);

    final double impactXNorm = ((parameters['impactCenterX'] as num?)?.toDouble() ?? 0.5).clamp(0.0, 1.0);
    final double impactYNorm = ((parameters['impactCenterY'] as num?)?.toDouble() ?? 0.5).clamp(0.0, 1.0);
    final int count = ((parameters['shardCount'] as num?)?.toDouble() ?? 16.0).round().clamp(3, 48);
    final double force = ((parameters['explosionForce'] as num?)?.toDouble() ?? 3.5).clamp(0.0, 30.0);
    final double gap = ((parameters['fractureGap'] as num?)?.toDouble() ?? 1.2).clamp(0.0, 10.0);
    final double rotStrength = ((parameters['shardRotation'] as num?)?.toDouble() ?? 0.3).clamp(0.0, 1.0);
    final double bevel = ((parameters['specularBevel'] as num?)?.toDouble() ?? 0.5).clamp(0.0, 1.0);
    final bool preserveAlpha = parameters['preserveAlpha'] as bool? ?? true;

    final double impactX = impactXNorm * width;
    final double impactY = impactYNorm * height;

    // Generate deterministic Voronoi seed points distributed across the canvas
    final int cols = math.max(1, math.sqrt(count * width / math.max(1, height)).round());
    final int rows = math.max(1, (count / cols).ceil());
    final int totalSeeds = cols * rows;

    final seedX = Float64List(totalSeeds);
    final seedY = Float64List(totalSeeds);
    final deltaX = Float64List(totalSeeds);
    final deltaY = Float64List(totalSeeds);
    final rotAngle = Float64List(totalSeeds);
    final cosR = Float64List(totalSeeds);
    final sinR = Float64List(totalSeeds);

    final double cellW = width / cols;
    final double cellH = height / rows;

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final int k = r * cols + c;
        final double h1 = _hash(k * 17 + 101);
        final double h2 = _hash(k * 31 + 211);
        final double h3 = _hash(k * 43 + 307);
        final double h4 = _hash(k * 59 + 419);

        // Jittered seed coordinates within each cell
        final double sx = (c + 0.15 + h1 * 0.7) * cellW;
        final double sy = (r + 0.15 + h2 * 0.7) * cellH;
        seedX[k] = sx;
        seedY[k] = sy;

        // Radial vector from blast center to shard seed
        final double vx = sx - impactX;
        final double vy = sy - impactY;
        final double distToCenter = math.sqrt(vx * vx + vy * vy) + 0.001;

        // Shard outward displacement vector
        final double shardDistFactor = 1.0 + (h3 - 0.5) * 0.5;
        deltaX[k] = (vx / distToCenter) * force * shardDistFactor;
        deltaY[k] = (vy / distToCenter) * force * shardDistFactor;

        // Shard rotational twist around its own center
        final double theta = (h4 - 0.5) * 0.7 * rotStrength;
        rotAngle[k] = theta;
        cosR[k] = math.cos(-theta);
        sinR[k] = math.sin(-theta);
      }
    }

    // Light direction for shard edge specular bevel (from top-left)
    const double lightDirX = -0.7071;
    const double lightDirY = -0.7071;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int idx = y * width + x;

        final int origPixel = pixels[idx];
        final int origA = (origPixel >> 24) & 0xFF;
        if (preserveAlpha && origA == 0) {
          output[idx] = 0;
          continue;
        }

        // Find closest seed (k1) and second closest seed (k2)
        double d1 = 1e12;
        double d2 = 1e12;
        int bestK = 0;

        for (int k = 0; k < totalSeeds; k++) {
          final double dx = x - seedX[k];
          final double dy = y - seedY[k];
          final double distSq = dx * dx + dy * dy;

          if (distSq < d1) {
            d2 = d1;
            d1 = distSq;
            bestK = k;
          } else if (distSq < d2) {
            d2 = distSq;
          }
        }

        final double dist1 = math.sqrt(d1);
        final double dist2 = math.sqrt(d2);
        final double distToBorder = (dist2 - dist1) * 0.5;

        // Fracture gap check: if within gap margin, render transparent void
        final double halfGap = gap * 0.5;
        if (distToBorder <= halfGap && gap > 0.1) {
          output[idx] = 0;
          continue;
        }

        // Inverse mapping: find the original sprite coordinate for this shard
        final double unShiftedX = x - deltaX[bestK];
        final double unShiftedY = y - deltaY[bestK];

        // Inverse rotation around seed
        final double rx = unShiftedX - seedX[bestK];
        final double ry = unShiftedY - seedY[bestK];
        final double c = cosR[bestK];
        final double s = sinR[bestK];
        final double origX = seedX[bestK] + (rx * c - ry * s);
        final double origY = seedY[bestK] + (rx * s + ry * c);

        final int srcX = origX.round();
        final int srcY = origY.round();

        // Check if sample coordinate is inside canvas bounds
        if (srcX < 0 || srcX >= width || srcY < 0 || srcY >= height) {
          output[idx] = 0;
          continue;
        }

        final int srcIdx = srcY * width + srcX;
        final int srcPixel = pixels[srcIdx];
        final int srcA = (srcPixel >> 24) & 0xFF;

        if (srcA == 0) {
          output[idx] = 0;
          continue;
        }

        final int srcR = (srcPixel >> 16) & 0xFF;
        final int srcG = (srcPixel >> 8) & 0xFF;
        final int srcB = srcPixel & 0xFF;

        // Glass edge specular beveling along shard lips
        double bevelFactor = 1.0;
        final double bevelZone = halfGap + 1.6;
        if (distToBorder < bevelZone && bevel > 0.05) {
          final double t = ((distToBorder - halfGap) / 1.6).clamp(0.0, 1.0);
          final double edgeWeight = (1.0 - t) * bevel;

          // Estimate shard edge normal from distance to center
          final double nx = (x - seedX[bestK]) / (dist1 + 0.001);
          final double ny = (y - seedY[bestK]) / (dist1 + 0.001);
          final double dotL = nx * lightDirX + ny * lightDirY;

          if (dotL > 0) {
            // Specular glass highlight along illuminated edge
            final double highlight = dotL * edgeWeight * 0.7;
            final int rOut = (srcR * (1.0 + highlight) + 255 * highlight * 0.5).clamp(0, 255).round();
            final int gOut = (srcG * (1.0 + highlight) + 255 * highlight * 0.5).clamp(0, 255).round();
            final int bOut = (srcB * (1.0 + highlight) + 255 * highlight * 0.5).clamp(0, 255).round();
            output[idx] = (srcA << 24) | (rOut << 16) | (gOut << 8) | bOut;
            continue;
          } else {
            // Shadow bevel on opposite edge
            bevelFactor = (1.0 + dotL * edgeWeight * 0.4).clamp(0.4, 1.0);
          }
        }

        final int rOut = (srcR * bevelFactor).clamp(0, 255).round();
        final int gOut = (srcG * bevelFactor).clamp(0, 255).round();
        final int bOut = (srcB * bevelFactor).clamp(0, 255).round();

        output[idx] = (srcA << 24) | (rOut << 16) | (gOut << 8) | bOut;
      }
    }

    return output;
  }

  static double _hash(int n) {
    int x = (n << 13) ^ n;
    x = (x * (x * x * 15731 + 789221) + 1376312589) & 0x7fffffff;
    return x / 2147483647.0;
  }
}
