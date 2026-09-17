part of 'effects.dart';

/// Procedural starfield with twinkling multi-tiered stars, optional cosmic
/// nebula clouds, shooting stars, and timeline animation synchronization.
class StarfieldEffect extends Effect implements UIFieldProvider {
  StarfieldEffect([Map<String, dynamic>? parameters])
      : super(
          EffectType.starfield,
          parameters ??
              const {
                'starDensity': 0.5,
                'twinkleSpeed': 1.5,
                'nebulaIntensity': 0.4,
                'nebulaTheme': 'violet',
                'shootingStars': true,
                'time': 0.0,
                'preserveAlpha': true,
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() => {
        'starDensity': 0.5,
        'twinkleSpeed': 1.5,
        'nebulaIntensity': 0.4,
        'nebulaTheme': 'violet',
        'shootingStars': true,
        'time': 0.0,
        'preserveAlpha': true,
      };

  @override
  Map<String, dynamic> getMetadata() => {
        'starDensity': {
          'label': 'Star Density',
          'description': 'Number of stars distributed across the sky.',
          'type': 'slider',
          'min': 0.1,
          'max': 1.0,
          'divisions': 90,
        },
        'twinkleSpeed': {
          'label': 'Twinkle Frequency',
          'description': 'Speed of star luminosity oscillation.',
          'type': 'slider',
          'min': 0.5,
          'max': 3.0,
          'divisions': 50,
        },
        'nebulaIntensity': {
          'label': 'Cosmic Nebula',
          'description': 'Richness of procedural cosmic dust clouds.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 100,
        },
        'nebulaTheme': {
          'label': 'Nebula Theme',
          'description': 'Color palette for the cosmic gas clouds.',
          'type': 'select',
          'options': ['violet', 'cyanBlue', 'synthwave', 'golden'],
        },
        'shootingStars': {
          'label': 'Shooting Stars',
          'description': 'Occasional luminous meteor streaks crossing the sky.',
          'type': 'bool',
        },
        'time': {
          'label': 'Timeline Time',
          'description': 'Timeline progress parameter for animated star twinkling.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 100,
        },
        'preserveAlpha': {
          'label': 'Preserve Transparency',
          'description': 'Float stars cleanly over transparent canvas without filling void.',
          'type': 'bool',
        },
      };

  @override
  List<UIField> getFields() => [
        SliderField(
          key: 'starDensity',
          label: 'Star Density',
          description: 'Amount of stars scattered across the space background.',
          min: 0.1,
          max: 1.0,
          divisions: 90,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        SliderField(
          key: 'twinkleSpeed',
          label: 'Twinkle Frequency',
          description: 'Pulsing pulsation speed of the star luminosity cycles.',
          min: 0.5,
          max: 3.0,
          divisions: 50,
          formatLabel: (v) => '${v.toStringAsFixed(1)}x',
        ),
        SliderField(
          key: 'nebulaIntensity',
          label: 'Nebula Intensity',
          description: 'Density and visibility of cosmic interstellar gas clouds.',
          min: 0.0,
          max: 1.0,
          divisions: 100,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        const SelectField(
          key: 'nebulaTheme',
          label: 'Cosmic Palette',
          description: 'Color theme of the cosmic nebula clouds.',
          options: {
            'violet': 'Cosmic Violet (Indigo/Magenta)',
            'cyanBlue': 'Deep Cosmos (Navy/Cyan)',
            'synthwave': 'Synthwave (Pink/Teal)',
            'golden': 'Solar Dust (Amber/Gold)',
          },
        ),
        const BoolField(
          key: 'shootingStars',
          label: 'Meteor Streaks',
          description: 'Include high-velocity diagonal shooting star streaks.',
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
          description: 'When enabled, stars float over transparent pixels without filling space void.',
        ),
      ];

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    if (width <= 0 || height <= 0 || pixels.isEmpty) return pixels;

    final starDensity = ((parameters['starDensity'] as num?)?.toDouble() ?? 0.5).clamp(0.1, 1.0);
    final twinkleSpeed = ((parameters['twinkleSpeed'] as num?)?.toDouble() ?? 1.5).clamp(0.5, 3.0);
    final nebulaIntensity = ((parameters['nebulaIntensity'] as num?)?.toDouble() ?? 0.4).clamp(0.0, 1.0);
    final nebulaTheme = (parameters['nebulaTheme'] as String?) ?? 'violet';
    final shootingStars = parameters['shootingStars'] as bool? ?? true;
    final time = ((parameters['time'] as num?)?.toDouble() ?? 0.0).clamp(0.0, 1.0);
    final preserveAlpha = parameters['preserveAlpha'] as bool? ?? true;

    final result = Uint32List(width * height);

    // 1. Render Background & Cosmic Nebula
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final idx = y * width + x;
        final srcPixel = pixels[idx];
        final srcA = (srcPixel >> 24) & 0xFF;

        if (preserveAlpha && srcA > 0) {
          // Keep foreground sprite pixel intact
          result[idx] = srcPixel;
          continue;
        }

        if (preserveAlpha && srcA == 0 && nebulaIntensity <= 0.01) {
          result[idx] = 0x00000000;
          continue;
        }

        // Procedural smooth nebula noise
        final nx = x / math.max(1, width);
        final ny = y / math.max(1, height);
        final nVal1 = math.sin(nx * 6.28 * 1.5 + ny * 3.14 * 2.0 + time * 0.5) * 0.5 + 0.5;
        final nVal2 = math.cos(nx * 3.14 * 3.0 - ny * 6.28 * 1.2 - time * 0.3) * 0.5 + 0.5;
        final nebulaVal = ((nVal1 * 0.6 + nVal2 * 0.4) * nebulaIntensity).clamp(0.0, 1.0);

        int bgR = 0, bgG = 0, bgB = 0;
        switch (nebulaTheme) {
          case 'cyanBlue':
            bgR = (10 * (1.0 - nebulaVal) + 20 * nebulaVal).round();
            bgG = (15 * (1.0 - nebulaVal) + 140 * nebulaVal).round();
            bgB = (40 * (1.0 - nebulaVal) + 245 * nebulaVal).round();
            break;
          case 'synthwave':
            bgR = (15 * (1.0 - nebulaVal) + 220 * nebulaVal).round();
            bgG = (5 * (1.0 - nebulaVal) + 40 * nebulaVal).round();
            bgB = (30 * (1.0 - nebulaVal) + 200 * nebulaVal).round();
            break;
          case 'golden':
            bgR = (20 * (1.0 - nebulaVal) + 240 * nebulaVal).round();
            bgG = (12 * (1.0 - nebulaVal) + 170 * nebulaVal).round();
            bgB = (5 * (1.0 - nebulaVal) + 40 * nebulaVal).round();
            break;
          case 'violet':
          default:
            bgR = (15 * (1.0 - nebulaVal) + 150 * nebulaVal).round();
            bgG = (5 * (1.0 - nebulaVal) + 30 * nebulaVal).round();
            bgB = (35 * (1.0 - nebulaVal) + 210 * nebulaVal).round();
            break;
        }

        final bgAlpha = preserveAlpha ? (nebulaVal * 200).round().clamp(0, 255) : 255;
        result[idx] = (bgAlpha << 24) | (bgR.clamp(0, 255) << 16) | (bgG.clamp(0, 255) << 8) | bgB.clamp(0, 255);
      }
    }

    // 2. Deterministic Starfield Generation
    final starCount = (width * height * 0.04 * starDensity).round().clamp(4, 500);
    final rand = math.Random(1337);

    for (int i = 0; i < starCount; i++) {
      final sx = rand.nextInt(width);
      final sy = rand.nextInt(height);
      final starType = rand.nextInt(10); // 0-6: small, 7-8: medium, 9: cross sparkle
      final phase = rand.nextDouble() * 2.0 * math.pi;
      final freq = 0.8 + rand.nextDouble() * 1.5;

      // Twinkle calculation
      final osc = math.sin(time * 2.0 * math.pi * twinkleSpeed * freq + phase) * 0.5 + 0.5;
      final brightness = (120 + osc * 135).round().clamp(0, 255);

      // Star color variation (pure starlight, slight blue tint, or warm yellow)
      final colorTint = rand.nextInt(4);
      int sR = brightness, sG = brightness, sB = brightness;
      if (colorTint == 1) {
        // Cyan-ish starlight
        sR = (brightness * 0.85).round();
      } else if (colorTint == 2) {
        // Warm gold starlight
        sB = (brightness * 0.8).round();
      }

      void drawStarPixel(int px, int py, int alpha, int r, int g, int b) {
        if (px < 0 || px >= width || py < 0 || py >= height) return;
        final targetIdx = py * width + px;

        if (preserveAlpha && (pixels[targetIdx] >> 24) & 0xFF > 128) {
          // Do not occlude dense foreground sprite pixels
          return;
        }

        final existing = result[targetIdx];
        final exA = (existing >> 24) & 0xFF;
        final exR = (existing >> 16) & 0xFF;
        final exG = (existing >> 8) & 0xFF;
        final exB = existing & 0xFF;

        // Screen / Additive blending
        final outR = math.min(255, exR + (r * alpha ~/ 255));
        final outG = math.min(255, exG + (g * alpha ~/ 255));
        final outB = math.min(255, exB + (b * alpha ~/ 255));
        final outA = math.max(exA, alpha);

        result[targetIdx] = (outA << 24) | (outR << 16) | (outG << 8) | outB;
      }

      if (starType < 7) {
        // 1x1 faint or normal star
        drawStarPixel(sx, sy, brightness, sR, sG, sB);
      } else if (starType < 9) {
        // 1x1 bright starlight with slight halo
        drawStarPixel(sx, sy, 255, 255, 255, 255);
        final haloAlpha = (brightness * 0.35).round();
        drawStarPixel(sx + 1, sy, haloAlpha, sR, sG, sB);
        drawStarPixel(sx - 1, sy, haloAlpha, sR, sG, sB);
        drawStarPixel(sx, sy + 1, haloAlpha, sR, sG, sB);
        drawStarPixel(sx, sy - 1, haloAlpha, sR, sG, sB);
      } else {
        // 3x3 4-point cross flare
        final crossAlpha = (brightness * 0.6).round();
        drawStarPixel(sx, sy, 255, 255, 255, 255);
        drawStarPixel(sx + 1, sy, crossAlpha, 255, 255, 255);
        drawStarPixel(sx - 1, sy, crossAlpha, 255, 255, 255);
        drawStarPixel(sx, sy + 1, crossAlpha, 255, 255, 255);
        drawStarPixel(sx, sy - 1, crossAlpha, 255, 255, 255);
      }
    }

    // 3. Shooting Star / Meteor Streak
    if (shootingStars) {
      // Periodic meteor crossing diagonally
      final meteorPhase = (time * 1.5) % 1.0;
      if (meteorPhase < 0.6) {
        final tMeteor = meteorPhase / 0.6;
        final startX = (width * 0.8).round();
        final startY = (height * 0.1).round();
        final endX = (width * 0.1).round();
        final endY = (height * 0.75).round();

        final headX = (startX + (endX - startX) * tMeteor).round();
        final headY = (startY + (endY - startY) * tMeteor).round();
        final dirX = (endX - startX).toDouble();
        final dirY = (endY - startY).toDouble();
        final len = math.sqrt(dirX * dirX + dirY * dirY);
        final normX = len > 0 ? dirX / len : 0.0;
        final normY = len > 0 ? dirY / len : 0.0;

        const tailSteps = 6;
        for (int step = 0; step < tailSteps; step++) {
          final px = (headX - normX * step * 1.2).round();
          final py = (headY - normY * step * 1.2).round();
          if (px < 0 || px >= width || py < 0 || py >= height) continue;

          final targetIdx = py * width + px;
          if (preserveAlpha && (pixels[targetIdx] >> 24) & 0xFF > 128) continue;

          final fade = 1.0 - (step / tailSteps);
          final a = (fade * 255).round().clamp(0, 255);
          final existing = result[targetIdx];
          final exA = (existing >> 24) & 0xFF;
          final exR = (existing >> 16) & 0xFF;
          final exG = (existing >> 8) & 0xFF;
          final exB = existing & 0xFF;

          final outR = math.min(255, exR + a);
          final outG = math.min(255, exG + (a * 0.95).round());
          final outB = math.min(255, exB + a);
          final outA = math.max(exA, a);

          result[targetIdx] = (outA << 24) | (outR << 16) | (outG << 8) | outB;
        }
      }
    }

    return result;
  }
}
