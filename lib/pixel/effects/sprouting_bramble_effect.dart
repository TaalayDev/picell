part of 'effects.dart';

/// Spawns verdant creeping moss, climbing vine tendrils, and blooming micro-flowers
/// wherever the character's feet make contact with the ground baseline.
class SproutingBrambleEffect extends Effect {
  SproutingBrambleEffect([Map<String, dynamic>? params])
      : super(
          EffectType.sproutingBramble,
          params ??
              {
                'growthSpread': 10.0,
                'brambleHeight': 5.0,
                'flowerDensity': 0.6,
                'naturePalette': 'enchantedMeadow',
                'behindOnly': false,
              },
        );

  @override
  Map<String, dynamic> getDefaultParameters() => {
        'growthSpread': 10.0,
        'brambleHeight': 5.0,
        'flowerDensity': 0.6,
        'naturePalette': 'enchantedMeadow',
        'behindOnly': false,
      };

  @override
  Map<String, dynamic> getMetadata() => {
        'growthSpread': {
          'label': 'Foliage Ground Spread',
          'description': 'Lateral distance creeping vines and moss spread along the ground.',
          'type': 'slider',
          'min': 4.0,
          'max': 20.0,
          'step': 1.0,
        },
        'brambleHeight': {
          'label': 'Vine Tendril Height',
          'description': 'Vertical climbing height of sprouted bramble stalks.',
          'type': 'slider',
          'min': 2.0,
          'max': 10.0,
          'step': 0.5,
        },
        'flowerDensity': {
          'label': 'Wildflower Bloom Density',
          'description': 'Abundance of blossoming micro-flowers at tendril tips.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'step': 0.1,
        },
        'naturePalette': {
          'label': 'Botanical Flora Palette',
          'description': 'Coloration of the vines, leaves, and wildflower petals.',
          'type': 'dropdown',
          'options': [
            {'value': 'enchantedMeadow', 'label': 'Enchanted Meadow (Emerald / Forest Moss / Rose Pink / Gold)'},
            {'value': 'witherThorn', 'label': 'Cursed Wither (Ash Thorn / Dark Purple / Wither Black / Bone)'},
            {'value': 'autumnFoliage', 'label': 'Autumn Harvest (Crimson Vine / Golden Amber / Burnt Ochre)'},
            {'value': 'celestialFlora', 'label': 'Celestial Flora (Starry Cyan / Moonlight White / Violet Core)'},
          ],
        },
        'behindOnly': {
          'label': 'Render Behind Sprite',
          'description': 'When enabled, renders foliage strictly behind existing sprite pixels.',
          'type': 'bool',
        },
      };

  @override
  List<UIField> getFields() => [
        SliderField(
          key: 'growthSpread',
          label: 'Foliage Ground Spread',
          description: 'Lateral distance creeping vines and moss spread along the ground.',
          min: 4.0,
          max: 20.0,
          divisions: 16,
          formatLabel: (v) => '${v.round()}px',
        ),
        SliderField(
          key: 'brambleHeight',
          label: 'Vine Tendril Height',
          description: 'Vertical climbing height of sprouted bramble stalks.',
          min: 2.0,
          max: 10.0,
          divisions: 16,
          formatLabel: (v) => '${v.toStringAsFixed(1)}px',
        ),
        SliderField(
          key: 'flowerDensity',
          label: 'Wildflower Bloom Density',
          description: 'Abundance of blossoming micro-flowers at tendril tips.',
          min: 0.0,
          max: 1.0,
          divisions: 10,
          formatLabel: (v) => '${(v * 100).round()}%',
        ),
        const SelectField(
          key: 'naturePalette',
          label: 'Botanical Flora Palette',
          description: 'Coloration of the vines, leaves, and wildflower petals.',
          options: {
            'enchantedMeadow': 'Enchanted Meadow (Emerald / Rose Pink / Gold)',
            'witherThorn': 'Cursed Wither (Ash Thorn / Purple / Wither Black)',
            'autumnFoliage': 'Autumn Harvest (Crimson / Amber / Burnt Ochre)',
            'celestialFlora': 'Celestial Flora (Star Cyan / Moonlight / Violet)',
          },
        ),
        const BoolField(
          key: 'behindOnly',
          label: 'Render Behind Sprite',
          description: 'When enabled, renders foliage strictly behind existing sprite pixels.',
        ),
      ];

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    final output = Uint32List(width * height);
    output.setAll(0, pixels);

