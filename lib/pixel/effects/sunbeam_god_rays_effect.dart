part of 'effects.dart';

/// An effect that procedurally renders volumetric crepuscular god rays
/// (Tyndall scattering effect) slicing through canopy apertures or clouds,
/// accompanied by drifting specular dust motes with 3D Brownian motion.
class SunbeamGodRaysEffect extends Effect {
  SunbeamGodRaysEffect([Map<String, dynamic>? params])
      : super(
          EffectType.sunbeamGodRays,
          params ??
              {
                'rayAngle': 30.0,
                'rayIntensity': 0.65,
                'dustMoteCount': 45,
                'atmosphereTint': 'goldenDawn',
                'canopyShadowScale': 3.5,
                'decayRate': 1.1,
                'moteSpeed': 1.0,
                'time': 0.0,
                'preserveAlpha': false,
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() => {
        'rayAngle': 30.0,
        'rayIntensity': 0.65,
        'dustMoteCount': 45,
        'atmosphereTint': 'goldenDawn',
        'canopyShadowScale': 3.5,
        'decayRate': 1.1,
        'moteSpeed': 1.0,
        'time': 0.0,
        'preserveAlpha': false,
      };

  @override
  Map<String, dynamic> getMetadata() => {
        'rayAngle': {
          'label': 'Sunbeam Angle',
          'description': 'Incidence angle of crepuscular light shafts in degrees.',
          'type': 'slider',
          'min': -60.0,
          'max': 60.0,
          'step': 1.0,
        },
        'rayIntensity': {
          'label': 'Ray Intensity',
          'description': 'Brightness and optical density of Tyndall light beams.',
          'type': 'slider',
          'min': 0.1,
          'max': 1.0,
          'step': 0.05,
        },
        'dustMoteCount': {
          'label': 'Dust Mote Count',
          'description': 'Number of floating specular airborne particles.',
          'type': 'slider',
          'min': 0,
          'max': 100,
          'step': 1,
        },
        'atmosphereTint': {
          'label': 'Atmospheric Tint',
          'description': 'Color temperature and environment palette.',
          'type': 'select',
          'options': {
            'goldenDawn': 'Golden Dawn Sunbeams',
            'mistyJungleCyan': 'Misty Rainforest Cyan',
            'twilightAmber': 'Twilight Crepuscular Amber',
            'celestialWhite': 'Celestial Sanctuary White',
          },
        },
        'canopyShadowScale': {
          'label': 'Canopy Aperture Frequency',
          'description': 'Spacing and width of foliage canopy gaps and light slits.',
          'type': 'slider',
          'min': 1.0,
          'max': 8.0,
          'step': 0.5,
        },
        'decayRate': {
          'label': 'Ray Attenuation Rate',
          'description': 'How quickly light beams dissipate as they plunge through air.',
          'type': 'slider',
          'min': 0.4,
          'max': 2.5,
          'step': 0.1,
        },
        'moteSpeed': {
          'label': 'Dust Drift Velocity',
          'description': 'Speed of turbulent 3D Brownian flight currents.',
          'type': 'slider',
          'min': 0.2,
          'max': 3.0,
          'step': 0.1,
        },
        'time': {
          'label': 'Animation Timeline',
          'description': 'Temporal loop cycle driving dust drift and ray shimmering.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'step': 0.01,
        },
        'preserveAlpha': {
          'label': 'Preserve Alpha',
          'description': 'Confine god rays and dust motes strictly to sprite pixels.',
          'type': 'bool',
        },
      };

  @override
  List<UIField> getFields() => [
        SliderField(
          key: 'rayAngle',
          label: 'Sunbeam Angle',
          description: 'Incidence angle of crepuscular light shafts in degrees.',
          min: -60.0,
          max: 60.0,
          divisions: 24,
          formatLabel: (v) => '${v.round()}°',
        ),
        SliderField(
          key: 'rayIntensity',
          label: 'Ray Intensity',
          description: 'Brightness and optical density of Tyndall light beams.',
          min: 0.1,
          max: 1.0,
          divisions: 18,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        SliderField(
          key: 'dustMoteCount',
          label: 'Dust Mote Count',
          description: 'Number of floating specular airborne particles.',
          min: 0,
          max: 100,
          divisions: 20,
          formatLabel: (v) => '${v.round()}',
        ),
        const SelectField(
          key: 'atmosphereTint',
          label: 'Atmospheric Tint',
          description: 'Color temperature and environment palette.',
          options: {
            'goldenDawn': 'Golden Dawn Sunbeams',
            'mistyJungleCyan': 'Misty Rainforest Cyan',
            'twilightAmber': 'Twilight Crepuscular Amber',
            'celestialWhite': 'Celestial Sanctuary White',
          },
        ),
        SliderField(
          key: 'canopyShadowScale',
          label: 'Canopy Aperture Frequency',
          description: 'Spacing and width of foliage canopy gaps and light slits.',
          min: 1.0,
          max: 8.0,
          divisions: 14,
          formatLabel: (v) => '${v.toStringAsFixed(1)}x',
        ),
        SliderField(
          key: 'decayRate',
          label: 'Ray Attenuation Rate',
          description: 'How quickly light beams dissipate as they plunge through air.',
          min: 0.4,
          max: 2.5,
          divisions: 21,
          formatLabel: (v) => '${v.toStringAsFixed(1)}x',
        ),
        SliderField(
          key: 'moteSpeed',
          label: 'Dust Drift Velocity',
          description: 'Speed of turbulent 3D Brownian flight currents.',
          min: 0.2,
          max: 3.0,
          divisions: 14,
          formatLabel: (v) => '${v.toStringAsFixed(1)}x',
        ),
        SliderField(
          key: 'time',
          label: 'Animation Timeline',
          description: 'Temporal loop cycle driving dust drift and ray shimmering.',
          min: 0.0,
          max: 1.0,
          divisions: 100,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        const BoolField(
          key: 'preserveAlpha',
          label: 'Preserve Alpha',
          description: 'Confine god rays and dust motes strictly to sprite pixels.',
        ),
      ];

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    final output = Uint32List(width * height);

    final double rayAngle = (parameters['rayAngle'] as num?)?.toDouble() ?? 30.0;
    final double rayIntensity = ((parameters['rayIntensity'] as num?)?.toDouble() ?? 0.65).clamp(0.05, 1.0);
    final int dustMoteCount = ((parameters['dustMoteCount'] as num?)?.toInt() ?? 45).clamp(0, 100);
    final String atmosphereTint = parameters['atmosphereTint'] as String? ?? 'goldenDawn';
    final double canopyShadowScale = ((parameters['canopyShadowScale'] as num?)?.toDouble() ?? 3.5).clamp(0.5, 10.0);
    final double decayRate = ((parameters['decayRate'] as num?)?.toDouble() ?? 1.1).clamp(0.2, 4.0);
    final double moteSpeed = ((parameters['moteSpeed'] as num?)?.toDouble() ?? 1.0).clamp(0.1, 5.0);
    final double time = ((parameters['time'] as num?)?.toDouble() ?? 0.0).clamp(0.0, 1.0);
    final bool preserveAlpha = parameters['preserveAlpha'] as bool? ?? false;

    final tau = time * 2.0 * math.pi;
    final theta = rayAngle * math.pi / 180.0;
    final cosT = math.cos(theta);
    final sinT = math.sin(theta);
    final double scaleRef = math.min(width, height).toDouble();

    final palette = _getSunbeamPalette(atmosphereTint);

    // 1. Calculate ray shafts across canvas
    final rayField = Float64List(width * height);
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final double u = (-x * cosT + y * sinT) / scaleRef;

        // Multi-frequency canopy gobo aperture
        final double gobo = 0.52 * math.sin(u * canopyShadowScale * 3.14159 + 0.35 * math.sin(u * 11.0) + math.sin(tau) * 0.22) +
            0.32 * math.cos(u * canopyShadowScale * 6.28318 - 0.25 * math.cos(u * 7.5) - math.cos(tau) * 0.18) +
            0.16 * math.sin(u * canopyShadowScale * 13.8 + 1.2 + math.sin(tau * 2.0) * 0.12);

        final double normalizedGobo = ((gobo + 1.0) * 0.5).clamp(0.0, 1.0);
        final double shaft = math.pow((normalizedGobo - 0.28).clamp(0.0, 1.0) / 0.72, 1.85).toDouble();

        // Along-ray attenuation
        final double distNorm = ((y + (x - width * 0.5) * sinT) / height).clamp(0.0, 2.5);
        final double attenuation = math.exp(-distNorm * decayRate);

        // Subtle ambient atmospheric haze floor
        final double hazeFloor = 0.08 * (1.0 - y / (height * 1.5));
        final double intensity = (shaft * attenuation + hazeFloor) * rayIntensity;

        rayField[y * width + x] = intensity.clamp(0.0, 1.5);
      }
    }

    // 2. Precompute dust motes and their specular flares
    final motes = <_DustMote>[];
    for (int i = 0; i < dustMoteCount; i++) {
      final double seedX = _hashToUnit(i * 13 + 1) * width;
      final double seedY = _hashToUnit(i * 37 + 7) * height;
      final double phase1 = _hashToUnit(i * 71 + 3) * 2.0 * math.pi;
      final double phase2 = _hashToUnit(i * 89 + 17) * 2.0 * math.pi;
      final double phase3 = _hashToUnit(i * 101 + 23) * 2.0 * math.pi;
      final double size = 0.8 + _hashToUnit(i * 53 + 9) * 1.2;

      // 3D Brownian cyclic drift
      double px = (seedX + math.sin(tau * moteSpeed + phase1) * 12.0 + math.cos(tau * 0.5 + phase2) * 8.0) % width;
      if (px < 0) px += width;

      double py = (seedY - time * height * 0.4 * moteSpeed + math.sin(tau * moteSpeed * 1.4 + phase3) * 7.0) % height;
      if (py < 0) py += height;

      // Check ray field at mote coordinate
      final int ix = px.floor().clamp(0, width - 1);
      final int iy = py.floor().clamp(0, height - 1);
      final double localRay = rayField[iy * width + ix];

      // Twinkle pulsation
      final double twinkle = 0.5 + 0.5 * math.sin(tau * 3.0 + phase1 * 2.0);
      final double flareMult = (localRay > 0.2) ? (1.0 + localRay * 2.8) : 0.4;
      final double brightness = (twinkle * flareMult).clamp(0.0, 3.0);

      motes.add(_DustMote(px, py, size, brightness));
    }

    // 3. Render pixels
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int idx = y * width + x;
        final int origPixel = pixels[idx];
        final int origA = (origPixel >> 24) & 0xFF;
        final int origR = (origPixel >> 16) & 0xFF;
        final int origG = (origPixel >> 8) & 0xFF;
        final int origB = origPixel & 0xFF;

        final double rayVal = rayField[idx];

        // Evaluate dust mote influence on this pixel
        double moteContrib = 0.0;
        for (int i = 0; i < motes.length; i++) {
          final m = motes[i];
          final double dx = (x - m.x).abs();
          final double dy = (y - m.y).abs();
          if (dx <= 2.2 && dy <= 2.2) {
            final double distSq = dx * dx + dy * dy;
            final double radSq = m.size * m.size;
            if (distSq <= radSq * 2.5) {
              final double falloff = math.max(0.0, 1.0 - math.sqrt(distSq) / (m.size * 1.5));
              moteContrib += falloff * m.brightness;
            }
          }
        }
        moteContrib = moteContrib.clamp(0.0, 2.5);

        if (preserveAlpha) {
          if (origA == 0) {
            output[idx] = 0;
            continue;
          }

          // Screen/additive light wash over sprite silhouette
          final double lightFactor = (rayVal * 0.85).clamp(0.0, 1.0);
          final double rLight = origR + (palette.sunlight.r - origR) * lightFactor * (palette.sunlight.r / 255.0);
          final double gLight = origG + (palette.sunlight.g - origG) * lightFactor * (palette.sunlight.g / 255.0);
          final double bLight = origB + (palette.sunlight.b - origB) * lightFactor * (palette.sunlight.b / 255.0);

          // Add dust motes
          final int finalR = (rLight + palette.moteColor.r * moteContrib * 0.7).clamp(0.0, 255.0).round();
          final int finalG = (gLight + palette.moteColor.g * moteContrib * 0.7).clamp(0.0, 255.0).round();
          final int finalB = (bLight + palette.moteColor.b * moteContrib * 0.7).clamp(0.0, 255.0).round();

          output[idx] = (origA << 24) | (finalR << 16) | (finalG << 8) | finalB;
        } else {
          // Full atmospheric background rendering
          final double normY = y / height.toDouble();

          // Gradient sky / environment background
          final double bgR = palette.ambientDeep.r + (palette.ambientMid.r - palette.ambientDeep.r) * (1.0 - normY);
          final double bgG = palette.ambientDeep.g + (palette.ambientMid.g - palette.ambientDeep.g) * (1.0 - normY);
          final double bgB = palette.ambientDeep.b + (palette.ambientMid.b - palette.ambientDeep.b) * (1.0 - normY);

          // Composite sprite if present
          double baseR = bgR;
          double baseG = bgG;
          double baseB = bgB;
          if (origA > 0) {
            final double alphaNorm = origA / 255.0;
            baseR = baseR * (1.0 - alphaNorm) + origR * alphaNorm;
            baseG = baseG * (1.0 - alphaNorm) + origG * alphaNorm;
            baseB = baseB * (1.0 - alphaNorm) + origB * alphaNorm;
          }

          // Volumetric god ray additive illumination
          final double rayR = palette.sunlight.r * rayVal * 0.9;
          final double rayG = palette.sunlight.g * rayVal * 0.9;
          final double rayB = palette.sunlight.b * rayVal * 0.9;

          // Dust motes
          final double moteR = palette.moteColor.r * moteContrib * 0.85;
          final double moteG = palette.moteColor.g * moteContrib * 0.85;
          final double moteB = palette.moteColor.b * moteContrib * 0.85;

          final int r = (baseR + rayR + moteR).clamp(0.0, 255.0).round();
          final int g = (baseG + rayG + moteG).clamp(0.0, 255.0).round();
          final int b = (baseB + rayB + moteB).clamp(0.0, 255.0).round();

          output[idx] = (0xFF << 24) | (r << 16) | (g << 8) | b;
        }
      }
    }

