part of 'effects.dart';

/// Procedural solar eclipse and cosmic corona pulse effect featuring a celestial
/// occulting disc, undulating plasma prominences, dynamic diamond ring flare, and atmospheric glow.
class SolarEclipseEffect extends Effect implements UIFieldProvider {
  SolarEclipseEffect([Map<String, dynamic>? parameters])
      : super(
          EffectType.solarEclipse,
          parameters ??
              const {
                'coronaRadius': 0.25,
                'flareTurbulence': 0.5,
                'eclipsePhase': 0.0,
                'glowColor': 0xFFFFB300,
                'diamondRing': true,
                'time': 0.0,
                'preserveAlpha': true,
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() => {
        'coronaRadius': 0.25,
        'flareTurbulence': 0.5,
        'eclipsePhase': 0.0,
        'glowColor': 0xFFFFB300,
        'diamondRing': true,
        'time': 0.0,
        'preserveAlpha': true,
      };

  @override
  Map<String, dynamic> getMetadata() => {
        'coronaRadius': {
          'label': 'Corona Base Radius',
          'description': 'Base diameter proportion of the solar core.',
          'type': 'slider',
          'min': 0.15,
          'max': 0.45,
          'divisions': 30,
        },
        'flareTurbulence': {
          'label': 'Flare Prominence Turbulence',
          'description': 'Height and turbulence amplitude of undulating plasma prominences.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 20,
        },
        'eclipsePhase': {
          'label': 'Eclipse Transit Phase',
          'description': 'Position of the occulting lunar disc (-1.0 entering to 1.0 exiting).',
          'type': 'slider',
          'min': -1.0,
          'max': 1.0,
          'divisions': 40,
        },
        'glowColor': {
          'label': 'Corona Atmosphere Color',
          'description': 'Color of the radiant solar flares and chromatic corona.',
          'type': 'color',
        },
        'diamondRing': {
          'label': 'Diamond Ring Flare',
          'description': 'Render high-luminance diamond ring starburst at transit edge.',
          'type': 'bool',
        },
        'time': {
          'label': 'Animation Time',
          'description': 'Timeline progress parameter for eclipse transit and plasma pulsation.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 100,
        },
        'preserveAlpha': {
          'label': 'Preserve Transparency',
          'description': 'Confine eclipse lighting over original sprite silhouette.',
          'type': 'bool',
        },
      };

  @override
  List<UIField> getFields() => [
        SliderField(
          key: 'coronaRadius',
          label: 'Corona Radius',
          description: 'Base size of the radiant celestial disk.',
          min: 0.15,
          max: 0.45,
          divisions: 30,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        SliderField(
          key: 'flareTurbulence',
          label: 'Flare Turbulence',
          description: 'Prominence height and wavy plasma instability.',
          min: 0.0,
          max: 1.0,
          divisions: 20,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        SliderField(
          key: 'eclipsePhase',
          label: 'Eclipse Phase',
          description: 'Manual transit position of the moon disc.',
          min: -1.0,
          max: 1.0,
          divisions: 40,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        const ColorField(
          key: 'glowColor',
          label: 'Corona Color',
          description: 'Energy color of the fiery corona and flares.',
        ),
        const BoolField(
          key: 'diamondRing',
          label: 'Diamond Ring Burst',
          description: 'Display bright flare glint at the sliver edge.',
        ),
        SliderField(
          key: 'time',
          label: 'Animation Time',
          description: 'Timeline progress of the solar transit cycle.',
          min: 0.0,
          max: 1.0,
          divisions: 100,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        const BoolField(
          key: 'preserveAlpha',
          label: 'Preserve Transparency',
          description: 'Retain transparent background outside character silhouette.',
        ),
      ];

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    final coronaRadius = (parameters['coronaRadius'] as num?)?.toDouble() ?? 0.25;
    final flareTurbulence = (parameters['flareTurbulence'] as num?)?.toDouble() ?? 0.5;
    final manualPhase = (parameters['eclipsePhase'] as num?)?.toDouble() ?? 0.0;
    final glowColorInt = (parameters['glowColor'] as num?)?.toInt() ?? 0xFFFFB300;
    final diamondRing = parameters['diamondRing'] as bool? ?? true;
    final time = (parameters['time'] as num?)?.toDouble() ?? 0.0;
    final preserveAlpha = parameters['preserveAlpha'] as bool? ?? true;

    final output = Uint32List(width * height);

    final gA = (glowColorInt >> 24) & 0xFF;
    final gR = (glowColorInt >> 16) & 0xFF;
    final gG = (glowColorInt >> 8) & 0xFF;
    final gB = glowColorInt & 0xFF;

    final cx = width / 2.0;
    final cy = height / 2.0;
    final maxDim = math.max(width, height).toDouble();
    final rSun = maxDim * coronaRadius;
    final rMoon = rSun * 1.03;

    // Phase: if time is progressing (> 0.0), sweep moon across (-1.1 -> 1.1)
    final transitPhase = (time > 0.0) ? (-1.1 + 2.2 * (time - time.floorToDouble())) : manualPhase;
    final mx = cx + transitPhase * rSun * 1.25;
    final my = cy - transitPhase * rSun * 0.15;

    // Diamond ring flare coordinates (at the solar limb where the moon just covers/uncovers)
    final isNearTotality = (transitPhase.abs() >= 0.12 && transitPhase.abs() <= 0.45);
    final flareAngle = transitPhase > 0 ? (math.pi * 0.2) : (math.pi * 1.2);
    final flareX = cx + math.cos(flareAngle) * rSun;
    final flareY = cy + math.sin(flareAngle) * rSun;

    final timeRad = time * math.pi * 2.0;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final idx = y * width + x;
        final origPixel = pixels[idx];
        final origA = (origPixel >> 24) & 0xFF;

        if (preserveAlpha && origA == 0) {
          output[idx] = 0x00000000;
          continue;
        }

        final dxSun = x - cx;
        final dySun = y - cy;
        final distSun = math.sqrt(dxSun * dxSun + dySun * dySun);

        final dxMoon = x - mx;
        final dyMoon = y - my;
        final distMoon = math.sqrt(dxMoon * dxMoon + dyMoon * dyMoon);

        final oR = (origPixel >> 16) & 0xFF;
        final oG = (origPixel >> 8) & 0xFF;
        final oB = origPixel & 0xFF;

        // Check if inside the pitch-black occulting moon disc
        if (distMoon <= rMoon) {
          if (preserveAlpha) {
            // Moon shadow casts a dark eclipse umbra over the sprite
            final umbraFactor = (distMoon / rMoon).clamp(0.0, 1.0);
            final shade = (0.2 + 0.3 * umbraFactor);
            final newR = (oR * shade).round().clamp(0, 255);
            final newG = (oG * shade).round().clamp(0, 255);
            final newB = (oB * shade).round().clamp(0, 255);
            output[idx] = (origA << 24) | (newR << 16) | (newG << 8) | newB;
          } else {
            // Celestial sky mode: deep space black moon silhouette
            output[idx] = (255 << 24) | (8 << 16) | (6 << 8) | 12;
          }
          continue;
        }

        // Plasma prominence calculation along angle
        final angle = math.atan2(dySun, dxSun);
        final promWave = math.sin(angle * 4.0 + timeRad * 2.0) * 0.4 +
            math.cos(angle * 9.0 - timeRad * 3.0) * 0.35 +
            math.sin(angle * 15.0 + timeRad) * 0.25;
        final promRadius = rSun * (1.0 + flareTurbulence * 0.8 * promWave.clamp(-0.5, 1.2));

        double glowIntensity = 0.0;
        if (distSun >= rSun * 0.85) {
          final distFromEdge = (distSun - promRadius);
          if (distFromEdge <= 0) {
            // Inside the fiery coronal ring
            glowIntensity = 1.0;
          } else {
            // Exponential falloff outward
            final normDist = distFromEdge / (maxDim * 0.4);
            glowIntensity = math.max(0.0, 1.0 / (1.0 + normDist * 8.0) - normDist * 0.5);
          }
        } else {
          // Inside the unoccluded sun area (if moon hasn't covered it)
          glowIntensity = 1.0;
        }

        // Diamond Ring lens flare
        double diamondGlow = 0.0;
        if (diamondRing && isNearTotality) {
          final dfx = (x - flareX).abs();
          final dfy = (y - flareY).abs();
          final distFlare = math.sqrt(dfx * dfx + dfy * dfy);
          if (distFlare < maxDim * 0.35) {
            final centralSpike = math.max(0.0, 1.0 - distFlare / (maxDim * 0.15));
            // Cross diffraction spikes
            final crossSpike = (dfx <= 1.2 || dfy <= 1.2) ? math.max(0.0, 1.0 - distFlare / (maxDim * 0.3)) * 0.8 : 0.0;
            diamondGlow = (centralSpike * centralSpike + crossSpike).clamp(0.0, 1.5);
          }
        }

        final combinedGlow = (glowIntensity + diamondGlow).clamp(0.0, 2.0);

        if (combinedGlow > 0.01) {
          // Inner core is hot white, outer halo is glowColor
          final whiteHot = (combinedGlow > 0.8) ? ((combinedGlow - 0.8) / 0.7).clamp(0.0, 1.0) : 0.0;
          final targetR = (gR * (1.0 - whiteHot) + 255 * whiteHot).round().clamp(0, 255);
          final targetG = (gG * (1.0 - whiteHot) + 255 * whiteHot).round().clamp(0, 255);
          final targetB = (gB * (1.0 - whiteHot) + 255 * whiteHot).round().clamp(0, 255);

          final effGlow = combinedGlow.clamp(0.0, 1.0);
          final newR = (oR * (1.0 - effGlow * 0.4) + targetR * effGlow).round().clamp(0, 255);
          final newG = (oG * (1.0 - effGlow * 0.4) + targetG * effGlow).round().clamp(0, 255);
          final newB = (oB * (1.0 - effGlow * 0.4) + targetB * effGlow).round().clamp(0, 255);
          final newA = preserveAlpha ? origA : math.max(origA, (combinedGlow * gA).round().clamp(0, 255));

          output[idx] = (newA << 24) | (newR << 16) | (newG << 8) | newB;
        } else {
          output[idx] = origPixel;
        }
      }
    }

    return output;
  }
}
