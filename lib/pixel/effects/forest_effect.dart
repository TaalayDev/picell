part of 'effects.dart';

/// A layered woodland planned on rolling terrain with species-specific trees.
/// Independent random streams keep scenery stable when lighting is adjusted.
class ForestEffect extends Effect {
  static const _defaults = <String, dynamic>{
    'layers': 4,
    'treeDensity': 0.5,
    'treeType': 2,
    'sizeVariation': 0.4,
    'baseHeight': 0.45,
    'colorScheme': 0,
    'atmosphericHaze': 0.5,
    'sunPosition': 0.75,
    'groundLevel': 0.82,
    'randomSeed': 42,
    'enableShadows': true,
    'shadowDirection': 0.3,
    'shadowSoftness': 0.55,
    'enableUndergrowth': true,
    'undergrowthDensity': 0.6,
    'lightingAngle': 0.7,
    'rimLight': 0.18,
    'enableMist': false,
    'mistHeight': 0.3,
    'mistIntensity': 0.35,
    'treeSpacing': 0.5,
    'groundTexture': 0.25,
    'godRays': 0.0,
    'terrainRelief': 0.35,
  };

  ForestEffect([Map<String, dynamic>? parameters]) : super(EffectType.forest, {..._defaults, ...?parameters});

  @override
  Map<String, dynamic> getDefaultParameters() => {..._defaults};

  @override
  Map<String, dynamic> getMetadata() => {
        'terrainRelief': {
          'label': 'Rolling Terrain',
          'description': 'Height and shape of forested ridges.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 100
        },
        'layers': {
          'label': 'Forest Layers',
          'description': 'Number of depth layers for parallax effect.',
          'type': 'slider',
          'min': 1,
          'max': 6,
          'divisions': 5,
        },
        'treeDensity': {
          'label': 'Tree Density',
          'description': 'How densely packed the trees are.',
          'type': 'slider',
          'min': 0.1,
          'max': 1.0,
          'divisions': 90,
        },
        'treeType': {
          'label': 'Tree Type',
          'description': 'Style of trees to generate.',
          'type': 'select',
          'options': {
            0: 'Pine/Conifer',
            1: 'Deciduous (Oak/Maple)',
            2: 'Mixed Forest',
            3: 'Birch',
            4: 'Willow',
          },
        },
        'sizeVariation': {
          'label': 'Size Variation',
          'description': 'Randomness in tree sizes.',
          'type': 'slider',
          'min': 0.0,
          'max': 0.8,
          'divisions': 80,
        },
        'baseHeight': {
          'label': 'Tree Height',
          'description': 'Average height of trees relative to canvas.',
          'type': 'slider',
          'min': 0.2,
          'max': 0.7,
          'divisions': 50,
        },
        'colorScheme': {
          'label': 'Season/Time',
          'description': 'Color palette and mood.',
          'type': 'select',
          'options': {
            0: 'Summer',
            1: 'Autumn',
            2: 'Winter',
            3: 'Night',
            4: 'Misty Morning',
            5: 'Sunset',
          },
        },
        'atmosphericHaze': {
          'label': 'Atmospheric Depth',
          'description': 'How much distant objects fade.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 100,
        },
        'sunPosition': {
          'label': 'Sun Position',
          'description': 'Sun horizontal position (0=left, 1=right).',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 100,
        },
        'groundLevel': {
          'label': 'Horizon Position',
          'description': 'Where the ground meets the sky.',
          'type': 'slider',
          'min': 0.5,
          'max': 0.95,
          'divisions': 45,
        },
        'enableShadows': {
          'label': 'Tree Shadows',
          'description': 'Enable shadow casting.',
          'type': 'bool',
        },
        'shadowDirection': {
          'label': 'Shadow Direction',
          'description': 'Direction of shadows (-1=left, 1=right).',
          'type': 'slider',
          'min': -1.0,
          'max': 1.0,
          'divisions': 200,
        },
        'shadowSoftness': {
          'label': 'Shadow Softness',
          'description': 'Softness of shadows (0=hard, 1=soft).',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 100,
        },
        'enableUndergrowth': {
          'label': 'Undergrowth',
          'description': 'Add bushes and ground vegetation.',
          'type': 'bool',
        },
        'undergrowthDensity': {
          'label': 'Undergrowth Density',
          'description': 'Amount of ground vegetation.',
          'type': 'slider',
          'min': 0.1,
          'max': 1.0,
          'divisions': 90,
        },
        'lightingAngle': {
          'label': 'Time of Day',
          'description': '0=noon, 1=dawn/dusk (warmer + longer shadows).',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 100,
        },
        'rimLight': {
          'label': 'Rim Light',
          'description': 'Adds a subtle rim highlight facing the sun.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 100,
        },
        'enableMist': {
          'label': 'Ground Mist',
          'description': 'Add low-lying mist effect.',
          'type': 'bool',
        },
        'mistHeight': {
          'label': 'Mist Height',
          'description': 'How high the mist rises.',
          'type': 'slider',
          'min': 0.1,
          'max': 0.6,
          'divisions': 50,
        },
        'mistIntensity': {
          'label': 'Mist Intensity',
          'description': 'Opacity of mist.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 100,
        },
        'treeSpacing': {
          'label': 'Tree Spacing',
          'description': 'Minimum distance between trees.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 100,
        },
        'groundTexture': {
          'label': 'Ground Texture',
          'description': 'Adds noise texture to the ground.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 100,
        },
        'godRays': {
          'label': 'God Rays',
          'description': 'Cheap sun rays through canopy (works best with mist).',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 100,
        },
        'randomSeed': {
          'label': 'Random Seed',
          'description': 'Change for different forest layouts.',
          'type': 'slider',
          'min': 1,
          'max': 999,
          'divisions': 998,
        },
      };

