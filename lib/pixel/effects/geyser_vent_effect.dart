part of 'effects.dart';

/// An effect that procedurally renders a geothermal geyser steam vent and boiling
/// mud pool with rhythmic pressure tremors, violent pressurized boiling eruptions,
/// billowing vapor clouds, boiling bubble bursts in sulfur mud, and terraced mineral rings.
class GeyserVentEffect extends Effect {
  GeyserVentEffect([Map<String, dynamic>? params])
      : super(
          EffectType.geyserVent,
          params ??
              {
                'eruptionInterval': 5.0,
                'plumeHeight': 0.75,
                'bubbleBoilRate': 2.0,
                'steamDispersion': 0.6,
                'mineralPalette': 'sulfurYellow',
                'time': 0.0,
                'preserveAlpha': false,
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() => {
        'eruptionInterval': 5.0,
        'plumeHeight': 0.75,
        'bubbleBoilRate': 2.0,
        'steamDispersion': 0.6,
        'mineralPalette': 'sulfurYellow',
        'time': 0.0,
        'preserveAlpha': false,
      };

  @override
  Map<String, dynamic> getMetadata() => {
        'eruptionInterval': {
          'label': 'Eruption Cycle',
          'description': 'Period length in seconds of pressure build-up and explosive release.',
          'type': 'slider',
          'min': 2.0,
          'max': 12.0,
          'step': 0.5,
        },
        'plumeHeight': {
          'label': 'Plume Height',
          'description': 'Vertical elevation reach of the superheated geyser jet.',
          'type': 'slider',
          'min': 0.3,
          'max': 1.0,
          'step': 0.05,
        },
        'bubbleBoilRate': {
          'label': 'Mud Boil Speed',
          'description': 'Frequency of boiling bubbles and bursts across the mud basin.',
          'type': 'slider',
          'min': 0.5,
          'max': 4.0,
          'step': 0.1,
        },
        'steamDispersion': {
          'label': 'Steam Dispersion',
          'description': 'Lateral expansion and atmospheric turbulence of rising vapor billows.',
          'type': 'slider',
          'min': 0.2,
          'max': 1.0,
          'step': 0.05,
        },
        'mineralPalette': {
          'label': 'Mineral Palette',
          'description': 'Geothermal sinter deposit and mud pot coloration.',
          'type': 'select',
          'options': {
            'sulfurYellow': 'Sulfur Sinter Basin',
            'ironRed': 'Iron Hematite Mud Pot',
            'silicaWhite': 'Silica White Spring',
            'abyssalBasalt': 'Abyssal Volcanic Basalt',
          },
        },
        'time': {
          'label': 'Animation Time',
          'description': 'Progress cycle (0.0 to 1.0) driving eruption phases and boils.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'step': 0.01,
        },
        'preserveAlpha': {
          'label': 'Preserve Alpha',
          'description': 'Restrict eruption, steam, and mud within sprite silhouette.',
          'type': 'bool',
        },
      };

  @override
  List<UIField> getFields() => [
        SliderField(
          key: 'eruptionInterval',
          label: 'Eruption Cycle',
          description: 'Period length in seconds of pressure build-up and explosive release.',
          min: 2.0,
          max: 12.0,
          divisions: 20,
          formatLabel: (v) => '${v.toStringAsFixed(1)}s',
        ),
        SliderField(
          key: 'plumeHeight',
          label: 'Plume Height',
          description: 'Vertical elevation reach of the superheated geyser jet.',
          min: 0.3,
          max: 1.0,
          divisions: 14,
          formatLabel: (v) => '${(v * 100).toInt()}%',
        ),
        SliderField(
          key: 'bubbleBoilRate',
          label: 'Mud Boil Speed',
          description: 'Frequency of boiling bubbles and bursts across the mud basin.',
          min: 0.5,
          max: 4.0,
          divisions: 35,
          formatLabel: (v) => '${v.toStringAsFixed(1)}x',
        ),
        SliderField(
          key: 'steamDispersion',
          label: 'Steam Dispersion',
          description: 'Lateral expansion and atmospheric turbulence of rising vapor billows.',
          min: 0.2,
          max: 1.0,
          divisions: 16,
          formatLabel: (v) => v.toStringAsFixed(2),
        ),
        const SelectField(
          key: 'mineralPalette',
          label: 'Mineral Palette',
          description: 'Geothermal sinter deposit and mud pot coloration.',
          options: {
            'sulfurYellow': 'Sulfur Sinter Basin',
            'ironRed': 'Iron Hematite Mud Pot',
            'silicaWhite': 'Silica White Spring',
            'abyssalBasalt': 'Abyssal Volcanic Basalt',
          },
        ),
        SliderField(
          key: 'time',
          label: 'Animation Time',
          description: 'Progress cycle (0.0 to 1.0) driving eruption phases and boils.',
          min: 0.0,
          max: 1.0,
          divisions: 100,
          formatLabel: (v) => v.toStringAsFixed(2),
        ),
        const BoolField(
          key: 'preserveAlpha',
          label: 'Preserve Alpha',
          description: 'Restrict eruption, steam, and mud within sprite silhouette.',
        ),
      ];

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    final out = Uint32List.fromList(pixels);

    final plumeHeight = ((parameters['plumeHeight'] as num?)?.toDouble() ?? 0.75).clamp(0.2, 1.0);
    final bubbleBoilRate = (parameters['bubbleBoilRate'] as num?)?.toDouble() ?? 2.0;
    final steamDispersion = ((parameters['steamDispersion'] as num?)?.toDouble() ?? 0.6).clamp(0.1, 1.2);
    final mineralPalette = (parameters['mineralPalette'] as String?) ?? 'sulfurYellow';
    final time = (parameters['time'] as num?)?.toDouble() ?? 0.0;
    final preserveAlpha = (parameters['preserveAlpha'] as bool?) ?? false;

    final palette = _getGeyserPalette(mineralPalette);

    // Vent center coordinates
    final ventX = width * 0.5;
    final ventY = height * 0.76;

    // Timeline phase calculations
    final cycle = time % 1.0;

    // Eruption envelope:
    // 0.00 .. 0.35: Pressure build-up / tremors / faint vent steam
    // 0.35 .. 0.45: Violent explosive jet surge
    // 0.45 .. 0.70: Sustained roaring superheated column
    // 0.70 .. 0.85: Jet collapse & subsidence
    // 0.85 .. 1.00: Heavy residual steam dispersion
    double eruptionIntensity = 0.0;
    if (cycle >= 0.35 && cycle < 0.45) {
      final t = (cycle - 0.35) / 0.10;
      eruptionIntensity = math.sin(t * (math.pi / 2.0));
    } else if (cycle >= 0.45 && cycle < 0.70) {
      final wobble = math.sin(cycle * 60.0) * 0.08;
      eruptionIntensity = (1.0 + wobble).clamp(0.85, 1.0);
    } else if (cycle >= 0.70 && cycle < 0.85) {
      final t = (cycle - 0.70) / 0.15;
      eruptionIntensity = 1.0 - t;
    }

    // Seismic tremor offset during high-pressure build-up & early blast
    int tremorX = 0;
    if (cycle >= 0.28 && cycle < 0.50) {
      final shake = math.sin(cycle * 130.0);
      if (shake.abs() > 0.45) {
        tremorX = shake > 0 ? 1 : -1;
      }
    }

    final currentPlumeY = ventY - (height * plumeHeight * eruptionIntensity);
    final jetHalfWidth = (width * 0.08).clamp(2.0, 8.0);

    // 1. Render Geothermal Mineral Terraces & Boiling Mud Basin
    for (int y = 0; y < height; y++) {
      final yNorm = y / height.toDouble();
      final isBasin = y >= ventY - 2;

      for (int x = 0; x < width; x++) {
        final idx = y * width + x;

        if (preserveAlpha && (pixels[idx] >>> 24) == 0) {
          continue;
        }

        // Apply tremor displacement horizontally to ground
        final sampleX = (isBasin ? (x + tremorX) : x).clamp(0, width - 1);

        if (!isBasin) {
          // Ambient sky / distant geothermal steam haze
          final skyR = (20 + (1.0 - yNorm) * 18).toInt().clamp(0, 255);
          final skyG = (22 + (1.0 - yNorm) * 16).toInt().clamp(0, 255);
          final skyB = (28 + (1.0 - yNorm) * 22).toInt().clamp(0, 255);
          out[idx] = 0xFF000000 | (skyR << 16) | (skyG << 8) | skyB;
        } else {
          // Concentric terraced mineral sinter rings
          final dx = sampleX - ventX;
          final dy = (y - ventY) * 1.7; // Squashed perspective ellipse
          final distFromVent = math.sqrt(dx * dx + dy * dy);

          int baseGround;
          final sinterNoise = _noise2D(sampleX * 0.2, y * 0.2, 73);
          final ringVal = math.sin(distFromVent * 0.65 + sinterNoise * 2.2);

          if (distFromVent < jetHalfWidth + 1.5) {
            // Central boiling vent orifice
            baseGround = palette.ventOrifice;
          } else if (distFromVent < width * 0.24) {
            // Inner boiling mud pot pool
            baseGround = (ringVal > 0.2) ? palette.mudLight : palette.mudDark;
          } else if (distFromVent < width * 0.42) {
            // Mid-terrace sulfur/mineral precipitate ring
            baseGround = (ringVal > -0.1) ? palette.mineralCrust : palette.mudLight;
          } else {
            // Outer weathered volcanic sinter rim
            baseGround = (sinterNoise > 0.1) ? palette.outerRock : palette.mineralCrust;
          }

          out[idx] = baseGround;
        }
      }
    }

    // 2. Render Boiling Mud Bubbles
    const bubbleCount = 8;
    for (int b = 0; b < bubbleCount; b++) {
      final seed = b * 43 + 17;
      final bx = (ventX + math.cos(seed.toDouble()) * (width * 0.28)).round();
      final by = (ventY + math.sin(seed.toDouble()).abs() * (height * 0.16) + 2.0).round();

      final bPhase = ((time * bubbleBoilRate * 3.0) + (seed % 100) / 100.0) % 1.0;

      if (bx >= 1 && bx < width - 1 && by >= 0 && by < height - 1) {
        if (bPhase < 0.70) {
          // Bubble swelling dome
          final domeRadius = (bPhase / 0.70) * 2.5;
          for (int dy = -domeRadius.ceil(); dy <= domeRadius.ceil(); dy++) {
            for (int dx = -domeRadius.ceil(); dx <= domeRadius.ceil(); dx++) {
              final px = bx + dx;
              final py = by + dy;
              if (px < 0 || px >= width || py < 0 || py >= height) continue;
              final pIdx = py * width + px;

              if (preserveAlpha && (pixels[pIdx] >>> 24) == 0) continue;

              final d = math.sqrt((dx * dx + dy * dy).toDouble());
              if (d <= domeRadius) {
                // Highlight at top-left of bubble
                if (dx <= 0 && dy <= 0 && d < domeRadius * 0.6) {
                  out[pIdx] = palette.bubbleHighlight;
                } else {
                  out[pIdx] = palette.mudLight;
                }
              }
            }
          }
        } else {
          // Popped bubble ring & froth splash
          final popProgress = (bPhase - 0.70) / 0.30;
          final ringRad = 2.0 + popProgress * 2.5;
          for (int dy = -ringRad.ceil(); dy <= ringRad.ceil(); dy++) {
            for (int dx = -ringRad.ceil(); dx <= ringRad.ceil(); dx++) {
              final px = bx + dx;
              final py = by + dy;
              if (px < 0 || px >= width || py < 0 || py >= height) continue;
              final pIdx = py * width + px;

              if (preserveAlpha && (pixels[pIdx] >>> 24) == 0) continue;

              final d = math.sqrt((dx * dx + dy * dy).toDouble());
              if ((d - ringRad).abs() < 0.9) {
                out[pIdx] = _alphaBlend(out[pIdx], palette.bubbleHighlight, ((1.0 - popProgress) * 220).toInt());
              }
            }
          }
        }
      }
    }

    // 3. Render Pressurized Eruptive Jet Column
    if (eruptionIntensity > 0.05) {
      final topY = currentPlumeY.round().clamp(0, height - 1);
      final botY = ventY.round().clamp(0, height - 1);

      for (int y = topY; y <= botY; y++) {
        final normColumnHeight = (ventY - y) / (height * plumeHeight);
        final currentHalfW = jetHalfWidth * (0.8 + normColumnHeight * 0.7);

        for (int x = (ventX - currentHalfW - 1).round(); x <= (ventX + currentHalfW + 1).round(); x++) {
          if (x < 0 || x >= width || y < 0 || y >= height) continue;
          final idx = y * width + x;

          if (preserveAlpha && (pixels[idx] >>> 24) == 0) continue;

          final dx = (x - ventX).abs();
          if (dx <= currentHalfW) {
            // Vertical high-speed stream noise
            final streamNoise = _noise2D(x * 0.8, (y * 0.4) + (time * 28.0), 31);
            final normDx = dx / currentHalfW;

            if (normDx < 0.35) {
              // Superheated incandescent white/boiling core
              out[idx] = palette.jetCore;
            } else if (normDx < 0.80) {
              // Aerated foaming water envelope
              out[idx] = (streamNoise > 0.0) ? palette.jetWater : palette.jetFoam;
            } else {
              // Outer shearing vapor fringe
              out[idx] = _alphaBlend(out[idx], palette.steamCloud, 180);
            }
          }
        }
      }
    }

    // 4. Render Expanding Billowing Steam Clouds
    final steamActive = (cycle >= 0.35 || cycle < 0.15 || eruptionIntensity > 0.1);
    if (steamActive) {
      final steamDensity = (eruptionIntensity > 0.2)
          ? (0.7 + eruptionIntensity * 0.3)
          : (0.5 * (1.0 - (cycle / 0.35)));

      final steamTop = math.max(0, (currentPlumeY - 14).round());
      final steamBottom = (ventY + 4).round();

      for (int y = steamTop; y < steamBottom; y++) {
        final steamNormY = (ventY - y) / height.toDouble();
        final spreadX = (width * steamDispersion * (0.2 + steamNormY * 0.6));

        final minX = math.max(0, (ventX - spreadX).round());
        final maxX = math.min(width - 1, (ventX + spreadX).round());

        for (int x = minX; x <= maxX; x++) {
          final idx = y * width + x;

          if (preserveAlpha && (pixels[idx] >>> 24) == 0) continue;

          final dxNorm = (x - ventX).abs() / spreadX;
          if (dxNorm > 1.0) continue;

          // 2D FBM Curling Steam Turbulences
          final curling = math.sin((y * 0.15) - (time * 4.0) + (x * 0.1));
          final n1 = _noise2D((x * 0.12) + curling, (y * 0.12) - (time * 5.0), 107);
          final n2 = _noise2D(x * 0.25, (y * 0.25) - (time * 9.0), 229);
          final steamNoise = (n1 * 0.65 + n2 * 0.35);

          if (steamNoise > -0.15) {
            final edgeFade = 1.0 - (dxNorm * dxNorm);
            final alpha = ((steamNoise + 0.15) * steamDensity * edgeFade * 170).toInt().clamp(0, 210);

            if (alpha > 15) {
              out[idx] = _alphaBlend(out[idx], palette.steamCloud, alpha);
            }
          }
        }
      }
    }

    return out;
  }

  // -----------------------------
  // Geothermal Color Grading
  // -----------------------------

  _GeyserPalette _getGeyserPalette(String key) {
    switch (key) {
      case 'ironRed':
        return const _GeyserPalette(
          mudDark: 0xFF3E1C12, // Dark iron oxide mud
          mudLight: 0xFF6D3425, // Ochre mud slurry
          mineralCrust: 0xFFBF360C, // Rust hematite terrace ring
          outerRock: 0xFF2A1510, // Weathered canyon basalt
          ventOrifice: 0xFF1C0A05, // Black thermal abyss
          bubbleHighlight: 0xFFFF8A65, // Terracotta froth dome
          jetCore: 0xFFFFF3E0, // Boiling mineral water core
          jetWater: 0xFFD84315, // Aerated iron spray
          jetFoam: 0xFFFFAB91, // Iron froth
          steamCloud: 0xFFFFEBE5, // Copper-tinted vapor billow
        );
      case 'silicaWhite':
        return const _GeyserPalette(
          mudDark: 0xFF1C282C, // Deep silica silt
          mudLight: 0xFF37474F, // Pale gray thermal mud
          mineralCrust: 0xFF00ACC1, // Vibrant cyan thermal spring rim
          outerRock: 0xFFCFD8DC, // Glistering white silica sinter
          ventOrifice: 0xFF004D40, // Abyssal turquoise throat
          bubbleHighlight: 0xFFE0F7FA, // Glacial silica bubble crest
          jetCore: 0xFFFFFFFF, // Pure incandescent white blast
          jetWater: 0xFF26C6DA, // Azure thermal water
          jetFoam: 0xFFE0F7FA, // Pure silica froth
          steamCloud: 0xFFF5FFFF, // Crisp geothermal steam
        );
      case 'abyssalBasalt':
        return const _GeyserPalette(
          mudDark: 0xFF140D1E, // Obsidian mud
          mudLight: 0xFF281938, // Violet volcanic clay
          mineralCrust: 0xFFFF6D00, // Incandescent magma fracture
          outerRock: 0xFF121214, // Dark volcanic basalt
          ventOrifice: 0xFF000000, // Bottomless caldera orifice
          bubbleHighlight: 0xFFFFAB40, // Glowing magma bubble
          jetCore: 0xFFFFF8E1, // Blinding superheated core
          jetWater: 0xFFFF6D00, // Fiery volcanic spray
          jetFoam: 0xFFCE93D8, // Lilac ash froth
          steamCloud: 0xFFE1BEE7, // Arcane violet thermal haze
        );
      case 'sulfurYellow':
      default:
        return const _GeyserPalette(
          mudDark: 0xFF2E2413, // Dark sulfur sediment mud
          mudLight: 0xFF544422, // Warm boiling mud slurry
          mineralCrust: 0xFFC0CA33, // Vivid sulfur yellow precipitate
          outerRock: 0xFF2E3326, // Lichen sinter stone
          ventOrifice: 0xFF171308, // Dark geothermal vent mouth
          bubbleHighlight: 0xFFE6EE9C, // Pale sulfur bubble cap
          jetCore: 0xFFFFFFF0, // Boiling scalding white core
          jetWater: 0xFFDCE775, // Aerated sulfur jet
          jetFoam: 0xFFF0F4C3, // Pale sulfur froth
          steamCloud: 0xFFFFFDE7, // Warm pale sulfur vapor
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

class _GeyserPalette {
  final int mudDark;
  final int mudLight;
  final int mineralCrust;
  final int outerRock;
  final int ventOrifice;
  final int bubbleHighlight;
  final int jetCore;
  final int jetWater;
  final int jetFoam;
  final int steamCloud;

  const _GeyserPalette({
    required this.mudDark,
    required this.mudLight,
    required this.mineralCrust,
    required this.outerRock,
    required this.ventOrifice,
    required this.bubbleHighlight,
    required this.jetCore,
    required this.jetWater,
    required this.jetFoam,
    required this.steamCloud,
  });
}
