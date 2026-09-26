part of 'effects.dart';

/// An effect that procedurally renders modular starship armor hull plating,
/// recessed panel seams, structural rivet rows, ventilation exhaust grilles,
/// hydraulic conduits, diagonal caution hazard stripes, and animated warning beacon lights.
class SpaceshipHullEffect extends Effect {
  SpaceshipHullEffect([Map<String, dynamic>? params])
      : super(
          EffectType.spaceshipHull,
          params ??
              {
                'panelGridSize': 8,
                'greebleDensity': 0.5,
                'rivetSpacing': 3,
                'hullWeathering': 0.3,
                'hazardStripes': true,
                'time': 0.0,
                'preserveAlpha': false,
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() => {
        'panelGridSize': 8,
        'greebleDensity': 0.5,
        'rivetSpacing': 3,
        'hullWeathering': 0.3,
        'hazardStripes': true,
        'time': 0.0,
        'preserveAlpha': false,
      };

  @override
  Map<String, dynamic> getMetadata() => {
        'panelGridSize': {
          'label': 'Hull Panel Size',
          'description': 'Tessellation grid size in pixels for armored modular tiles.',
          'type': 'slider',
          'min': 4,
          'max': 16,
          'step': 2,
        },
        'greebleDensity': {
          'label': 'Greeble Density',
          'description': 'Frequency of ventilation grilles, access ports, and conduit lines.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'step': 0.05,
        },
        'rivetSpacing': {
          'label': 'Rivet Spacing',
          'description': 'Pixel spacing between perimeter structural rivets (0 = none).',
          'type': 'slider',
          'min': 0,
          'max': 6,
          'step': 1,
        },
        'hullWeathering': {
          'label': 'Hull Weathering',
          'description': 'Micrometeorite pits, armor scuffs, and thermal scorch noise.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'step': 0.05,
        },
        'hazardStripes': {
          'label': 'Caution Hazard Stripes',
          'description': 'Paint diagonal black and yellow caution markings on selected bulkheads.',
          'type': 'bool',
        },
        'time': {
          'label': 'Animation Time',
          'description': 'Warning beacon light blinker and exhaust heat shimmer cycle.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'step': 0.01,
        },
        'preserveAlpha': {
          'label': 'Preserve Transparency',
          'description': 'Restrict starship hull plating to existing sprite silhouette.',
          'type': 'bool',
        },
      };

  @override
  List<UIField> getFields() => [
        SliderField(
          key: 'panelGridSize',
          label: 'Hull Panel Size',
          description: 'Armored modular tile size.',
          min: 4,
          max: 16,
          divisions: 6,
          isInteger: true,
          formatLabel: (v) => '${v.round()} px',
        ),
        const SliderField(
          key: 'greebleDensity',
          label: 'Greeble Density',
          description: 'Vent grilles and conduits.',
          min: 0.0,
          max: 1.0,
          divisions: 20,
        ),
        const SliderField(
          key: 'rivetSpacing',
          label: 'Rivet Spacing',
          description: 'Perimeter seam rivet spacing.',
          min: 0,
          max: 6,
          divisions: 6,
          isInteger: true,
        ),
        const SliderField(
          key: 'hullWeathering',
          label: 'Hull Weathering',
          description: 'Armor scuffing and scorch marks.',
          min: 0.0,
          max: 1.0,
          divisions: 20,
        ),
        const BoolField(
          key: 'hazardStripes',
          label: 'Caution Hazard Stripes',
          description: 'Yellow/black chevron markings.',
        ),
        const SliderField(
          key: 'time',
          label: 'Animation Time',
          description: 'Beacon blink and heat pulse.',
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

    final panelGridSize = (parameters['panelGridSize'] as num?)?.toInt() ?? 8;
    final greebleDensity = (parameters['greebleDensity'] as num?)?.toDouble() ?? 0.5;
    final rivetSpacing = (parameters['rivetSpacing'] as num?)?.toInt() ?? 3;
    final hullWeathering = (parameters['hullWeathering'] as num?)?.toDouble() ?? 0.3;
    final hazardStripes = parameters['hazardStripes'] as bool? ?? true;
    final time = (parameters['time'] as num?)?.toDouble() ?? 0.0;
    final preserveAlpha = parameters['preserveAlpha'] as bool? ?? false;

    final output = Uint32List(width * height);

    // Armor plate color hierarchy (Duranium Battleship Grey):
    // [plateBase, plateHighlight, plateShadow, seamGroove, rivetHead]
    const basePlate = [92, 100, 112]; // Cold naval titanium grey
    const seamDark = [22, 25, 30]; // Recessed joint seam
    const rivetColor = [180, 190, 205]; // Specular metal fastener

    final cycleTime = time - time.floorToDouble();
    final pSize = math.max(4, panelGridSize);

    // Beacon blink state (flashes every cycle)
    final beaconOn = (cycleTime % 0.5) < 0.25;

    for (int y = 0; y < height; y++) {
      final cellY = y ~/ pSize;
      final localY = y % pSize;

      for (int x = 0; x < width; x++) {
        final idx = y * width + x;
        final origA = (pixels[idx] >> 24) & 0xFF;

        if (preserveAlpha && origA == 0) continue;

        final cellX = x ~/ pSize;
        final localX = x % pSize;

        // Deterministic pseudo-random seed per panel cell
        final cellSeed = (cellX * 73 + cellY * 179) & 0xFF;

        // Panel variation tint (some plates slightly lighter or darker composite alloys)
        final plateShade = (cellSeed % 7) - 3;
        int r = (basePlate[0] + plateShade * 4).clamp(0, 255);
        int g = (basePlate[1] + plateShade * 4).clamp(0, 255);
        int b = (basePlate[2] + plateShade * 4).clamp(0, 255);

        // 1. Panel Seam Joints & Bevel Borders
        final isSeamX = (localX == 0);
        final isSeamY = (localY == 0);
        final isBevelTopLeft = (localX == 1 || localY == 1);
        final isBevelBottomRight = (localX == pSize - 1 || localY == pSize - 1);

        if (isSeamX || isSeamY) {
          // Recessed joint groove
          r = seamDark[0];
          g = seamDark[1];
          b = seamDark[2];
        } else if (isBevelTopLeft) {
          // Sunward top/left bevel highlight
          r = (r + 28).clamp(0, 255);
          g = (g + 30).clamp(0, 255);
          b = (b + 35).clamp(0, 255);
        } else if (isBevelBottomRight) {
          // Shadow bottom/right bevel
          r = (r - 28).clamp(0, 255);
          g = (g - 30).clamp(0, 255);
          b = (b - 35).clamp(0, 255);
        }

        // 2. Structural Rivet Fasteners along seams
        if (rivetSpacing > 0 && !isSeamX && !isSeamY) {
          final isRivetRow = (localY == 1 || localY == pSize - 2);
          final isRivetCol = (localX == 1 || localX == pSize - 2);
          final isRivetSpot = ((isRivetRow && (localX % rivetSpacing == 0)) ||
              (isRivetCol && (localY % rivetSpacing == 0)));

          if (isRivetSpot) {
            r = rivetColor[0];
            g = rivetColor[1];
            b = rivetColor[2];
          }
        }

        // 3. Hazard Stripes on designated bulkhead cells
        final isHazardPanel = hazardStripes && (cellSeed % 9 == 0);
        if (isHazardPanel && !isSeamX && !isSeamY) {
          // Diagonal 45-degree warning chevrons
          final isYellowStripe = ((x + y) ~/ 2) % 2 == 0;
          if (isYellowStripe) {
            r = 245;
            g = 195;
            b = 15;
          } else {
            r = 30;
            g = 30;
            b = 35;
          }
        }

        // 4. Greeble Details: Ventilation louvers & hydraulic conduit lines
        final hasVentGreeble = (greebleDensity > 0.3) && (cellSeed % 5 == 1) && !isHazardPanel;
        if (hasVentGreeble && localX >= 2 && localX <= pSize - 3 && localY >= 2 && localY <= pSize - 3) {
          // Horizontal heat louvers
          if (localY % 2 == 0) {
            // Dark exhaust slot
            r = 18;
            g = 20;
            b = 24;
          } else {
            // Vent metal vane
            r = (basePlate[0] + 20).clamp(0, 255);
            g = (basePlate[1] + 20).clamp(0, 255);
            b = (basePlate[2] + 25).clamp(0, 255);
          }
        }

        // 5. Warning Beacon Flasher / Conduit Status LED
        final isBeaconSpot = (cellSeed % 11 == 0) && (localX == pSize ~/ 2) && (localY == pSize ~/ 2);
        if (isBeaconSpot) {
          if (beaconOn) {
            // Pulsing bright warning amber/crimson LED
            r = 255;
            g = 45;
            b = 35;
          } else {
            // Idle unlit diode
            r = 75;
            g = 15;
            b = 15;
          }
        }

        // 6. Hull Weathering & Micro-Impact Scuffs
        if (hullWeathering > 0.05) {
          final scuffNoise = ((x * 67 + y * 131) % 17) - 8;
          final wear = (scuffNoise * hullWeathering * 4.5).round();
          r = (r + wear).clamp(0, 255);
          g = (g + wear).clamp(0, 255);
          b = (b + wear).clamp(0, 255);
        }

        final targetA = preserveAlpha ? origA : 255;
        output[idx] = (targetA << 24) | (r << 16) | (g << 8) | b;
      }
    }

    return output;
  }
}