  double _value(String key) {
    final value = parameters[key];
    return value is num && value.isFinite ? value.toDouble() : (_defaults[key] as num).toDouble();
  }

  double _unit(String key) => _value(key).clamp(0.0, 1.0);
  bool _on(String key) => parameters[key] == true;

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    if (width <= 0 || height <= 0) return Uint32List(pixels.length);
    if (pixels.length != width * height) {
      throw ArgumentError('Forest canvas dimensions must match the pixel buffer.');
    }
    final out = Uint32List(pixels.length);
    final p = _WoodlandRaster(out, width, height);
    final seed = _value('randomSeed').round();
    final scheme = _value('colorScheme').round().clamp(0, 5);
    final pal = _WoodlandPalette.schemes[scheme];
    final layers = _value('layers').round().clamp(1, 6);
    final horizon = (_unit('groundLevel') * height).round();
    final scale = max(1, min(width, height) ~/ 120);
    final sunX = _unit('sunPosition') * width;
    final sunY = height * .25;

    for (var layer = 0; layer < layers; layer++) {
      final depth = (layer + 1) / layers;
      final haze = (1 - depth) * _unit('atmosphericHaze') * .85;
      final foliage = _woodMix(pal.leaf, pal.haze, haze);
      final shadow = _woodMix(pal.dark, pal.haze, haze);
      final highlight = _woodMix(pal.highlight, pal.haze, haze);
      final bark = _woodMix(pal.bark, pal.haze, haze);
      final ground = _woodMix(pal.ground, pal.haze, haze);
      final ridge = List<int>.generate(width, (x) => _ground(x, width, height, horizon, depth, seed));
      for (var x = 0; x < width; x++) {
        for (var y = max(0, ridge[x]); y < height; y++) {
          var color = ground;
          if (layer == layers - 1) {
            final t = (y - ridge[x]) / max(1, height - ridge[x]);
            color = _woodMix(ground, pal.dark, t * .35);
            final grain = _woodHash(seed, x ~/ scale, y ~/ scale);
            if (grain < _unit('groundTexture') * .22) {
              color = _woodMix(color, highlight, .3);
            }
          }
          p.dot(x, y, color);
        }
      }
      final random = Random(seed ^ ((layer + 1) * 0x45d9));
      final trees = <_WoodlandTree>[];
      final average = max(3.0, width * (.035 + .045 * _unit('treeSpacing')) * (.5 + depth * .7));
      var x = -average / 2;
      while (x < width + average) {
        final tx = x.round();
        final roll = random.nextDouble();
        final variation = random.nextDouble();
        final treeSeed = random.nextInt(0x7fffffff);
        final grove = _woodNoise(x / max(1, width) * 5, depth * 3, seed);
        if (roll < _unit('treeDensity') * (.65 + .5 * grove)) {
          final base = ridge[tx.clamp(0, width - 1)];
          final th = max(
              3,
              (height * _unit('baseHeight') * (.38 + depth * .68) * (1 + (variation - .5) * _unit('sizeVariation')))
                  .round());
          final type = _value('treeType').round().clamp(0, 4);
          // Mixed forests grow in related groves instead of alternating species.
          final species = type == 2
              ? (grove > .55
                  ? 0
                  : grove < .32
                      ? 3
                      : 1)
              : type;
          trees.add(_WoodlandTree(tx, base, th, species, treeSeed));
        }
        x += average * (.7 + random.nextDouble() * .6);
      }
      // Project shadows onto terrain before drawing trunks and crowns.
      if (_on('enableShadows')) {
        for (final tree in trees) {
          final length = tree.height * (.12 + .32 * _unit('lightingAngle'));
          final direction = _value('shadowDirection').clamp(-1.0, 1.0);
          for (var step = 0; step < length; step++) {
            final sx = tree.x + (step * direction).round();
            final sy = tree.y + (step * .2).round();
            final radius = max(1, ((1 - step / max(1, length)) * tree.height * .07).round());
            p.tintEllipse(sx, sy, radius, max(1, scale), shadow,
                (.4 - .2 * _unit('shadowSoftness')) * (1 - step / max(1, length)));
          }
        }
      }
      for (final tree in trees) {
        _tree(p, tree, scale, foliage, shadow, highlight, bark, pal, scheme, sunX);
      }
      if (_on('enableUndergrowth') && depth >= .6) {
        final plants = Random(seed ^ (layer * 931 + 0x1137));
        final count = (width / (3 * scale) * _unit('undergrowthDensity')).round();
        for (var i = 0; i < count; i++) {
          final px = plants.nextInt(width);
          final py = ridge[px] + plants.nextInt(max(1, height - ridge[px]));
          final ph = max(1, (scale * (1 + plants.nextDouble() * 3) * depth).round());
          p.line(px, py, px - scale, py - ph, shadow);
          p.line(px, py, px + scale, py - ph + scale, foliage);
          if (i % 7 == 0) p.dot(px - scale, py - ph, scheme == 2 ? pal.light : highlight);
          if (i % 13 == 0 && scheme != 2) {
            p.line(px + 2 * scale, py, px + 2 * scale, py - scale, bark);
            p.rect(px + scale, py - 2 * scale, 3 * scale, scale, pal.detail);
          }
        }
      }
      // Mist between depth planes lets foreground trees remain crisp.
      if (_on('enableMist')) {
        final mistHeight = max(1.0, height * _unit('mistHeight'));
        for (var y = 0; y < height; y++) {
          for (var x = 0; x < width; x++) {
            final band = max(0.0, 1 - (y - ridge[x]).abs() / mistHeight);
            final billow = .45 + .55 * _woodNoise(x / 19, y / 9, seed + layer);
            p.tint(x, y, pal.haze, band * billow * _unit('mistIntensity') * .5);
          }
        }
      }
    }
    if (_unit('godRays') > 0) {
      for (var y = 0; y < height; y++) {
        for (var x = 0; x < width; x++) {
          final slope = (x - sunX) / max(4.0, y - sunY + height * .15);
          final ray = pow(max(0.0, sin(slope * 19 + seed)), 14).toDouble();
          p.tint(x, y, pal.light, ray * _unit('godRays') * .18 * y / height);
        }
      }
    }
    return out;
  }

  int _ground(int x, int width, int height, int horizon, double depth, int seed) {
    final hills = (_woodNoise(x / max(1, width) * 3, depth * 2, seed) - .5) * 2;
    return (horizon - (1 - depth) * height * .2 + hills * height * .12 * _unit('terrainRelief'))
        .round()
        .clamp(0, height - 1);
  }

  void _tree(_WoodlandRaster p, _WoodlandTree tree, int scale, int leaf, int dark, int light, int bark,
      _WoodlandPalette palette, int season, double sunX) {
    final r = Random(tree.seed);
    final h = tree.height;
    final x = tree.x;
    final y = tree.y;
    final top = y - h;
    final trunk = max(1, h ~/ (tree.species == 3 ? 24 : 15));
    final lean = ((r.nextDouble() - .5) * h * .12).round();
    final crownX = x + lean;
    final canopyWidth = max(
        2,
        (h *
                (tree.species == 0
                    ? .24
                    : tree.species == 4
                        ? .42
                        : .36))
            .round());
    final trunkColor = tree.species == 3 ? _woodMix(palette.light, bark, .25) : bark;
    final lit = _woodMix(light, palette.light, _unit('rimLight') * .35 + _unit('lightingAngle') * .08);
    for (var row = 0; row < h * .8; row++) {
      final px = x + (lean * row / max(1, h)).round();
      p.rect(px - trunk ~/ 2, y - row, trunk, 1, trunkColor);
      if (trunk > 1) p.dot(px - trunk ~/ 2, y - row, _woodMix(trunkColor, dark, .5));
      if (tree.species == 3 && row % max(3, h ~/ 10) == 0) {
        p.rect(px, y - row, max(1, trunk ~/ 2), 1, dark);
      }
    }
    p.line(x, y, x - trunk * 2, y + scale, bark);
    p.line(x, y, x + trunk * 2, y + scale, bark);
    if (tree.species == 0) {
      final tiers = max(3, min(8, h ~/ 7));
      for (var tier = tiers - 1; tier >= 0; tier--) {
        final fraction = tier / max(1, tiers - 1);
        final cy = top + (h * (.12 + fraction * .57)).round();
        final radius = max(1, (canopyWidth * (.22 + .78 * fraction)).round());
        final tierH = max(2, (h * .23).round());
        for (var row = 0; row < tierH; row++) {
          final spread = max(0, (radius * row / tierH).round());
          p.rect(crownX - spread, cy + row, spread * 2 + 1, 1, row > tierH * .72 ? dark : leaf);
          for (var offset = -spread; offset <= spread; offset++) {
            final patch =
                _woodNoise((crownX + offset) / (2.0 * scale), (cy + row) / (2.0 * scale), tree.seed + tier * 53);
            final facingSun = sunX < x ? offset < 0 : offset > 0;
            if (row < tierH * .8 && patch > (facingSun ? .46 : .7)) {
              p.dot(crownX + offset, cy + row, season == 2 && patch > .56 ? palette.light : lit);
            }
          }
        }
      }
    } else {
      // Branches connect clustered crowns to the trunk, including visible gaps.
      final count = tree.species == 3 ? 6 : 9;
      for (var i = 0; i < count; i++) {
        final angle = i * 2.39996;
        final radius = sqrt((i + .5) / count);
        final cx = crownX + (cos(angle) * canopyWidth * radius * .8).round();
        final cy = top + (h * .25 + sin(angle) * h * .18 * radius).round();
        p.line(x + lean ~/ 2, y - h ~/ 3, cx, cy, bark);
      }
      for (var i = 0; i < count; i++) {
        final angle = i * 2.39996;
        final radius = sqrt((i + .5) / count);
        final cx = crownX + (cos(angle) * canopyWidth * radius * .8).round();
        final cy = top + (h * .25 + sin(angle) * h * .18 * radius).round();
        final rx = max(2, (canopyWidth * (.38 + r.nextDouble() * .15)).round());
        final ry = max(2, (h * (tree.species == 3 ? .13 : .16)).round());
        _cluster(p, cx, cy, rx, ry, leaf, dark, lit, tree.seed + i * 131, sunX < x, season == 2);
        if (tree.species == 4) {
          for (var strand = -rx; strand <= rx; strand += max(2, scale * 2)) {
            final drop = (h * (.15 + r.nextDouble() * .22)).round();
            p.line(cx + strand, cy, cx + strand - scale, cy + drop, strand.isEven ? leaf : dark);
            p.dot(cx + strand - scale, cy + drop, lit);
          }
        }
      }
    }
  }

  void _cluster(_WoodlandRaster p, int cx, int cy, int rx, int ry, int leaf, int dark, int light, int seed,
      bool lightLeft, bool snow) {
    for (var y = -ry; y <= ry; y++) {
      for (var x = -rx; x <= rx; x++) {
        final nx = x / rx;
        final ny = y / ry;
        final shape = nx * nx + ny * ny;
        final edge = .88 + .15 * _woodNoise((x + cx) / 3, (y + cy) / 3, seed);
        if (shape > edge) continue;
        final patch = _woodNoise((x + cx) / 3, (y + cy) / 3, seed + 71);
        final facing = lightLeft ? -nx : nx;
        var color = ny > .35 || patch < .22 ? dark : leaf;
        if (ny < -.15 && facing > -.4 && patch > .43) color = light;
        if (snow && ny < -.35 && patch > .25) color = _woodMix(light, 0xffeff5ed, .75);
        p.dot(cx + x, cy + y, color);
      }
    }
  }
}

