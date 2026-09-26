part of 'effects.dart';

/// Procedural gothic stained glass rosette & sacred mandala generator.
///
/// Constructs mathematically symmetrical radial rose windows with lead came
/// tracery framing, multi-tiered petal foils, jewel-toned stained glass panes,
/// and streaming volumetric sunlight shafts that drift dynamically with time.
class GothicRosetteEffect extends Effect implements UIFieldProvider {
  GothicRosetteEffect([Map<String, dynamic>? parameters])
      : super(
          EffectType.gothicRosette,
          parameters ??
              const {
                'symmetryOrder': 8,
                'leadThickness': 1,
                'glassPalette': 'roseCathedral',
                'innerRings': 3,
                'sunlightShaft': 0.5,
                'time': 0.0,
                'preserveAlpha': false,
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() => {
        'symmetryOrder': 8,
        'leadThickness': 1,
        'glassPalette': 'roseCathedral',
        'innerRings': 3,
        'sunlightShaft': 0.5,
        'time': 0.0,
        'preserveAlpha': false,
      };

  @override
  Map<String, dynamic> getMetadata() => {
        'symmetryOrder': {
          'label': 'Symmetry Order',
          'description': 'Number of radial petal sectors around the rosette.',
          'type': 'slider',
          'min': 6,
          'max': 12,
          'step': 2,
        },
        'leadThickness': {
          'label': 'Lead Came Thickness',
          'description': 'Width of the dark iron/lead came framing strips.',
          'type': 'slider',
          'min': 1,
          'max': 3,
          'step': 1,
        },
        'glassPalette': {
          'label': 'Glass Color Palette',
          'description': 'Stained glass jewel and cathedral color harmonies.',
          'type': 'select',
          'options': {
            'roseCathedral': 'Notre-Dame Rose & Gold',
            'jewel': 'Medieval Jewel Tones',
            'celestial': 'Celestial Starlight',
            'monochrome': 'Frosted Crypt Monochrome',
          },
        },
        'innerRings': {
          'label': 'Concentric Tiers',
          'description': 'Number of concentric annular petal tiers.',
          'type': 'slider',
          'min': 2,
          'max': 5,
          'step': 1,
        },
        'sunlightShaft': {
          'label': 'Sunlight Beam Shafts',
          'description': 'Intensity of volumetric sunbeams streaming through glass.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'step': 0.05,
        },
        'time': {
          'label': 'Animation Time',
          'description': 'Timeline progress rotating sunbeam angle and refraction.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'step': 0.01,
        },
        'preserveAlpha': {
          'label': 'Preserve Transparency',
          'description': 'Restrict rosette window to existing silhouette.',
          'type': 'bool',
        },
      };

  @override
  List<UIField> getFields() => [
        SliderField(
          key: 'symmetryOrder',
          label: 'Symmetry Order',
          description: 'Radial petal sectors.',
          min: 6,
          max: 12,
          divisions: 3,
          formatLabel: (v) => '${v.round()}-fold',
        ),
        SliderField(
          key: 'leadThickness',
          label: 'Lead Thickness',
          description: 'Dark lead framing strip width.',
          min: 1,
          max: 3,
          divisions: 2,
          formatLabel: (v) => '${v.round()} px',
        ),
        const SelectField(
          key: 'glassPalette',
          label: 'Glass Palette',
          description: 'Stained glass coloration harmony.',
          options: {
            'roseCathedral': 'Notre-Dame Rose & Gold',
            'jewel': 'Medieval Jewel Tones',
            'celestial': 'Celestial Starlight',
            'monochrome': 'Frosted Crypt Monochrome',
          },
        ),
        SliderField(
          key: 'innerRings',
          label: 'Concentric Tiers',
          description: 'Number of circular concentric tiers.',
          min: 2,
          max: 5,
          divisions: 3,
          formatLabel: (v) => '${v.round()} tiers',
        ),
        SliderField(
          key: 'sunlightShaft',
          label: 'Sunbeam Shafts',
          description: 'Volumetric streaming light intensity.',
          min: 0.0,
          max: 1.0,
          divisions: 20,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        SliderField(
          key: 'time',
          label: 'Animation Time',
          description: 'Sunbeam angle rotation progress.',
          min: 0.0,
          max: 1.0,
          divisions: 100,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        const BoolField(
          key: 'preserveAlpha',
          label: 'Preserve Transparency',
          description: 'Confine window within original sprite bounds.',
        ),
      ];

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    final symmetryOrder = (parameters['symmetryOrder'] as num?)?.toInt() ?? 8;
    final leadThickness = (parameters['leadThickness'] as num?)?.toInt() ?? 1;
    final glassPalette = parameters['glassPalette'] as String? ?? 'roseCathedral';
    final innerRings = (parameters['innerRings'] as num?)?.toInt() ?? 3;
    final sunlightShaft = (parameters['sunlightShaft'] as num?)?.toDouble() ?? 0.5;
    final time = (parameters['time'] as num?)?.toDouble() ?? 0.0;
    final preserveAlpha = parameters['preserveAlpha'] as bool? ?? false;

    final output = Uint32List(width * height);

    // Color palettes [Pane0, Pane1, Pane2, Pane3, CenterOculus]
    late final List<List<int>> panes;
    switch (glassPalette) {
      case 'jewel':
        panes = [
          [213, 0, 0], // Ruby
          [41, 98, 255], // Cobalt Blue
          [0, 200, 83], // Emerald
          [255, 171, 0], // Amber Gold
          [170, 0, 255], // Amethyst
        ];
        break;
      case 'celestial':
        panes = [
          [0, 229, 255], // Astral Cyan
          [124, 77, 255], // Starlight Violet
          [48, 79, 254], // Deep Indigo
          [255, 238, 88], // Astral Gold
          [255, 255, 255], // Pure White Core
        ];
        break;
      case 'monochrome':
        panes = [
          [236, 239, 241], // Frosted White
          [176, 190, 197], // Silver Slate
          [120, 144, 156], // Deep Gray
          [207, 216, 220], // Pale Slate
          [255, 255, 255], // Core White
        ];
        break;
      case 'roseCathedral':
      default:
        panes = [
          [194, 24, 91], // Magenta Rose
          [211, 47, 47], // Scarlet Carmine
          [255, 193, 7], // Cathedral Gold
          [26, 35, 126], // Midnight Navy
          [255, 235, 59], // Golden Sun Oculus
        ];
        break;
    }

    final cx = width / 2.0;
    final cy = height / 2.0;
    final maxRadius = math.min(width, height) * 0.46;
    final sectorAngle = (math.pi * 2.0) / symmetryOrder;
    final leadCameHalf = (leadThickness * 0.55).clamp(0.45, 1.8);

    final cycleTime = time - time.floorToDouble();
    final sunbeamAngle = cycleTime * math.pi * 2.0 - math.pi / 4.0;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final idx = y * width + x;
        final origPixel = pixels[idx];
        final origA = (origPixel >> 24) & 0xFF;

        if (preserveAlpha && origA == 0) continue;

        final dx = x - cx;
        final dy = y - cy;
        final r = math.sqrt(dx * dx + dy * dy);

        int rCol, gCol, bCol;

        if (r > maxRadius) {
          // Surrounding Gothic cathedral stone arch masonry
          final stoneNoise = ((x * 37 + y * 73) % 9) == 0;
          final isArchMortar = (r - maxRadius < 2.0) || ((x + y) % 7 == 0 && r - maxRadius < 5.0);

          if (isArchMortar) {
            rCol = 32;
            gCol = 34;
            bCol = 38;
          } else if (stoneNoise) {
            rCol = 70;
            gCol = 75;
            bCol = 82;
          } else {
            rCol = 55;
            gCol = 60;
            bCol = 68;
          }
        } else {
          // Inside the circular stained glass rosette
          final theta = math.atan2(dy, dx);
          final normTheta = (theta + math.pi * 2.0) % sectorAngle;
          final relTheta = (normTheta - sectorAngle / 2.0).abs();
          final sectorIdx = ((theta + math.pi * 2.0) / sectorAngle).floor() % symmetryOrder;

          // Determine concentric ring tier
          final ringFrac = r / maxRadius;
          final currentTier = (ringFrac * innerRings).floor().clamp(0, innerRings - 1);
          final tierInnerR = currentTier * (maxRadius / innerRings);
          final tierOuterR = (currentTier + 1) * (maxRadius / innerRings);

          // Lead came conditions:
          // 1. Outer circumference border
          final isOuterRim = (maxRadius - r).abs() <= leadCameHalf;
          // 2. Concentric ring dividers
          final isConcentricRing = (r - tierOuterR).abs() <= leadCameHalf;
          // 3. Radial spokes separating sectors
          final spokeDist = r * relTheta;
          final isRadialSpoke = spokeDist <= leadCameHalf;
          // 4. Petal foil cusps
          final petalHarmonic = math.cos(relTheta * symmetryOrder) * (maxRadius / (innerRings * 2.8));
          final isPetalLead = (r - (tierInnerR + (maxRadius / innerRings) * 0.5 + petalHarmonic)).abs() <= leadCameHalf;

          final isLead = isOuterRim || isConcentricRing || isRadialSpoke || isPetalLead;

          if (isLead) {
            // Dark iron lead came strip with subtle 3D highlight
            final isHighlight = (dx - dy).abs() < 1.0;
            rCol = isHighlight ? 55 : 22;
            gCol = isHighlight ? 58 : 24;
            bCol = isHighlight ? 66 : 28;
          } else {
            // Stained glass pane
            if (currentTier == 0) {
              // Central oculus window
              final oculus = panes[4];
              rCol = oculus[0];
              gCol = oculus[1];
              bCol = oculus[2];
            } else {
              // Alternating petal foils across sectors and tiers
              final panePaletteIdx = (sectorIdx + currentTier) % 4;
              final pane = panes[panePaletteIdx];

              // Subtle natural glass texture variations
              final glassGrain = ((x * 11 + y * 19) % 5) - 2;
              rCol = (pane[0] + glassGrain * 6).clamp(0, 255);
              gCol = (pane[1] + glassGrain * 6).clamp(0, 255);
              bCol = (pane[2] + glassGrain * 6).clamp(0, 255);
            }

            // Volumetric streaming sunlight shaft
            if (sunlightShaft > 0.01) {
              // Project angled diagonal sunlight beam
              final beamCoord = math.cos(theta - sunbeamAngle);
              if (beamCoord > 0.3) {
                final beamIntensity = ((beamCoord - 0.3) / 0.7) * sunlightShaft;
                // Additive golden-white cathedral illumination
                rCol = (rCol + 255 * beamIntensity * 0.45).round().clamp(0, 255);
                gCol = (gCol + 245 * beamIntensity * 0.40).round().clamp(0, 255);
                bCol = (bCol + 180 * beamIntensity * 0.25).round().clamp(0, 255);
              }
            }
          }
        }

        final targetA = preserveAlpha ? origA : 255;
        output[idx] = (targetA << 24) | (rCol << 16) | (gCol << 8) | bCol;
      }
    }

    return output;
  }
}
