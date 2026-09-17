part of 'effects.dart';

/// Procedural radiant ascension rays and god ray light pillars with
/// volumetric light shafts, additive luminance aura, and rising starlight dust motes.
class RadiantRaysEffect extends Effect implements UIFieldProvider {
  RadiantRaysEffect([Map<String, dynamic>? parameters])
      : super(
          EffectType.radiantRays,
          parameters ??
              const {
                'beamCount': 4,
                'rayIntensity': 0.6,
                'dustDensity': 0.5,
                'ascendSpeed': 1.2,
                'auraColor': 0xFFFFD700,
                'time': 0.0,
                'preserveAlpha': true,
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() => {
        'beamCount': 4,
        'rayIntensity': 0.6,
        'dustDensity': 0.5,
        'ascendSpeed': 1.2,
        'auraColor': 0xFFFFD700,
        'time': 0.0,
        'preserveAlpha': true,
      };

  @override
  Map<String, dynamic> getMetadata() => {
        'beamCount': {
          'label': 'Ray Beam Count',
          'description': 'Number of distinct volumetric light shafts.',
          'type': 'slider',
          'min': 2,
          'max': 8,
          'divisions': 6,
        },
        'rayIntensity': {
          'label': 'Light Shaft Intensity',
          'description': 'Brightness and presence of the descending light beams.',
          'type': 'slider',
          'min': 0.1,
          'max': 1.0,
          'divisions': 90,
        },
        'dustDensity': {
          'label': 'Ascending Dust Motes',
          'description': 'Density of rising starlight particles and glowing motes.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 20,
        },
        'ascendSpeed': {
          'label': 'Ascension Speed',
          'description': 'Upward velocity of floating dust motes and ray shimmer.',
          'type': 'slider',
          'min': 0.5,
          'max': 2.5,
          'divisions': 40,
        },
        'auraColor': {
          'label': 'Radiant Ray Color',
          'description': 'Color of the divine light pillars and starlight motes.',
          'type': 'color',
        },
        'time': {
          'label': 'Animation Time',
          'description': 'Timeline progress parameter for vertical ascension cycle.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 100,
        },
        'preserveAlpha': {
          'label': 'Preserve Transparency',
          'description': 'Allows god rays to cast cleanly over transparent canvas.',
          'type': 'bool',
        },
      };

  @override
  List<UIField> getFields() => [
        SliderField(
          key: 'beamCount',
          label: 'Beam Count',
          description: 'Number of vertical light pillars traversing the scene.',
          min: 2,
          max: 8,
          divisions: 6,
          formatLabel: (v) => '${v.round()} beams',
        ),
        SliderField(
          key: 'rayIntensity',
          label: 'Ray Intensity',
          description: 'Luminance and opacity of the volumetric light beams.',
          min: 0.1,
          max: 1.0,
          divisions: 90,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        SliderField(
          key: 'dustDensity',
          label: 'Dust Motes Density',
          description: 'Amount of glowing starlight particles rising in the light.',
          min: 0.0,
          max: 1.0,
          divisions: 20,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        SliderField(
          key: 'ascendSpeed',
          label: 'Ascension Speed',
          description: 'Upward drift speed of floating dust motes.',
          min: 0.5,
          max: 2.5,
          divisions: 40,
          formatLabel: (v) => '${v.toStringAsFixed(1)}x',
        ),
        const ColorField(
          key: 'auraColor',
          label: 'Aura Tint Color',
          description: 'Color of the radiant rays and shimmering stardust.',
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
          description: 'When enabled, light rays float over transparent canvas.',
        ),
      ];

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    if (width <= 0 || height <= 0 || pixels.isEmpty) return pixels;

    final beamCount = ((parameters['beamCount'] as num?)?.toInt() ?? 4).clamp(2, 8);
    final rayIntensity = ((parameters['rayIntensity'] as num?)?.toDouble() ?? 0.6).clamp(0.1, 1.0);
    final dustDensity = ((parameters['dustDensity'] as num?)?.toDouble() ?? 0.5).clamp(0.0, 1.0);
    final ascendSpeed = ((parameters['ascendSpeed'] as num?)?.toDouble() ?? 1.2).clamp(0.5, 2.5);
    final auraColorInt = (parameters['auraColor'] as int?) ?? 0xFFFFD700;
    final time = ((parameters['time'] as num?)?.toDouble() ?? 0.0).clamp(0.0, 1.0);
    final preserveAlpha = parameters['preserveAlpha'] as bool? ?? true;

    final auraR = (auraColorInt >> 16) & 0xFF;
    final auraG = (auraColorInt >> 8) & 0xFF;
    final auraB = auraColorInt & 0xFF;

    final result = Uint32List(width * height);
    if (preserveAlpha) {
      result.setAll(0, pixels);
    } else {
      const darkCelestial = 0xFF0D0B1C;
      const bgR = (darkCelestial >> 16) & 0xFF;
      const bgG = (darkCelestial >> 8) & 0xFF;
      const bgB = darkCelestial & 0xFF;
      result.fillRange(0, result.length, darkCelestial);
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

    // 1. Volumetric God Rays (Light Columns)
    final beamCenters = List<double>.generate(beamCount, (i) {
      final base = (i + 0.5) * (width / beamCount);
      final drift = math.sin((time * 2.0 * math.pi) + (i * 1.5)) * (width / (beamCount * 3.5));
      return base + drift;
    });

    final beamWidth = math.max(1.5, width / (beamCount * 2.0));
    final twoSigmaSq = 2.0 * beamWidth * beamWidth;

    for (int y = 0; y < height; y++) {
      // Gentle vertical shimmering wave
      final verticalShimmer = math.sin((y * 0.12) - (time * 6.28 * ascendSpeed)) * 0.15 + 0.85;

      for (int x = 0; x < width; x++) {
        final idx = y * width + x;
        final origA = (pixels[idx] >> 24) & 0xFF;
        if (origA == 0 && preserveAlpha && rayIntensity < 0.15) continue;

        // Sum ray contributions
        double totalRay = 0.0;
        for (int b = 0; b < beamCount; b++) {
          final dx = (x - beamCenters[b]);
          final rayVal = math.exp(-(dx * dx) / twoSigmaSq);
          totalRay += rayVal;
        }

        final combinedIntensity = (totalRay * verticalShimmer * rayIntensity).clamp(0.0, 1.0);
        if (combinedIntensity <= 0.01) continue;

        final rayAlpha = (combinedIntensity * 180).round().clamp(0, 255);
        final existing = result[idx];
        final exA = (existing >> 24) & 0xFF;
        final exR = (existing >> 16) & 0xFF;
        final exG = (existing >> 8) & 0xFF;
        final exB = existing & 0xFF;

        final na = rayAlpha / 255.0;
        // Screen / Additive blend
        final outR = math.min(255, (exR + auraR * na).round());
        final outG = math.min(255, (exG + auraG * na).round());
        final outB = math.min(255, (exB + auraB * na).round());
        final outA = math.max(exA, rayAlpha);

        result[idx] = (outA << 24) | (outR << 16) | (outG << 8) | outB;
      }
    }

    // 2. Ascending Starlight / Dust Motes
    if (dustDensity > 0.02) {
      final moteCount = (width * height * 0.04 * dustDensity).round().clamp(6, 400);
      final rand = math.Random(777);

      void plotMote(int px, int py, int alpha, {bool isCore = true}) {
        if (px < 0 || px >= width || py < 0 || py >= height) return;
        final idx = py * width + px;

        final existing = result[idx];
        final exA = (existing >> 24) & 0xFF;
        final exR = (existing >> 16) & 0xFF;
        final exG = (existing >> 8) & 0xFF;
        final exB = existing & 0xFF;

        final r = isCore ? 255 : auraR;
        final g = isCore ? 255 : auraG;
        final b = isCore ? 255 : auraB;

        final na = alpha / 255.0;
        final outR = math.min(255, (exR + r * na).round());
        final outG = math.min(255, (exG + g * na).round());
        final outB = math.min(255, (exB + b * na).round());
        final outA = math.max(exA, alpha);

        result[idx] = (outA << 24) | (outR << 16) | (outG << 8) | outB;
      }

      for (int i = 0; i < moteCount; i++) {
        final seedX = rand.nextDouble() * width;
        final seedY = rand.nextDouble() * height;
        final speedFactor = 0.6 + rand.nextDouble() * 1.0;
        final flutterFreq = 2.0 + rand.nextDouble() * 3.0;

        // Upward ascension with wrapping modulo
        final currentY = ((seedY - time * height * ascendSpeed * speedFactor) % height + height) % height;
        final sway = math.sin((currentY * 0.2) + (time * 6.28 * flutterFreq) + i) * 2.0;
        final currentX = ((seedX + sway) % width + width) % width;

        final px = currentX.round();
        final py = currentY.round();
        final twinkle = math.sin((time * 12.0) + (i * 0.8)) * 0.4 + 0.6;
        final moteAlpha = (twinkle * 240).round().clamp(0, 255);

        // Center dot
        plotMote(px, py, moteAlpha, isCore: true);

        // Subtle cross aura for larger particles
        if (i % 3 == 0) {
          final haloAlpha = (moteAlpha * 0.45).round();
          plotMote(px + 1, py, haloAlpha, isCore: false);
          plotMote(px - 1, py, haloAlpha, isCore: false);
          plotMote(px, py + 1, haloAlpha, isCore: false);
          plotMote(px, py - 1, haloAlpha, isCore: false);
        }
      }
    }

    return result;
  }
}