int _woodMix(int a, int b, double t) {
  t = t.clamp(0.0, 1.0);
  int c(int shift) => (((a >> shift) & 255) * (1 - t) + ((b >> shift) & 255) * t).round();
  return 0xff000000 | c(16) << 16 | c(8) << 8 | c(0);
}

double _woodHash(int seed, int x, int y) {
  var h = (seed ^ (x * 374761393) ^ (y * 668265263)) & 0x7fffffff;
  h = ((h ^ (h >> 13)) * 1274126177) & 0x7fffffff;
  return (h ^ (h >> 16)) / 2147483647;
}

double _woodNoise(double x, double y, int seed) {
  final ix = x.floor(), iy = y.floor();
  final fx = x - ix, fy = y - iy;
  final sx = fx * fx * (3 - 2 * fx), sy = fy * fy * (3 - 2 * fy);
  final a = _woodHash(seed, ix, iy) * (1 - sx) + _woodHash(seed, ix + 1, iy) * sx;
  final b = _woodHash(seed, ix, iy + 1) * (1 - sx) + _woodHash(seed, ix + 1, iy + 1) * sx;
  return a * (1 - sy) + b * sy;
}

class _WoodlandTree {
  final int x, y, height, species, seed;
  const _WoodlandTree(this.x, this.y, this.height, this.species, this.seed);
}

