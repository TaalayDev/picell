part of 'effects.dart';

/// An effect that procedurally renders hanging limestone speleothems (stalactites)
/// dripping translucent mineral water beads with gravitational acceleration,
/// landing splashes on opposing floor stalagmites, and expanding acoustic puddle echo ripples.
class StalactiteDripsEffect extends Effect {
  StalactiteDripsEffect([Map<String, dynamic>? params])
      : super(
          EffectType.stalactiteDrips,
          params ??
              {
                'dripRate': 1.5,
                'stalactiteDensity': 6,
                'splashImpactParticles': 8,
                'acousticRippleDecay': 0.5,
                'caveAmbiance': 'limestoneEcho',
                'time': 0.0,
                'preserveAlpha': false,
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() => {
        'dripRate': 1.5,
        'stalactiteDensity': 6,
        'splashImpactParticles': 8,
        'acousticRippleDecay': 0.5,
        'caveAmbiance': 'limestoneEcho',
        'time': 0.0,
        'preserveAlpha': false,
      };

  @override
  Map<String, dynamic> getMetadata() => {
        'dripRate': {
          'label': 'Drip Frequency',
          'description': 'Pace of droplet gathering, elongation, and falling.',
          'type': 'slider',
          'min': 0.5,
          'max': 4.0,
          'step': 0.1,
        },
        'stalactiteDensity': {
          'label': 'Speleothem Count',
          'description': 'Number of hanging stalactites and floor stalagmites.',
          'type': 'slider',
          'min': 3,
          'max': 12,
          'step': 1,
        },
        'splashImpactParticles': {
          'label': 'Splash Particles',
          'description': 'Droplet spray particles bounced into the air on floor impact.',
          'type': 'slider',
          'min': 4,
          'max': 20,
          'step': 1,
        },
        'acousticRippleDecay': {
          'label': 'Ripple Resonance',
          'description': 'Persistence and acoustic expansion distance of puddle ripples.',
          'type': 'slider',
          'min': 0.2,
          'max': 1.0,
          'step': 0.05,
        },
        'caveAmbiance': {
          'label': 'Cavern Ambiance',
          'description': 'Subterranean geological color grading and lighting.',
          'type': 'select',
          'options': {
            'limestoneEcho': 'Ancient Limestone Grotto',
            'bioluminescentCyan': 'Bioluminescent Abyssal Cavern',
            'crystalGrotto': 'Amethyst Crystal Mine',
            'dungeonCrypt': 'Dungeon Crypt Cistern',
          },
        },
        'time': {
          'label': 'Animation Time',
          'description': 'Progress cycle (0.0 to 1.0) advancing drops and ripples.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'step': 0.01,
        },
        'preserveAlpha': {
          'label': 'Preserve Alpha',
          'description': 'Confine stalactites, drips, and splashes to sprite boundary.',
          'type': 'bool',
        },
      };

  @override
  List<UIField> getFields() => [
        SliderField(
          key: 'dripRate',
          label: 'Drip Frequency',
          description: 'Pace of droplet gathering, elongation, and falling.',
          min: 0.5,
          max: 4.0,
          divisions: 35,
          formatLabel: (v) => '${v.toStringAsFixed(1)}x',
        ),
        const SliderField(
          key: 'stalactiteDensity',
          label: 'Speleothem Count',
          description: 'Number of hanging stalactites and floor stalagmites.',
          min: 3,
          max: 12,
          divisions: 9,
          isInteger: true,
        ),
        const SliderField(
          key: 'splashImpactParticles',
          label: 'Splash Particles',
          description: 'Droplet spray particles bounced into the air on floor impact.',
          min: 4,
          max: 20,
          divisions: 16,
          isInteger: true,
        ),
        SliderField(
          key: 'acousticRippleDecay',
          label: 'Ripple Resonance',
          description: 'Persistence and acoustic expansion distance of puddle ripples.',
          min: 0.2,
          max: 1.0,
          divisions: 16,
          formatLabel: (v) => v.toStringAsFixed(2),
        ),
        const SelectField(
          key: 'caveAmbiance',
          label: 'Cavern Ambiance',
          description: 'Subterranean geological color grading and lighting.',
          options: {
            'limestoneEcho': 'Ancient Limestone Grotto',
            'bioluminescentCyan': 'Bioluminescent Abyssal Cavern',
            'crystalGrotto': 'Amethyst Crystal Mine',
            'dungeonCrypt': 'Dungeon Crypt Cistern',
          },
        ),
        SliderField(
          key: 'time',
          label: 'Animation Time',
          description: 'Progress cycle (0.0 to 1.0) advancing drops and ripples.',
          min: 0.0,
          max: 1.0,
          divisions: 100,
          formatLabel: (v) => v.toStringAsFixed(2),
        ),
        const BoolField(
          key: 'preserveAlpha',
          label: 'Preserve Alpha',
          description: 'Confine stalactites, drips, and splashes to sprite boundary.',
        ),
      ];

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    final out = Uint32List.fromList(pixels);

    final dripRate = (parameters['dripRate'] as num?)?.toDouble() ?? 1.5;
    final stalactiteDensity = ((parameters['stalactiteDensity'] as num?)?.toInt() ?? 6).clamp(2, 16);
    final splashImpactParticles = ((parameters['splashImpactParticles'] as num?)?.toInt() ?? 8).clamp(2, 30);
    final acousticRippleDecay = ((parameters['acousticRippleDecay'] as num?)?.toDouble() ?? 0.5).clamp(0.1, 1.0);
    final caveAmbiance = (parameters['caveAmbiance'] as String?) ?? 'limestoneEcho';
    final time = (parameters['time'] as num?)?.toDouble() ?? 0.0;
    final preserveAlpha = (parameters['preserveAlpha'] as bool?) ?? false;

    final theme = _getCaveTheme(caveAmbiance);

    final ceilingY = (height * 0.22).toInt();
    final floorY = (height * 0.78).toInt();

    // 1. Generate Speleothem Positions (Stalactites & Matching Stalagmites)
    final speleothems = _generateSpeleothems(stalactiteDensity, width, height, ceilingY, floorY);

    // 2. Render Cavern Background, Ceiling, and Floor Puddles
    for (int y = 0; y < height; y++) {
      final isCeiling = y <= ceilingY;
      final isFloor = y >= floorY;

      for (int x = 0; x < width; x++) {
        final idx = y * width + x;

        if (preserveAlpha && (pixels[idx] >>> 24) == 0) {
          continue;
        }

        if (isCeiling) {
          // Rocky cavern ceiling with limestone fissures
          final rockNoise = _noise2D(x * 0.25, y * 0.25, 41);
          out[idx] = (rockNoise > 0.1) ? theme.rockLight : theme.rockDark;
        } else if (isFloor) {
          // Cavern floor puddle surface
          int floorColor = theme.puddleWater;

          // Acoustic concentric ripples from droplet impacts
          double totalWave = 0.0;
          for (final sp in speleothems) {
            final phase = ((time * dripRate * 2.0) + sp.phaseOffset) % 1.0;
            if (phase >= 0.65) {
              // Impact happened at phase 0.65
              final rippleProgress = (phase - 0.65) / 0.35;
              final maxRadius = width * 0.35 * acousticRippleDecay;
              final r = rippleProgress * maxRadius;

              final dx = x - sp.x;
              final dy = (y - floorY) * 2.2; // Perspective squashed puddle
              final dist = math.sqrt(dx * dx + dy * dy);

              final diff = (dist - r).abs();
              if (diff < 3.0 && dist > 0.5) {
                final waveAmp = math.exp(-dist * (0.12 / acousticRippleDecay)) * (1.0 - rippleProgress);
                totalWave += math.cos(diff * math.pi * 0.6) * waveAmp;
              }
            }
          }

          if (totalWave.abs() > 0.08) {
            final clampedWave = totalWave.clamp(-1.0, 1.0);
            if (clampedWave > 0.2) {
              // Specular ripple crest reflecting ceiling light
              final alpha = (clampedWave * 240).toInt().clamp(0, 255);
              floorColor = _additiveBlend(floorColor, theme.rippleHighlight, alpha);
            } else if (clampedWave < -0.15) {
              // Wave shadow trough
              floorColor = _multiplyColor(floorColor, (1.0 - (-clampedWave * 0.4)).clamp(0.5, 1.0));
            }
          }

          out[idx] = floorColor;
        } else {
          // Subterranean hollow grotto air
          out[idx] = theme.voidAir;
        }
      }
    }

    // 3. Render Speleothem Stone Formations (Stalactites & Stalagmites)
    for (final sp in speleothems) {
      final sx = sp.x;
      final tipY = sp.stalactiteTipY;
      final baseWidth = sp.baseHalfWidth;

      // Draw downward hanging Stalactite
      for (int y = 0; y <= tipY; y++) {
        final progress = y / tipY.toDouble();
        final currentHalfW = (baseWidth * (1.0 - progress)).round();

        for (int dx = -currentHalfW; dx <= currentHalfW; dx++) {
          final px = sx + dx;
          if (px < 0 || px >= width || y >= height) continue;
          final pIdx = y * width + px;

          if (preserveAlpha && (pixels[pIdx] >>> 24) == 0) continue;

          if (dx == -currentHalfW) {
            // Shadow left rim
            out[pIdx] = theme.rockDark;
          } else if (dx == currentHalfW || (dx == 0 && progress > 0.8)) {
            // Wet specular mineral highlight
            out[pIdx] = theme.rockLight;
          } else {
            out[pIdx] = theme.rockMedium;
          }
        }
      }

      // Draw upward matching Stalagmite mound on floor
      final stalagmiteHeight = sp.stalagmiteHeight;
      for (int h = 0; h < stalagmiteHeight; h++) {
        final y = floorY - h;
        if (y < 0 || y >= height) continue;
        final progress = h / stalagmiteHeight.toDouble();
        final currentHalfW = ((baseWidth * 0.8) * (1.0 - progress)).round();

        for (int dx = -currentHalfW; dx <= currentHalfW; dx++) {
          final px = sx + dx;
          if (px < 0 || px >= width) continue;
          final pIdx = y * width + px;

          if (preserveAlpha && (pixels[pIdx] >>> 24) == 0) continue;

          out[pIdx] = (dx == currentHalfW) ? theme.rockLight : theme.rockMedium;
        }
      }
    }

    // 4. Render Dynamic Droplets, Elongated Necks, Free-Fall & Splashes
    for (final sp in speleothems) {
      final sx = sp.x;
      final tipY = sp.stalactiteTipY;
      final targetY = floorY - sp.stalagmiteHeight;

      final phase = ((time * dripRate * 2.0) + sp.phaseOffset) % 1.0;

      if (phase < 0.35) {
        // Stage 1: Bead gathering & neck elongation at stalactite tip
        final gatherNorm = phase / 0.35;
        final beadLen = (gatherNorm * 2.2).round();

        for (int dy = 0; dy <= beadLen; dy++) {
          final py = tipY + dy;
          if (py >= 0 && py < height && sx >= 0 && sx < width) {
            final pIdx = py * width + sx;
            if (!preserveAlpha || (pixels[pIdx] >>> 24) != 0) {
              out[pIdx] = (dy == beadLen) ? theme.dropletCore : theme.dropletGlow;
            }
          }
        }
      } else if (phase >= 0.35 && phase < 0.65) {
        // Stage 2: Free fall under gravity
        final fallProgress = (phase - 0.35) / 0.30;
        final fallY = (tipY + (targetY - tipY) * (fallProgress * fallProgress)).round();

        // Render teardrop bead (2 vertical pixels with streak)
        for (int dy = -1; dy <= 0; dy++) {
          final py = fallY + dy;
          if (py >= 0 && py < height && sx >= 0 && sx < width) {
            final pIdx = py * width + sx;
            if (!preserveAlpha || (pixels[pIdx] >>> 24) != 0) {
              out[pIdx] = (dy == 0) ? theme.dropletCore : theme.dropletGlow;
            }
          }
        }
      } else {
        // Stage 3: Impact splash bouncing particles
        final splashProgress = (phase - 0.65) / 0.35;

        for (int p = 0; p < splashImpactParticles; p++) {
          final seed = p * 53 + sp.seed;
          final angle = (((seed % 80) - 40) * math.pi / 180.0) - (math.pi / 2.0); // Upward spray
          final speed = 2.5 + ((seed % 30) / 10.0);

          final vx = math.cos(angle) * speed;
          final vy0 = math.sin(angle) * speed;

          final px = (sx + vx * splashProgress * 6.0).round();
          final py = (targetY + vy0 * splashProgress * 5.0 + 0.5 * 9.8 * splashProgress * splashProgress * 3.0).round();

          if (px >= 0 && px < width && py >= 0 && py < height) {
            final pIdx = py * width + px;
            if (!preserveAlpha || (pixels[pIdx] >>> 24) != 0) {
              final alpha = ((1.0 - splashProgress) * 255).toInt().clamp(0, 255);
              out[pIdx] = _alphaBlend(out[pIdx], theme.dropletCore, alpha);
            }
          }
        }
      }
    }

    return out;
  }

  // -----------------------------
  // Speleothem Generator
  // -----------------------------

  List<_SpeleothemSpec> _generateSpeleothems(
    int count,
    int width,
    int height,
    int ceilingY,
    int floorY,
  ) {
    final list = <_SpeleothemSpec>[];
    final spacing = width / (count + 1);

    for (int i = 0; i < count; i++) {
      final seed = i * 67 + 29;
      final x = ((i + 1) * spacing + ((seed % 7) - 3)).round().clamp(2, width - 3);

      final stalactiteTipY = (ceilingY + ((seed % 100) / 100.0) * (height * 0.18)).round();
      final baseHalfW = 1 + (seed % 3);
      final stalagmiteH = (2 + (seed % ((height * 0.08).toInt() + 1))).round();
      final phaseOffset = (seed % 100) / 100.0;

      list.add(
        _SpeleothemSpec(
          x: x,
          stalactiteTipY: stalactiteTipY,
          baseHalfWidth: baseHalfW,
          stalagmiteHeight: stalagmiteH,
          phaseOffset: phaseOffset,
          seed: seed,
        ),
      );
    }

    return list;
  }

  // -----------------------------
  // Theme Color Grading
  // -----------------------------

  _CaveTheme _getCaveTheme(String key) {
    switch (key) {
      case 'bioluminescentCyan':
        return const _CaveTheme(
          rockDark: 0xFF080F16, // Abyssal grotto slate
          rockMedium: 0xFF10212E, // Moist subterranean stone
          rockLight: 0xFF00B0FF, // Bioluminescent algae edge
          voidAir: 0xFF04090E, // Dark cave void
          puddleWater: 0xFF002233, // Glowing cyan pool
          dropletCore: 0xFFE0FFFF, // Incandescent cyan water bead
          dropletGlow: 0xFF00E5FF, // Phosphor cyan water droplet
          rippleHighlight: 0xFF18FFFF, // Electric cyan ripple crest
        );
      case 'crystalGrotto':
        return const _CaveTheme(
          rockDark: 0xFF160B1E, // Amethyst matrix
          rockMedium: 0xFF2B1838, // Purple quartz strata
          rockLight: 0xFFCE93D8, // Specular crystal facet
          voidAir: 0xFF0E0714, // Crystal cavern shadow
          puddleWater: 0xFF241030, // Mineral violet puddle
          dropletCore: 0xFFFFF0FF, // Diamond-clear droplet core
          dropletGlow: 0xFFBA68C8, // Violet refraction bead
          rippleHighlight: 0xFFE1BEE7, // Crystalline ripple shimmer
        );
      case 'dungeonCrypt':
        return const _CaveTheme(
          rockDark: 0xFF141614, // Damp dungeon slate
          rockMedium: 0xFF222822, // Weathered crypt cobblestone
          rockLight: 0xFF4E6B4E, // Wet mossy stone glint
          voidAir: 0xFF0C0E0C, // Damp crypt air
          puddleWater: 0xFF161F16, // Stagnant mineral cistern pool
          dropletCore: 0xFFE8F5E9, // Pale cold water drop
          dropletGlow: 0xFF81C784, // Lichen water bead
          rippleHighlight: 0xFFB2DFDB, // Pale green ripple ring
        );
      case 'limestoneEcho':
      default:
        return const _CaveTheme(
          rockDark: 0xFF1E2228, // Dark limestone cave
          rockMedium: 0xFF353C45, // Calcified speleothem wall
          rockLight: 0xFF8C9BAE, // Wet limestone ridge highlight
          voidAir: 0xFF121519, // Deep cave atmosphere
          puddleWater: 0xFF1F2933, // Clear mineral puddle
          dropletCore: 0xFFFFFFFF, // Pure white specular bead
          dropletGlow: 0xFF78909C, // Translucent mineral water drop
          rippleHighlight: 0xFFB0BEC5, // Acoustic silver ripple crest
        );
    }
  }

  // -----------------------------
  // Procedural Noise & Blending
  // -----------------------------

  double _noise2D(double x, double y, int seed) {
    final xi = x.floor();
    final yi = y.floor();
    final xf = x - xi;
    final yf = y - yi;

    final u = xf * xf * (3.0 - 2.0 * xf);
    final v = yf * yf * (3.0 - 2.0 * yf);

    final g00 = _hash2D(xi, yi, seed);
    final g10 = _hash2D(xi + 1, yi, seed);
    final g01 = _hash2D(xi, yi + 1, seed);
    final g11 = _hash2D(xi + 1, yi + 1, seed);

    final x1 = g00 + (g10 - g00) * u;
    final x2 = g01 + (g11 - g01) * u;
    return x1 + (x2 - x1) * v;
  }

  double _hash2D(int x, int y, int seed) {
    int h = seed ^ (x * 374761393) ^ (y * 668265263);
    h = (h ^ (h >> 13)) * 1274126177;
    return ((h & 0x7FFFFFFF) / 1073741824.0) - 1.0;
  }

  int _additiveBlend(int base, int light, int alpha) {
    final a = alpha.clamp(0, 255) / 255.0;

    final bA = (base >>> 24) & 0xFF;
    final bR = (base >>> 16) & 0xFF;
    final bG = (base >>> 8) & 0xFF;
    final bB = base & 0xFF;

    final lR = (light >>> 16) & 0xFF;
    final lG = (light >>> 8) & 0xFF;
    final lB = light & 0xFF;

    final r = math.min(255, bR + (lR * a).toInt());
    final g = math.min(255, bG + (lG * a).toInt());
    final b = math.min(255, bB + (lB * a).toInt());

    final finalAlpha = math.max(bA, (alpha * 0.9).toInt().clamp(0, 255));
    return (finalAlpha << 24) | (r << 16) | (g << 8) | b;
  }

  int _multiplyColor(int color, double factor) {
    final a = (color >>> 24) & 0xFF;
    final r = (((color >>> 16) & 0xFF) * factor).toInt().clamp(0, 255);
    final g = (((color >>> 8) & 0xFF) * factor).toInt().clamp(0, 255);
    final b = ((color & 0xFF) * factor).toInt().clamp(0, 255);
    return (a << 24) | (r << 16) | (g << 8) | b;
  }

  int _alphaBlend(int base, int overlay, int alpha) {
    final a = alpha.clamp(0, 255);
    if (a == 0) return base;
    if (a == 255) return overlay;

    final inv = 255 - a;

    final bA = (base >>> 24) & 0xFF;
    final bR = (base >>> 16) & 0xFF;
    final bG = (base >>> 8) & 0xFF;
    final bB = base & 0xFF;

    final oR = (overlay >>> 16) & 0xFF;
    final oG = (overlay >>> 8) & 0xFF;
    final oB = overlay & 0xFF;

    final r = ((bR * inv) + (oR * a)) ~/ 255;
    final g = ((bG * inv) + (oG * a)) ~/ 255;
    final b = ((bB * inv) + (oB * a)) ~/ 255;

    return (bA << 24) | (r << 16) | (g << 8) | b;
  }
}

class _SpeleothemSpec {
  final int x;
  final int stalactiteTipY;
  final int baseHalfWidth;
  final int stalagmiteHeight;
  final double phaseOffset;
  final int seed;

  const _SpeleothemSpec({
    required this.x,
    required this.stalactiteTipY,
    required this.baseHalfWidth,
    required this.stalagmiteHeight,
    required this.phaseOffset,
    required this.seed,
  });
}

class _CaveTheme {
  final int rockDark;
  final int rockMedium;
  final int rockLight;
  final int voidAir;
  final int puddleWater;
  final int dropletCore;
  final int dropletGlow;
  final int rippleHighlight;

  const _CaveTheme({
    required this.rockDark,
    required this.rockMedium,
    required this.rockLight,
    required this.voidAir,
    required this.puddleWater,
    required this.dropletCore,
    required this.dropletGlow,
    required this.rippleHighlight,
  });
}
