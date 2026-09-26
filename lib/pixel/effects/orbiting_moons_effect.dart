part of 'effects.dart';

/// Renders a celestial gravitational system with spherical shaded moons orbiting on
/// an inclined Keplerian orbital plane, complete with shadow terminators and orbital guide tracks.
class OrbitingMoonsEffect extends Effect {
  OrbitingMoonsEffect([Map<String, dynamic>? params])
      : super(
          EffectType.orbitingMoons,
          params ??
              {
                'moonCount': 3.0,
                'orbitRadius': 13.0,
                'orbitTilt': 15.0,
                'showTracks': true,
                'celestialPalette': 'terrestrialMoons',
                'behindOnly': false,
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() => {
        'moonCount': 3.0,
        'orbitRadius': 13.0,
        'orbitTilt': 15.0,
        'showTracks': true,
        'celestialPalette': 'terrestrialMoons',
        'behindOnly': false,
      };

  @override
  Map<String, dynamic> getMetadata() => {
        'moonCount': {
          'label': 'Satellite Moon Count',
          'description': 'Number of spherical moons orbiting the character.',
          'type': 'slider',
          'min': 2.0,
          'max': 6.0,
          'step': 1.0,
        },
        'orbitRadius': {
          'label': 'Orbital Distance',
          'description': 'Major radial distance of the satellite orbit.',
          'type': 'slider',
          'min': 7.0,
          'max': 28.0,
          'step': 1.0,
        },
        'orbitTilt': {
          'label': 'Orbital Plane Tilt',
          'description': 'Angle of inclination of the orbital ellipse plane.',
          'type': 'slider',
          'min': -45.0,
          'max': 45.0,
          'step': 5.0,
        },
        'showTracks': {
          'label': 'Orbital Guide Tracks',
          'description': 'Renders faint orbital trajectory ellipse and asteroid dust motes.',
          'type': 'bool',
        },
        'celestialPalette': {
          'label': 'Planetary Moon Theme',
          'description': 'Surface mineralogy and atmospheric reflection palette.',
          'type': 'select',
          'options': {
            'terrestrialMoons': 'Terrestrial Moons (Lunar Regolith)',
            'gasGiantSatellites': 'Gas Giant Moons (Jovian Gold)',
            'crystallineIce': 'Crystalline Ice (Europa Frost)',
            'volcanicIo': 'Volcanic Io (Sulfur Magma)',
          },
        },
        'behindOnly': {
          'label': 'Behind Foreground',
          'description': 'Renders moons behind existing opaque character pixels.',
          'type': 'bool',
        },
      };

  @override
  List<UIField> getFields() => const [
        SliderField(
          key: 'moonCount',
          label: 'Satellite Moon Count',
          min: 2.0,
          max: 6.0,
        ),
        SliderField(
          key: 'orbitRadius',
          label: 'Orbital Distance',
          min: 7.0,
          max: 28.0,
        ),
        SliderField(
          key: 'orbitTilt',
          label: 'Orbital Plane Tilt',
          min: -45.0,
          max: 45.0,
        ),
        BoolField(
          key: 'showTracks',
          label: 'Orbital Guide Tracks',
        ),
        SelectField(
          key: 'celestialPalette',
          label: 'Planetary Moon Theme',
          options: <String, String>{
            'terrestrialMoons': 'Terrestrial Moons (Lunar Regolith)',
            'gasGiantSatellites': 'Gas Giant Moons (Jovian Gold)',
            'crystallineIce': 'Crystalline Ice (Europa Frost)',
            'volcanicIo': 'Volcanic Io (Sulfur Magma)',
          },
        ),
        BoolField(
          key: 'behindOnly',
          label: 'Behind Foreground',
        ),
      ];

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    final moonCount = (parameters['moonCount'] as num?)?.toInt().clamp(1, 10) ?? 3;
    final orbitRadius = (parameters['orbitRadius'] as num?)?.toDouble() ?? 13.0;
    final orbitTilt = (parameters['orbitTilt'] as num?)?.toDouble() ?? 15.0;
    final showTracks = parameters['showTracks'] as bool? ?? true;
    final celestialPalette = parameters['celestialPalette'] as String? ?? 'terrestrialMoons';
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
    final int sunlitColor;
    final int bodyColor;
    final int shadowColor;
    final int trackColor;

    switch (celestialPalette) {
      case 'gasGiantSatellites':
        sunlitColor = 0xFFFFF59D;
        bodyColor = 0xFFFFB74D;
        shadowColor = 0xFF4E342E;
        trackColor = 0x44FFE082;
        break;
      case 'crystallineIce':
        sunlitColor = 0xFFE0F7FA;
        bodyColor = 0xFF4DD0E1;
        shadowColor = 0xFF006064;
        trackColor = 0x4480DEEA;
        break;
      case 'volcanicIo':
        sunlitColor = 0xFFFFE082;
        bodyColor = 0xFFFF5722;
        shadowColor = 0xFFBF360C;
        trackColor = 0x44FF8A65;
        break;
      case 'terrestrialMoons':
      default:
        sunlitColor = 0xFFFFFFFF;
        bodyColor = 0xFFB0BEC5;
        shadowColor = 0xFF37474F;
        trackColor = 0x4490A4AE;
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

    // 2. Orbital Geometry Calculations
    final double phi = orbitTilt * math.pi / 180.0;
    final double cosPhi = math.cos(phi);
    final double sinPhi = math.sin(phi);

    final double a = orbitRadius;
    final double b = orbitRadius * 0.45;

    math.Point<int> getOrbitPoint(double theta) {
      final double xPrime = a * math.cos(theta);
      final double yPrime = b * math.sin(theta);
      final int px = (cx + xPrime * cosPhi - yPrime * sinPhi).round();
      final int py = (cy + xPrime * sinPhi + yPrime * cosPhi).round();
      return math.Point(px, py);
    }

    // 3. Render Orbital Guide Track & Asteroid Dust
    if (showTracks) {
      final int trackSteps = (2 * math.pi * a * 1.5).ceil().clamp(24, 240);
      for (int i = 0; i < trackSteps; i++) {
        final theta = i * 2 * math.pi / trackSteps;
        final pt = getOrbitPoint(theta);

        // Draw dotted/subtle orbital track line
        if (i % 2 == 0) {
          setPixel(pt.x, pt.y, trackColor);
        }

        // Asteroid belt dust motes
        if (i % 11 == 0) {
          final dustOffset = ((i * 17) % 3) - 1;
          setPixel(pt.x + dustOffset, pt.y + dustOffset, trackColor);
        }
      }
    }

    // 4. Render Spherical Shaded Moons
    const double lightDirX = -0.7071;
    const double lightDirY = -0.7071;

    for (int m = 0; m < moonCount; m++) {
      final thetaM = (m * 2 * math.pi / moonCount) + 0.35;
      final mCenter = getOrbitPoint(thetaM);

      final double moonRadius = (m % 2 == 0) ? 1.5 : 2.2;
      final int rCeil = moonRadius.ceil();

      for (int dy = -rCeil; dy <= rCeil; dy++) {
        for (int dx = -rCeil; dx <= rCeil; dx++) {
          final dist = math.sqrt(dx * dx + dy * dy);
          if (dist <= moonRadius) {
            // Directional lighting dot product
            final dot = (dx * lightDirX + dy * lightDirY) / moonRadius;

            final int pixelColor;
            if (dot > 0.25) {
              pixelColor = sunlitColor;
            } else if (dot > -0.25) {
              pixelColor = bodyColor;
            } else {
              pixelColor = shadowColor;
            }

            setPixel(mCenter.x + dx, mCenter.y + dy, pixelColor);
          }
        }
      }

      // 1px specular crescent glint
      setPixel(mCenter.x - 1, mCenter.y - 1, sunlitColor);
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
