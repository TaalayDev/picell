part of 'effects.dart';

/// Renders glowing cyberware PCB circuit traces, orthogonal and 45-degree bus tracks,
/// terminal solder via pads, and pulsing nanite data packet nodes across the sprite.
class NanotechCircuitEffect extends Effect {
  NanotechCircuitEffect([Map<String, dynamic>? params])
      : super(
          EffectType.nanotechCircuit,
          params ??
              {
                'traceDensity': 6.0,
                'angleMode': 'angled45',
                'showPads': true,
                'dataPackets': true,
                'circuitPalette': 'neonCyanPCB',
                'behindOnly': false,
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() => {
        'traceDensity': 6.0,
        'angleMode': 'angled45',
        'showPads': true,
        'dataPackets': true,
        'circuitPalette': 'neonCyanPCB',
        'behindOnly': false,
      };

  @override
  Map<String, dynamic> getMetadata() => {
        'traceDensity': {
          'label': 'Circuit Trace Density',
          'description': 'Number of routed PCB conductive traces across the sprite.',
          'type': 'slider',
          'min': 2.0,
          'max': 14.0,
          'step': 1.0,
        },
        'angleMode': {
          'label': 'Bus Routing Angles',
          'description': 'Geometric routing geometry for circuit traces.',
          'type': 'select',
          'options': {
            'orthogonal90': 'Orthogonal (Strict 90° Turns)',
            'angled45': 'Angled (Diagonal 45° Bends)',
            'bothMixed': 'Hybrid Mixed (45° & 90° PCB Bus)',
          },
        },
        'showPads': {
          'label': 'Solder Via Pads',
          'description': 'Renders micro solder pads and through-hole vias at endpoints.',
          'type': 'bool',
        },
        'dataPackets': {
          'label': 'Nanite Data Packets',
          'description': 'Renders bright illuminated signal pulses traveling along traces.',
          'type': 'bool',
        },
        'circuitPalette': {
          'label': 'Circuit Board Theme',
          'description': 'Subdermal cyberware and PCB trace metallization color.',
          'type': 'select',
          'options': {
            'neonCyanPCB': 'Neon Cyan PCB (Subdermal Cyberware)',
            'goldTraces': '24K Gold Traces (Classic Motherboard)',
            'crimsonOverclock': 'Crimson Overclock (Overheated Copper)',
            'quantumPurple': 'Quantum Purple (Ultraviolet Processor)',
          },
        },
        'behindOnly': {
          'label': 'Behind Foreground',
          'description': 'Renders circuit traces behind existing opaque character pixels.',
          'type': 'bool',
        },
      };

  @override
  List<UIField> getFields() => const [
        SliderField(
          key: 'traceDensity',
          label: 'Circuit Trace Density',
          min: 2.0,
          max: 14.0,
        ),
        SelectField(
          key: 'angleMode',
          label: 'Bus Routing Angles',
          options: <String, String>{
            'orthogonal90': 'Orthogonal (Strict 90° Turns)',
            'angled45': 'Angled (Diagonal 45° Bends)',
            'bothMixed': 'Hybrid Mixed (45° & 90° PCB Bus)',
          },
        ),
        BoolField(
          key: 'showPads',
          label: 'Solder Via Pads',
        ),
        BoolField(
          key: 'dataPackets',
          label: 'Nanite Data Packets',
        ),
        SelectField(
          key: 'circuitPalette',
          label: 'Circuit Board Theme',
          options: <String, String>{
            'neonCyanPCB': 'Neon Cyan PCB (Subdermal Cyberware)',
            'goldTraces': '24K Gold Traces (Classic Motherboard)',
            'crimsonOverclock': 'Crimson Overclock (Overheated Copper)',
            'quantumPurple': 'Quantum Purple (Ultraviolet Processor)',
          },
        ),
        BoolField(
          key: 'behindOnly',
          label: 'Behind Foreground',
        ),
      ];

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    final traceDensity = (parameters['traceDensity'] as num?)?.toInt().clamp(1, 20) ?? 6;
    final angleMode = parameters['angleMode'] as String? ?? 'angled45';
    final showPads = parameters['showPads'] as bool? ?? true;
    final dataPackets = parameters['dataPackets'] as bool? ?? true;
    final circuitPalette = parameters['circuitPalette'] as String? ?? 'neonCyanPCB';
    final behindOnly = parameters['behindOnly'] as bool? ?? false;

    final output = Uint32List.fromList(pixels);

    // Color definitions
    final int traceCore;
    final int traceGlow;
    final int padColor;
    final int viaHole;
    final int packetSpark;

    switch (circuitPalette) {
      case 'goldTraces':
        traceCore = 0xFFFFD700;
        traceGlow = 0x88AA8800;
        padColor = 0xFFFFF099;
        viaHole = 0xFF2B1B00;
        packetSpark = 0xFFFFFFFF;
        break;
      case 'crimsonOverclock':
        traceCore = 0xFFFF1E44;
        traceGlow = 0x88880011;
        padColor = 0xFFFFA0B0;
        viaHole = 0xFF220005;
        packetSpark = 0xFFFFDDEE;
        break;
      case 'quantumPurple':
        traceCore = 0xFFBF40FF;
        traceGlow = 0x88550088;
        padColor = 0xFFDF99FF;
        viaHole = 0xFF1A002E;
        packetSpark = 0xFFF5EEFF;
        break;
      case 'neonCyanPCB':
      default:
        traceCore = 0xFF00F0FF;
        traceGlow = 0x88005577;
        padColor = 0xFF80FFFF;
        viaHole = 0xFF001A24;
        packetSpark = 0xFFE0FFFF;
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

    void drawPad(int cx, int cy) {
      // Diamond solder pad with center micro-via hole
      setPixel(cx, cy - 1, padColor);
      setPixel(cx, cy + 1, padColor);
      setPixel(cx - 1, cy, padColor);
      setPixel(cx + 1, cy, padColor);
      setPixel(cx, cy, viaHole);
    }

    // 1. Collect boundary and internal sprite anchor pixels
    final List<int> anchorXs = [];
    final List<int> anchorYs = [];

    for (int y = 1; y < height - 1; y++) {
      final rowOffset = y * width;
      for (int x = 1; x < width - 1; x++) {
        final a = (pixels[rowOffset + x] >> 24) & 0xFF;
        if (a > 30) {
          // Check if perimeter edge
          final leftA = (pixels[rowOffset + x - 1] >> 24) & 0xFF;
          final rightA = (pixels[rowOffset + x + 1] >> 24) & 0xFF;
          final topA = (pixels[(y - 1) * width + x] >> 24) & 0xFF;
          final bottomA = (pixels[(y + 1) * width + x] >> 24) & 0xFF;

          if (leftA < 20 || rightA < 20 || topA < 20 || bottomA < 20) {
            anchorXs.add(x);
            anchorYs.add(y);
          }
        }
      }
    }

    if (anchorXs.isEmpty) {
      // Fallback grid anchors
      for (int i = 0; i < 8; i++) {
        anchorXs.add(width ~/ 4 + (i * width ~/ 10));
        anchorYs.add(height ~/ 4 + ((i * 3) % (height ~/ 2)));
      }
    }

    // 2. Generate and Route Traces
    final numAnchors = anchorXs.length;
    final int stepStride = (numAnchors ~/ traceDensity).clamp(1, numAnchors);

    for (int t = 0; t < traceDensity; t++) {
      final anchorIdx = (t * stepStride) % numAnchors;
      int currX = anchorXs[anchorIdx];
      int currY = anchorYs[anchorIdx];

      final traceSeed = ((t * 7919 + currX * 31 + currY * 97) & 0x7FFFFFFF);

      // Routing style for this trace
      final String mode;
      if (angleMode == 'bothMixed') {
        mode = (t % 2 == 0) ? 'orthogonal90' : 'angled45';
      } else {
        mode = angleMode;
      }

      // Draw initial terminal solder pad
      if (showPads) {
        drawPad(currX, currY);
      }

      // Direction vectors
      final dirSignX = ((traceSeed % 2) == 0) ? 1 : -1;
      final dirSignY = (((traceSeed >> 1) % 2) == 0) ? 1 : -1;

      final seg1Len = 4 + (traceSeed % 7);
      final seg2Len = 4 + ((traceSeed >> 3) % 8);

      final List<int> pathXs = [currX];
      final List<int> pathYs = [currY];

      if (mode == 'orthogonal90') {
        // Segment 1: Horizontal run
        for (int s = 0; s < seg1Len; s++) {
          currX += dirSignX;
          if (currX < 1 || currX >= width - 1) break;
          pathXs.add(currX);
          pathYs.add(currY);
        }
        // Segment 2: Vertical bend (strict 90-degree corner)
        for (int s = 0; s < seg2Len; s++) {
          currY += dirSignY;
          if (currY < 1 || currY >= height - 1) break;
          pathXs.add(currX);
          pathYs.add(currY);
        }
      } else {
        // angled45:
        // Segment 1: 45-degree diagonal run
        for (int s = 0; s < seg1Len; s++) {
          currX += dirSignX;
          currY += dirSignY;
          if (currX < 1 || currX >= width - 1 || currY < 1 || currY >= height - 1) break;
          pathXs.add(currX);
          pathYs.add(currY);
        }
        // Segment 2: Horizontal or vertical branch
        final bool branchHoriz = (traceSeed % 2 == 0);
        for (int s = 0; s < seg2Len; s++) {
          if (branchHoriz) {
            currX += dirSignX;
          } else {
            currY += dirSignY;
          }
          if (currX < 1 || currX >= width - 1 || currY < 1 || currY >= height - 1) break;
          pathXs.add(currX);
          pathYs.add(currY);
        }
      }

      // Draw trace line segments
      for (int p = 0; p < pathXs.length; p++) {
        final px = pathXs[p];
        final py = pathYs[p];
        setPixel(px, py, traceCore);
        // Translucent border glow for micro trace definition
        setPixel(px + 1, py, traceGlow);
      }

      // Terminal pad at the end of the trace
      if (showPads && pathXs.isNotEmpty) {
        drawPad(currX, currY);
      }

      // Nanite Data Packets along the route
      if (dataPackets && pathXs.length >= 4) {
        final packetIdx = pathXs.length ~/ 2;
        final kx = pathXs[packetIdx];
        final ky = pathYs[packetIdx];
        setPixel(kx, ky, packetSpark);
        setPixel(kx - 1, ky, traceCore);
        setPixel(kx + 1, ky, traceCore);
        setPixel(kx, ky - 1, traceCore);
        setPixel(kx, ky + 1, traceCore);
      }
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
