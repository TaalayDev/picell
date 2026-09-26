part of 'effects.dart';

/// Spawns creeping ink-black serpentine tendrils and viscous dark matter oozing
/// and twisting outward from the sprite's silhouette edges with glowing miasma fringes.
class AbyssalTendrilMiasmaEffect extends Effect {
  AbyssalTendrilMiasmaEffect([Map<String, dynamic>? params])
      : super(
          EffectType.abyssalTendrilMiasma,
          params ??
              {
                'tendrilCount': 6,
                'reachLength': 10.0,
                'curlTwist': 1.5,
                'bubbleMotes': true,
                'inkPalette': 'voidBlack',
                'behindOnly': false,
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() => {
        'tendrilCount': 6,
        'reachLength': 10.0,
        'curlTwist': 1.5,
        'bubbleMotes': true,
        'inkPalette': 'voidBlack',
        'behindOnly': false,
      };

  @override
  Map<String, dynamic> getMetadata() => {
        'tendrilCount': {
          'label': 'Dark Tendril Count',
          'description': 'Number of creeping serpentine tendrils sprouting from the contour.',
          'type': 'slider',
          'min': 3.0,
          'max': 12.0,
          'step': 1.0,
        },
        'reachLength': {
          'label': 'Tendril Reach Length',
          'description': 'Maximum distance extending dark matter tendrils stretch outward.',
          'type': 'slider',
          'min': 4.0,
          'max': 20.0,
          'step': 1.0,
        },
        'curlTwist': {
          'label': 'Serpentine Curl Twist',
          'description': 'Angular curvature and waving turbulence along the tendril stalks.',
          'type': 'slider',
          'min': 0.5,
          'max': 3.0,
          'step': 0.25,
        },
        'bubbleMotes': {
          'label': 'Boiling Bubble Motes',
          'description': 'Spawns detached floating dark droplet specks dissolving into space.',
          'type': 'bool',
        },
        'inkPalette': {
          'label': 'Abyssal Sludge Palette',
          'description': 'Coloration of the dark matter core and surrounding miasma glow.',
          'type': 'dropdown',
          'options': [
            {'value': 'voidBlack', 'label': 'Void Black (Pitch Core / Nether Violet / Lavender Mist)'},
            {'value': 'vampireBlood', 'label': 'Vampiric Blood (Dark Clot Core / Crimson Sheen / Scarlet)'},
            {'value': 'toxicBile', 'label': 'Toxic Bile (Abyssal Core / Sickly Lime / Necro Green)'},
            {'value': 'curseGold', 'label': 'Cursed Gold (Obsidian Core / Occult Amber / Honey Spark)'},
          ],
        },
        'behindOnly': {
          'label': 'Render Behind Sprite',
          'description': 'When enabled, renders tendrils strictly behind existing sprite pixels.',
          'type': 'bool',
        },
      };

  @override
  List<UIField> getFields() => [
        SliderField(
          key: 'tendrilCount',
          label: 'Dark Tendril Count',
          description: 'Number of creeping serpentine tendrils sprouting from the contour.',
          min: 3.0,
          max: 12.0,
          divisions: 9,
          formatLabel: (v) => '${v.round()} tendrils',
        ),
        SliderField(
          key: 'reachLength',
          label: 'Tendril Reach Length',
          description: 'Maximum distance extending dark matter tendrils stretch outward.',
          min: 4.0,
          max: 20.0,
          divisions: 16,
          formatLabel: (v) => '${v.round()}px',
        ),
        SliderField(
          key: 'curlTwist',
          label: 'Serpentine Curl Twist',
          description: 'Angular curvature and waving turbulence along the tendril stalks.',
          min: 0.5,
          max: 3.0,
          divisions: 10,
          formatLabel: (v) => '${v.toStringAsFixed(2)}x',
        ),
        const BoolField(
          key: 'bubbleMotes',
          label: 'Boiling Bubble Motes',
          description: 'Spawns detached floating dark droplet specks dissolving into space.',
        ),
        const SelectField(
          key: 'inkPalette',
          label: 'Abyssal Sludge Palette',
          description: 'Coloration of the dark matter core and surrounding miasma glow.',
          options: {
            'voidBlack': 'Void Black (Pitch Core / Nether Violet)',
            'vampireBlood': 'Vampiric Blood (Clot Core / Crimson Sheen)',
            'toxicBile': 'Toxic Bile (Abyssal Core / Sickly Lime)',
            'curseGold': 'Cursed Gold (Obsidian Core / Occult Amber)',
          },
        ),
        const BoolField(
          key: 'behindOnly',
          label: 'Render Behind Sprite',
          description: 'When enabled, renders tendrils strictly behind existing sprite pixels.',
        ),
      ];

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    final output = Uint32List(width * height);
    output.setAll(0, pixels);

    final tendrilCount = ((parameters['tendrilCount'] as num?)?.toInt() ?? 6).clamp(3, 12);
    final reachLength = ((parameters['reachLength'] as num?)?.toDouble() ?? 10.0).clamp(4.0, 20.0);
    final curlTwist = ((parameters['curlTwist'] as num?)?.toDouble() ?? 1.5).clamp(0.5, 3.0);
    final bubbleMotes = parameters['bubbleMotes'] as bool? ?? true;
    final paletteKey = parameters['inkPalette'] as String? ?? 'voidBlack';
    final behindOnly = parameters['behindOnly'] as bool? ?? false;

    // 1. Scan contour boundary pixels and center of mass
    final contour = <math.Point<int>>[];
    double sumX = 0, sumY = 0;
    int solidCount = 0;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final p = pixels[y * width + x];
        if (((p >> 24) & 0xFF) > 20) {
          sumX += x;
          sumY += y;
          solidCount++;

          bool isBoundary = false;
          const dx = [0, 0, -1, 1];
          const dy = [-1, 1, 0, 0];
          for (int i = 0; i < 4; i++) {
            final nx = x + dx[i];
            final ny = y + dy[i];
            if (nx < 0 || nx >= width || ny < 0 || ny >= height || ((pixels[ny * width + nx] >> 24) & 0xFF) <= 20) {
              isBoundary = true;
              break;
            }
          }
          if (isBoundary) {
            contour.add(math.Point(x, y));
          }
        }
      }
    }