    final growthSpread = ((parameters['growthSpread'] as num?)?.toDouble() ?? 10.0).clamp(4.0, 20.0);
    final brambleHeight = ((parameters['brambleHeight'] as num?)?.toDouble() ?? 5.0).clamp(2.0, 10.0);
    final flowerDensity = ((parameters['flowerDensity'] as num?)?.toDouble() ?? 0.6).clamp(0.0, 1.0);
    final paletteKey = parameters['naturePalette'] as String? ?? 'enchantedMeadow';
    final behindOnly = parameters['behindOnly'] as bool? ?? false;

    // 1. Locate bottom baseline and foot contact points
    int maxY = -1;
    for (int y = height - 1; y >= 0; y--) {
      for (int x = 0; x < width; x++) {
        if (((pixels[y * width + x] >> 24) & 0xFF) > 20) {
          maxY = y;
          break;
        }
      }
      if (maxY != -1) break;
    }

    if (maxY == -1) return output;

    final contactXs = <int>[];
    for (int y = math.max(0, maxY - 1); y <= maxY; y++) {
      for (int x = 0; x < width; x++) {
        if (((pixels[y * width + x] >> 24) & 0xFF) > 20) {
          contactXs.add(x);
        }
      }
    }

    if (contactXs.isEmpty) return output;
    contactXs.sort();

    final minX = contactXs.first.toDouble();
    final maxX = contactXs.last.toDouble();
    final centerX = (minX + maxX) * 0.5;
    final baseY = maxY.toDouble();

    final colors = _getBrambleColors(paletteKey);

    void setFloraPixel(int x, int y, int color) {
      if (x < 0 || x >= width || y < 0 || y >= height) return;
      final idx = y * width + x;
      if (behindOnly && ((pixels[idx] >> 24) & 0xFF) > 30) return;
      output[idx] = _blendPixel(output[idx], color);
    }

    // 2. Creeping ground root mat and moss bed
    final startX = (minX - growthSpread).round().clamp(0, width - 1);
    final endX = (maxX + growthSpread).round().clamp(0, width - 1);

    for (int x = startX; x <= endX; x++) {
      final distFromCenter = (x - centerX).abs();
      final spreadNorm = (distFromCenter / (growthSpread + (maxX - minX) * 0.5)).clamp(0.0, 1.0);
      final mossAlpha = (240 * (1.0 - spreadNorm * 0.5)).round().clamp(0, 255);

      final hash = ((x * 83 + (baseY.round()) * 199) ^ 0x4B3A) & 0x7FFFFFFF;

      // Baseline mat
      final rootColor = (hash % 3 == 0) ? colors.vine : colors.moss;
      setFloraPixel(x, maxY, (mossAlpha << 24) | (rootColor & 0x00FFFFFF));

      // 1px lower soil/moss fringe
      if (maxY + 1 < height && hash % 4 != 0) {
        final fringeAlpha = (mossAlpha * 0.75).round();
        setFloraPixel(x, maxY + 1, (fringeAlpha << 24) | (colors.moss & 0x00FFFFFF));
      }
    }

    // 3. Sprouting climbing vine tendrils
    final sproutStep = math.max(2, ((endX - startX) / 8).round());

