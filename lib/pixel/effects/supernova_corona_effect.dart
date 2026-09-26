part of 'effects.dart';

/// Renders a blazing celestial supernova corona flare with multi-point diffraction
/// starburst spikes, radial solar chromosphere halo, and coronal plasma prominences.
class SupernovaCoronaEffect extends Effect {
  SupernovaCoronaEffect([Map<String, dynamic>? params])
      : super(
          EffectType.supernovaCorona,
          params ??
              {
                'coronaRadius': 10.0,
                'spikeLength': 16.0,
                'spikePattern': 'cross4',
                'prominences': true,
                'coronaPalette': 'solarWhite',
                'behindOnly': false,
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() => {
        'coronaRadius': 10.0,
        'spikeLength': 16.0,
        'spikePattern': 'cross4',
        'prominences': true,
        'coronaPalette': 'solarWhite',
        'behindOnly': false,
      };

  @override
  Map<String, dynamic> getMetadata() => {
        'coronaRadius': {
          'label': 'Corona Halo Radius',
          'description': 'Radius of the glowing central solar chromosphere aura.',
          'type': 'slider',
          'min': 5.0,
          'max': 24.0,
          'step': 1.0,
        },
        'spikeLength': {
          'label': 'Diffraction Spike Length',
          'description': 'Reach of the tapered anamorphic starlight diffraction rays.',
          'type': 'slider',
          'min': 6.0,
          'max': 36.0,
          'step': 1.0,
        },
        'spikePattern': {
          'label': 'Diffraction Pattern',
          'description': 'Number and arrangement of diffraction starlight spikes.',
          'type': 'select',
          'options': {
            'cross4': '4-Point Celestial Cross',
            'star8': '8-Point Supernova Star',
            'anamorphic2': '2-Axis Anamorphic Flare',
          },
        },
        'prominences': {
          'label': 'Plasma Prominences',
          'description': 'Spawns curved coronal solar flares and plasma filaments.',
          'type': 'bool',
        },
        'coronaPalette': {
          'label': 'Stellar Spectrum',
          'description': 'Spectral temperature and starlight emission palette.',
          'type': 'select',
          'options': {
            'solarWhite': 'Solar White (G-Type Star)',
            'hypernovaBlue': 'Hypernova Blue (O-Type Supergiant)',
            'pulsarMagenta': 'Pulsar Magenta (Magnetar Relic)',
            'goldenDawn': 'Golden Dawn (Solar Sunrise)',
          },
        },
        'behindOnly': {
          'label': 'Behind Foreground',
          'description': 'Renders flare graphics behind existing opaque character pixels.',
          'type': 'bool',
        },
      };

  @override
  List<UIField> getFields() => const [
        SliderField(
          key: 'coronaRadius',
          label: 'Corona Halo Radius',
          min: 5.0,
          max: 24.0,
        ),
        SliderField(
          key: 'spikeLength',
          label: 'Diffraction Spike Length',
          min: 6.0,
          max: 36.0,
        ),
        SelectField(
          key: 'spikePattern',
          label: 'Diffraction Pattern',
          options: <String, String>{
            'cross4': '4-Point Celestial Cross',
            'star8': '8-Point Supernova Star',
            'anamorphic2': '2-Axis Anamorphic Flare',
          },
        ),
        BoolField(
          key: 'prominences',
          label: 'Plasma Prominences',
        ),
        SelectField(
          key: 'coronaPalette',
          label: 'Stellar Spectrum',
          options: <String, String>{
            'solarWhite': 'Solar White (G-Type Star)',
            'hypernovaBlue': 'Hypernova Blue (O-Type Supergiant)',
            'pulsarMagenta': 'Pulsar Magenta (Magnetar Relic)',
            'goldenDawn': 'Golden Dawn (Solar Sunrise)',
          },
        ),
        BoolField(
          key: 'behindOnly',
          label: 'Behind Foreground',
        ),
      ];

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    final coronaRadius = (parameters['coronaRadius'] as num?)?.toDouble() ?? 10.0;
    final spikeLength = (parameters['spikeLength'] as num?)?.toDouble() ?? 16.0;
    final spikePattern = parameters['spikePattern'] as String? ?? 'cross4';
    final prominences = parameters['prominences'] as bool? ?? true;
    final coronaPalette = parameters['coronaPalette'] as String? ?? 'solarWhite';
    final behindOnly = parameters['behindOnly'] as bool? ?? false;

    final output = Uint32List.fromList(pixels);

    // 1. Identify focal star centroid
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
    const int whiteCore = 0xFFFFFFFF;
    final int innerColor;
    final int haloColor;
    final int rayColor;

    switch (coronaPalette) {
      case 'hypernovaBlue':
        innerColor = 0xFF80D8FF;
        haloColor = 0x880091EA;
        rayColor = 0xFFB3E5FC;
        break;
      case 'pulsarMagenta':
        innerColor = 0xFFEA80FC;
        haloColor = 0x88AA00FF;
        rayColor = 0xFFF8BBD0;
        break;
      case 'goldenDawn':
        innerColor = 0xFFFFD180;
        haloColor = 0x88FF6D00;
        rayColor = 0xFFFFE0B2;
        break;
      case 'solarWhite':
      default:
        innerColor = 0xFFFFF176;
        haloColor = 0x88FFB300;
        rayColor = 0xFFFFE082;
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

    // 2. Radial Solar Corona Glow
    final int rCeil = coronaRadius.ceil();
    for (int dy = -rCeil; dy <= rCeil; dy++) {
      for (int dx = -rCeil; dx <= rCeil; dx++) {
        final dist = math.sqrt(dx * dx + dy * dy);
        if (dist <= coronaRadius) {
          final t = (1.0 - dist / coronaRadius);
          final alpha = (t * t * 255).round().clamp(0, 255);
          if (alpha > 5) {
            final color = dist < (coronaRadius * 0.45)
                ? ((alpha << 24) | (innerColor & 0x00FFFFFF))
                : ((alpha ~/ 2 << 24) | (haloColor & 0x00FFFFFF));
            setPixel(cx + dx, cy + dy, color);
          }
        }
      }
    }

    // 3. Diffraction Spikes
    final List<double> spikeAngles = [];
    switch (spikePattern) {
      case 'anamorphic2':
        spikeAngles.addAll([0.0, math.pi]);
        break;
      case 'star8':
        for (int i = 0; i < 8; i++) {
          spikeAngles.add(i * math.pi / 4);
        }
        break;
      case 'cross4':
      default:
        for (int i = 0; i < 4; i++) {
          spikeAngles.add(i * math.pi / 2);
        }
        break;
    }

    final double effectiveSpikeLength = spikePattern == 'anamorphic2' ? spikeLength * 1.5 : spikeLength;

    for (final angle in spikeAngles) {
      final cosA = math.cos(angle);
      final sinA = math.sin(angle);
      final len = effectiveSpikeLength.round();

      for (int s = 1; s <= len; s++) {
        final sx = (cx + s * cosA).round();
        final sy = (cy + s * sinA).round();

        final falloff = 1.0 - (s / len);
        final alpha = (falloff * 255).round().clamp(0, 255);

        if (alpha > 10) {
          final rayPx = (alpha << 24) | (rayColor & 0x00FFFFFF);
          setPixel(sx, sy, rayPx);

          // Thicker glare near base of primary cross axes
          if (s <= len ~/ 3) {
            final perpX = (-sinA).round();
            final perpY = cosA.round();
            final haloAlpha = (alpha ~/ 3).clamp(0, 255);
            final haloPx = (haloAlpha << 24) | (haloColor & 0x00FFFFFF);
            setPixel(sx + perpX, sy + perpY, haloPx);
            setPixel(sx - perpX, sy - perpY, haloPx);
          }
        }
      }
    }

    // 4. Coronal Plasma Prominences
    if (prominences) {
      const promCount = 6;
      for (int p = 0; p < promCount; p++) {
        final pAngle = (p * 2 * math.pi / promCount) + 0.35;
        final cosP = math.cos(pAngle);
        final sinP = math.sin(pAngle);
        final loopLen = (coronaRadius * 0.7).round();

        for (int step = 0; step < loopLen; step++) {
          final curve = math.sin(step * math.pi / loopLen) * 2.0;
          final px = (cx + (coronaRadius * 0.7 + step) * cosP - curve * sinP).round();
          final py = (cy + (coronaRadius * 0.7 + step) * sinP + curve * cosP).round();
          setPixel(px, py, innerColor);
        }
      }
    }

    // 5. Blazing White-Hot Core Diamond Spark
    setPixel(cx, cy, whiteCore);
    setPixel(cx - 1, cy, whiteCore);
    setPixel(cx + 1, cy, whiteCore);
    setPixel(cx, cy - 1, whiteCore);
    setPixel(cx, cy + 1, whiteCore);
    setPixel(cx - 2, cy, innerColor);
    setPixel(cx + 2, cy, innerColor);
    setPixel(cx, cy - 2, innerColor);
    setPixel(cx, cy + 2, innerColor);

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
