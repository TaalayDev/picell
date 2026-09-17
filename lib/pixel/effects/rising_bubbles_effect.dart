part of 'effects.dart';

/// Procedural rising bubbles and potion effervescence effect with buoyant
/// multi-size bubbles, lateral wobble sway, specular highlights, and surface popping.
class RisingBubblesEffect extends Effect implements UIFieldProvider {
  RisingBubblesEffect([Map<String, dynamic>? parameters])
      : super(
          EffectType.risingBubbles,
          parameters ??
              const {
                'bubbleCount': 20,
                'bubbleSize': 'mixed',
                'wobbleSpeed': 1.5,
                'riseSpeed': 1.2,
                'bubbleColor': 0xFFE0F7FA,
                'popSplashes': true,
                'time': 0.0,
                'preserveAlpha': true,
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() => {
        'bubbleCount': 20,
        'bubbleSize': 'mixed',
        'wobbleSpeed': 1.5,
        'riseSpeed': 1.2,
        'bubbleColor': 0xFFE0F7FA,
        'popSplashes': true,
        'time': 0.0,
        'preserveAlpha': true,
      };

  @override
  Map<String, dynamic> getMetadata() => {
        'bubbleCount': {
          'label': 'Bubble Density',
          'description': 'Number of active rising bubbles in the liquid.',
          'type': 'slider',
          'min': 6,
          'max': 60,
          'divisions': 54,
        },
        'bubbleSize': {
          'label': 'Bubble Size Profile',
          'description': 'Dimensions and distribution of bubble radii.',
          'type': 'select',
          'options': {
            'small': 'Small Fizz (1-2px)',
            'mixed': 'Mixed Effervescence (1-3px)',
            'large': 'Large Potion Bubbles (2-4px)',
          },
        },
        'wobbleSpeed': {
          'label': 'Wobble Flutter Speed',
          'description': 'Frequency of lateral drifting and hydrodynamic wobble.',
          'type': 'slider',
          'min': 0.5,
          'max': 3.0,
          'divisions': 50,
        },
        'riseSpeed': {
          'label': 'Buoyant Ascent Speed',
          'description': 'Vertical upward velocity of the bubbles.',
          'type': 'slider',
          'min': 0.5,
          'max': 3.0,
          'divisions': 50,
        },
        'bubbleColor': {
          'label': 'Bubble Tint Color',
          'description': 'Color of the bubble membrane and translucent sheen.',
          'type': 'color',
        },
        'popSplashes': {
          'label': 'Surface Popping',
          'description': 'Burst into tiny splash droplets upon reaching the surface.',
          'type': 'bool',
        },
        'time': {
          'label': 'Animation Time',
          'description': 'Timeline progress parameter for looping bubble ascent.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 100,
        },
        'preserveAlpha': {
          'label': 'Preserve Transparency',
          'description': 'Allow bubbles to float cleanly over transparent canvas.',
          'type': 'bool',
        },
      };

  @override
  List<UIField> getFields() => [
        SliderField(
          key: 'bubbleCount',
          label: 'Bubble Count',
          description: 'Total number of bubbles rising simultaneously.',
          min: 6,
          max: 60,
          divisions: 54,
          formatLabel: (v) => '${v.round()} bubbles',
        ),
        const SelectField(
          key: 'bubbleSize',
          label: 'Bubble Sizes',
          description: 'Diameter distribution of the rising bubbles.',
          options: {
            'small': 'Small Fizz (1-2px)',
            'mixed': 'Mixed Effervescence (1-3px)',
            'large': 'Large Potion Bubbles (2-4px)',
          },
        ),
        SliderField(
          key: 'wobbleSpeed',
          label: 'Wobble Speed',
          description: 'Hydrodynamic lateral sway frequency.',
          min: 0.5,
          max: 3.0,
          divisions: 50,
          formatLabel: (v) => '${v.toStringAsFixed(1)}x',
        ),
        SliderField(
          key: 'riseSpeed',
          label: 'Ascent Velocity',
          description: 'Speed of vertical buoyant rise.',
          min: 0.5,
          max: 3.0,
          divisions: 50,
          formatLabel: (v) => '${v.toStringAsFixed(1)}x',
        ),
        const ColorField(
          key: 'bubbleColor',
          label: 'Bubble Tint',
          description: 'Color of the bubble perimeter and sheen.',
        ),
        const BoolField(
          key: 'popSplashes',
          label: 'Surface Popping',
          description: 'Render bursting micro-droplets as bubbles reach the liquid surface.',
        ),
        SliderField(
          key: 'time',
          label: 'Animation Time',
          description: 'Timeline progress parameter updated during animation generation.',
          min: 0.0,
          max: 1.0,
          divisions: 100,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        const BoolField(
          key: 'preserveAlpha',
          label: 'Preserve Transparency',
          description: 'When enabled, bubbles float over transparent pixels.',
        ),
      ];

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    if (width <= 0 || height <= 0 || pixels.isEmpty) return pixels;

    final bubbleCount = ((parameters['bubbleCount'] as num?)?.toInt() ?? 20).clamp(6, 60);
    final bubbleSize = (parameters['bubbleSize'] as String?) ?? 'mixed';
    final wobbleSpeed = ((parameters['wobbleSpeed'] as num?)?.toDouble() ?? 1.5).clamp(0.5, 3.0);
    final riseSpeed = ((parameters['riseSpeed'] as num?)?.toDouble() ?? 1.2).clamp(0.5, 3.0);
    final bubbleColorInt = (parameters['bubbleColor'] as int?) ?? 0xFFE0F7FA;
    final popSplashes = parameters['popSplashes'] as bool? ?? true;
    final time = ((parameters['time'] as num?)?.toDouble() ?? 0.0).clamp(0.0, 1.0);
    final preserveAlpha = parameters['preserveAlpha'] as bool? ?? true;

    final bubR = (bubbleColorInt >> 16) & 0xFF;
    final bubG = (bubbleColorInt >> 8) & 0xFF;
    final bubB = bubbleColorInt & 0xFF;

    final result = Uint32List(width * height);
    if (preserveAlpha) {
      result.setAll(0, pixels);
    } else {
      const darkPotion = 0xFF051B24;
      const bgR = (darkPotion >> 16) & 0xFF;
      const bgG = (darkPotion >> 8) & 0xFF;
      const bgB = darkPotion & 0xFF;
      result.fillRange(0, result.length, darkPotion);
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

    void plotPixel(int px, int py, int r, int g, int b, int alpha) {
      if (px < 0 || px >= width || py < 0 || py >= height) return;
      final idx = py * width + px;

      final existing = result[idx];
      final exA = (existing >> 24) & 0xFF;
      final exR = (existing >> 16) & 0xFF;
      final exG = (existing >> 8) & 0xFF;
      final exB = existing & 0xFF;

      final na = alpha / 255.0;
      final outR = math.min(255, (exR * (1.0 - na) + r * na).round());
      final outG = math.min(255, (exG * (1.0 - na) + g * na).round());
      final outB = math.min(255, (exB * (1.0 - na) + b * na).round());
      final outA = math.max(exA, alpha);

      result[idx] = (outA << 24) | (outR << 16) | (outG << 8) | outB;
    }

    final rand = math.Random(101);

    for (int i = 0; i < bubbleCount; i++) {
      final seedX = rand.nextDouble() * width;
      final seedY = rand.nextDouble() * height;
      final speedFactor = 0.6 + rand.nextDouble() * 0.8;

      // Determine bubble radius
      int rad = 1;
      if (bubbleSize == 'small') {
        rad = 1;
      } else if (bubbleSize == 'large') {
        rad = 2 + rand.nextInt(3); // 2, 3, 4
      } else {
        // mixed
        final rRoll = rand.nextDouble();
        if (rRoll < 0.55) {
          rad = 1;
        } else if (rRoll < 0.85) {
          rad = 2;
        } else {
          rad = 3;
        }
      }

      // Vertical rise with seamless wrapping modulo
      final curY = ((seedY - time * height * riseSpeed * speedFactor) % height + height) % height;
      final sway = math.sin(curY * 0.25 + time * 6.28 * wobbleSpeed + i) * (1.5 + rad * 0.5);
      final curX = ((seedX + sway) % width + width) % width;

      final bx = curX.round();
      final by = curY.round();

      // Check surface pop
      if (curY < 3.0 && popSplashes) {
        // Pop particles
        final popProgress = (curY / 3.0).clamp(0.0, 1.0);
        final popAlpha = (popProgress * 220).round();
        plotPixel(bx - 2, by, bubR, bubG, bubB, popAlpha);
        plotPixel(bx + 2, by, bubR, bubG, bubB, popAlpha);
        plotPixel(bx, by - 1, 255, 255, 255, popAlpha);
        continue;
      }

      if (rad == 1) {
        // Single bright bubble pixel
        plotPixel(bx, by, bubR, bubG, bubB, 220);
      } else {
        // Render circular bubble with perimeter rim, sheen, and specular highlight
        for (int dy = -rad; dy <= rad; dy++) {
          for (int dx = -rad; dx <= rad; dx++) {
            final distSq = dx * dx + dy * dy;
            if (distSq <= rad * rad) {
              final isRim = distSq >= (rad - 1) * (rad - 1);
              final isHighlight = (dx == -rad ~/ 2 && dy == -rad ~/ 2);

              if (isHighlight) {
                // Shiny white starlight specular highlight
                plotPixel(bx + dx, by + dy, 255, 255, 255, 255);
              } else if (isRim) {
                // Bubble membrane rim
                plotPixel(bx + dx, by + dy, bubR, bubG, bubB, 210);
              } else {
                // Translucent bubble interior sheen
                plotPixel(bx + dx, by + dy, bubR, bubG, bubB, 50);
              }
            }
          }
        }
      }
    }

    return result;
  }
}
