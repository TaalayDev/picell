part of 'effects.dart';

/// Procedural burning embers and soul disintegration effect with advancing
/// scorch boundaries, incandescent edge burning, and drifting thermal sparks.
class BurningEmbersEffect extends Effect implements UIFieldProvider {
  BurningEmbersEffect([Map<String, dynamic>? parameters])
      : super(
          EffectType.burningEmbers,
          parameters ??
              const {
                'emberColor': 0xFFFF6D00,
                'decayDirection': 'bottomToTop',
                'wispSpread': 0.5,
                'sparkCount': 40,
                'burnProgress': 0.5,
                'time': 0.0,
                'preserveAlpha': true,
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() => {
        'emberColor': 0xFFFF6D00,
        'decayDirection': 'bottomToTop',
        'wispSpread': 0.5,
        'sparkCount': 40,
        'burnProgress': 0.5,
        'time': 0.0,
        'preserveAlpha': true,
      };

  @override
  Map<String, dynamic> getMetadata() => {
        'emberColor': {
          'label': 'Ember Glow Color',
          'description': 'Color of the burning sparks and incandescent rim.',
          'type': 'color',
        },
        'decayDirection': {
          'label': 'Disintegration Direction',
          'description': 'Direction along which the sprite crumbles and dissolves.',
          'type': 'select',
          'options': {
            'bottomToTop': 'Ascending Dissolution (Bottom to Top)',
            'topToBottom': 'Descending Dissolution (Top to Bottom)',
            'radialOutward': 'Core Outward Dissolution',
          },
        },
        'wispSpread': {
          'label': 'Edge Jaggedness',
          'description': 'Irregularity and chaotic spread of the dissolving burn boundary.',
          'type': 'slider',
          'min': 0.1,
          'max': 1.0,
          'divisions': 18,
        },
        'sparkCount': {
          'label': 'Floating Sparks',
          'description': 'Quantity of burning ember particles cast into the air.',
          'type': 'slider',
          'min': 10,
          'max': 100,
          'divisions': 18,
        },
        'burnProgress': {
          'label': 'Burn Progress',
          'description': 'Static disintegration threshold when not animating.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 100,
        },
        'time': {
          'label': 'Animation Time',
          'description': 'Timeline progress parameter for progressive disintegration.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 100,
        },
        'preserveAlpha': {
          'label': 'Preserve Transparency',
          'description': 'Keep background transparent as sprite dissolves away.',
          'type': 'bool',
        },
      };

  @override
  List<UIField> getFields() => [
        const ColorField(
          key: 'emberColor',
          label: 'Ember Fire Color',
          description: 'Luminescent color of the hot burning sparks and glowing ash.',
        ),
        const SelectField(
          key: 'decayDirection',
          label: 'Decay Direction',
          description: 'Path and advance orientation of the disintegration wave.',
          options: {
            'bottomToTop': 'Ascending Dissolution (Bottom to Top)',
            'topToBottom': 'Descending Dissolution (Top to Bottom)',
            'radialOutward': 'Core Outward Dissolution',
          },
        ),
        SliderField(
          key: 'wispSpread',
          label: 'Edge Jaggedness',
          description: 'Chaotic turbulence along the advancing burn frontier.',
          min: 0.1,
          max: 1.0,
          divisions: 18,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        SliderField(
          key: 'sparkCount',
          label: 'Ember Sparks',
          description: 'Number of floating ember particles released into the air.',
          min: 10,
          max: 100,
          divisions: 18,
          formatLabel: (v) => '${v.round()} sparks',
        ),
        SliderField(
          key: 'burnProgress',
          label: 'Burn Progress',
          description: 'Extent of disintegration when applied as a static frame.',
          min: 0.0,
          max: 1.0,
          divisions: 100,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        SliderField(
          key: 'time',
          label: 'Animation Time',
          description: 'Timeline progress parameter updated during animation generation.',
          min: 0.0,
          max: 1.0,
          divisions: 100,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        const BoolField(
          key: 'preserveAlpha',
          label: 'Preserve Transparency',
          description: 'Keep background canvas transparent during disintegration.',
        ),
      ];

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    if (width <= 0 || height <= 0 || pixels.isEmpty) return pixels;

    final emberColorInt = (parameters['emberColor'] as int?) ?? 0xFFFF6D00;
    final decayDirection = (parameters['decayDirection'] as String?) ?? 'bottomToTop';
    final wispSpread = ((parameters['wispSpread'] as num?)?.toDouble() ?? 0.5).clamp(0.1, 1.0);
    final sparkCount = ((parameters['sparkCount'] as num?)?.toInt() ?? 40).clamp(10, 100);
    final burnProgress = ((parameters['burnProgress'] as num?)?.toDouble() ?? 0.5).clamp(0.0, 1.0);
    final time = ((parameters['time'] as num?)?.toDouble() ?? 0.0).clamp(0.0, 1.0);
    final preserveAlpha = parameters['preserveAlpha'] as bool? ?? true;

    // Use time parameter if animating, else static burnProgress
    final progress = time > 0.0 ? time : burnProgress;

    final embR = (emberColorInt >> 16) & 0xFF;
    final embG = (emberColorInt >> 8) & 0xFF;
    final embB = emberColorInt & 0xFF;

    final result = Uint32List(width * height);
    if (preserveAlpha) {
      result.setAll(0, pixels);
    } else {
      const darkAsh = 0xFF0E0A08;
      const bgR = (darkAsh >> 16) & 0xFF;
      const bgG = (darkAsh >> 8) & 0xFF;
      const bgB = darkAsh & 0xFF;
      result.fillRange(0, result.length, darkAsh);
      for (int i = 0; i < pixels.length; i++) {
        final p = pixels[i];
        final a = (p >> 24) & 0xFF;
        if (a > 0) {
          final na = a / 255.0;
          final pr = (p >> 16) & 0xFF;
          final pg = (p >> 8) & 0xFF;
          final pb = p & 0xFF;
          final outR = (pr * na + bgR * (1.0 - na)).round().clamp(0, 255);
          final outG = (pg * na + bgG * (1.0 - na)).round().clamp(0, 255);
          final outB = (pb * na + bgB * (1.0 - na)).round().clamp(0, 255);
          result[i] = 0xFF000000 | (outR << 16) | (outG << 8) | outB;
        }
      }
    }

    // Find bounding box of foreground sprite
    int minY = height, maxY = 0, minX = width, maxX = 0;
    bool hasFg = false;
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        if ((pixels[y * width + x] >> 24) & 0xFF > 30) {
          hasFg = true;
          if (x < minX) minX = x;
          if (x > maxX) maxX = x;
          if (y < minY) minY = y;
          if (y > maxY) maxY = y;
        }
      }
    }

    if (!hasFg) {
      minY = 0;
      maxY = height - 1;
      minX = 0;
      maxX = width - 1;
    }

    final cx = (minX + maxX) / 2.0;
    final cy = (minY + maxY) / 2.0;
    final maxR = math.max(1.0, math.max(maxX - minX, maxY - minY) / 2.0);

    // List of active burn edge points where sparks spawn
    final burnEdgePoints = <math.Point<double>>[];

    // 1. Advance Burn Disintegration Front
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final idx = y * width + x;
        final srcPixel = pixels[idx];
        final srcA = (srcPixel >> 24) & 0xFF;
        if (srcA == 0) continue;

        double coordRatio;
        if (decayDirection == 'bottomToTop') {
          coordRatio = (maxY - y) / math.max(1, maxY - minY);
        } else if (decayDirection == 'topToBottom') {
          coordRatio = (y - minY) / math.max(1, maxY - minY);
        } else {
          // radialOutward
          final dx = x - cx;
          final dy = y - cy;
          coordRatio = math.sqrt(dx * dx + dy * dy) / maxR;
        }

        // Noise perturbation
        final noise = (math.sin(x * 0.7 + y * 0.9) * 0.5 + math.cos(x * 1.3 - y * 0.4) * 0.5) * 0.15 * wispSpread;
        final effectiveT = coordRatio + noise;

        if (effectiveT < progress) {
          // Check if it lies in the incandescent burn rim
          final edgeDist = progress - effectiveT;
          const rimWidth = 0.14;

          if (edgeDist < rimWidth) {
            burnEdgePoints.add(math.Point(x.toDouble(), y.toDouble()));

            final rimFactor = 1.0 - (edgeDist / rimWidth);
            final isCoreHot = rimFactor > 0.7;

            // Gradient: White-Hot -> Yellow -> Ember Color -> Burnt Ash
            int r, g, b;
            if (isCoreHot) {
              r = 255;
              g = 255;
              b = (200 * (rimFactor - 0.7) / 0.3).round().clamp(0, 255);
            } else if (rimFactor > 0.3) {
              final tMid = (rimFactor - 0.3) / 0.4;
              r = 255;
              g = (embG * (1.0 - tMid) + 230 * tMid).round().clamp(0, 255);
              b = (embB * (1.0 - tMid)).round().clamp(0, 255);
            } else {
              final tAsh = rimFactor / 0.3;
              r = (embR * tAsh + 30 * (1.0 - tAsh)).round().clamp(0, 255);
              g = (embG * tAsh + 20 * (1.0 - tAsh)).round().clamp(0, 255);
              b = (embB * tAsh + 20 * (1.0 - tAsh)).round().clamp(0, 255);
            }

            final rimA = (srcA * math.max(0.4, rimFactor)).round().clamp(0, 255);
            result[idx] = (rimA << 24) | (r << 16) | (g << 8) | b;
          } else {
            // Completely crumbled into ash
            result[idx] = preserveAlpha ? 0x00000000 : 0xFF0E0A08;
          }
        }
      }
    }

    // 2. Drifting Ember Sparks & Ash Wisps
    if (sparkCount > 0 && burnEdgePoints.isNotEmpty) {
      final rand = math.Random(1337);

      void plotSpark(int px, int py, int r, int g, int b, int alpha) {
        if (px < 0 || px >= width || py < 0 || py >= height) return;
        final idx = py * width + px;

        final existing = result[idx];
        final exA = (existing >> 24) & 0xFF;
        final exR = (existing >> 16) & 0xFF;
        final exG = (existing >> 8) & 0xFF;
        final exB = existing & 0xFF;

        final na = alpha / 255.0;
        final outR = math.min(255, (exR + r * na).round());
        final outG = math.min(255, (exG + g * na).round());
        final outB = math.min(255, (exB + b * na).round());
        final outA = math.max(exA, alpha);

        result[idx] = (outA << 24) | (outR << 16) | (outG << 8) | outB;
      }

      for (int i = 0; i < sparkCount; i++) {
        final origin = burnEdgePoints[rand.nextInt(burnEdgePoints.length)];
        final lifespan = 0.4 + rand.nextDouble() * 0.6;
        final sparkProgress = ((progress * 2.0 + (i / sparkCount)) % 1.0);

        // Sparks float upward with heat draft
        final riseDist = sparkProgress * (height * 0.6) * lifespan;
        final flutter = math.sin((riseDist * 0.25) + i) * 3.0 * wispSpread;

        final sx = (origin.x + flutter).round();
        final sy = (origin.y - riseDist).round();

        // Spark cools over flight: White -> Ember Color -> Dark Red
        final cooling = (1.0 - sparkProgress).clamp(0.0, 1.0);
        final sparkA = (cooling * 255).round().clamp(0, 255);

        int sr, sg, sb;
        if (cooling > 0.6) {
          sr = 255;
          sg = math.min(255, embG + 60);
          sb = math.min(255, embB + 40);
        } else {
          sr = (embR * cooling + 60 * (1.0 - cooling)).round().clamp(0, 255);
          sg = (embG * cooling).round().clamp(0, 255);
          sb = (embB * cooling).round().clamp(0, 255);
        }

        plotSpark(sx, sy, sr, sg, sb, sparkA);
        // Soft aura on brightest sparks
        if (cooling > 0.8) {
          plotSpark(sx + 1, sy, sr, sg, sb, sparkA ~/ 3);
          plotSpark(sx - 1, sy, sr, sg, sb, sparkA ~/ 3);
        }
      }
    }

    return result;
  }
}