    return output;
  }

  static double _hashToUnit(int n) {
    int x = (n << 13) ^ n;
    x = (x * (x * x * 15731 + 789221) + 1376312589) & 0x7fffffff;
    return (x & 0xffff) / 65535.0;
  }

  static _SunbeamPalette _getSunbeamPalette(String tint) {
    switch (tint) {
      case 'mistyJungleCyan':
        return const _SunbeamPalette(
          sunlight: _RGB(175, 255, 230),
          moteColor: _RGB(200, 255, 245),
          ambientMid: _RGB(20, 60, 48),
          ambientDeep: _RGB(10, 26, 22),
        );
      case 'twilightAmber':
        return const _SunbeamPalette(
          sunlight: _RGB(255, 175, 95),
          moteColor: _RGB(255, 215, 150),
          ambientMid: _RGB(65, 30, 45),
          ambientDeep: _RGB(25, 14, 32),
        );
      case 'celestialWhite':
        return const _SunbeamPalette(
          sunlight: _RGB(240, 248, 255),
          moteColor: _RGB(255, 255, 255),
          ambientMid: _RGB(35, 48, 75),
          ambientDeep: _RGB(16, 20, 36),
        );
      case 'goldenDawn':
      default:
        return const _SunbeamPalette(
          sunlight: _RGB(255, 238, 170),
          moteColor: _RGB(255, 250, 200),
          ambientMid: _RGB(55, 38, 24),
          ambientDeep: _RGB(28, 18, 22),
        );
    }
  }
}

class _SunbeamPalette {
  final _RGB sunlight;
  final _RGB moteColor;
  final _RGB ambientMid;
  final _RGB ambientDeep;

  const _SunbeamPalette({
    required this.sunlight,
    required this.moteColor,
    required this.ambientMid,
    required this.ambientDeep,
  });
}

class _DustMote {
  final double x;
  final double y;
  final double size;
  final double brightness;

  _DustMote(this.x, this.y, this.size, this.brightness);
}