class _WoodlandRaster {
  final Uint32List pixels;
  final int width, height;
  _WoodlandRaster(this.pixels, this.width, this.height);
  void dot(int x, int y, int color) {
    if (x >= 0 && y >= 0 && x < width && y < height) pixels[y * width + x] = color;
  }

  void rect(int x, int y, int w, int h, int color) {
    for (var py = max(0, y); py < min(height, y + h); py++) {
      for (var px = max(0, x); px < min(width, x + w); px++) {
        pixels[py * width + px] = color;
      }
    }
  }

  void line(int x0, int y0, int x1, int y1, int color) {
    final dx = (x1 - x0).abs(), dy = -(y1 - y0).abs();
    final sx = x0 < x1 ? 1 : -1, sy = y0 < y1 ? 1 : -1;
    var error = dx + dy;
    while (true) {
      dot(x0, y0, color);
      if (x0 == x1 && y0 == y1) break;
      final twice = error * 2;
      if (twice >= dy) {
        error += dy;
        x0 += sx;
      }
      if (twice <= dx) {
        error += dx;
        y0 += sy;
      }
    }
  }

  void tint(int x, int y, int color, double amount) {
    if (x < 0 || y < 0 || x >= width || y >= height) return;
    final i = y * width + x;
    if (pixels[i] != 0) pixels[i] = _woodMix(pixels[i], color, amount);
  }

