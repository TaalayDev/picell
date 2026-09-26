part of 'effects.dart';

/// Spawns a glowing cyberpunk hard-light hexagonal energy shield contouring
/// around the sprite's silhouette or directional forward facing guard.
class HexagonalAegisEffect extends Effect {
  HexagonalAegisEffect([Map<String, dynamic>? params])
      : super(
          EffectType.hexagonalAegis,
          params ??
              {
                'barrierOffset': 3.0,
                'hexRadius': 4.0,
                'shieldCoverage': 'fullBubble',
                'barrierPalette': 'holoCyan',
                'innerDither': true,
                'edgeGlow': 0.75,
                'behindOnly': false,
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() => {
        'barrierOffset': 3.0,
        'hexRadius': 4.0,
        'shieldCoverage': 'fullBubble',
        'barrierPalette': 'holoCyan',
        'innerDither': true,
        'edgeGlow': 0.75,
        'behindOnly': false,
      };

  @override
  Map<String, dynamic> getMetadata() => {
        'barrierOffset': {
          'label': 'Barrier Distance',
          'description': 'Distance from sprite contour to the inner shield edge.',
          'type': 'slider',
          'min': 1.0,
          'max': 8.0,
          'step': 0.5,
        },
        'hexRadius': {
          'label': 'Hex Plate Radius',
          'description': 'Geometric size of each individual hexagonal plate.',
          'type': 'slider',
          'min': 2.5,
          'max': 8.0,
          'step': 0.5,
        },
        'shieldCoverage': {
          'label': 'Shield Coverage Arc',
          'description': 'Angular coverage of the deployed barrier arc.',
          'type': 'dropdown',
          'options': [
            {'value': 'fullBubble', 'label': 'Full 360° Spherical Bubble'},
            {'value': 'forwardRight', 'label': 'Forward Guard (Facing Right)'},
            {'value': 'forwardLeft', 'label': 'Forward Guard (Facing Left)'},
            {'value': 'overheadDome', 'label': 'Overhead Sky Dome'},
          ],
        },
        'barrierPalette': {
          'label': 'Hard-Light Energy Palette',
          'description': 'Color frequency and luminous glow theme of the barrier.',
          'type': 'dropdown',
          'options': [
            {'value': 'holoCyan', 'label': 'Holo Cyan (Cyberpunk Neon Cyan / Cobalt Blue)'},
            {'value': 'neonOrange', 'label': 'Heavy Aegis Orange (Warning Orange / Amber Gold)'},
            {'value': 'matrixGreen', 'label': 'Matrix Phosphor (Terminal Emerald / Bright Lime)'},
            {'value': 'voidPurple', 'label': 'Void Warp Purple (Dark Violet / Neon Magenta)'},
          ],
        },
        'innerDither': {
          'label': 'Cell Energy Dither',
          'description': 'Applies a dithered energy fill within each hexagonal plate.',
          'type': 'bool',
        },
        'edgeGlow': {
          'label': 'Hex Perimeter Glow',
          'description': 'Intensity of the 1px luminous hexagonal boundary wireframe.',
          'type': 'slider',
          'min': 0.2,
          'max': 1.0,
          'step': 0.05,
        },
        'behindOnly': {
          'label': 'Render Behind Sprite',
          'description': 'When enabled, renders the barrier strictly behind existing sprite pixels.',
          'type': 'bool',
        },
      };

  @override
  List<UIField> getFields() => [
        SliderField(
          key: 'barrierOffset',
          label: 'Barrier Distance',
          description: 'Distance from sprite contour to the inner shield edge.',
          min: 1.0,
          max: 8.0,
          divisions: 14,
          formatLabel: (v) => '${v.toStringAsFixed(1)}px',
        ),
        SliderField(
          key: 'hexRadius',
          label: 'Hex Plate Radius',
          description: 'Geometric size of each individual hexagonal plate.',
          min: 2.5,
          max: 8.0,
          divisions: 11,
          formatLabel: (v) => '${v.toStringAsFixed(1)}px',
        ),
        const SelectField(
          key: 'shieldCoverage',
          label: 'Shield Coverage Arc',
          description: 'Angular coverage of the deployed barrier arc.',
          options: {
            'fullBubble': 'Full 360° Spherical Bubble',
            'forwardRight': 'Forward Guard (Facing Right)',
            'forwardLeft': 'Forward Guard (Facing Left)',
            'overheadDome': 'Overhead Sky Dome',
          },
        ),
        const SelectField(
          key: 'barrierPalette',
          label: 'Hard-Light Energy Palette',
          description: 'Color frequency and luminous glow theme of the barrier.',
          options: {
            'holoCyan': 'Holo Cyan (Cyberpunk Neon Cyan / Cobalt Blue)',
            'neonOrange': 'Heavy Aegis Orange (Warning Orange / Amber Gold)',
            'matrixGreen': 'Matrix Phosphor (Terminal Emerald / Bright Lime)',
            'voidPurple': 'Void Warp Purple (Dark Violet / Neon Magenta)',
          },
        ),
        const BoolField(
          key: 'innerDither',
          label: 'Cell Energy Dither',
          description: 'Applies a dithered energy fill within each hexagonal plate.',
        ),
        SliderField(
          key: 'edgeGlow',
          label: 'Hex Perimeter Glow',
          description: 'Intensity of the 1px luminous hexagonal boundary wireframe.',
          min: 0.2,
          max: 1.0,
          divisions: 16,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        const BoolField(
          key: 'behindOnly',
          label: 'Render Behind Sprite',
          description: 'When enabled, renders the barrier strictly behind existing sprite pixels.',
        ),
      ];

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    final output = Uint32List(width * height);
    output.setAll(0, pixels);

    final barrierOffset = ((parameters['barrierOffset'] as num?)?.toDouble() ?? 3.0).clamp(1.0, 8.0);
    final hexRadius = ((parameters['hexRadius'] as num?)?.toDouble() ?? 4.0).clamp(2.5, 8.0);
    final coverage = parameters['shieldCoverage'] as String? ?? 'fullBubble';
    final paletteKey = parameters['barrierPalette'] as String? ?? 'holoCyan';
    final innerDither = parameters['innerDither'] as bool? ?? true;
    final edgeGlow = ((parameters['edgeGlow'] as num?)?.toDouble() ?? 0.75).clamp(0.2, 1.0);
    final behindOnly = parameters['behindOnly'] as bool? ?? false;

    // Scan sprite bounds and contour boundary pixels
    final contourPoints = <math.Point<int>>[];
    double sumX = 0, sumY = 0;
    int solidCount = 0;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final p = pixels[y * width + x];
        final a = (p >> 24) & 0xFF;
        if (a > 20) {
          sumX += x;
          sumY += y;
          solidCount++;

          // Check if boundary
          bool isBoundary = false;
          const dx = [0, 0, -1, 1];
          const dy = [-1, 1, 0, 0];
          for (int i = 0; i < 4; i++) {
            final nx = x + dx[i];
            final ny = y + dy[i];
            if (nx < 0 || nx >= width || ny < 0 || ny >= height) {
              isBoundary = true;
              break;
            }
            final na = (pixels[ny * width + nx] >> 24) & 0xFF;
            if (na <= 20) {
              isBoundary = true;
              break;
            }
          }
          if (isBoundary) {
            contourPoints.add(math.Point(x, y));
          }
        }
      }
    }

    if (contourPoints.isEmpty || solidCount == 0) {
      return output;
    }

    final centerX = sumX / solidCount;
    final centerY = sumY / solidCount;
    final colors = _getAegisColors(paletteKey);

    // Shell distance bounds
    final innerBound = barrierOffset;
    final outerBound = barrierOffset + hexRadius * 2.2;

    const bayer4x4 = [
      [0, 8, 2, 10],
      [12, 4, 14, 6],
      [3, 11, 1, 9],
      [15, 7, 13, 5],
    ];

    final sqrt3 = math.sqrt(3.0);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final idx = y * width + x;
        final origPixel = pixels[idx];
        final origAlpha = (origPixel >> 24) & 0xFF;
        if (behindOnly && origAlpha > 30) {
          continue;
        }

        // Measure minimum distance to contour
        double minDistSq = double.infinity;
        for (final p in contourPoints) {
          final distSq = (x - p.x) * (x - p.x) + (y - p.y) * (y - p.y);
          if (distSq < minDistSq) {
            minDistSq = distSq.toDouble();
          }
        }
        final d = math.sqrt(minDistSq);

        if (d < innerBound || d > outerBound) {
          continue;
        }

        // Directional coverage filtering
        final vx = x - centerX;
        final vy = y - centerY;

        if (coverage == 'forwardRight' && vx < -0.35 * vy.abs()) {
          continue;
        } else if (coverage == 'forwardLeft' && vx > 0.35 * vy.abs()) {
          continue;
        } else if (coverage == 'overheadDome' && vy > 0.35 * vx.abs()) {
          continue;
        }

        // Pointy-topped hexagon coordinate mapping
        final q = (sqrt3 / 3.0 * (x - centerX) - 1.0 / 3.0 * (y - centerY)) / hexRadius;
        final r = (2.0 / 3.0 * (y - centerY)) / hexRadius;
        final s = -q - r;

        int rq = q.round();
        int rr = r.round();
        int rs = s.round();

        final qDiff = (rq - q).abs();
        final rDiff = (rr - r).abs();
        final sDiff = (rs - s).abs();

        if (qDiff > rDiff && qDiff > sDiff) {
          rq = -rr - rs;
        } else if (rDiff > sDiff) {
          rr = -rq - rs;
        }

        // Center of closest hex
        final hcx = hexRadius * (sqrt3 * rq + sqrt3 / 2.0 * rr) + centerX;
        final hcy = hexRadius * (3.0 / 2.0 * rr) + centerY;

        final px = (x - hcx).abs();
        final py = (y - hcy).abs();

        // Distance from center toward boundary of hexagon
        final hexEdgeDist = (hexRadius * (sqrt3 / 2.0)) - math.max(sqrt3 / 2.0 * px + 0.5 * py, py);

        // Shell falloff: strongest in middle of barrier shell
        final shellMid = (innerBound + outerBound) * 0.5;
        final shellHalfWidth = (outerBound - innerBound) * 0.5;
        final shellAlpha = math.max(0.0, 1.0 - ((d - shellMid) / shellHalfWidth).abs());

        if (hexEdgeDist.abs() <= 0.65) {
          // Luminous 1px hexagonal perimeter wireframe
          final glowAlpha = ((255 * edgeGlow * shellAlpha).clamp(0, 255)).toInt();
          if (glowAlpha <= 5) continue;

          // Wireframe color with vertex highlight
          int wireColor = colors.wireframe;
          if (hexEdgeDist.abs() < 0.25) {
            wireColor = colors.apexGlint;
          }
          final tinted = _withAlpha(wireColor, glowAlpha);
          output[idx] = _blendPixel(output[idx], tinted);
        } else if (innerDither && hexEdgeDist > 0.65) {
          // Inner plate energy field using Bayer 4x4 dither
          final bayerVal = bayer4x4[y % 4][x % 4] / 16.0;
          final ditherIntensity = 0.35 * shellAlpha;

          if (bayerVal < ditherIntensity) {
            final plateAlpha = ((180 * (ditherIntensity / 0.35) * edgeGlow).clamp(0, 255)).toInt();
            if (plateAlpha <= 5) continue;

            final tinted = _withAlpha(colors.innerField, plateAlpha);
            output[idx] = _blendPixel(output[idx], tinted);
          }
        }
      }
    }

    return output;
  }

  int _withAlpha(int color, int alpha) {
    return (alpha.clamp(0, 255) << 24) | (color & 0x00FFFFFF);
  }

  int _blendPixel(int dst, int src) {
    final sa = (src >> 24) & 0xFF;
    if (sa == 0) return dst;
    if (sa == 255) return src;
    final da = (dst >> 24) & 0xFF;
    if (da == 0) return src;

    final sf = sa / 255.0;
    final df = (da / 255.0) * (1.0 - sf);
    final outA = sf + df;
    if (outA <= 0.0) return 0;

    final sr = (src >> 16) & 0xFF;
    final sg = (src >> 8) & 0xFF;
    final sb = src & 0xFF;

    final dr = (dst >> 16) & 0xFF;
    final dg = (dst >> 8) & 0xFF;
    final db = dst & 0xFF;

    final r = ((sr * sf + dr * df) / outA).round().clamp(0, 255);
    final g = ((sg * sf + dg * df) / outA).round().clamp(0, 255);
    final b = ((sb * sf + db * df) / outA).round().clamp(0, 255);
    final a = (outA * 255.0).round().clamp(0, 255);

    return (a << 24) | (r << 16) | (g << 8) | b;
  }

  _AegisColors _getAegisColors(String palette) {
    switch (palette) {
      case 'neonOrange':
        return const _AegisColors(
          wireframe: 0xFFFF8800,
          innerField: 0xFFFFAA33,
          apexGlint: 0xFFFFF0AA,
        );
      case 'matrixGreen':
        return const _AegisColors(
          wireframe: 0xFF00FF66,
          innerField: 0xFF00AA44,
          apexGlint: 0xFFCCFFDD,
        );
      case 'voidPurple':
        return const _AegisColors(
          wireframe: 0xFFD500F9,
          innerField: 0xFF651FFF,
          apexGlint: 0xFFF8BBD0,
        );
      case 'holoCyan':
      default:
        return const _AegisColors(
          wireframe: 0xFF00E5FF,
          innerField: 0xFF0091EA,
          apexGlint: 0xFFE0F7FA,
        );
    }
  }
}

class _AegisColors {
  final int wireframe;
  final int innerField;
  final int apexGlint;

  const _AegisColors({
    required this.wireframe,
    required this.innerField,
    required this.apexGlint,
  });
}
