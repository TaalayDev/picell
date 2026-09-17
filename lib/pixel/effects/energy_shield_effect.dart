part of 'effects.dart';

/// Procedural energy shield and forcefield barrier featuring hexagonal
/// matrix wireframes, spherical plasma bubble fresnel, and kinetic impact ripples.
class EnergyShieldEffect extends Effect implements UIFieldProvider {
  EnergyShieldEffect([Map<String, dynamic>? parameters])
      : super(
          EffectType.energyShield,
          parameters ??
              const {
                'shieldShape': 'hexMatrix',
                'barrierColor': 0xFF00B0FF,
                'pulseRate': 1.5,
                'impactRipple': 0.6,
                'shieldThickness': 2,
                'time': 0.0,
                'preserveAlpha': true,
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() => {
        'shieldShape': 'hexMatrix',
        'barrierColor': 0xFF00B0FF,
        'pulseRate': 1.5,
        'impactRipple': 0.6,
        'shieldThickness': 2,
        'time': 0.0,
        'preserveAlpha': true,
      };

  @override
  Map<String, dynamic> getMetadata() => {
        'shieldShape': {
          'label': 'Shield Geometry',
          'description': 'Lattice and barrier structure of the protective field.',
          'type': 'select',
          'options': {
            'hexMatrix': 'Hexagonal Matrix Shield',
            'spherical': 'Spherical Plasma Bubble',
            'contourAura': 'Sprite Contour Aura',
          },
        },
        'barrierColor': {
          'label': 'Energy Barrier Color',
          'description': 'Luminescent hue of the energy shield.',
          'type': 'color',
        },
        'pulseRate': {
          'label': 'Harmonic Pulse Rate',
          'description': 'Speed of kinetic ripple waves traveling across the barrier.',
          'type': 'slider',
          'min': 0.5,
          'max': 3.0,
          'divisions': 50,
        },
        'impactRipple': {
          'label': 'Kinetic Ripple Amplitude',
          'description': 'Intensity of dynamic shockwave ripples upon the shield surface.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 20,
        },
        'shieldThickness': {
          'label': 'Barrier Thickness',
          'description': 'Pixel width of the perimeter forcefield boundary.',
          'type': 'slider',
          'min': 1,
          'max': 4,
          'divisions': 3,
        },
        'time': {
          'label': 'Animation Time',
          'description': 'Timeline progress parameter for ripple wave propagation.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 100,
        },
        'preserveAlpha': {
          'label': 'Preserve Transparency',
          'description': 'Allow forcefield to float cleanly over transparent backgrounds.',
          'type': 'bool',
        },
      };

  @override
  List<UIField> getFields() => [
        const SelectField(
          key: 'shieldShape',
          label: 'Shield Shape',
          description: 'Structural geometry of the protective deflector barrier.',
          options: {
            'hexMatrix': 'Hexagonal Matrix Shield',
            'spherical': 'Spherical Plasma Bubble',
            'contourAura': 'Sprite Contour Aura',
          },
        ),
        const ColorField(
          key: 'barrierColor',
          label: 'Forcefield Color',
          description: 'Color of the glowing energy field and ripple crests.',
        ),
        SliderField(
          key: 'pulseRate',
          label: 'Pulse Frequency',
          description: 'Propagation speed of traveling kinetic ripple waves.',
          min: 0.5,
          max: 3.0,
          divisions: 50,
          formatLabel: (v) => '${v.toStringAsFixed(1)}x',
        ),
        SliderField(
          key: 'impactRipple',
          label: 'Impact Ripple',
          description: 'Visibility and depth of expanding impact shockwaves.',
          min: 0.0,
          max: 1.0,
          divisions: 20,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        SliderField(
          key: 'shieldThickness',
          label: 'Shield Thickness',
          description: 'Width of the outer protective force rim in pixels.',
          min: 1,
          max: 4,
          divisions: 3,
          formatLabel: (v) => '${v.round()} px',
        ),
        SliderField(
          key: 'time',
          label: 'Animation Time',
          description: 'Timeline progress parameter for animated frame generation.',
          min: 0.0,
          max: 1.0,
          divisions: 100,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        const BoolField(
          key: 'preserveAlpha',
          label: 'Preserve Transparency',
          description: 'When enabled, the shield renders over transparent canvas.',
        ),
      ];

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    if (width <= 0 || height <= 0 || pixels.isEmpty) return pixels;

    final shieldShape = (parameters['shieldShape'] as String?) ?? 'hexMatrix';
    final barrierColorInt = (parameters['barrierColor'] as int?) ?? 0xFF00B0FF;
    final pulseRate = ((parameters['pulseRate'] as num?)?.toDouble() ?? 1.5).clamp(0.5, 3.0);
    final impactRipple = ((parameters['impactRipple'] as num?)?.toDouble() ?? 0.6).clamp(0.0, 1.0);
    final shieldThickness = ((parameters['shieldThickness'] as num?)?.toInt() ?? 2).clamp(1, 4);
    final time = ((parameters['time'] as num?)?.toDouble() ?? 0.0).clamp(0.0, 1.0);
    final preserveAlpha = parameters['preserveAlpha'] as bool? ?? true;

    final barR = (barrierColorInt >> 16) & 0xFF;
    final barG = (barrierColorInt >> 8) & 0xFF;
    final barB = barrierColorInt & 0xFF;

    final result = Uint32List(width * height);
    if (preserveAlpha) {
      result.setAll(0, pixels);
    } else {
      const darkBackdrop = 0xFF080D1A;
      const bgR = (darkBackdrop >> 16) & 0xFF;
      const bgG = (darkBackdrop >> 8) & 0xFF;
      const bgB = darkBackdrop & 0xFF;
      result.fillRange(0, result.length, darkBackdrop);
      for (int i = 0; i < pixels.length; i++) {
        final p = pixels[i];
        final a = (p >> 24) & 0xFF;
        if (a > 0) {
          final na = a / 255.0;
          final pr = (p >> 16) & 0xFF;
          final pg = (p >> 8) & 0xFF;
          final pb = p & 0xFF;
          final outR = (pr * na + bgR * (1.0 - na)).round().clamp(0, 255);
          final outG = (pg * na + bgG * (1.0 - na)).round().clamp(0, 255);
          final outB = (pb * na + bgB * (1.0 - na)).round().clamp(0, 255);
          result[i] = 0xFF000000 | (outR << 16) | (outG << 8) | outB;
        }
      }
    }

    // Find bounding box of non-transparent foreground sprite
    int minX = width, maxX = 0, minY = height, maxY = 0;
    bool hasFg = false;
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        if ((pixels[y * width + x] >> 24) & 0xFF > 30) {
          hasFg = true;
          if (x < minX) minX = x;
          if (x > maxX) maxX = x;
          if (y < minY) minY = y;
          if (y > maxY) maxY = y;
        }
      }
    }

    if (!hasFg) {
      minX = 2;
      maxX = width - 3;
      minY = 2;
      maxY = height - 3;
    }

    final cx = (minX + maxX) / 2.0;
    final cy = (minY + maxY) / 2.0;
    final rx = math.max(3.0, (maxX - minX) / 2.0 + 3.0);
    final ry = math.max(3.0, (maxY - minY) / 2.0 + 3.0);

    void blendShieldPixel(int x, int y, int alpha, {bool isCore = false}) {
      if (x < 0 || x >= width || y < 0 || y >= height) return;
      final idx = y * width + x;

      final existing = result[idx];
      final exA = (existing >> 24) & 0xFF;
      final exR = (existing >> 16) & 0xFF;
      final exG = (existing >> 8) & 0xFF;
      final exB = existing & 0xFF;

      final r = isCore ? 255 : barR;
      final g = isCore ? 255 : barG;
      final b = isCore ? 255 : barB;

      final na = (alpha / 255.0).clamp(0.0, 1.0);
      final outR = math.min(255, (exR + r * na).round());
      final outG = math.min(255, (exG + g * na).round());
      final outB = math.min(255, (exB + b * na).round());
      final outA = math.max(exA, alpha);

      result[idx] = (outA << 24) | (outR << 16) | (outG << 8) | outB;
    }

    // Ripple wave phase
    final wavePhase = time * 2.0 * math.pi * pulseRate;

    if (shieldShape == 'contourAura') {
      // Contour-based energy aura: Distance field from sprite contour
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final p = pixels[y * width + x];
          final a = (p >> 24) & 0xFF;
          if (a > 30) continue; // Skip solid sprite interior

          // Search nearest sprite pixel within distance 1..shieldThickness + 2
          double minDist = 999.0;
          final searchR = shieldThickness + 2;
          for (int dy = -searchR; dy <= searchR; dy++) {
            final sy = y + dy;
            if (sy < 0 || sy >= height) continue;
            for (int dx = -searchR; dx <= searchR; dx++) {
              final sx = x + dx;
              if (sx < 0 || sx >= width) continue;
              if ((pixels[sy * width + sx] >> 24) & 0xFF > 50) {
                final d = math.sqrt((dx * dx + dy * dy).toDouble());
                if (d < minDist) minDist = d;
              }
            }
          }

          if (minDist <= shieldThickness + 1.0) {
            final edgeFalloff = (1.0 - (minDist / (shieldThickness + 1.5))).clamp(0.0, 1.0);
            final ripple = math.sin(minDist * 3.0 - wavePhase) * 0.5 + 0.5;
            final alpha = ((edgeFalloff * 0.7 + ripple * impactRipple * 0.3) * 220).round().clamp(0, 255);
            blendShieldPixel(x, y, alpha, isCore: minDist <= 1.2);
          }
        }
      }
    } else {
      // Elliptical Bubble or Hex Matrix
      const hexSize = 5.0;
      const sqrt3 = 1.7320508;

      for (int y = 0; y < height; y++) {
        final dy = (y - cy) / ry;
        for (int x = 0; x < width; x++) {
          final dx = (x - cx) / rx;
          final d = math.sqrt(dx * dx + dy * dy);

          if (d > 1.25) continue; // Outside shield area

          // Kinetic impact ripple
          final rippleWave = math.sin(d * 10.0 - wavePhase) * 0.5 + 0.5;
          final rippleBoost = rippleWave * impactRipple;

          // 1. Perimeter Fresnel rim
          final rimDist = (d - 1.0).abs();
          if (rimDist <= (shieldThickness * 0.12)) {
            final rimFactor = (1.0 - (rimDist / (shieldThickness * 0.12))).clamp(0.0, 1.0);
            final rimAlpha = ((rimFactor * 0.8 + rippleBoost * 0.2) * 255).round().clamp(0, 255);
            blendShieldPixel(x, y, rimAlpha, isCore: rimDist < 0.03);
          }

          // 2. Interior Fill Sheen & Hexagonal Lattice
          if (d < 1.0) {
            if (shieldShape == 'hexMatrix') {
              // Hexagonal axial coordinate math
              final hx = (x - cx);
              final hy = (y - cy);
              final q = (sqrt3 / 3.0 * hx - 1.0 / 3.0 * hy) / hexSize;
              final r = (2.0 / 3.0 * hy) / hexSize;

              // Fractional distance to nearest hex cell edge
              final fq = q - q.round();
              final fr = r - r.round();
              final fs = -q - r - (-q - r).round();
              final edgeDist = math.min((fq.abs() - 0.5).abs(), math.min((fr.abs() - 0.5).abs(), (fs.abs() - 0.5).abs()));

              if (edgeDist < 0.2) {
                // Hex wireframe boundary
                final wireFactor = (1.0 - edgeDist / 0.2);
                final hexAlpha = ((wireFactor * 0.5 + rippleBoost * 0.5) * 190).round().clamp(0, 255);
                blendShieldPixel(x, y, hexAlpha, isCore: edgeDist < 0.06);
              } else {
                // Subtle hex interior shimmer
                final interiorAlpha = ((0.12 + rippleBoost * 0.25) * 100).round().clamp(0, 255);
                blendShieldPixel(x, y, interiorAlpha);
              }
            } else {
              // Spherical plasma sheen
              final interiorAlpha = ((d * 0.3 + rippleBoost * 0.4) * 120).round().clamp(0, 255);
              blendShieldPixel(x, y, interiorAlpha);
            }
          }
        }
      }
    }

    return result;
  }
}
