part of 'effects.dart';

/// Procedural melee slash wave and katana sword arc effect with curved crescent
/// blade streaks, white-hot cutting edge, trailing glow, and tangential spark sprays.
class SlashArcEffect extends Effect implements UIFieldProvider {
  SlashArcEffect([Map<String, dynamic>? parameters])
      : super(
          EffectType.slashArc,
          parameters ??
              const {
                'slashAngle': -35.0,
                'arcCurvature': 0.4,
                'slashWidth': 3,
                'bladeColor': 0xFF00E5FF,
                'sparkSpray': true,
                'sparkCount': 25,
                'time': 0.0,
                'preserveAlpha': true,
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() => {
        'slashAngle': -35.0,
        'arcCurvature': 0.4,
        'slashWidth': 3,
        'bladeColor': 0xFF00E5FF,
        'sparkSpray': true,
        'sparkCount': 25,
        'time': 0.0,
        'preserveAlpha': true,
      };

  @override
  Map<String, dynamic> getMetadata() => {
        'slashAngle': {
          'label': 'Slash Stroke Angle',
          'description': 'Orientation angle of the cutting strike in degrees.',
          'type': 'slider',
          'min': -180.0,
          'max': 180.0,
          'divisions': 72,
        },
        'arcCurvature': {
          'label': 'Arc Crescent Curvature',
          'description': 'Curvature depth of the sweeping crescent blade.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 20,
        },
        'slashWidth': {
          'label': 'Blade Trail Width',
          'description': 'Thickness of the glowing cutting blade streak.',
          'type': 'slider',
          'min': 1,
          'max': 8,
          'divisions': 7,
        },
        'bladeColor': {
          'label': 'Blade Energy Color',
          'description': 'Aura and trail glow color of the weapon stroke.',
          'type': 'color',
        },
        'sparkSpray': {
          'label': 'Speed Spark Spray',
          'description': 'Spray sharp cutting friction sparks along trajectory.',
          'type': 'bool',
        },
        'sparkCount': {
          'label': 'Spark Density',
          'description': 'Number of trailing impact speed sparks.',
          'type': 'slider',
          'min': 10,
          'max': 50,
          'divisions': 40,
        },
        'time': {
          'label': 'Animation Time',
          'description': 'Timeline progress parameter sweeping the slash stroke.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 100,
        },
        'preserveAlpha': {
          'label': 'Preserve Transparency',
          'description': 'Confine slash arc within original sprite silhouette.',
          'type': 'bool',
        },
      };

  @override
  List<UIField> getFields() => [
        SliderField(
          key: 'slashAngle',
          label: 'Slash Angle',
          description: 'Directional angle of the cutting weapon sweep.',
          min: -180.0,
          max: 180.0,
          divisions: 72,
          formatLabel: (v) => '${v.round()}°',
        ),
        SliderField(
          key: 'arcCurvature',
          label: 'Arc Curvature',
          description: 'Curved bow depth of the crescent sword stroke.',
          min: 0.0,
          max: 1.0,
          divisions: 20,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        SliderField(
          key: 'slashWidth',
          label: 'Blade Width',
          description: 'Thickness of the glowing cutting trail.',
          min: 1,
          max: 8,
          divisions: 7,
          formatLabel: (v) => '${v.round()} px',
        ),
        const ColorField(
          key: 'bladeColor',
          label: 'Blade Color',
          description: 'Energy color of the weapon slash arc.',
        ),
        const BoolField(
          key: 'sparkSpray',
          label: 'Speed Sparks',
          description: 'Spray cutting friction sparks outward.',
        ),
        SliderField(
          key: 'sparkCount',
          label: 'Spark Count',
          description: 'Density of ejected speed sparks.',
          min: 10,
          max: 50,
          divisions: 40,
          formatLabel: (v) => '${v.round()} sparks',
        ),
        SliderField(
          key: 'time',
          label: 'Animation Time',
          description: 'Timeline progress of the sword sweep.',
          min: 0.0,
          max: 1.0,
          divisions: 100,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        const BoolField(
          key: 'preserveAlpha',
          label: 'Preserve Transparency',
          description: 'Keep transparency around the character bounds.',
        ),
      ];

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    final slashAngleDeg = (parameters['slashAngle'] as num?)?.toDouble() ?? -35.0;
    final arcCurvature = (parameters['arcCurvature'] as num?)?.toDouble() ?? 0.4;
    final slashWidth = (parameters['slashWidth'] as num?)?.toDouble() ?? 3.0;
    final bladeColorInt = (parameters['bladeColor'] as num?)?.toInt() ?? 0xFF00E5FF;
    final sparkSpray = parameters['sparkSpray'] as bool? ?? true;
    final sparkCount = (parameters['sparkCount'] as num?)?.toInt() ?? 25;
    final time = (parameters['time'] as num?)?.toDouble() ?? 0.0;
    final preserveAlpha = parameters['preserveAlpha'] as bool? ?? true;

    final output = Uint32List.fromList(pixels);

    final cx = width / 2.0;
    final cy = height / 2.0;
    final halfL = math.max(width, height) * 0.7;

    final rad = slashAngleDeg * (math.pi / 180.0);
    final cosA = math.cos(-rad);
    final sinA = math.sin(-rad);

    final bA = (bladeColorInt >> 24) & 0xFF;
    final bR = (bladeColorInt >> 16) & 0xFF;
    final bG = (bladeColorInt >> 8) & 0xFF;
    final bB = bladeColorInt & 0xFF;

    // Timeline normalized cycle: sweep head progresses from -halfL to +halfL
    final cycleTime = time - time.floorToDouble();
    final headU = (-1.0 + 2.0 * cycleTime) * halfL;
    final trailLen = halfL * 1.3;
    final tailU = headU - trailLen;

    // Fade out slightly towards the finish of the stroke
    final slashLifeFade = cycleTime < 0.7 ? 1.0 : (1.0 - (cycleTime - 0.7) / 0.3);

    // 1. Render blade streak arc
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final idx = y * width + x;
        final origPixel = pixels[idx];
        final origA = (origPixel >> 24) & 0xFF;

        if (preserveAlpha && origA == 0) {
          continue;
        }

        final dx = x - cx;
        final dy = y - cy;

        // Transform into slash coordinate space (u = along strike, v = perpendicular)
        final u = dx * cosA - dy * sinA;
        final v = dx * sinA + dy * cosA;

        // Curved arc offset: parabolic curve
        final normU = u / halfL;
        final curveV = arcCurvature * halfL * 0.4 * (1.0 - normU * normU);
        final distFromArc = (v - curveV).abs();

        if (distFromArc <= slashWidth && u <= headU && u >= tailU) {
          // Distance along trail from head (0.0 at head, 1.0 at tail)
          final trailT = ((headU - u) / trailLen).clamp(0.0, 1.0);
          // Intensity decays along trail length and perpendicular distance
          final widthT = 1.0 - (distFromArc / slashWidth);
          final trailIntensity = (1.0 - trailT) * widthT * slashLifeFade;

          if (trailIntensity > 0.02) {
            final oR = (origPixel >> 16) & 0xFF;
            final oG = (origPixel >> 8) & 0xFF;
            final oB = origPixel & 0xFF;

            // Razor-sharp cutting head is incandescent white, body is bladeColor
            final headGlint = trailT < 0.15 ? (1.0 - trailT / 0.15) : 0.0;
            final targetR = (bR * (1.0 - headGlint) + 255 * headGlint).round().clamp(0, 255);
            final targetG = (bG * (1.0 - headGlint) + 255 * headGlint).round().clamp(0, 255);
            final targetB = (bB * (1.0 - headGlint) + 255 * headGlint).round().clamp(0, 255);

            final newR = (oR + targetR * trailIntensity).round().clamp(0, 255);
            final newG = (oG + targetG * trailIntensity).round().clamp(0, 255);
            final newB = (oB + targetB * trailIntensity).round().clamp(0, 255);
            final newA = preserveAlpha ? origA : math.max(origA, (trailIntensity * bA).round().clamp(0, 255));

            output[idx] = (newA << 24) | (newR << 16) | (newG << 8) | newB;
          }
        }
      }
    }

    // 2. High-speed directional sparks
    if (sparkSpray && sparkCount > 0) {
      for (int i = 0; i < sparkCount; i++) {
        // Sparks emit from points trailing slightly behind the head
        final emitFraction = ((i * 37 + 13) % 100) / 100.0;
        final sparkU = headU - emitFraction * (trailLen * 0.7);
        final sparkNormU = sparkU / halfL;
        final sparkCurveV = arcCurvature * halfL * 0.4 * (1.0 - sparkNormU * sparkNormU);

        // Sparks fly outwards along v and backwards along u
        final flyProgress = emitFraction;
        final sparkDistV = (i % 2 == 0 ? 1 : -1) * (1.5 + ((i * 53) % 10)) * flyProgress * 1.5;
        final finalU = sparkU - flyProgress * 3.0;
        final finalV = sparkCurveV + sparkDistV;

        // Convert back to canvas coordinate space
        // dx = u cosA + v sinA, dy = -u sinA + v cosA
        final px = (cx + finalU * math.cos(rad) - finalV * math.sin(rad)).round();
        final py = (cy + finalU * math.sin(rad) + finalV * math.cos(rad)).round();

        if (px >= 0 && px < width && py >= 0 && py < height) {
          final sIdx = py * width + px;
          final origPixel = pixels[sIdx];
          final origA = (origPixel >> 24) & 0xFF;

          if (preserveAlpha && origA == 0) {
            continue;
          }

          final sparkFade = (1.0 - flyProgress) * slashLifeFade;
          if (sparkFade > 0.05) {
            final oR = (origPixel >> 16) & 0xFF;
            final oG = (origPixel >> 8) & 0xFF;
            final oB = origPixel & 0xFF;

            // Spark is hot white-yellow or blade tinted
            final sR = (bR * 0.5 + 200 * 0.5).round().clamp(0, 255);
            final sG = (bG * 0.5 + 230 * 0.5).round().clamp(0, 255);
            final sB = (bB * 0.5 + 255 * 0.5).round().clamp(0, 255);

            final newR = (oR + sR * sparkFade).round().clamp(0, 255);
            final newG = (oG + sG * sparkFade).round().clamp(0, 255);
            final newB = (oB + sB * sparkFade).round().clamp(0, 255);
            final newA = preserveAlpha ? origA : math.max(origA, (sparkFade * 255).round().clamp(0, 255));

            output[sIdx] = (newA << 24) | (newR << 16) | (newG << 8) | newB;
          }
        }
      }
    }

    return output;
  }
}