    for (int sx = startX + 1; sx < endX; sx += sproutStep) {
      final sproutHash = ((sx * 137 + (baseY.round()) * 293) ^ 0x6C2E) & 0x7FFFFFFF;
      final distFromCenter = (sx - centerX).abs();
      final reachFactor = 1.0 - (distFromCenter / (growthSpread + (maxX - minX) * 0.5)).clamp(0.0, 0.8);
      final tendrilH = (brambleHeight * reachFactor * (0.6 + (sproutHash % 5) * 0.1)).round().clamp(2, 10);

      final curlDir = (sx < centerX) ? -1 : 1;
      int currX = sx;

      for (int h = 1; h <= tendrilH; h++) {
        final py = maxY - h;
        if (py < 0) break;

        // Slight horizontal sway/curl
        if (h % 2 == 0) {
          currX += curlDir;
          currX = currX.clamp(0, width - 1);
        }

        // Stem pixel
        setFloraPixel(currX, py, (245 << 24) | (colors.vine & 0x00FFFFFF));

        // Leaf nodule on side
        if (h % 2 == 1 && (sproutHash + h) % 3 != 0) {
          final leafX = currX - curlDir;
          setFloraPixel(leafX, py, (220 << 24) | (colors.leaf & 0x00FFFFFF));
        }

        // Flower bloom at tip
        if (h == tendrilH && flowerDensity > 0.05) {
          final bloomCheck = (sproutHash + h) % 10;
          if (bloomCheck < flowerDensity * 10) {
            // Draw 3px blossom (cross petals + center pollen)
            setFloraPixel(currX, py, (255 << 24) | (colors.pollen & 0x00FFFFFF));
            setFloraPixel(currX - 1, py, (240 << 24) | (colors.petal & 0x00FFFFFF));
            setFloraPixel(currX + 1, py, (240 << 24) | (colors.petal & 0x00FFFFFF));
            setFloraPixel(currX, py - 1, (240 << 24) | (colors.petal & 0x00FFFFFF));
          }
        }
      }
    }

    return output;
  }

  int _blendPixel(int dst, int src) {
    final sa = (src >> 24) & 0xFF;
    if (sa == 0) return dst;
    if (sa == 255) return src;
    final da = (dst >> 24) & 0xFF;
    if (da == 0) return src;

    final sf = sa / 255.0;
    final df = (da / 255.0) * (1.0 - sf);
    final outA = sf + df;
    if (outA <= 0.0) return 0;

    final sr = (src >> 16) & 0xFF;
    final sg = (src >> 8) & 0xFF;
    final sb = src & 0xFF;

    final dr = (dst >> 16) & 0xFF;
    final dg = (dst >> 8) & 0xFF;
    final db = dst & 0xFF;

    final r = ((sr * sf + dr * df) / outA).round().clamp(0, 255);
    final g = ((sg * sf + dg * df) / outA).round().clamp(0, 255);
    final b = ((sb * sf + db * df) / outA).round().clamp(0, 255);
    final a = (outA * 255.0).round().clamp(0, 255);

    return (a << 24) | (r << 16) | (g << 8) | b;
  }

  _BrambleColors _getBrambleColors(String palette) {
    switch (palette) {
      case 'witherThorn':
        return const _BrambleColors(
          vine: 0xFF3E2723,
          moss: 0xFF1A1A1A,
          leaf: 0xFF4E342E,
          petal: 0xFF7B1FA2,
          pollen: 0xFFD7CCC8,
        );
      case 'autumnFoliage':
        return const _BrambleColors(
          vine: 0xFF5D4037,
          moss: 0xFF3E2723,
          leaf: 0xFFFF8F00,
          petal: 0xFFB71C1C,
          pollen: 0xFFFFD54F,
        );
      case 'celestialFlora':
        return const _BrambleColors(
          vine: 0xFF0D47A1,
          moss: 0xFF004D40,
          leaf: 0xFF00E5FF,
          petal: 0xFFAA00FF,
          pollen: 0xFFFFFF00,
        );
      case 'enchantedMeadow':
      default:
        return const _BrambleColors(
          vine: 0xFF1B5E20,
          moss: 0xFF00C853,
          leaf: 0xFF69F0AE,
          petal: 0xFFFF4081,
          pollen: 0xFFFFEB3B,
        );
    }
  }
}

class _BrambleColors {
  final int vine;
  final int moss;
  final int leaf;
  final int petal;
  final int pollen;

  const _BrambleColors({
    required this.vine,
    required this.moss,
    required this.leaf,
    required this.petal,
    required this.pollen,
  });
}
