part of 'effects.dart';

/// Synthesizes ancient Elder Futhark and celestial sigil glyphs orbiting the character
/// with mystical luminescence, runic staves, and connecting ether threads.
class FloatingSigilsEffect extends Effect {
  FloatingSigilsEffect([Map<String, dynamic>? params])
      : super(
          EffectType.floatingSigils,
          params ??
              {
                'sigilCount': 6.0,
                'orbitRadius': 11.0,
                'runeStyle': 'elderFuthark',
                'linkThreads': true,
                'sigilPalette': 'elderGold',
                'behindOnly': false,
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() => {
        'sigilCount': 6.0,
        'orbitRadius': 11.0,
        'runeStyle': 'elderFuthark',
        'linkThreads': true,
        'sigilPalette': 'elderGold',
        'behindOnly': false,
      };

  @override
  Map<String, dynamic> getMetadata() => {
        'sigilCount': {
          'label': 'Sigil Count',
          'description': 'Number of floating runic glyphs orbiting the character.',
          'type': 'slider',
          'min': 3.0,
          'max': 10.0,
          'step': 1.0,
        },
        'orbitRadius': {
          'label': 'Orbit Distance',
          'description': 'Distance of the floating sigil constellation from character center.',
          'type': 'slider',
          'min': 5.0,
          'max': 24.0,
          'step': 1.0,
        },
        'runeStyle': {
          'label': 'Runic Scripture',
          'description': 'Calligraphic style of the synthesized glyph staves.',
          'type': 'select',
          'options': {
            'elderFuthark': 'Elder Futhark (Norse Runes)',
            'celestialSigil': 'Celestial Sigils (Angelic Seals)',
            'linearStaves': 'Linear Staves (Occult Wards)',
          },
        },
        'linkThreads': {
          'label': 'Etheric Link Threads',
          'description': 'Connects adjacent sigils with faint mystical energy threads.',
          'type': 'bool',
        },
        'sigilPalette': {
          'label': 'Rune Glow Theme',
          'description': 'Luminescent aura color of the orbiting sigils.',
          'type': 'select',
          'options': {
            'elderGold': 'Elder Gold (Ancient Runestone)',
            'valkyrieCyan': 'Valkyrie Cyan (Glacial Ward)',
            'infernalCrimson': 'Infernal Crimson (Blood Seal)',
            'voidViolet': 'Void Violet (Nether Arcana)',
          },
        },
        'behindOnly': {
          'label': 'Behind Foreground',
          'description': 'Renders sigils behind existing opaque character pixels.',
          'type': 'bool',
        },
      };

  @override
  List<UIField> getFields() => const [
        SliderField(
          key: 'sigilCount',
          label: 'Sigil Count',
          min: 3.0,
          max: 10.0,
        ),
        SliderField(
          key: 'orbitRadius',
          label: 'Orbit Distance',
          min: 5.0,
          max: 24.0,
        ),
        SelectField(
          key: 'runeStyle',
          label: 'Runic Scripture',
          options: <String, String>{
            'elderFuthark': 'Elder Futhark (Norse Runes)',
            'celestialSigil': 'Celestial Sigils (Angelic Seals)',
            'linearStaves': 'Linear Staves (Occult Wards)',
          },
        ),
        BoolField(
          key: 'linkThreads',
          label: 'Etheric Link Threads',
        ),
        SelectField(
          key: 'sigilPalette',
          label: 'Rune Glow Theme',
          options: <String, String>{
            'elderGold': 'Elder Gold (Ancient Runestone)',
            'valkyrieCyan': 'Valkyrie Cyan (Glacial Ward)',
            'infernalCrimson': 'Infernal Crimson (Blood Seal)',
            'voidViolet': 'Void Violet (Nether Arcana)',
          },
        ),
        BoolField(
          key: 'behindOnly',
          label: 'Behind Foreground',
        ),
      ];

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    final sigilCount = (parameters['sigilCount'] as num?)?.toInt().clamp(2, 16) ?? 6;
    final orbitRadius = (parameters['orbitRadius'] as num?)?.toDouble() ?? 11.0;
    final runeStyle = parameters['runeStyle'] as String? ?? 'elderFuthark';
    final linkThreads = parameters['linkThreads'] as bool? ?? true;
    final sigilPalette = parameters['sigilPalette'] as String? ?? 'elderGold';
    final behindOnly = parameters['behindOnly'] as bool? ?? false;

    final output = Uint32List.fromList(pixels);

    // 1. Find character centroid
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
    final int coreColor;
    final int haloColor;
    final int threadColor;
    final int sparkColor;

    switch (sigilPalette) {
      case 'valkyrieCyan':
        coreColor = 0xFF18FFFF;
        haloColor = 0x88007799;
        threadColor = 0x55005577;
        sparkColor = 0xFFE0FFFF;
        break;
      case 'infernalCrimson':
        coreColor = 0xFFFF2D55;
        haloColor = 0x88880011;
        threadColor = 0x55660011;
        sparkColor = 0xFFFFDDEE;
        break;
      case 'voidViolet':
        coreColor = 0xFFB388FF;
        haloColor = 0x88440077;
        threadColor = 0x55330055;
        sparkColor = 0xFFF3E5F5;
        break;
      case 'elderGold':
      default:
        coreColor = 0xFFFFD700;
        haloColor = 0x88996600;
        threadColor = 0x55AA7700;
        sparkColor = 0xFFFFF9C4;
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

    // 2. Predefined 3x5 Glyph Bitmaps
    // 15 bits per glyph: bit 14 is (0,0), bit 0 is (2,4)
    final List<int> futharkBitmaps = [
      0x57D4, // Fehu ᚠ
      0x5674, // Thurisaz ᚦ
      0x55D4, // Ansuz ᚫ
      0x5395, // Algiz ᛉ
      0x79CE, // Sowilo ᛋ
      0x7292, // Tiwaz ᛏ
      0x5775, // Ehwaz ᛖ
      0x5555, // Isa ᛁ
    ];

    final List<int> celestialBitmaps = [
      0x27BA, // Star diamond
      0x7777, // Portal gate
      0x2BAE, // Celestial cross
      0x5755, // Solar seal
      0x7575, // Hex beacon
      0x2EE2, // Double ward
    ];

    final List<int> linearBitmaps = [
      0x22F2, // Cross staff
      0x7222, // T-Staff
      0x2F22, // Mid-cross
      0x2A22, // Diamond staff
      0x5225, // Dual bar
      0x2722, // Bar staff
    ];

    final List<int> chosenGlyphs;
    if (runeStyle == 'celestialSigil') {
      chosenGlyphs = celestialBitmaps;
    } else if (runeStyle == 'linearStaves') {
      chosenGlyphs = linearBitmaps;
    } else {
      chosenGlyphs = futharkBitmaps;
    }

    final double rx = orbitRadius * 1.25;
    final double ry = orbitRadius * 0.85;

    final List<math.Point<int>> sigilCenters = [];

    // Calculate sigil centers along elliptical orbit
    for (int i = 0; i < sigilCount; i++) {
      final theta = i * 2 * math.pi / sigilCount - math.pi / 2;
      final gx = (cx + rx * math.cos(theta)).round();
      final gy = (cy + ry * math.sin(theta)).round();
      sigilCenters.add(math.Point(gx, gy));
    }

    // 3. Draw Connecting Ether Threads
    if (linkThreads && sigilCenters.length >= 2) {
      for (int i = 0; i < sigilCenters.length; i++) {
        final p1 = sigilCenters[i];
        final p2 = sigilCenters[(i + 1) % sigilCenters.length];
        drawLine(p1.x, p1.y, p2.x, p2.y, threadColor);
      }
    }

    // 4. Render 3x5 Sigil Glyphs and Luminescent Halos
    for (int i = 0; i < sigilCenters.length; i++) {
      final p = sigilCenters[i];
      final glyphBits = chosenGlyphs[i % chosenGlyphs.length];

      // Draw 3x5 matrix centered at (p.x, p.y) -> offset (-1..1, -2..2)
      for (int dy = -2; dy <= 2; dy++) {
        for (int dx = -1; dx <= 1; dx++) {
          final bitIndex = (dy + 2) * 3 + (dx + 1);
          final isSet = (glyphBits & (1 << (14 - bitIndex))) != 0;

          if (isSet) {
            final px = p.x + dx;
            final py = p.y + dy;

            // Halo glow around set pixel
            setPixel(px - 1, py, haloColor);
            setPixel(px + 1, py, haloColor);
            setPixel(px, py - 1, haloColor);
            setPixel(px, py + 1, haloColor);

            // Core bright glyph pixel
            setPixel(px, py, coreColor);
          }
        }
      }

      // Sparkle core at glyph center
      setPixel(p.x, p.y, sparkColor);
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
