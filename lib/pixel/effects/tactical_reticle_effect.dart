part of 'effects.dart';

/// Renders a sci-fi tactical lock-on targeting reticle with corner framing brackets,
/// centroid crosshair tick notches, rangefinder deadzones, and HUD telemetry tags.
class TacticalReticleEffect extends Effect {
  TacticalReticleEffect([Map<String, dynamic>? params])
      : super(
          EffectType.tacticalReticle,
          params ??
              {
                'bracketPadding': 3.0,
                'bracketLength': 6.0,
                'showCrosshairs': true,
                'deadzoneRadius': 6.0,
                'showTelemetry': true,
                'reticlePalette': 'cyberCyan',
                'behindOnly': false,
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() => {
        'bracketPadding': 3.0,
        'bracketLength': 6.0,
        'showCrosshairs': true,
        'deadzoneRadius': 6.0,
        'showTelemetry': true,
        'reticlePalette': 'cyberCyan',
        'behindOnly': false,
      };

  @override
  Map<String, dynamic> getMetadata() => {
        'bracketPadding': {
          'label': 'Frame Padding',
          'description': 'Distance between the sprite bounding silhouette and corner brackets.',
          'type': 'slider',
          'min': 0.0,
          'max': 10.0,
          'step': 1.0,
        },
        'bracketLength': {
          'label': 'Bracket Arm Length',
          'description': 'Length of the four corner framing bracket segments.',
          'type': 'slider',
          'min': 2.0,
          'max': 14.0,
          'step': 1.0,
        },
        'showCrosshairs': {
          'label': 'Centroid Crosshairs',
          'description': 'Renders horizontal and vertical targeting tick axes.',
          'type': 'bool',
        },
        'deadzoneRadius': {
          'label': 'Deadzone Radius',
          'description': 'Central clear zone around centroid to preserve character visibility.',
          'type': 'slider',
          'min': 2.0,
          'max': 14.0,
          'step': 1.0,
        },
        'showTelemetry': {
          'label': 'HUD Telemetry Tags',
          'description': 'Renders targeting data readouts and lock status indicators.',
          'type': 'bool',
        },
        'reticlePalette': {
          'label': 'HUD Color Theme',
          'description': 'Tactical holographic color palette.',
          'type': 'select',
          'options': {
            'cyberCyan': 'Cyber Cyan (Neon Teal)',
            'dangerAmber': 'Danger Amber (Hazard Gold)',
            'targetingRed': 'Targeting Red (Lock-On Crimson)',
            'matrixGreen': 'Matrix Green (Terminal Phosphor)',
          },
        },
        'behindOnly': {
          'label': 'Behind Foreground',
          'description': 'Renders reticle graphics behind existing opaque character pixels.',
          'type': 'bool',
        },
      };

  @override
  List<UIField> getFields() => const [
        SliderField(
          key: 'bracketPadding',
          label: 'Frame Padding',
          min: 0.0,
          max: 10.0,
        ),
        SliderField(
          key: 'bracketLength',
          label: 'Bracket Arm Length',
          min: 2.0,
          max: 14.0,
        ),
        BoolField(
          key: 'showCrosshairs',
          label: 'Centroid Crosshairs',
        ),
        SliderField(
          key: 'deadzoneRadius',
          label: 'Deadzone Radius',
          min: 2.0,
          max: 14.0,
        ),
        BoolField(
          key: 'showTelemetry',
          label: 'HUD Telemetry Tags',
        ),
        SelectField(
          key: 'reticlePalette',
          label: 'HUD Color Theme',
          options: <String, String>{
            'cyberCyan': 'Cyber Cyan (Neon Teal)',
            'dangerAmber': 'Danger Amber (Hazard Gold)',
            'targetingRed': 'Targeting Red (Lock-On Crimson)',
            'matrixGreen': 'Matrix Green (Terminal Phosphor)',
          },
        ),
        BoolField(
          key: 'behindOnly',
          label: 'Behind Foreground',
        ),
      ];

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    final bracketPadding = (parameters['bracketPadding'] as num?)?.toInt() ?? 3;
    final bracketLength = (parameters['bracketLength'] as num?)?.toInt() ?? 6;
    final showCrosshairs = parameters['showCrosshairs'] as bool? ?? true;
    final deadzoneRadius = (parameters['deadzoneRadius'] as num?)?.toInt() ?? 6;
    final showTelemetry = parameters['showTelemetry'] as bool? ?? true;
    final reticlePalette = parameters['reticlePalette'] as String? ?? 'cyberCyan';
    final behindOnly = parameters['behindOnly'] as bool? ?? false;

    final output = Uint32List.fromList(pixels);

    // 1. Determine bounding box and centroid of active pixels
    int minX = width;
    int maxX = -1;
    int minY = height;
    int maxY = -1;
    int activeCount = 0;
    int sumX = 0;
    int sumY = 0;

    for (int y = 0; y < height; y++) {
      final rowOffset = y * width;
      for (int x = 0; x < width; x++) {
        final a = (pixels[rowOffset + x] >> 24) & 0xFF;
        if (a > 20) {
          if (x < minX) minX = x;
          if (x > maxX) maxX = x;
          if (y < minY) minY = y;
          if (y > maxY) maxY = y;
          sumX += x;
          sumY += y;
          activeCount++;
        }
      }
    }

    if (activeCount == 0) {
      minX = width ~/ 4;
      maxX = 3 * width ~/ 4;
      minY = height ~/ 4;
      maxY = 3 * height ~/ 4;
      sumX = width ~/ 2;
      sumY = height ~/ 2;
      activeCount = 1;
    }

    final int cx = sumX ~/ activeCount;
    final int cy = sumY ~/ activeCount;

    // Expand bounding box with padding
    final int bx1 = (minX - bracketPadding).clamp(0, width - 1);
    final int bx2 = (maxX + bracketPadding).clamp(0, width - 1);
    final int by1 = (minY - bracketPadding).clamp(0, height - 1);
    final int by2 = (maxY + bracketPadding).clamp(0, height - 1);

    // Color definitions
    final int coreColor;
    final int haloColor;
    final int tagColor;

    switch (reticlePalette) {
      case 'dangerAmber':
        coreColor = 0xFFFFB000;
        haloColor = 0x88FF7700;
        tagColor = 0xFFFFD700;
        break;
      case 'targetingRed':
        coreColor = 0xFFFF003C;
        haloColor = 0x88990022;
        tagColor = 0xFFFF5577;
        break;
      case 'matrixGreen':
        coreColor = 0xFF00FF66;
        haloColor = 0x88007733;
        tagColor = 0xFF88FFAA;
        break;
      case 'cyberCyan':
      default:
        coreColor = 0xFF00F0FF;
        haloColor = 0x88006688;
        tagColor = 0xFFB0FFFF;
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

    // 2. Render 4 Corner L-Brackets
    final bLen = bracketLength.clamp(2, (bx2 - bx1 + 1) ~/ 2);
    final bLenY = bracketLength.clamp(2, (by2 - by1 + 1) ~/ 2);

    // Top-Left corner
    for (int dx = 0; dx < bLen; dx++) {
      setPixel(bx1 + dx, by1, coreColor);
      setPixel(bx1 + dx, by1 + 1, haloColor);
    }
    for (int dy = 0; dy < bLenY; dy++) {
      setPixel(bx1, by1 + dy, coreColor);
      setPixel(bx1 + 1, by1 + dy, haloColor);
    }
    // Corner accent tick
    if (bx1 > 0 && by1 > 0) setPixel(bx1 - 1, by1 - 1, haloColor);

    // Top-Right corner
    for (int dx = 0; dx < bLen; dx++) {
      setPixel(bx2 - dx, by1, coreColor);
      setPixel(bx2 - dx, by1 + 1, haloColor);
    }
    for (int dy = 0; dy < bLenY; dy++) {
      setPixel(bx2, by1 + dy, coreColor);
      setPixel(bx2 - 1, by1 + dy, haloColor);
    }
    if (bx2 < width - 1 && by1 > 0) setPixel(bx2 + 1, by1 - 1, haloColor);

    // Bottom-Left corner
    for (int dx = 0; dx < bLen; dx++) {
      setPixel(bx1 + dx, by2, coreColor);
      setPixel(bx1 + dx, by2 - 1, haloColor);
    }
    for (int dy = 0; dy < bLenY; dy++) {
      setPixel(bx1, by2 - dy, coreColor);
      setPixel(bx1 + 1, by2 - dy, haloColor);
    }
    if (bx1 > 0 && by2 < height - 1) setPixel(bx1 - 1, by2 + 1, haloColor);

    // Bottom-Right corner
    for (int dx = 0; dx < bLen; dx++) {
      setPixel(bx2 - dx, by2, coreColor);
      setPixel(bx2 - dx, by2 - 1, haloColor);
    }
    for (int dy = 0; dy < bLenY; dy++) {
      setPixel(bx2, by2 - dy, coreColor);
      setPixel(bx2 - 1, by2 - dy, haloColor);
    }
    if (bx2 < width - 1 && by2 < height - 1) setPixel(bx2 + 1, by2 + 1, haloColor);

    // 3. Render Crosshair Axes (excluding deadzone)
    if (showCrosshairs) {
      // Horizontal crosshair
      for (int x = bx1; x <= bx2; x++) {
        final dist = (x - cx).abs();
        if (dist >= deadzoneRadius && dist <= (bx2 - bx1) ~/ 2 + 2) {
          // Dash pattern: every 2nd or 3rd pixel for a tactical look
          if (dist % 2 == 0) {
            setPixel(x, cy, coreColor);
          } else {
            setPixel(x, cy, haloColor);
          }
        }
      }
      // Centroid deadzone notch marks
      setPixel(cx - deadzoneRadius, cy - 1, coreColor);
      setPixel(cx - deadzoneRadius, cy + 1, coreColor);
      setPixel(cx + deadzoneRadius, cy - 1, coreColor);
      setPixel(cx + deadzoneRadius, cy + 1, coreColor);

      // Vertical crosshair
      for (int y = by1; y <= by2; y++) {
        final dist = (y - cy).abs();
        if (dist >= deadzoneRadius && dist <= (by2 - by1) ~/ 2 + 2) {
          if (dist % 2 == 0) {
            setPixel(cx, y, coreColor);
          } else {
            setPixel(cx, y, haloColor);
          }
        }
      }
      setPixel(cx - 1, cy - deadzoneRadius, coreColor);
      setPixel(cx + 1, cy - deadzoneRadius, coreColor);
      setPixel(cx - 1, cy + deadzoneRadius, coreColor);
      setPixel(cx + 1, cy + deadzoneRadius, coreColor);
    }

    // 4. Render Sci-Fi Telemetry & Lock Status Indicators
    if (showTelemetry) {
      // Micro "[+]" or lock chevron at top frame center
      final tagY = by1 - 3;
      if (tagY >= 0) {
        // Mini targeting diamond/cross above frame
        setPixel(cx, tagY, tagColor);
        setPixel(cx - 1, tagY + 1, coreColor);
        setPixel(cx + 1, tagY + 1, coreColor);
        setPixel(cx, tagY + 2, coreColor);
      }

      // Rangefinder corner ticks on right border
      final rightMidY = (by1 + by2) ~/ 2;
      setPixel(bx2 + 1, rightMidY - 3, coreColor);
      setPixel(bx2 + 2, rightMidY - 3, haloColor);
      setPixel(bx2 + 1, rightMidY, tagColor);
      setPixel(bx2 + 2, rightMidY, coreColor);
      setPixel(bx2 + 3, rightMidY, haloColor);
      setPixel(bx2 + 1, rightMidY + 3, coreColor);
      setPixel(bx2 + 2, rightMidY + 3, haloColor);

      // Bottom lock brackets: [TGT] indicator as a 3x3 pixel glyph block
      final bottomTagY = by2 + 2;
      if (bottomTagY + 2 < height) {
        final startX = bx1 + 1;
        // Bracket open [
        setPixel(startX, bottomTagY, tagColor);
        setPixel(startX, bottomTagY + 1, tagColor);
        setPixel(startX, bottomTagY + 2, tagColor);
        setPixel(startX + 1, bottomTagY, haloColor);
        setPixel(startX + 1, bottomTagY + 2, haloColor);

        // Center dot
        setPixel(startX + 3, bottomTagY + 1, coreColor);

        // Bracket close ]
        setPixel(startX + 5, bottomTagY, haloColor);
        setPixel(startX + 5, bottomTagY + 2, haloColor);
        setPixel(startX + 6, bottomTagY, tagColor);
        setPixel(startX + 6, bottomTagY + 1, tagColor);
        setPixel(startX + 6, bottomTagY + 2, tagColor);
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