    if (contour.isEmpty || solidCount == 0) return output;

    final centerX = sumX / solidCount;
    final centerY = sumY / solidCount;
    final colors = _getMiasmaColors(paletteKey);

    void setMiasmaPixel(int x, int y, int color) {
      if (x < 0 || x >= width || y < 0 || y >= height) return;
      final idx = y * width + x;
      if (behindOnly && ((pixels[idx] >> 24) & 0xFF) > 30) return;
      output[idx] = _blendPixel(output[idx], color);
    }

    // 2. Select evenly distributed anchor points along the contour
    final stepAngle = (2.0 * math.pi) / tendrilCount;

    for (int t = 0; t < tendrilCount; t++) {
      final targetAngle = t * stepAngle;
      final cosA = math.cos(targetAngle);
      final sinA = math.sin(targetAngle);

      math.Point<int>? bestPt;
      double maxProj = -double.infinity;

      for (final pt in contour) {
        final proj = (pt.x - centerX) * cosA + (pt.y - centerY) * sinA;
        if (proj > maxProj) {
          maxProj = proj;
          bestPt = pt;
        }
      }

      if (bestPt == null) continue;

      // Normal outward direction
      double nx = bestPt.x - centerX;
      double ny = bestPt.y - centerY;
      final len = math.sqrt(nx * nx + ny * ny);
      if (len > 0.001) {
        nx /= len;
        ny /= len;
      } else {
        nx = cosA;
        ny = sinA;
      }

      final baseAngle = math.atan2(ny, nx);
      final seedHash = ((bestPt.x * 79 + bestPt.y * 163) ^ 0x3F1A) & 0x7FFFFFFF;

      double currX = bestPt.x.toDouble();
      double currY = bestPt.y.toDouble();

      final totalSteps = reachLength.round();

      // 3. March serpentine curling tendril
      for (int s = 0; s < totalSteps; s++) {
        final progress = s / totalSteps;
        // Serpentine waving angle with upward curling bias
        final wave = math.sin(s * 0.65 + (seedHash % 7)) * curlTwist * 0.6;
        final currentAngle = baseAngle + wave - (progress * 0.35); // Tendrils curl upward

        currX += math.cos(currentAngle) * 1.1;
        currY += math.sin(currentAngle) * 1.1;

        final radius = math.max(0.6, 1.8 * (1.0 - progress * 0.7));
        final ix = currX.round();
        final iy = currY.round();

        // Stamp circle of pixels at current tendril segment
        final radCeil = radius.ceil();
        for (int dy = -radCeil; dy <= radCeil; dy++) {
          for (int dx = -radCeil; dx <= radCeil; dx++) {
            final dist = math.sqrt(dx * dx + dy * dy);
            if (dist <= radius) {
              final normD = dist / radius;

              int pixelColor;
              int alpha;

              if (normD < 0.45) {
                // Pitch-black / dense core
                pixelColor = colors.core;
                alpha = 250;
              } else {
                // Luminous miasma fringe
                pixelColor = colors.glow;
                alpha = (230 * (1.0 - normD)).toInt().clamp(0, 255);
              }

              setMiasmaPixel(ix + dx, iy + dy, (alpha << 24) | (pixelColor & 0x00FFFFFF));
            }
          }
        }
      }

      // 4. Detached boiling droplet motes beyond tip
      if (bubbleMotes) {
        final moteOffsets = [2.2, 4.0, 5.8];
        for (int m = 0; m < moteOffsets.length; m++) {
          final moteDist = moteOffsets[m];
          final mx = (currX + nx * moteDist + (m == 1 ? 1.0 : -1.0)).round();
          final my = (currY + ny * moteDist - (m * 0.8)).round(); // float upward

          final moteAlpha = (210 - m * 50).clamp(0, 255);
          setMiasmaPixel(mx, my, (moteAlpha << 24) | (colors.mote & 0x00FFFFFF));
        }
      }
    }

    return output;
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

  _MiasmaColors _getMiasmaColors(String palette) {
    switch (palette) {
      case 'vampireBlood':
        return const _MiasmaColors(
          core: 0xFF1A0005,
          glow: 0xFFB71C1C,
          mote: 0xFFFF5252,
        );
      case 'toxicBile':
        return const _MiasmaColors(
          core: 0xFF0A1400,
          glow: 0xFF64DD17,
          mote: 0xFFCCFF90,
        );
      case 'curseGold':
        return const _MiasmaColors(
          core: 0xFF0D0A00,
          glow: 0xFFFFB300,
          mote: 0xFFFFD54F,
        );
      case 'voidBlack':
      default:
        return const _MiasmaColors(
          core: 0xFF080010,
          glow: 0xFF7B1FA2,
          mote: 0xFFCE93D8,
        );
    }
  }
}

class _MiasmaColors {
  final int core;
  final int glow;
  final int mote;

  const _MiasmaColors({
    required this.core,
    required this.glow,
    required this.mote,
  });
}
