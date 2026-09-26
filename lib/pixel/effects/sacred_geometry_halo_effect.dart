part of 'effects.dart';

/// Renders sacred geometry matrices, including Metatron's 13-sphere cube, the Flower of Life,
/// Merkaba star tetrahedrons, and platonic polyhedra halos with illuminated nodal spheres.
class SacredGeometryHaloEffect extends Effect {
  SacredGeometryHaloEffect([Map<String, dynamic>? params])
      : super(
          EffectType.sacredGeometryHalo,
          params ??
              {
                'geometryType': 'metatronCube',
                'haloRadius': 13.0,
                'showNodes': true,
                'isometricLines': true,
                'sacredPalette': 'divineGold',
                'behindOnly': false,
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() => {
        'geometryType': 'metatronCube',
        'haloRadius': 13.0,
        'showNodes': true,
        'isometricLines': true,
        'sacredPalette': 'divineGold',
        'behindOnly': false,
      };

  @override
  Map<String, dynamic> getMetadata() => {
        'geometryType': {
          'label': 'Sacred Matrix Type',
          'description': 'Geometric archetype of the divine polyhedral halo.',
          'type': 'select',
          'options': {
            'metatronCube': "Metatron's Cube (13-Sphere Vector)",
            'flowerOfLife': 'Flower of Life (Interlocking Petals)',
            'merkabaStar': 'Merkaba Star (3D Star Tetrahedron)',
            'platonicIcosa': 'Platonic Icosa (Geodesic Matrix)',
          },
        },
        'haloRadius': {
          'label': 'Halo Outer Radius',
          'description': 'Overall radial scale of the sacred geometric projection.',
          'type': 'slider',
          'min': 8.0,
          'max': 30.0,
          'step': 1.0,
        },
        'showNodes': {
          'label': 'Nodal Sphere Points',
          'description': 'Renders luminous celestial spheres at geometric vertices.',
          'type': 'bool',
        },
        'isometricLines': {
          'label': 'Isometric Vector Lines',
          'description': 'Draws connecting harmonic chords between nodal centers.',
          'type': 'bool',
        },
        'sacredPalette': {
          'label': 'Divine Color Theme',
          'description': 'Harmonic light spectrum and celestial aura color.',
          'type': 'select',
          'options': {
            'divineGold': 'Divine Gold (Sacred Temple)',
            'cosmicPlatonic': 'Cosmic Platonic (Astral Cyan)',
            'solarPrism': 'Solar Prism (Warm Rainbow)',
            'monochromeSilver': 'Monochrome Silver (Platinum Light)',
          },
        },
        'behindOnly': {
          'label': 'Behind Foreground',
          'description': 'Renders halo behind existing opaque character pixels.',
          'type': 'bool',
        },
      };

  @override
  List<UIField> getFields() => const [
        SelectField(
          key: 'geometryType',
          label: 'Sacred Matrix Type',
          options: <String, String>{
            'metatronCube': "Metatron's Cube (13-Sphere Vector)",
            'flowerOfLife': 'Flower of Life (Interlocking Petals)',
            'merkabaStar': 'Merkaba Star (3D Star Tetrahedron)',
            'platonicIcosa': 'Platonic Icosa (Geodesic Matrix)',
          },
        ),
        SliderField(
          key: 'haloRadius',
          label: 'Halo Outer Radius',
          min: 8.0,
          max: 30.0,
        ),
        BoolField(
          key: 'showNodes',
          label: 'Nodal Sphere Points',
        ),
        BoolField(
          key: 'isometricLines',
          label: 'Isometric Vector Lines',
        ),
        SelectField(
          key: 'sacredPalette',
          label: 'Divine Color Theme',
          options: <String, String>{
            'divineGold': 'Divine Gold (Sacred Temple)',
            'cosmicPlatonic': 'Cosmic Platonic (Astral Cyan)',
            'solarPrism': 'Solar Prism (Warm Rainbow)',
            'monochromeSilver': 'Monochrome Silver (Platinum Light)',
          },
        ),
        BoolField(
          key: 'behindOnly',
          label: 'Behind Foreground',
        ),
      ];

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    final geometryType = parameters['geometryType'] as String? ?? 'metatronCube';
    final haloRadius = (parameters['haloRadius'] as num?)?.toDouble() ?? 13.0;
    final showNodes = parameters['showNodes'] as bool? ?? true;
    final isometricLines = parameters['isometricLines'] as bool? ?? true;
    final sacredPalette = parameters['sacredPalette'] as String? ?? 'divineGold';
    final behindOnly = parameters['behindOnly'] as bool? ?? false;

    final output = Uint32List.fromList(pixels);

    // 1. Identify character upper body / head centroid
    int sumX = 0;
    int sumY = 0;
    int activeCount = 0;
    int minY = height;

    for (int y = 0; y < height; y++) {
      final rowOffset = y * width;
      for (int x = 0; x < width; x++) {
        final a = (pixels[rowOffset + x] >> 24) & 0xFF;
        if (a > 20) {
          sumX += x;
          sumY += y;
          activeCount++;
          if (y < minY) minY = y;
        }
      }
    }

    final int cx = activeCount > 0 ? (sumX ~/ activeCount) : (width ~/ 2);
    // Position halo slightly above character center for an overhead aura feel
    final int cy = activeCount > 0
        ? ((minY + (sumY ~/ activeCount)) ~/ 2).clamp(0, height - 1)
        : (height ~/ 2);

    // Color definitions
    final int coreColor;
    final int haloColor;
    final int nodeColor;

    switch (sacredPalette) {
      case 'cosmicPlatonic':
        coreColor = 0xFF40C4FF;
        haloColor = 0x88005599;
        nodeColor = 0xFFE1F5FE;
        break;
      case 'solarPrism':
        coreColor = 0xFFFF8A65;
        haloColor = 0x88D84315;
        nodeColor = 0xFFFBE9E7;
        break;
      case 'monochromeSilver':
        coreColor = 0xFFECEFF1;
        haloColor = 0x8878909C;
        nodeColor = 0xFFFFFFFF;
        break;
      case 'divineGold':
      default:
        coreColor = 0xFFFFD54F;
        haloColor = 0x88FFA000;
        nodeColor = 0xFFFFFDE7;
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

    void drawCircle(int ocx, int ocy, double r, int color) {
      final int steps = (2 * math.pi * r * 1.5).ceil().clamp(12, 360);
      for (int i = 0; i < steps; i++) {
        final theta = i * 2 * math.pi / steps;
        final px = (ocx + r * math.cos(theta)).round();
        final py = (ocy + r * math.sin(theta)).round();
        setPixel(px, py, color);
      }
    }

    void drawNodeSphere(int nx, int ny) {
      setPixel(nx, ny, nodeColor);
      setPixel(nx - 1, ny, coreColor);
      setPixel(nx + 1, ny, coreColor);
      setPixel(nx, ny - 1, coreColor);
      setPixel(nx, ny + 1, coreColor);
    }

    // 2. Render Sacred Geometry Typology
    final List<math.Point<int>> nodes = [];

    switch (geometryType) {
      case 'flowerOfLife':
        // Overlapping hexagonal circles
        final rPetal = haloRadius * 0.5;
        // Central circle
        drawCircle(cx, cy, rPetal, haloColor);
        nodes.add(math.Point(cx, cy));

        // 6 Surrounding petal circles
        for (int k = 0; k < 6; k++) {
          final theta = k * math.pi / 3;
          final px = (cx + rPetal * math.cos(theta)).round();
          final py = (cy + rPetal * math.sin(theta)).round();
          nodes.add(math.Point(px, py));
          drawCircle(px, py, rPetal, haloColor);
        }
        // Outer containment circle
        drawCircle(cx, cy, haloRadius, coreColor);
        break;

      case 'merkabaStar':
        // 3D Star Tetrahedron: Interlocking upward and downward triangles
        final rMain = haloRadius;
        final List<math.Point<int>> upTri = [];
        final List<math.Point<int>> downTri = [];

        for (int k = 0; k < 3; k++) {
          final thetaUp = -math.pi / 2 + k * 2 * math.pi / 3;
          final thetaDown = math.pi / 2 + k * 2 * math.pi / 3;
          upTri.add(math.Point((cx + rMain * math.cos(thetaUp)).round(), (cy + rMain * math.sin(thetaUp)).round()));
          downTri.add(math.Point((cx + rMain * math.cos(thetaDown)).round(), (cy + rMain * math.sin(thetaDown)).round()));
        }

        nodes.addAll(upTri);
        nodes.addAll(downTri);
        nodes.add(math.Point(cx, cy)); // Apex center

        if (isometricLines) {
          // Upward triangle
          for (int k = 0; k < 3; k++) {
            drawLine(upTri[k].x, upTri[k].y, upTri[(k + 1) % 3].x, upTri[(k + 1) % 3].y, coreColor);
            drawLine(cx, cy, upTri[k].x, upTri[k].y, haloColor);
          }
          // Downward triangle
          for (int k = 0; k < 3; k++) {
            drawLine(downTri[k].x, downTri[k].y, downTri[(k + 1) % 3].x, downTri[(k + 1) % 3].y, coreColor);
            drawLine(cx, cy, downTri[k].x, downTri[k].y, haloColor);
          }
        }
        drawCircle(cx, cy, haloRadius, haloColor);
        break;

      case 'platonicIcosa':
        // Geodesic icosahedral matrix
        final rOuter = haloRadius;
        final rMid = haloRadius * 0.6;

        // Outer ring of 6 vertices
        for (int k = 0; k < 6; k++) {
          final theta = k * math.pi / 3;
          nodes.add(math.Point((cx + rOuter * math.cos(theta)).round(), (cy + rOuter * math.sin(theta)).round()));
        }
        // Inner ring of 6 vertices
        for (int k = 0; k < 6; k++) {
          final theta = k * math.pi / 3 + math.pi / 6;
          nodes.add(math.Point((cx + rMid * math.cos(theta)).round(), (cy + rMid * math.sin(theta)).round()));
        }
        nodes.add(math.Point(cx, cy));

        if (isometricLines) {
          for (int k = 0; k < 6; k++) {
            final pOut = nodes[k];
            final pNextOut = nodes[(k + 1) % 6];
            final pIn = nodes[6 + k];
            final pNextIn = nodes[6 + ((k + 1) % 6)];

            drawLine(pOut.x, pOut.y, pNextOut.x, pNextOut.y, coreColor);
            drawLine(pOut.x, pOut.y, pIn.x, pIn.y, haloColor);
            drawLine(pIn.x, pIn.y, pNextIn.x, pNextIn.y, haloColor);
            drawLine(cx, cy, pIn.x, pIn.y, haloColor);
          }
        }
        break;

      case 'metatronCube':
      default:
        // Metatron's 13-sphere vector matrix: Center (1) + Inner 6 + Outer 6
        final rInner = haloRadius * 0.5;
        final rOuter = haloRadius;

        nodes.add(math.Point(cx, cy)); // 1. Center sphere

        // 2. Inner 6 spheres
        for (int k = 0; k < 6; k++) {
          final theta = k * math.pi / 3 - math.pi / 2;
          nodes.add(math.Point((cx + rInner * math.cos(theta)).round(), (cy + rInner * math.sin(theta)).round()));
        }

        // 3. Outer 6 spheres
        for (int k = 0; k < 6; k++) {
          final theta = k * math.pi / 3 - math.pi / 2;
          nodes.add(math.Point((cx + rOuter * math.cos(theta)).round(), (cy + rOuter * math.sin(theta)).round()));
        }

        if (isometricLines) {
          // Connect center to all inner nodes
          for (int k = 1; k <= 6; k++) {
            drawLine(cx, cy, nodes[k].x, nodes[k].y, coreColor);
          }
          // Connect inner nodes in a hexagon
          for (int k = 1; k <= 6; k++) {
            final nextK = (k % 6) + 1;
            drawLine(nodes[k].x, nodes[k].y, nodes[nextK].x, nodes[nextK].y, haloColor);
          }
          // Connect inner nodes to outer nodes
          for (int k = 1; k <= 6; k++) {
            final outK = k + 6;
            drawLine(nodes[k].x, nodes[k].y, nodes[outK].x, nodes[outK].y, coreColor);
          }
          // Connect outer nodes to form outer hexagon
          for (int k = 7; k <= 12; k++) {
            final nextK = k == 12 ? 7 : k + 1;
            drawLine(nodes[k].x, nodes[k].y, nodes[nextK].x, nodes[nextK].y, haloColor);
          }
          // Opposing outer diagonal cross-chords
          for (int k = 7; k <= 9; k++) {
            final oppK = k + 3;
            drawLine(nodes[k].x, nodes[k].y, nodes[oppK].x, nodes[oppK].y, haloColor);
          }
        }

        // Boundary containment circle
        drawCircle(cx, cy, haloRadius, haloColor);
        break;
    }

    // 3. Draw Nodal Spheres
    if (showNodes) {
      for (final n in nodes) {
        drawNodeSphere(n.x, n.y);
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
