part of 'effects.dart';

/// Procedural electrical discharge and lightning bolts using fractal midpoint
/// displacement, multi-tier branching, plasma core rendering, and strike animations.
class ElectricArcEffect extends Effect implements UIFieldProvider {
  ElectricArcEffect([Map<String, dynamic>? parameters])
      : super(
          EffectType.electricArc,
          parameters ??
              const {
                'strikeMode': 'vertical',
                'arcColor': 0xFF00E5FF,
                'branching': 0.6,
                'jaggedness': 0.8,
                'glowRadius': 2,
                'flashIntensity': 0.3,
                'time': 0.0,
                'preserveAlpha': true,
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() => {
        'strikeMode': 'vertical',
        'arcColor': 0xFF00E5FF,
        'branching': 0.6,
        'jaggedness': 0.8,
        'glowRadius': 2,
        'flashIntensity': 0.3,
        'time': 0.0,
        'preserveAlpha': true,
      };

  @override
  Map<String, dynamic> getMetadata() => {
        'strikeMode': {
          'label': 'Arc Routing Mode',
          'description': 'Trajectory and strike pattern of the electric bolts.',
          'type': 'select',
          'options': ['vertical', 'radial', 'horizontal', 'contourAura'],
        },
        'arcColor': {
          'label': 'Electric Arc Tint',
          'description': 'Color of the surrounding plasma glow aura.',
          'type': 'color',
        },
        'branching': {
          'label': 'Branch Density',
          'description': 'Frequency of secondary fork branches splitting from main trunk.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 20,
        },
        'jaggedness': {
          'label': 'Bolt Jaggedness',
          'description': 'Roughness and chaos of the midpoint displacement path.',
          'type': 'slider',
          'min': 0.2,
          'max': 2.0,
          'divisions': 36,
        },
        'glowRadius': {
          'label': 'Plasma Glow Radius',
          'description': 'Width of the high-energy electric ionization halo.',
          'type': 'slider',
          'min': 1,
          'max': 3,
          'divisions': 2,
        },
        'flashIntensity': {
          'label': 'Ambient Flash',
          'description': 'Luminance surge illuminating the surroundings on strike.',
          'type': 'slider',
          'min': 0.0,
          'max': 0.8,
          'divisions': 16,
        },
        'time': {
          'label': 'Animation Time',
          'description': 'Timeline progress parameter for animated strike cycles.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 100,
        },
        'preserveAlpha': {
          'label': 'Preserve Transparency',
          'description': 'Renders electric arcs cleanly over transparent sprites.',
          'type': 'bool',
        },
      };

  @override
  List<UIField> getFields() => [
        const SelectField(
          key: 'strikeMode',
          label: 'Arc Pattern',
          description: 'Direction and path configuration of the electric arcs.',
          options: {
            'vertical': 'Vertical Thunder Strike (Top-Down)',
            'radial': 'Tesla Coil Discharge (Center Burst)',
            'horizontal': 'Horizontal Shock (Left-Right)',
            'contourAura': 'Electric Aura (Sprite Contour)',
          },
        ),
        const ColorField(
          key: 'arcColor',
          label: 'Plasma Glow Color',
          description: 'Color of the electrical ionization field surrounding the core.',
        ),
        SliderField(
          key: 'branching',
          label: 'Branch Density',
          description: 'Frequency and occurrence of splitting fork branches.',
          min: 0.0,
          max: 1.0,
          divisions: 20,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        SliderField(
          key: 'jaggedness',
          label: 'Bolt Jaggedness',
          description: 'Chaotic displacement amplitude of lightning segments.',
          min: 0.2,
          max: 2.0,
          divisions: 36,
          formatLabel: (v) => '${v.toStringAsFixed(1)}x',
        ),
        SliderField(
          key: 'glowRadius',
          label: 'Plasma Glow Width',
          description: 'Pixel radius of the energetic plasma aura.',
          min: 1,
          max: 3,
          divisions: 2,
          formatLabel: (v) => '${v.round()} px',
        ),
        SliderField(
          key: 'flashIntensity',
          label: 'Flash Intensity',
          description: 'Intensity of ambient lightning storm flashes.',
          min: 0.0,
          max: 0.8,
          divisions: 16,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        SliderField(
          key: 'time',
          label: 'Animation Time',
          description: 'Timeline progress parameter updated during frame generation.',
          min: 0.0,
          max: 1.0,
          divisions: 100,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        const BoolField(
          key: 'preserveAlpha',
          label: 'Preserve Transparency',
          description: 'Allow electric bolts to float cleanly over transparent backgrounds.',
        ),
      ];

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    if (width <= 0 || height <= 0 || pixels.isEmpty) return pixels;

    final strikeMode = (parameters['strikeMode'] as String?) ?? 'vertical';
    final arcColorInt = (parameters['arcColor'] as int?) ?? 0xFF00E5FF;
    final branching = ((parameters['branching'] as num?)?.toDouble() ?? 0.6).clamp(0.0, 1.0);
    final jaggedness = ((parameters['jaggedness'] as num?)?.toDouble() ?? 0.8).clamp(0.2, 2.0);
    final glowRadius = ((parameters['glowRadius'] as num?)?.toInt() ?? 2).clamp(1, 3);
    final flashIntensity = ((parameters['flashIntensity'] as num?)?.toDouble() ?? 0.3).clamp(0.0, 0.8);
    final time = ((parameters['time'] as num?)?.toDouble() ?? 0.0).clamp(0.0, 1.0);
    final preserveAlpha = parameters['preserveAlpha'] as bool? ?? true;

    final arcR = (arcColorInt >> 16) & 0xFF;
    final arcG = (arcColorInt >> 8) & 0xFF;
    final arcB = arcColorInt & 0xFF;

    // Start with a copy of input pixels or dark atmosphere
    final result = Uint32List(width * height);
    if (preserveAlpha) {
      result.setAll(0, pixels);
    } else {
      // Dark stormy background
      const darkBg = 0xFF060814;
      const bgR = (darkBg >> 16) & 0xFF;
      const bgG = (darkBg >> 8) & 0xFF;
      const bgB = darkBg & 0xFF;
      result.fillRange(0, result.length, darkBg);
      // Blend foreground sprite over dark background
      for (int i = 0; i < pixels.length; i++) {
        final p = pixels[i];
        final a = (p >> 24) & 0xFF;
        if (a > 0) {
          final r = (p >> 16) & 0xFF;
          final g = (p >> 8) & 0xFF;
          final b = p & 0xFF;
          final na = a / 255.0;
          final outR = (r * na + bgR * (1.0 - na)).round().clamp(0, 255);
          final outG = (g * na + bgG * (1.0 - na)).round().clamp(0, 255);
          final outB = (b * na + bgB * (1.0 - na)).round().clamp(0, 255);
          result[i] = 0xFF000000 | (outR << 16) | (outG << 8) | outB;
        }
      }
    }

    // Ambient strike flash calculation
    final flashPulse = (math.sin(time * math.pi * 12.0) * 0.5 + 0.5);
    final currentFlash = flashIntensity * flashPulse;
    if (currentFlash > 0.05) {
      final flashVal = (currentFlash * 120).round();
      for (int i = 0; i < result.length; i++) {
        final p = result[i];
        final a = (p >> 24) & 0xFF;
        if (a == 0 && preserveAlpha) continue;
        final r = math.min(255, ((p >> 16) & 0xFF) + flashVal);
        final g = math.min(255, ((p >> 8) & 0xFF) + flashVal);
        final b = math.min(255, (p & 0xFF) + flashVal);
        result[i] = (a << 24) | (r << 16) | (g << 8) | b;
      }
    }

    // Seeded Random based on time intervals so bolts jiggle and strike
    final cycleIndex = (time * 8.0).floor();
    final rng = math.Random(cycleIndex * 19937 + 42);

    // List of line segments to rasterize: each segment has [x0, y0, x1, y1, isCore]
    final segments = <List<num>>[];

    void subdivide(num x0, num y0, num x1, num y1, double disp, int depth) {
      if (depth <= 0) {
        segments.add([x0, y0, x1, y1]);
        return;
      }

      final midX = (x0 + x1) / 2.0;
      final midY = (y0 + y1) / 2.0;
      final dx = (x1 - x0).toDouble();
      final dy = (y1 - y0).toDouble();
      final len = math.sqrt(dx * dx + dy * dy);

      if (len < 1.0) {
        segments.add([x0, y0, x1, y1]);
        return;
      }

      // Normal vector perpendicular to segment
      final nx = -dy / len;
      final ny = dx / len;

      final offset = (rng.nextDouble() * 2.0 - 1.0) * disp * jaggedness;
      final pX = midX + nx * offset;
      final pY = midY + ny * offset;

      subdivide(x0, y0, pX, pY, disp * 0.55, depth - 1);
      subdivide(pX, pY, x1, y1, disp * 0.55, depth - 1);

      // Potential child branch
      if (depth >= 2 && rng.nextDouble() < (branching * 0.45)) {
        final branchAngle = (rng.nextDouble() * 0.8 - 0.4);
        final branchLen = len * (0.3 + rng.nextDouble() * 0.4);
        final dirCos = math.cos(branchAngle);
        final dirSin = math.sin(branchAngle);
        final bDirX = (dx / len) * dirCos - (dy / len) * dirSin;
        final bDirY = (dx / len) * dirSin + (dy / len) * dirCos;
        final bEndX = pX + bDirX * branchLen;
        final bEndY = pY + bDirY * branchLen;
        subdivide(pX, pY, bEndX, bEndY, disp * 0.4, depth - 1);
      }
    }

    // Build arcs based on strikeMode
    if (strikeMode == 'vertical') {
      final startX = width * (0.3 + rng.nextDouble() * 0.4);
      final endX = startX + (rng.nextDouble() * 2.0 - 1.0) * width * 0.25;
      subdivide(startX, 0, endX.clamp(0, width - 1), height - 1, width * 0.25, 4);
    } else if (strikeMode == 'horizontal') {
      final startY = height * (0.3 + rng.nextDouble() * 0.4);
      final endY = startY + (rng.nextDouble() * 2.0 - 1.0) * height * 0.25;
      subdivide(0, startY, width - 1, endY.clamp(0, height - 1), height * 0.25, 4);
    } else if (strikeMode == 'radial') {
      final cx = width / 2.0;
      final cy = height / 2.0;
      final boltCount = 3 + rng.nextInt(3);
      for (int b = 0; b < boltCount; b++) {
        final angle = (b * 2.0 * math.pi / boltCount) + (rng.nextDouble() * 0.5 - 0.25);
        final maxR = math.min(width, height) * 0.45;
        final tx = cx + math.cos(angle) * maxR;
        final ty = cy + math.sin(angle) * maxR;
        subdivide(cx, cy, tx.clamp(0, width - 1), ty.clamp(0, height - 1), maxR * 0.28, 4);
      }
    } else if (strikeMode == 'contourAura') {
      // Find contour pixels along edges of non-transparent sprite
      final edgePixels = <int>[];
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final idx = y * width + x;
          final a = (pixels[idx] >> 24) & 0xFF;
          if (a > 30) {
            // Check if it borders a transparent pixel
            bool isEdge = false;
            for (int dy = -1; dy <= 1 && !isEdge; dy++) {
              for (int dx = -1; dx <= 1; dx++) {
                final nx = x + dx;
                final ny = y + dy;
                if (nx < 0 || nx >= width || ny < 0 || ny >= height) {
                  isEdge = true;
                  break;
                }
                if ((pixels[ny * width + nx] >> 24) & 0xFF < 30) {
                  isEdge = true;
                  break;
                }
              }
            }
            if (isEdge) edgePixels.add(idx);
          }
        }
      }

      if (edgePixels.length >= 2) {
        final miniArcCount = (edgePixels.length ~/ 12).clamp(2, 8);
        for (int i = 0; i < miniArcCount; i++) {
          final p0Idx = edgePixels[rng.nextInt(edgePixels.length)];
          final p1Idx = edgePixels[rng.nextInt(edgePixels.length)];
          final x0 = p0Idx % width;
          final y0 = p0Idx ~/ width;
          final x1 = p1Idx % width;
          final y1 = p1Idx ~/ width;
          final dist = math.sqrt((x1 - x0) * (x1 - x0) + (y1 - y0) * (y1 - y0));
          if (dist > 2 && dist < width * 0.7) {
            subdivide(x0, y0, x1, y1, dist * 0.35, 3);
          }
        }
      } else {
        // Fallback to vertical if sprite is empty or solid
        subdivide(width * 0.5, 0, width * 0.5, height - 1, width * 0.25, 4);
      }
    }

    // Rasterize all segments: Core + Plasma Glow
    void plotPixel(int px, int py, int r, int g, int b, int a) {
      if (px < 0 || px >= width || py < 0 || py >= height) return;
      final idx = py * width + px;

      final existing = result[idx];
      final exA = (existing >> 24) & 0xFF;
      final exR = (existing >> 16) & 0xFF;
      final exG = (existing >> 8) & 0xFF;
      final exB = existing & 0xFF;

      final na = a / 255.0;
      final outR = math.min(255, (exR + r * na).round());
      final outG = math.min(255, (exG + g * na).round());
      final outB = math.min(255, (exB + b * na).round());
      final outA = math.max(exA, a);

      result[idx] = (outA << 24) | (outR << 16) | (outG << 8) | outB;
    }

    for (final seg in segments) {
      int x0 = seg[0].round();
      int y0 = seg[1].round();
      final x1 = seg[2].round();
      final y1 = seg[3].round();

      // Bresenham's line algorithm
      final dx = (x1 - x0).abs();
      final dy = -(y1 - y0).abs();
      final sx = x0 < x1 ? 1 : -1;
      final sy = y0 < y1 ? 1 : -1;
      var err = dx + dy;

      while (true) {
        // High-voltage central core: pure white
        plotPixel(x0, y0, 255, 255, 255, 255);

        // Surrounding plasma glow aura
        for (int gy = -glowRadius; gy <= glowRadius; gy++) {
          for (int gx = -glowRadius; gx <= glowRadius; gx++) {
            if (gx == 0 && gy == 0) continue;
            final distSq = gx * gx + gy * gy;
            if (distSq <= glowRadius * glowRadius + 1) {
              final dist = math.sqrt(distSq);
              final falloff = (1.0 - (dist / (glowRadius + 1.2))).clamp(0.1, 0.85);
              final alpha = (falloff * 220).round().clamp(0, 255);
              plotPixel(x0 + gx, y0 + gy, arcR, arcG, arcB, alpha);
            }
          }
        }

        if (x0 == x1 && y0 == y1) break;
        final e2 = 2 * err;
        if (e2 >= dy) {
          err += dy;
          x0 += sx;
        }
        if (e2 <= dx) {
          err += dx;
          y0 += sy;
        }
      }
    }

    return result;
  }
}
