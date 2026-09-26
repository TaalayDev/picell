part of 'effects.dart';

/// Projects authentic astronomical constellation charts with major star vertices,
/// connecting asterism chord lines, 4-point star glints, and magnitude stardust.
class ZodiacConstellationEffect extends Effect {
  ZodiacConstellationEffect([Map<String, dynamic>? params])
      : super(
          EffectType.zodiacConstellation,
          params ??
              {
                'starScale': 14.0,
                'constellationPattern': 'orionHunter',
                'crossGlints': true,
                'dustDensity': 8.0,
                'starPalette': 'polarWhite',
                'behindOnly': false,
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() => {
        'starScale': 14.0,
        'constellationPattern': 'orionHunter',
        'crossGlints': true,
        'dustDensity': 8.0,
        'starPalette': 'polarWhite',
        'behindOnly': false,
      };

  @override
  Map<String, dynamic> getMetadata() => {
        'starScale': {
          'label': 'Constellation Scale',
          'description': 'Spatial span of the astronomical star chart across the canvas.',
          'type': 'slider',
          'min': 8.0,
          'max': 28.0,
          'step': 1.0,
        },
        'constellationPattern': {
          'label': 'Mythological Asterism',
          'description': 'Astronomical star constellation figure.',
          'type': 'select',
          'options': {
            'orionHunter': "Orion the Hunter (Belt & Rigel)",
            'cassiopeiaCrown': "Cassiopeia's Crown (Celestial W)",
            'phoenixAscendant': 'Phoenix Ascendant (Stellar Wings)',
            'cygnusCross': 'Cygnus Northern Cross (Swan Flight)',
          },
        },
        'crossGlints': {
          'label': 'Stellar Cross Glints',
          'description': 'Renders 4-point starlight diffraction spikes on alpha stars.',
          'type': 'bool',
        },
        'dustDensity': {
          'label': 'Background Stardust',
          'description': 'Density of sprinkled deep space background stardust motes.',
          'type': 'slider',
          'min': 0.0,
          'max': 20.0,
          'step': 2.0,
        },
        'starPalette': {
          'label': 'Stellar Magnitude Theme',
          'description': 'Color temperature of stellar vertices and asterism cords.',
          'type': 'select',
          'options': {
            'polarWhite': 'Polar White (Astronomical Catalog)',
            'celestialGold': 'Celestial Gold (Ancient Astrolabe)',
            'nebulaAzure': 'Nebula Azure (Interstellar Cyan)',
            'stellarRuby': 'Stellar Ruby (Giant Star Carmine)',
          },
        },
        'behindOnly': {
          'label': 'Behind Foreground',
          'description': 'Renders constellation behind existing opaque character pixels.',
          'type': 'bool',
        },
      };

  @override
  List<UIField> getFields() => const [
        SliderField(
          key: 'starScale',
          label: 'Constellation Scale',
          min: 8.0,
          max: 28.0,
        ),
        SelectField(
          key: 'constellationPattern',
          label: 'Mythological Asterism',
          options: <String, String>{
            'orionHunter': "Orion the Hunter (Belt & Rigel)",
            'cassiopeiaCrown': "Cassiopeia's Crown (Celestial W)",
            'phoenixAscendant': 'Phoenix Ascendant (Stellar Wings)',
            'cygnusCross': 'Cygnus Northern Cross (Swan Flight)',
          },
        ),
        BoolField(
          key: 'crossGlints',
          label: 'Stellar Cross Glints',
        ),
        SliderField(
          key: 'dustDensity',
          label: 'Background Stardust',
          min: 0.0,
          max: 20.0,
        ),
        SelectField(
          key: 'starPalette',
          label: 'Stellar Magnitude Theme',
          options: <String, String>{
            'polarWhite': 'Polar White (Astronomical Catalog)',
            'celestialGold': 'Celestial Gold (Ancient Astrolabe)',
            'nebulaAzure': 'Nebula Azure (Interstellar Cyan)',
            'stellarRuby': 'Stellar Ruby (Giant Star Carmine)',
          },
        ),
        BoolField(
          key: 'behindOnly',
          label: 'Behind Foreground',
        ),
      ];

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    final starScale = (parameters['starScale'] as num?)?.toDouble() ?? 14.0;
    final constellationPattern = parameters['constellationPattern'] as String? ?? 'orionHunter';
    final crossGlints = parameters['crossGlints'] as bool? ?? true;
    final dustDensity = (parameters['dustDensity'] as num?)?.toInt().clamp(0, 30) ?? 8;
    final starPalette = parameters['starPalette'] as String? ?? 'polarWhite';
    final behindOnly = parameters['behindOnly'] as bool? ?? false;

    final output = Uint32List.fromList(pixels);

    // 1. Identify character centroid
    int sumX = 0;
    int sumY = 0;
    int activeCount = 0;

    for (int y = 0; y < height; y++) {
      final rowOffset = y * width;
      for (int x = 0; x < width; x++) {
        final a = (pixels[rowOffset + x] >> 24) & 0xFF;
        if (a > 20) {
          sumX += x;
          sumY += y;
          activeCount++;
        }
      }
    }

    final int cx = activeCount > 0 ? (sumX ~/ activeCount) : (width ~/ 2);
    final int cy = activeCount > 0 ? (sumY ~/ activeCount) : (height ~/ 2);

    // Color definitions
    final int starColor;
    final int rayColor;
    final int chordColor;
    final int dustColor;

    switch (starPalette) {
      case 'celestialGold':
        starColor = 0xFFFFF9C4;
        rayColor = 0xFFFFD54F;
        chordColor = 0x66FFA000;
        dustColor = 0x55FFECB3;
        break;
      case 'nebulaAzure':
        starColor = 0xFFE1F5FE;
        rayColor = 0xFF40C4FF;
        chordColor = 0x660091EA;
        dustColor = 0x5580D8FF;
        break;
      case 'stellarRuby':
        starColor = 0xFFFFEBEE;
        rayColor = 0xFFFF5252;
        chordColor = 0x66D50000;
        dustColor = 0x55FF8A80;
        break;
      case 'polarWhite':
      default:
        starColor = 0xFFFFFFFF;
        rayColor = 0xFFE0E0E0;
        chordColor = 0x66B0BEC5;
        dustColor = 0x5590A4AE;
        break;
    }

    void setPixel(int x, int y, int color) {
      if (x < 0 || x >= width || y < 0 || y >= height) return;
      final idx = y * width + x;
      if (behindOnly) {
        final srcA = (pixels[idx] >> 24) & 0xFF;
        if (srcA > 20) return;
      }
      output[idx] = _blendPixel(output[idx], color);
    }

    void drawLine(int x0, int y0, int x1, int y1, int color) {
      int dx = (x1 - x0).abs();
      int dy = (y1 - y0).abs();
      int sx = x0 < x1 ? 1 : -1;
      int sy = y0 < y1 ? 1 : -1;
      int err = dx - dy;

      int cx0 = x0;
      int cy0 = y0;

      while (true) {
        setPixel(cx0, cy0, color);
        if (cx0 == x1 && cy0 == y1) break;
        int e2 = 2 * err;
        if (e2 > -dy) {
          err -= dy;
          cx0 += sx;
        }
        if (e2 < dx) {
          err += dx;
          cy0 += sy;
        }
      }
    }

    // 2. Constellation Coordinates & Asterism Chords
    final List<math.Point<double>> starCoords = [];
    final List<List<int>> asterismLines = [];
    final List<bool> isAlphaStar = [];

    switch (constellationPattern) {
      case 'cassiopeiaCrown':
        // 5-star W-crown
        starCoords.addAll([
          const math.Point(-1.0, 0.4),  // 0: Schedar (alpha)
          const math.Point(-0.5, -0.6), // 1: Caph
          const math.Point(0.0, 0.2),   // 2: Gamma (alpha)
          const math.Point(0.5, -0.5),  // 3: Ruchbah
          const math.Point(1.0, 0.5),   // 4: Segin
        ]);
        asterismLines.addAll([
          [0, 1], [1, 2], [2, 3], [3, 4]
        ]);
        isAlphaStar.addAll([true, false, true, false, false]);
        break;

      case 'cygnusCross':
        // Northern Cross
        starCoords.addAll([
          const math.Point(0.0, -1.0),  // 0: Deneb (alpha)
          const math.Point(0.0, -0.1),  // 1: Sadr (alpha)
          const math.Point(0.0, 0.9),   // 2: Albireo
          const math.Point(-0.85, -0.1),// 3: Gienah
          const math.Point(0.85, -0.1), // 4: Delta Cygnus
        ]);
        asterismLines.addAll([
          [0, 1], [1, 2], [3, 1], [1, 4]
        ]);
        isAlphaStar.addAll([true, true, false, false, false]);
        break;

      case 'phoenixAscendant':
        // Star bird with radiating wings
        starCoords.addAll([
          const math.Point(0.0, -0.9),  // 0: Ankaa Head
          const math.Point(0.0, -0.1),  // 1: Heart
          const math.Point(-1.1, -0.5), // 2: Left Wing Tip
          const math.Point(-0.5, 0.1),  // 3: Left Wing Base
          const math.Point(0.5, 0.1),   // 4: Right Wing Base
          const math.Point(1.1, -0.5),  // 5: Right Wing Tip
          const math.Point(-0.25, 0.85),// 6: Left Tail
          const math.Point(0.25, 0.85), // 7: Right Tail
        ]);
        asterismLines.addAll([
          [0, 1], [1, 3], [3, 2], [1, 4], [4, 5], [1, 6], [1, 7]
        ]);
        isAlphaStar.addAll([true, true, false, false, false, false, false, false]);
        break;

      case 'orionHunter':
      default:
        // Orion's Belt, Betelgeuse, Rigel
        starCoords.addAll([
          const math.Point(-0.75, -0.85), // 0: Betelgeuse (alpha)
          const math.Point(0.75, -0.75),  // 1: Bellatrix
          const math.Point(-0.25, 0.0),   // 2: Alnitak (belt)
          const math.Point(0.0, 0.0),     // 3: Alnilam (belt)
          const math.Point(0.25, 0.0),    // 4: Mintaka (belt)
          const math.Point(-0.65, 0.85),  // 5: Saiph
          const math.Point(0.65, 0.85),   // 6: Rigel (alpha)
          const math.Point(1.15, -0.1),   // 7: Bow Star
        ]);
        asterismLines.addAll([
          [0, 1], [0, 2], [1, 4], [2, 3], [3, 4], [2, 5], [4, 6], [5, 6], [1, 7]
        ]);
        isAlphaStar.addAll([true, false, false, true, false, false, true, false]);
        break;
    }

    // Convert normalized coords to pixel coords
    final List<math.Point<int>> starPixels = [];
    for (final coord in starCoords) {
      final px = (cx + coord.x * starScale).round();
      final py = (cy + coord.y * starScale).round();
      starPixels.add(math.Point(px, py));
    }

    // 3. Draw Asterism Chords
    for (final line in asterismLines) {
      final p1 = starPixels[line[0]];
      final p2 = starPixels[line[1]];
      drawLine(p1.x, p1.y, p2.x, p2.y, chordColor);
    }

    // 4. Sprinkled Deep Space Stardust
    if (dustDensity > 0) {
      for (int i = 0; i < dustDensity; i++) {
        final seed = (i * 2654435761 + cx * 37 + cy * 59) & 0x7FFFFFFF;
        final dTheta = (seed % 360) * math.pi / 180.0;
        final dDist = 4.0 + (seed % ((starScale * 1.3).round().clamp(5, 40)));
        final dx = (cx + dDist * math.cos(dTheta)).round();
        final dy = (cy + dDist * math.sin(dTheta)).round();
        setPixel(dx, dy, dustColor);
      }
    }

    // 5. Draw Star Vertices & Cross Glints
    for (int i = 0; i < starPixels.length; i++) {
      final sp = starPixels[i];
      final isAlpha = isAlphaStar[i];

      // Star core
      setPixel(sp.x, sp.y, starColor);

      if (crossGlints && isAlpha) {
        // 4-point cross glint
        setPixel(sp.x - 1, sp.y, rayColor);
        setPixel(sp.x + 1, sp.y, rayColor);
        setPixel(sp.x, sp.y - 1, rayColor);
        setPixel(sp.x, sp.y + 1, rayColor);

        setPixel(sp.x - 2, sp.y, chordColor);
        setPixel(sp.x + 2, sp.y, chordColor);
        setPixel(sp.x, sp.y - 2, chordColor);
        setPixel(sp.x, sp.y + 2, chordColor);
      } else {
        // Subtle glow halo
        setPixel(sp.x - 1, sp.y, chordColor);
        setPixel(sp.x + 1, sp.y, chordColor);
        setPixel(sp.x, sp.y - 1, chordColor);
        setPixel(sp.x, sp.y + 1, chordColor);
      }
    }

    return output;
  }

  int _blendPixel(int background, int foreground) {
    final fgA = (foreground >> 24) & 0xFF;
    if (fgA == 255) return foreground;
    if (fgA == 0) return background;

    final bgA = (background >> 24) & 0xFF;
    final fgR = (foreground >> 16) & 0xFF;
    final fgG = (foreground >> 8) & 0xFF;
    final fgB = foreground & 0xFF;

    if (bgA == 0) return foreground;

    final bgR = (background >> 16) & 0xFF;
    final bgG = (background >> 8) & 0xFF;
    final bgB = background & 0xFF;

    final alpha = fgA / 255.0;
    final invAlpha = 1.0 - alpha;

    final outR = (fgR * alpha + bgR * invAlpha).round().clamp(0, 255);
    final outG = (fgG * alpha + bgG * invAlpha).round().clamp(0, 255);
    final outB = (fgB * alpha + bgB * invAlpha).round().clamp(0, 255);
    final outA = (fgA + bgA * invAlpha).round().clamp(0, 255);

    return (outA << 24) | (outR << 16) | (outG << 8) | outB;
  }
}
