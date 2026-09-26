part of 'effects.dart';

/// Spawns haunting geometric eyeballs opening along the silhouette perimeter and
/// peering from the dark miasma with demonic pupils and creeping capillary veins.
class EldritchPeepingEyesEffect extends Effect {
  EldritchPeepingEyesEffect([Map<String, dynamic>? params])
      : super(
          EffectType.eldritchPeepingEyes,
          params ??
              {
                'eyeCount': 5,
                'pupilType': 'slitCat',
                'eyeSize': 4.5,
                'veinGlow': true,
                'eyePalette': 'crimsonCurse',
                'behindOnly': false,
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() => {
        'eyeCount': 5,
        'pupilType': 'slitCat',
        'eyeSize': 4.5,
        'veinGlow': true,
        'eyePalette': 'crimsonCurse',
        'behindOnly': false,
      };

  @override
  Map<String, dynamic> getMetadata() => {
        'eyeCount': {
          'label': 'Peeping Eye Count',
          'description': 'Number of eldritch eyeballs opening along the contour.',
          'type': 'slider',
          'min': 2.0,
          'max': 10.0,
          'step': 1.0,
        },
        'pupilType': {
          'label': 'Demonic Pupil Aperture',
          'description': 'Geometric aperture design of the peeping eyes.',
          'type': 'dropdown',
          'options': [
            {'value': 'slitCat', 'label': 'Vertical Slit (Predatory Reptile / Cat Eye)'},
            {'value': 'roundVoid', 'label': 'Round Void (Abyssal Pupil with Catchlight)'},
            {'value': 'demonicCross', 'label': 'Occult Cross (Demonic 4-Way Cross Pupil)'},
          ],
        },
        'eyeSize': {
          'label': 'Eyeball Scale',
          'description': 'Geometric dimensions of the almond-shaped eye sclera.',
          'type': 'slider',
          'min': 3.0,
          'max': 7.0,
          'step': 0.5,
        },
        'veinGlow': {
          'label': 'Capillary Vein Threads',
          'description': 'Renders thin 1px bloodshot vein threads connecting eyes to the sprite.',
          'type': 'bool',
        },
        'eyePalette': {
          'label': 'Ominous Eye Palette',
          'description': 'Coloration of the sclera, iris, and demonic pupil.',
          'type': 'dropdown',
          'options': [
            {'value': 'crimsonCurse', 'label': 'Crimson Curse (Amber Sclera / Blood Iris / Void Pupil)'},
            {'value': 'voidWatcher', 'label': 'Void Watcher (Violet Sclera / Neon Purple / Dark Magenta)'},
            {'value': 'goldenOmen', 'label': 'Golden Omen (Pale Gold / Radiant Sun / Deep Amber)'},
            {'value': 'emeraldMadness', 'label': 'Emerald Madness (Mint Sclera / Toxic Lime / Dark Bile)'},
          ],
        },
        'behindOnly': {
          'label': 'Render Behind Sprite',
          'description': 'When enabled, renders eyes strictly behind existing sprite pixels.',
          'type': 'bool',
        },
      };

  @override
  List<UIField> getFields() => [
        SliderField(
          key: 'eyeCount',
          label: 'Peeping Eye Count',
          description: 'Number of eldritch eyeballs opening along the contour.',
          min: 2.0,
          max: 10.0,
          divisions: 8,
          formatLabel: (v) => '${v.round()} eyes',
        ),
        const SelectField(
          key: 'pupilType',
          label: 'Demonic Pupil Aperture',
          description: 'Geometric aperture design of the peeping eyes.',
          options: {
            'slitCat': 'Vertical Slit (Predatory Slit)',
            'roundVoid': 'Round Void (Abyssal Pupil)',
            'demonicCross': 'Occult Cross (4-Way Cross)',
          },
        ),
        SliderField(
          key: 'eyeSize',
          label: 'Eyeball Scale',
          description: 'Geometric dimensions of the almond-shaped eye sclera.',
          min: 3.0,
          max: 7.0,
          divisions: 8,
          formatLabel: (v) => '${v.toStringAsFixed(1)}px',
        ),
        const BoolField(
          key: 'veinGlow',
          label: 'Capillary Vein Threads',
          description: 'Renders thin 1px bloodshot vein threads connecting eyes to the sprite.',
        ),
        const SelectField(
          key: 'eyePalette',
          label: 'Ominous Eye Palette',
          description: 'Coloration of the sclera, iris, and demonic pupil.',
          options: {
            'crimsonCurse': 'Crimson Curse (Amber Sclera / Blood Iris)',
            'voidWatcher': 'Void Watcher (Violet / Neon Purple)',
            'goldenOmen': 'Golden Omen (Pale Gold / Radiant Sun)',
            'emeraldMadness': 'Emerald Madness (Mint Sclera / Toxic Lime)',
          },
        ),
        const BoolField(
          key: 'behindOnly',
          label: 'Render Behind Sprite',
          description: 'When enabled, renders eyes strictly behind existing sprite pixels.',
        ),
      ];

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    final output = Uint32List(width * height);
    output.setAll(0, pixels);

    final eyeCount = ((parameters['eyeCount'] as num?)?.toInt() ?? 5).clamp(2, 10);
    final pupilType = parameters['pupilType'] as String? ?? 'slitCat';
    final eyeSize = ((parameters['eyeSize'] as num?)?.toDouble() ?? 4.5).clamp(3.0, 7.0);
    final veinGlow = parameters['veinGlow'] as bool? ?? true;
    final paletteKey = parameters['eyePalette'] as String? ?? 'crimsonCurse';
    final behindOnly = parameters['behindOnly'] as bool? ?? false;

    // 1. Scan contour boundary pixels and centroid
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
    final colors = _getEyeColors(paletteKey);

    void setEyePixel(int x, int y, int color) {
      if (x < 0 || x >= width || y < 0 || y >= height) return;
      final idx = y * width + x;
      if (behindOnly && ((pixels[idx] >> 24) & 0xFF) > 30) return;
      output[idx] = _blendPixel(output[idx], color);
    }

    // 2. Select positions around contour
    final stepAngle = (2.0 * math.pi) / eyeCount;

    for (int i = 0; i < eyeCount; i++) {
      final targetAngle = i * stepAngle + 0.3;
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

      // Eye center: offset outward 2.5px along normal
      final ex = bestPt.x + nx * 2.5;
      final ey = bestPt.y + ny * 2.5;

      // Tangent vector
      final tx = -ny;
      final ty = nx;

      // 3. Draw capillary vein threads from anchor to eye
      if (veinGlow) {
        const veinSteps = 4;
        for (int v = 0; v <= veinSteps; v++) {
          final frac = v / veinSteps;
          final vx = (bestPt.x * (1.0 - frac) + ex * frac).round();
          final vy = (bestPt.y * (1.0 - frac) + ey * frac).round();
          setEyePixel(vx, vy, (180 << 24) | (colors.vein & 0x00FFFFFF));
        }
      }

      // 4. Render almond-shaped sclera and pupil
      final halfLen = eyeSize * 0.85;
      final halfWidth = eyeSize * 0.55;

      final minX = (ex - eyeSize - 1).floor().clamp(0, width - 1);
      final maxX = (ex + eyeSize + 1).ceil().clamp(0, width - 1);
      final minY = (ey - eyeSize - 1).floor().clamp(0, height - 1);
      final maxY = (ey + eyeSize + 1).ceil().clamp(0, height - 1);

      for (int py = minY; py <= maxY; py++) {
        for (int px = minX; px <= maxX; px++) {
          final relX = px - ex;
          final relY = py - ey;

          // Align with tangent (horizontal eye axis) and normal (vertical eye axis)
          final u = relX * tx + relY * ty; // Along tangent (width of eye)
          final v = relX * nx + relY * ny; // Along normal (height of eye)

          final normDist = (u * u) / (halfLen * halfLen) + (v * v) / (halfWidth * halfWidth);

          if (normDist <= 1.0) {
            int pixelColor;
            int alpha = 255;

            final radialCenterDist = math.sqrt(u * u + v * v);

            // Eyelid rim
            if (normDist > 0.75) {
              pixelColor = colors.rim;
            } else if (radialCenterDist > eyeSize * 0.42) {
              // Sclera white / pale
              pixelColor = colors.sclera;
            } else {
              // Iris zone
              pixelColor = colors.iris;

              // Demonic pupil aperture
              if (pupilType == 'slitCat') {
                if (u.abs() <= 0.6) {
                  pixelColor = colors.pupil;
                }
              } else if (pupilType == 'demonicCross') {
                if (u.abs() <= 0.6 || v.abs() <= 0.6) {
                  pixelColor = colors.pupil;
                }
              } else {
                // roundVoid
                if (radialCenterDist <= eyeSize * 0.22) {
                  pixelColor = colors.pupil;
                } else if (u.round() == 1 && v.round() == -1) {
                  // Catchlight spark
                  pixelColor = colors.spark;
                }
              }
            }

            setEyePixel(px, py, (alpha << 24) | (pixelColor & 0x00FFFFFF));
          }
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

  _EyeColors _getEyeColors(String palette) {
    switch (palette) {
      case 'voidWatcher':
        return const _EyeColors(
          sclera: 0xFFEDE7F6,
          iris: 0xFFAA00FF,
          pupil: 0xFF050014,
          rim: 0xFF4A148C,
          vein: 0xFFE040FB,
          spark: 0xFFFFFFFF,
        );
      case 'goldenOmen':
        return const _EyeColors(
          sclera: 0xFFFFFDE7,
          iris: 0xFFFFD700,
          pupil: 0xFF1F1400,
          rim: 0xFFE65100,
          vein: 0xFFFF6F00,
          spark: 0xFFFFFFFF,
        );
      case 'emeraldMadness':
        return const _EyeColors(
          sclera: 0xFFE8F5E9,
          iris: 0xFF76FF03,
          pupil: 0xFF001A05,
          rim: 0xFF1B5E20,
          vein: 0xFF00C853,
          spark: 0xFFCCFF90,
        );
      case 'crimsonCurse':
      default:
        return const _EyeColors(
          sclera: 0xFFFFF8E1,
          iris: 0xFFFF1744,
          pupil: 0xFF0A0000,
          rim: 0xFF880E4F,
          vein: 0xFFD50000,
          spark: 0xFFFFFFFF,
        );
    }
  }
}

class _EyeColors {
  final int sclera;
  final int iris;
  final int pupil;
  final int rim;
  final int vein;
  final int spark;

  const _EyeColors({
    required this.sclera,
    required this.iris,
    required this.pupil,
    required this.rim,
    required this.vein,
    required this.spark,
  });
}