  void tintEllipse(int cx, int cy, int rx, int ry, int color, double amount) {
    for (var y = -ry; y <= ry; y++) {
      for (var x = -rx; x <= rx; x++) {
        if (x * x / max(1, rx * rx) + y * y / max(1, ry * ry) <= 1) tint(cx + x, cy + y, color, amount);
      }
    }
  }
}

class _WoodlandPalette {
  final int haze, leaf, dark, highlight, bark, ground, detail, light;
  const _WoodlandPalette(
      this.haze, this.leaf, this.dark, this.highlight, this.bark, this.ground, this.detail, this.light);
  static const schemes = [
    _WoodlandPalette(0xffc3d3b5, 0xff416b4a, 0xff203b38, 0xff83a85b, 0xff574b3f, 0xff526248, 0xffa39468, 0xffffe2a0),
    _WoodlandPalette(0xffdfc6a4, 0xffb46a3c, 0xff4d3d39, 0xffe4b55b, 0xff574336, 0xff806849, 0xffc0a078, 0xffffdf9c),
    _WoodlandPalette(0xffd3e2df, 0xff668a90, 0xff354d64, 0xffbed6d5, 0xff626778, 0xffccd9d7, 0xffaabcc4, 0xffeff4e5),
    _WoodlandPalette(0xff4d6279, 0xff294b54, 0xff101f35, 0xff52757a, 0xff343344, 0xff283e4c, 0xff58626a, 0xffbbd6d8),
    _WoodlandPalette(0xffd8dfcb, 0xff68867a, 0xff354e50, 0xffa3b69a, 0xff66655a, 0xff788b70, 0xffb2ad8c, 0xffffe7b5),
    _WoodlandPalette(0xffeab39a, 0xff675568, 0xff302f49, 0xffbd8b82, 0xff564254, 0xff665669, 0xffb58a80, 0xffffd5a0),
  ];
}
