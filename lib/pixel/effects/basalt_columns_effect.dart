part of 'effects.dart';

/// An effect that procedurally renders interlocking hexagonal volcanic basalt columns
/// (inspired by the Giant's Causeway) with stepped elevations, top cap bevel highlights,
/// cooling fracture joints, and glowing subterranean magma seepage channels.
class BasaltColumnsEffect extends Effect {
  BasaltColumnsEffect([Map<String, dynamic>? params])
      : super(
          EffectType.basaltColumns,
          params ??
              {
                'columnScale': 8,
                'heightVariation': 0.5,
                'hexBevel': 0.6,
                'lavaSeepage': true,
                'columnTexture': 'volcanicBasalt',
                'time': 0.0,
                'preserveAlpha': false,
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() => {
        'columnScale': 8,
        'heightVariation': 0.5,
        'hexBevel': 0.6,
        'lavaSeepage': true,
        'columnTexture': 'volcanicBasalt',
        'time': 0.0,
        'preserveAlpha': false,
      };

  @override
  Map<String, dynamic> getMetadata() => {
        'columnScale': {
          'label': 'Column Hex Radius',
          'description': 'Radius in pixels of individual hexagonal basalt pillars.',
          'type': 'slider',
          'min': 4,
          'max': 14,
          'step': 1,
        },
        'heightVariation': {
          'label': 'Height Disparity',
          'description': 'Elevation disparity between adjacent stepped columns.',
          'type': 'slider',
          'min': 0.1,
          'max': 1.0,
          'step': 0.05,
        },
        'hexBevel': {
          'label': 'Hex Rim Bevel',
          'description': 'Chiseled edge highlight on column top surfaces.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'step': 0.05,
        },
        'lavaSeepage': {
          'label': 'Magma Seepage',
          'description': 'Render glowing subterranean lava channels along hexagonal joints.',
          'type': 'bool',
        },
        'columnTexture': {
          'label': 'Mineral Finish',
          'description': 'Geological stone type and surface aging.',
          'type': 'select',
          'options': {
            'volcanicBasalt': 'Giant’s Causeway Volcanic Basalt',
            'obsidianGlass': 'Vitreous Black Obsidian Glass',
            'ancientMoss': 'Weathered Mossy Sea Steppes',
          },
        },
        'time': {
          'label': 'Animation Time',
          'description': 'Thermal magma glow pulsation cycle.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'step': 0.01,
        },
        'preserveAlpha': {
          'label': 'Preserve Transparency',
          'description': 'Restrict basalt columns to existing sprite silhouette.',
          'type': 'bool',
        },
      };

  @override
  List<UIField> getFields() => [
        SliderField(
          key: 'columnScale',
          label: 'Column Hex Radius',
          description: 'Hex column width.',
          min: 4,
          max: 14,
          divisions: 10,
          isInteger: true,
          formatLabel: (v) => '${v.round()} px',
        ),
        const SliderField(
          key: 'heightVariation',
          label: 'Height Disparity',
          description: 'Elevation step disparity.',
          min: 0.1,
          max: 1.0,
          divisions: 18,
        ),
        const SliderField(
          key: 'hexBevel',
          label: 'Hex Rim Bevel',
          description: 'Chiseled rim highlight.',
          min: 0.0,
          max: 1.0,
          divisions: 20,
        ),
        const BoolField(
          key: 'lavaSeepage',
          label: 'Magma Seepage',
          description: 'Glowing magma in joints.',
        ),
        const SelectField(
          key: 'columnTexture',
          label: 'Mineral Finish',
          description: 'Geological stone finish.',
          options: {
            'volcanicBasalt': 'Giant’s Causeway Volcanic Basalt',
            'obsidianGlass': 'Vitreous Black Obsidian Glass',
            'ancientMoss': 'Weathered Mossy Sea Steppes',
          },
        ),
        const SliderField(
          key: 'time',
          label: 'Animation Time',
          description: 'Thermal lava pulsation cycle.',
          min: 0.0,
          max: 1.0,
          divisions: 100,
        ),
        const BoolField(
          key: 'preserveAlpha',
          label: 'Preserve Transparency',
          description: 'Restrict to existing sprite silhouette.',
        ),
      ];

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    if (width <= 0 || height <= 0) return pixels;

    final columnScale = (parameters['columnScale'] as num?)?.toInt() ?? 8;
    final heightVariation = (parameters['heightVariation'] as num?)?.toDouble() ?? 0.5;
    final hexBevel = (parameters['hexBevel'] as num?)?.toDouble() ?? 0.6;
    final lavaSeepage = parameters['lavaSeepage'] as bool? ?? true;
    final columnTexture = parameters['columnTexture'] as String? ?? 'volcanicBasalt';
    final time = (parameters['time'] as num?)?.toDouble() ?? 0.0;
    final preserveAlpha = parameters['preserveAlpha'] as bool? ?? false;

    final output = Uint32List(width * height);
    final cycleTime = time - time.floorToDouble();

    // Stone mineral base palette: [topCapBase, bevelHighlight, shadowRiser, crackDark]
    final List<List<int>> stonePal;
    switch (columnTexture) {
      case 'obsidianGlass':
        stonePal = const [
          [28, 30, 38], // Dark obsidian vitreous face
          [130, 140, 160], // Sharp specular glass edge
          [14, 15, 20], // Deep shadow wall
          [6, 6, 10], // Joint crack
        ];
        break;
      case 'ancientMoss':
        stonePal = const [
          [55, 68, 48], // Mossy olive cap
          [95, 115, 80], // Lichen highlight
          [35, 42, 32], // Wet stone wall
          [15, 18, 14], // Damp crevice
        ];
        break;
      case 'volcanicBasalt':
      default:
        stonePal = const [
          [58, 60, 66], // Charcoal basalt top cap
          [100, 105, 115], // Beveled sunlit edge
          [36, 38, 42], // Vertical columnar joint shadow
          [18, 19, 22], // Joint fracture
        ];
        break;
    }

    final hexR = math.max(4.0, columnScale.toDouble());

    // Thermal magma pulse
    final lavaPulse = 0.75 + 0.25 * math.sin(cycleTime * math.pi * 2.0);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final idx = y * width + x;
        final origA = (pixels[idx] >> 24) & 0xFF;

        if (preserveAlpha && origA == 0) continue;

        // Hexagonal axial coordinate projection
        // Column coordinates (colX, colY)
        final q = (2.0 / 3.0 * x) / hexR;
        final rCoord = (-1.0 / 3.0 * x + math.sqrt(3.0) / 3.0 * y) / hexR;

        // Cube coordinates rounding for nearest hexagon center
        final sCoord = -q - rCoord;
        int rx = q.round();
        int ry = rCoord.round();
        int rz = sCoord.round();

        final xDiff = (rx - q).abs();
        final yDiff = (ry - rCoord).abs();
        final zDiff = (rz - sCoord).abs();

        if (xDiff > yDiff && xDiff > zDiff) {
          rx = -ry - rz;
        } else if (yDiff > zDiff) {
          ry = -rx - rz;
        }

        // Hexagon center coordinate in pixel space
        final centerPixelX = hexR * (3.0 / 2.0 * rx);
        final centerPixelY = hexR * (math.sqrt(3.0) / 2.0 * rx + math.sqrt(3.0) * ry);

        // Distance from current pixel to column center
        final dx = x - centerPixelX;
        final dy = y - centerPixelY;

        // Normalized distance to hex boundary
        // Hexagon distance metric: max(|dx|, |dx|*0.5 + |dy|*sqrt(3)/2)
        final d1 = dx.abs();
        final d2 = dx.abs() * 0.5 + dy.abs() * (math.sqrt(3.0) / 2.0);
        final hexDist = math.max(d1, d2) / hexR;

        // Elevation step based on column seed
        final hexSeed = ((rx * 97 + ry * 193) & 0xFFFF);
        final elevation = (hexSeed % 100) / 100.0;
        final elevationShade = ((elevation - 0.5) * heightVariation * 50).round();

        int r, g, b;

        // Check if on the outer cooling fracture joint between columns
        final isJoint = hexDist > 0.88;
        final isJointDeep = hexDist > 0.94;

        if (isJoint) {
          if (lavaSeepage && isJointDeep) {
            // Glowing subterranean magma fissure
            final lavaHeat = (lavaPulse * (0.8 + 0.2 * math.sin((rx + ry) * 0.5 + cycleTime * 4.0))).clamp(0.0, 1.0);
            r = (255 * lavaHeat).round().clamp(0, 255);
            g = (120 * lavaHeat).round().clamp(0, 255);
            b = (20 * lavaHeat).round().clamp(0, 255);
          } else {
            // Dark cooling fissure joint
            r = stonePal[3][0];
            g = stonePal[3][1];
            b = stonePal[3][2];
          }
        } else {
          // Inside hexagonal basalt pillar top cap
          final baseR = (stonePal[0][0] + elevationShade).clamp(0, 255);
          final baseG = (stonePal[0][1] + elevationShade).clamp(0, 255);
          final baseB = (stonePal[0][2] + elevationShade).clamp(0, 255);

          // Top/Left sunlit bevel highlight vs Bottom/Right shadow
          final isTopLeftBevel = (hexDist > 0.72) && (dx <= 0 || dy <= 0);
          final isBottomRightShadow = (hexDist > 0.72) && (dx > 0 && dy > 0);

          if (isTopLeftBevel && hexBevel > 0.05) {
            final boost = (35 * hexBevel).round();
            r = (baseR + boost).clamp(0, 255);
            g = (baseG + boost).clamp(0, 255);
            b = (baseB + boost).clamp(0, 255);
          } else if (isBottomRightShadow && hexBevel > 0.05) {
            final drop = (30 * hexBevel).round();
            r = (baseR - drop).clamp(0, 255);
            g = (baseG - drop).clamp(0, 255);
            b = (baseB - drop).clamp(0, 255);
          } else {
            r = baseR;
            g = baseG;
            b = baseB;
          }

          // Subtle cooling rock vesicular micro-grain
          final grain = ((x * 43 + y * 79) % 7) - 3;
          r = (r + grain).clamp(0, 255);
          g = (g + grain).clamp(0, 255);
          b = (b + grain).clamp(0, 255);
        }

        final targetA = preserveAlpha ? origA : 255;
        output[idx] = (targetA << 24) | (r << 16) | (g << 8) | b;
      }
    }

    return output;
  }
}
