part of 'effects.dart';

/// Renders an alchemical transmutation circle with concentric containment rings,
/// interlocking sacred geometric star polygons, radial celestial spoke rays, and nodal sparks.
class AlchemicalCircleEffect extends Effect {
  AlchemicalCircleEffect([Map<String, dynamic>? params])
      : super(
          EffectType.alchemicalCircle,
          params ??
              {
                'circleRadius': 12.0,
                'polygonSides': 'hexagram6',
                'spokeRays': true,
                'outerRings': true,
                'alchemyPalette': 'hermeticGold',
                'behindOnly': false,
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() => {
        'circleRadius': 12.0,
        'polygonSides': 'hexagram6',
        'spokeRays': true,
        'outerRings': true,
        'alchemyPalette': 'hermeticGold',
        'behindOnly': false,
      };

  @override
  Map<String, dynamic> getMetadata() => {
        'circleRadius': {
          'label': 'Circle Radius',
          'description': 'Radius of the main alchemical transmutation containment ring.',
          'type': 'slider',
          'min': 6.0,
          'max': 28.0,
          'step': 1.0,
        },
        'polygonSides': {
          'label': 'Sacred Polygon',
          'description': 'Geometric star or polygon inscribed inside the array.',
          'type': 'select',
          'options': {
            'triangle3': 'Trine (Sacred Triangle)',
            'pentagram5': 'Pentacle (5-Pointed Star)',
            'hexagram6': 'Solomon Hexagram (Seal of Saturn)',
            'octagram8': 'Octagram (8-Axis Wheel)',
          },
        },
        'spokeRays': {
          'label': 'Radial Spoke Rays',
          'description': 'Radiates connecting alignment rays between concentric rings.',
          'type': 'bool',
        },
        'outerRings': {
          'label': 'Outer Containment Ring',
          'description': 'Renders double perimeter runes and celestial containment border.',
          'type': 'bool',
        },
        'alchemyPalette': {
          'label': 'Transmutation Theme',
          'description': 'Mystical alchemical illumination and aura color.',
          'type': 'select',
          'options': {
            'hermeticGold': 'Hermetic Gold (24K Transmutation)',
            'astralCyan': 'Astral Cyan (Celestial Projection)',
            'bloodPhilosopher': "Philosopher's Crimson (Vital Elixir)",
            'amethystOccult': 'Amethyst Occult (Nether Violet)',
          },
        },
        'behindOnly': {
          'label': 'Behind Foreground',
          'description': 'Renders array behind existing opaque character pixels.',
          'type': 'bool',
        },
      };

  @override
  List<UIField> getFields() => const [
        SliderField(
          key: 'circleRadius',
          label: 'Circle Radius',
          min: 6.0,
          max: 28.0,
        ),
        SelectField(
          key: 'polygonSides',
          label: 'Sacred Polygon',
          options: <String, String>{
            'triangle3': 'Trine (Sacred Triangle)',
            'pentagram5': 'Pentacle (5-Pointed Star)',
            'hexagram6': 'Solomon Hexagram (Seal of Saturn)',
            'octagram8': 'Octagram (8-Axis Wheel)',
          },
        ),
        BoolField(
          key: 'spokeRays',
          label: 'Radial Spoke Rays',
        ),
        BoolField(
          key: 'outerRings',
          label: 'Outer Containment Ring',
        ),
        SelectField(
          key: 'alchemyPalette',
          label: 'Transmutation Theme',
          options: <String, String>{
            'hermeticGold': 'Hermetic Gold (24K Transmutation)',
            'astralCyan': 'Astral Cyan (Celestial Projection)',
            'bloodPhilosopher': "Philosopher's Crimson (Vital Elixir)",
            'amethystOccult': 'Amethyst Occult (Nether Violet)',
          },
        ),
        BoolField(
          key: 'behindOnly',
          label: 'Behind Foreground',
        ),
      ];

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    final circleRadius = (parameters['circleRadius'] as num?)?.toDouble() ?? 12.0;
    final polygonSides = parameters['polygonSides'] as String? ?? 'hexagram6';
    final spokeRays = parameters['spokeRays'] as bool? ?? true;
    final outerRings = parameters['outerRings'] as bool? ?? true;
    final alchemyPalette = parameters['alchemyPalette'] as String? ?? 'hermeticGold';
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
    final int sparkColor;

    switch (alchemyPalette) {
      case 'astralCyan':
        coreColor = 0xFF00E5FF;
        haloColor = 0x88005588;
        sparkColor = 0xFFE0FFFF;
        break;
      case 'bloodPhilosopher':
        coreColor = 0xFFFF1744;
        haloColor = 0x88880011;
        sparkColor = 0xFFFFCDD2;
        break;
      case 'amethystOccult':
        coreColor = 0xFFD500F9;
        haloColor = 0x88550077;
        sparkColor = 0xFFF3E5F5;
        break;
      case 'hermeticGold':
      default:
        coreColor = 0xFFFFD700;
        haloColor = 0x88996600;
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

    void drawCircle(double r, int color) {
      final int steps = (2 * math.pi * r * 1.5).ceil().clamp(16, 360);
      for (int i = 0; i < steps; i++) {
        final theta = i * 2 * math.pi / steps;
        final px = (cx + r * math.cos(theta)).round();
        final py = (cy + r * math.sin(theta)).round();
        setPixel(px, py, color);
      }
    }

    // 2. Draw Concentric Circles
    final rMain = circleRadius;
    final rInner = circleRadius * 0.55;
    final rOuter = circleRadius * 1.25;

    // Main ring
    drawCircle(rMain, coreColor);
    drawCircle(rInner, haloColor);

    if (outerRings) {
      drawCircle(rOuter, coreColor);
      drawCircle(rOuter - 1.0, haloColor);
    }

    // 3. Draw Inscribed Sacred Polygon / Star
    final List<math.Point<double>> vertices = [];

    switch (polygonSides) {
      case 'triangle3':
        for (int k = 0; k < 3; k++) {
          final theta = -math.pi / 2 + k * 2 * math.pi / 3;
          vertices.add(math.Point(cx + rMain * math.cos(theta), cy + rMain * math.sin(theta)));
        }
        for (int k = 0; k < 3; k++) {
          final p1 = vertices[k];
          final p2 = vertices[(k + 1) % 3];
          drawLine(p1.x.round(), p1.y.round(), p2.x.round(), p2.y.round(), coreColor);
          setPixel(p1.x.round(), p1.y.round(), sparkColor);
        }
        break;

      case 'pentagram5':
        for (int k = 0; k < 5; k++) {
          final theta = -math.pi / 2 + k * 2 * math.pi / 5;
          vertices.add(math.Point(cx + rMain * math.cos(theta), cy + rMain * math.sin(theta)));
        }
        // Interlocking 5-point star: connect k to (k + 2) % 5
        for (int k = 0; k < 5; k++) {
          final p1 = vertices[k];
          final p2 = vertices[(k + 2) % 5];
          drawLine(p1.x.round(), p1.y.round(), p2.x.round(), p2.y.round(), coreColor);
          setPixel(p1.x.round(), p1.y.round(), sparkColor);
        }
        break;

      case 'octagram8':
        // Two interlocking squares offset by 45 degrees
        for (int k = 0; k < 8; k++) {
          final theta = -math.pi / 2 + k * 2 * math.pi / 8;
          vertices.add(math.Point(cx + rMain * math.cos(theta), cy + rMain * math.sin(theta)));
        }
        // Square 1: vertices 0, 2, 4, 6
        for (int k = 0; k < 4; k++) {
          final p1 = vertices[k * 2];
          final p2 = vertices[((k + 1) % 4) * 2];
          drawLine(p1.x.round(), p1.y.round(), p2.x.round(), p2.y.round(), coreColor);
          setPixel(p1.x.round(), p1.y.round(), sparkColor);
        }
        // Square 2: vertices 1, 3, 5, 7
        for (int k = 0; k < 4; k++) {
          final p1 = vertices[k * 2 + 1];
          final p2 = vertices[((k + 1) % 4) * 2 + 1];
          drawLine(p1.x.round(), p1.y.round(), p2.x.round(), p2.y.round(), haloColor);
          setPixel(p1.x.round(), p1.y.round(), sparkColor);
        }
        break;

      case 'hexagram6':
      default:
        // Solomon's seal: two interlocking equilateral triangles
        for (int k = 0; k < 6; k++) {
          final theta = -math.pi / 2 + k * 2 * math.pi / 6;
          vertices.add(math.Point(cx + rMain * math.cos(theta), cy + rMain * math.sin(theta)));
        }
        // Upward triangle: vertices 0, 2, 4
        for (int k = 0; k < 3; k++) {
          final p1 = vertices[k * 2];
          final p2 = vertices[((k + 1) % 3) * 2];
          drawLine(p1.x.round(), p1.y.round(), p2.x.round(), p2.y.round(), coreColor);
          setPixel(p1.x.round(), p1.y.round(), sparkColor);
        }
        // Downward triangle: vertices 1, 3, 5
        for (int k = 0; k < 3; k++) {
          final p1 = vertices[k * 2 + 1];
          final p2 = vertices[((k + 1) % 3) * 2 + 1];
          drawLine(p1.x.round(), p1.y.round(), p2.x.round(), p2.y.round(), coreColor);
          setPixel(p1.x.round(), p1.y.round(), sparkColor);
        }
        break;
    }

    // 4. Spoke Rays & Outer Alignment Ticks
    if (spokeRays) {
      final spokeCount = vertices.length;
      final rayMax = outerRings ? rOuter : rMain;
      for (int k = 0; k < spokeCount; k++) {
        final theta = -math.pi / 2 + k * 2 * math.pi / spokeCount;
        final xIn = (cx + rInner * math.cos(theta)).round();
        final yIn = (cy + rInner * math.sin(theta)).round();
        final xOut = (cx + rayMax * math.cos(theta)).round();
        final yOut = (cy + rayMax * math.sin(theta)).round();
        drawLine(xIn, yIn, xOut, yOut, haloColor);

        // Notches on outer ring
        if (outerRings) {
          final notchX = (cx + (rOuter + 1.5) * math.cos(theta)).round();
          final notchY = (cy + (rOuter + 1.5) * math.sin(theta)).round();
          setPixel(notchX, notchY, sparkColor);
        }
      }
    }

    // Center transmutation catalyst dot
    setPixel(cx, cy, sparkColor);
    setPixel(cx - 1, cy, haloColor);
    setPixel(cx + 1, cy, haloColor);
    setPixel(cx, cy - 1, haloColor);
    setPixel(cx, cy + 1, haloColor);

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
