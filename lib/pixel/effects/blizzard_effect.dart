part of 'effects.dart';

/// Procedural pixel blizzard and snowfall effect with multi-depth particles,
/// dynamic wind drift, swirling turbulence, atmospheric haze, and surface frosting.
class BlizzardEffect extends Effect implements UIFieldProvider {
  BlizzardEffect([Map<String, dynamic>? parameters])
      : super(
          EffectType.blizzard,
          parameters ??
              const {
                'intensity': 0.6,
                'windAngle': 25.0,
                'swirlTurbulence': 0.5,
                'blizzardHaze': 0.3,
                'frostSurfaces': true,
                'time': 0.0,
                'preserveAlpha': true,
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() => {
        'intensity': 0.6,
        'windAngle': 25.0,
        'swirlTurbulence': 0.5,
        'blizzardHaze': 0.3,
        'frostSurfaces': true,
        'time': 0.0,
        'preserveAlpha': true,
      };

  @override
  Map<String, dynamic> getMetadata() => {
        'intensity': {
          'label': 'Snowfall Intensity',
          'description': 'Density of falling snow particles and blizzard volume.',
          'type': 'slider',
          'min': 0.1,
          'max': 1.0,
          'divisions': 90,
        },
        'windAngle': {
          'label': 'Wind Angle',
          'description': 'Direction and tilt of the blizzard wind gust.',
          'type': 'slider',
          'min': -45.0,
          'max': 45.0,
          'divisions': 90,
        },
        'swirlTurbulence': {
          'label': 'Swirling Turbulence',
          'description': 'Sinusoidal flutter and chaotic lateral drift.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 20,
        },
        'blizzardHaze': {
          'label': 'Whiteout Haze',
          'description': 'Atmospheric drifting mist and fog density.',
          'type': 'slider',
          'min': 0.0,
          'max': 0.8,
          'divisions': 16,
        },
        'frostSurfaces': {
          'label': 'Frost Top Surfaces',
          'description': 'Accumulate delicate frosty snow rims on upward-facing sprite edges.',
          'type': 'bool',
        },
        'time': {
          'label': 'Animation Time',
          'description': 'Timeline progress parameter for looping snowfall cycles.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 100,
        },
        'preserveAlpha': {
          'label': 'Preserve Transparency',
          'description': 'Float snow particles cleanly over transparent backgrounds.',
          'type': 'bool',
        },
      };

  @override
  List<UIField> getFields() => [
        SliderField(
          key: 'intensity',
          label: 'Snowfall Density',
          description: 'Volume of snow particles actively falling.',
          min: 0.1,
          max: 1.0,
          divisions: 90,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        SliderField(
          key: 'windAngle',
          label: 'Wind Angle',
          description: 'Wind direction angle (-45° leftward gust to +45° rightward gale).',
          min: -45.0,
          max: 45.0,
          divisions: 90,
          formatLabel: (v) => '${v.round()}°',
        ),
        SliderField(
          key: 'swirlTurbulence',
          label: 'Swirl Turbulence',
          description: 'Chaotic lateral flutter and wind turbulence amplitude.',
          min: 0.0,
          max: 1.0,
          divisions: 20,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        SliderField(
          key: 'blizzardHaze',
          label: 'Whiteout Fog Haze',
          description: 'Atmospheric blizzard fog and cold mist density.',
          min: 0.0,
          max: 0.8,
          divisions: 16,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        const BoolField(
          key: 'frostSurfaces',
          label: 'Frost Upward Surfaces',
          description: 'Deposit subtle white snow frost on upper sprite edges.',
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
          description: 'Allows snowflakes to float cleanly over transparent backgrounds.',
        ),
      ];

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    if (width <= 0 || height <= 0 || pixels.isEmpty) return pixels;

    final intensity = ((parameters['intensity'] as num?)?.toDouble() ?? 0.6).clamp(0.1, 1.0);
    final windAngle = ((parameters['windAngle'] as num?)?.toDouble() ?? 25.0).clamp(-45.0, 45.0);
    final swirlTurbulence = ((parameters['swirlTurbulence'] as num?)?.toDouble() ?? 0.5).clamp(0.0, 1.0);
    final blizzardHaze = ((parameters['blizzardHaze'] as num?)?.toDouble() ?? 0.3).clamp(0.0, 0.8);
    final frostSurfaces = parameters['frostSurfaces'] as bool? ?? true;
    final time = ((parameters['time'] as num?)?.toDouble() ?? 0.0).clamp(0.0, 1.0);
    final preserveAlpha = parameters['preserveAlpha'] as bool? ?? true;

    final result = Uint32List(width * height);

    // 1. Initialize Base Background / Copy
    if (preserveAlpha) {
      result.setAll(0, pixels);
    } else {
      // Opaque winter night sky
      const darkNight = 0xFF081220;
      const bgR = (darkNight >> 16) & 0xFF;
      const bgG = (darkNight >> 8) & 0xFF;
      const bgB = darkNight & 0xFF;
      result.fillRange(0, result.length, darkNight);
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

    // 2. Blizzard Atmospheric Haze / Whiteout Mist
    if (blizzardHaze > 0.02) {
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final idx = y * width + x;
          final srcA = (result[idx] >> 24) & 0xFF;
          if (srcA == 0 && preserveAlpha) continue;

          final mistVal = math.sin((y * 0.15) - (time * 6.28 * 2.0) + (x * 0.08)) * 0.5 + 0.5;
          final hazeA = (mistVal * blizzardHaze * 80).round().clamp(0, 255);
          if (hazeA <= 0) continue;

          final ex = result[idx];
          final exA = (ex >> 24) & 0xFF;
          final exR = (ex >> 16) & 0xFF;
          final exG = (ex >> 8) & 0xFF;
          final exB = ex & 0xFF;

          final na = hazeA / 255.0;
          // Cool icy mist tint (230, 245, 255)
          final outR = (exR * (1.0 - na) + 230 * na).round().clamp(0, 255);
          final outG = (exG * (1.0 - na) + 245 * na).round().clamp(0, 255);
          final outB = (exB * (1.0 - na) + 255 * na).round().clamp(0, 255);
          final outA = math.max(exA, hazeA);

          result[idx] = (outA << 24) | (outR << 16) | (outG << 8) | outB;
        }
      }
    }

    // 3. Surface Frosting on Top Edges of Sprite
    if (frostSurfaces) {
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final idx = y * width + x;
          final p = pixels[idx];
          final a = (p >> 24) & 0xFF;
          if (a > 50) {
            // Check if top pixel is transparent or outside frame
            final isTopSurface = (y == 0) || (((pixels[(y - 1) * width + x] >> 24) & 0xFF) < 30);
            if (isTopSurface) {
              final ex = result[idx];
              final exR = (ex >> 16) & 0xFF;
              final exG = (ex >> 8) & 0xFF;
              final exB = ex & 0xFF;
              final exA = (ex >> 24) & 0xFF;

              // Frost overlay: gentle icy white accumulation
              const frostAlpha = 180;
              const na = frostAlpha / 255.0;
              final outR = (exR * (1.0 - na) + 240 * na).round().clamp(0, 255);
              final outG = (exG * (1.0 - na) + 248 * na).round().clamp(0, 255);
              final outB = (exB * (1.0 - na) + 255 * na).round().clamp(0, 255);

              result[idx] = (exA << 24) | (outR << 16) | (outG << 8) | outB;
            }
          }
        }
      }
    }

    // 4. Multi-Tier Snow Particles
    final flakeCount = (width * height * 0.05 * intensity).round().clamp(12, 600);
    final rand = math.Random(2026);

    final rad = windAngle * math.pi / 180.0;
    final windSlope = math.tan(rad);

    void plotSnow(int px, int py, int r, int g, int b, int a) {
      if (px < 0 || px >= width || py < 0 || py >= height) return;
      final idx = py * width + px;

      final existing = result[idx];
      final exA = (existing >> 24) & 0xFF;
      final exR = (existing >> 16) & 0xFF;
      final exG = (existing >> 8) & 0xFF;
      final exB = existing & 0xFF;

      final na = a / 255.0;
      final outR = math.min(255, (exR * (1.0 - na) + r * na).round());
      final outG = math.min(255, (exG * (1.0 - na) + g * na).round());
      final outB = math.min(255, (exB * (1.0 - na) + b * na).round());
      final outA = math.max(exA, a);

      result[idx] = (outA << 24) | (outR << 16) | (outG << 8) | outB;
    }

    for (int i = 0; i < flakeCount; i++) {
      final seedX = rand.nextDouble() * width;
      final seedY = rand.nextDouble() * height;
      final depth = rand.nextDouble(); // 0 = distant background, 1 = close foreground
      final speedFactor = 0.5 + depth * 1.5;

      // Vertical fall position with seamless wrap modulo
      final fallY = (seedY + time * height * speedFactor) % height;

      // Horizontal drift with wind angle + turbulence sway
      final driftX = (fallY - seedY) * windSlope;
      final swirl = math.sin((fallY * 0.1) + (time * 6.28 * 2.0) + (i * 0.5)) * swirlTurbulence * 4.0;
      final finalX = ((seedX + driftX + swirl) % width + width) % width;

      final px = finalX.round();
      final py = fallY.round();

      if (depth < 0.4) {
        // Distant flake: 1x1, translucent
        final a = (110 + depth * 100).round().clamp(0, 255);
        plotSnow(px, py, 215, 230, 255, a);
      } else if (depth < 0.85) {
        // Midground flake: 1x1, solid crisp white
        plotSnow(px, py, 255, 255, 255, 255);
      } else {
        // Foreground snowflake: 3x3 diamond cross pattern (+)
        plotSnow(px, py, 255, 255, 255, 255);
        plotSnow(px + 1, py, 230, 245, 255, 180);
        plotSnow(px - 1, py, 230, 245, 255, 180);
        plotSnow(px, py + 1, 230, 245, 255, 180);
        plotSnow(px, py - 1, 230, 245, 255, 180);
      }
    }

    return result;
  }
}
