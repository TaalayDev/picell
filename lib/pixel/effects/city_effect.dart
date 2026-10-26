part of 'effects.dart';

/// A seeded, district-planned pixel skyline. Layout, facade and atmosphere
/// have separate random streams so cosmetic changes never reshuffle buildings.
class CityEffect extends Effect {
  static const _defaults = <String, dynamic>{
    'buildingDensity': 0.7,
    'heightVariation': 0.65,
    'minHeight': 0.18,
    'maxHeight': 0.85,
    'buildingStyle': 0,
    'windowDensity': 0.65,
    'colorScheme': 0,
    'perspective': 0.35,
    'weatherEffect': 0,
    'randomSeed': 42,
    'backgroundMode': 0,
    'antennasAndDetails': 0.5,
    'buildingWidth': 0.5,
    'litWindowRatio': 0.7,
    'windowStyle': 0,
    'waterReflection': false,
    'groundStreets': true,
    'backgroundSilhouette': true,
    'depthLayers': 3,
    'districtLayout': 0,
    'landmarkStrength': 0.65,
  };

  CityEffect([Map<String, dynamic>? parameters]) : super(EffectType.city, {..._defaults, ...?parameters});

  @override
  Map<String, dynamic> getDefaultParameters() => {..._defaults};

  @override
  Map<String, dynamic> getMetadata() {
    return {
      'depthLayers': {
        'label': 'City Depth',
        'description': 'Number of independently planned skyline layers.',
        'type': 'slider',
        'min': 1,
        'max': 4,
        'divisions': 3
      },
      'districtLayout': {
        'label': 'District Layout',
        'description': 'Organizes building heights into coherent neighborhoods.',
        'type': 'select',
        'options': {0: 'Downtown Core', 1: 'Twin Centers', 2: 'Neighborhoods'}
      },
      'landmarkStrength': {
        'label': 'Landmark Towers',
        'description': 'Emphasizes signature towers at district centers.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100
      },
      'buildingDensity': {
        'label': 'Building Density',
        'description': 'How densely packed the buildings are in the city.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
      'heightVariation': {
        'label': 'Height Variation',
        'description': 'How much building heights vary across the skyline.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
      'minHeight': {
        'label': 'Minimum Height',
        'description': 'Minimum height of buildings relative to image height.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
      'maxHeight': {
        'label': 'Maximum Height',
        'description': 'Maximum height of buildings relative to image height.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
      'buildingStyle': {
        'label': 'Building Style',
        'description': 'Architectural style of the buildings.',
        'type': 'select',
        'options': {
          0: 'Modern',
          1: 'Classic',
          2: 'Futuristic',
          3: 'Mixed Styles',
          4: 'Art Deco / Stepped',
          5: 'Cyberpunk Neon',
        },
      },
      'windowDensity': {
        'label': 'Window Density',
        'description': 'How many windows appear on building facades.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
      'colorScheme': {
        'label': 'Color Scheme',
        'description': 'Color palette for the city.',
        'type': 'select',
        'options': {
          0: 'Realistic',
          1: 'Neon/Cyberpunk',
          2: 'Monochrome',
          3: 'Sunset',
          4: 'Matrix Emerald',
          5: 'Vaporwave Sunset',
        },
      },
      'perspective': {
        'label': 'Perspective Effect',
        'description': 'Adds 3D perspective depth to buildings.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
      'weatherEffect': {
        'label': 'Weather Effect',
        'description': 'Atmospheric effects on the city.',
        'type': 'select',
        'options': {
          0: 'Clear',
          1: 'Foggy',
          2: 'Rainy',
          3: 'Night',
        },
      },
      'randomSeed': {
        'label': 'Random Seed',
        'description': 'Changes the procedural city layout.',
        'type': 'slider',
        'min': 1,
        'max': 100,
        'divisions': 99,
      },
      'backgroundMode': {
        'label': 'Background',
        'description': 'Background behind the city.',
        'type': 'select',
        'options': {
          0: 'Transparent',
          1: 'Sky',
          2: 'Gradient',
        },
      },
      'antennasAndDetails': {
        'label': 'Rooftop Details',
        'description': 'Density of antennas and rooftop details.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
      'buildingWidth': {
        'label': 'Building Width',
        'description': 'Average width of buildings.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
      'litWindowRatio': {
        'label': 'Lit Window Ratio',
        'description': 'Percentage of windows that are lit up.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
      'windowStyle': {
        'label': 'Window Style',
        'description': 'Style of windows on buildings.',
        'type': 'select',
        'options': {
          0: 'Standard',
          1: 'Floor-to-Ceiling',
          2: 'Small/Classic',
          3: 'Mixed',
        },
      },
      'backgroundSilhouette': {
        'label': 'Distant Skyline',
        'description': 'Adds distant background skyscraper silhouettes.',
        'type': 'bool',
      },
      'groundStreets': {
        'label': 'Ground Traffic & Lights',
        'description': 'Street level warm glow and headlights/taillights.',
        'type': 'bool',
      },
      'waterReflection': {
        'label': 'Water Reflection',
        'description': 'Renders waterfront reflections below the skyline.',
        'type': 'bool',
      },
    };
  }

  double _number(String key) {
    final value = parameters[key];
    return value is num && value.isFinite ? value.toDouble() : (_defaults[key] as num).toDouble();
  }

  double _unit(String key) => _number(key).clamp(0.0, 1.0);
  int _choice(String key, int maximum) => _number(key).round().clamp(0, maximum);
  bool _enabled(String key) => parameters[key] == true;

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    if (width <= 0 || height <= 0) return Uint32List(pixels.length);
    if (pixels.length != width * height) {
      throw ArgumentError('City canvas dimensions must match the pixel buffer.');
    }
    final out = Uint32List(pixels.length);
    final seed = _number('randomSeed').round();
    final weather = _choice('weatherEffect', 3);
    final palette = _CityPalette.forScheme(_choice('colorScheme', 5), weather == 3);
    final background = _choice('backgroundMode', 2);
    final unit = max(1, (min(width, height) / 128).floor());
    final water = _enabled('waterReflection') ? max(1, (height * .22).round()) : 0;
    final shore = height - water;
    final street = _enabled('groundStreets') ? max(1, (height * .055).round()) : 0;
    final baseline = max(1, shore - street);
    final painter = _CityRaster(out, width, height);

    if (background != 0) {
      for (var y = 0; y < height; y++) {
        // Quantized sky bands keep the result deliberately pixel-art friendly.
        final t = ((y / max(1, baseline) * 20).floor() / 20).clamp(0.0, 1.0);
        painter.rect(0, y, width, 1, _cityMix(palette.sky, palette.horizon, t));
      }
      if (background == 1) {
        final skyRandom = Random(seed ^ 0x51af);
        if (weather == 3) {
          for (var i = 0; i < width * height ~/ 180; i++) {
            painter.dot(skyRandom.nextInt(width), skyRandom.nextInt(max(1, baseline * 2 ~/ 3)),
                _cityMix(palette.horizon, 0xffffffff, .65));
          }
        }
        final cx = (width * .78).round();
        final cy = (baseline * .2).round();
        final radius = max(1, min(width, height) ~/ 19);
        for (var y = -radius; y <= radius; y++) {
          final half = sqrt(max(0, radius * radius - y * y)).floor();
          painter.rect(cx - half, cy + y, half * 2 + 1, 1, weather == 3 ? 0xffdce6eb : palette.light);
        }
      }
    }

    final layers = _number('depthLayers').round().clamp(1, 4);
    // A separate distant silhouette provides scale without overpowering the core.
    if (_enabled('backgroundSilhouette')) {
      _drawDistrict(painter, width, baseline, unit, seed, -1, layers, palette, weather);
    }
    for (var layer = 0; layer < layers; layer++) {
      _drawDistrict(painter, width, baseline, unit, seed, layer, layers, palette, weather);
    }

    if (street > 0) {
      painter.rect(0, baseline, width, street, palette.shadow);
      painter.rect(0, baseline, width, unit, palette.trim);
      final roadRandom = Random(seed ^ 0x7123);
      final spacing = max(8 * unit, width ~/ 10);
      for (var x = spacing ~/ 2; x < width; x += spacing) {
        painter.rect(x, baseline - 4 * unit, unit, 4 * unit, palette.shadow);
        painter.rect(x - unit, baseline - 4 * unit, 3 * unit, unit, palette.light);
      }
      if (street >= 3) {
        for (var x = 0; x < width; x += 9 * unit) {
          painter.rect(x, baseline + street ~/ 2, 3 * unit, 1, palette.trim);
        }
        for (var i = 0; i < width ~/ (12 * unit); i++) {
          final x = roadRandom.nextInt(width);
          final y = baseline + 1 + roadRandom.nextInt(max(1, street - 1));
          painter.rect(x, y, 2 * unit, 1, i.isEven ? palette.light : 0xffe76d72);
        }
      }
    }

    if (water > 0) {
      final waterColor = _cityMix(palette.shadow, palette.sky, .25);
      for (var y = shore; y < height; y++) {
        final distance = y - shore;
        final sourceY = max(0, shore - 1 - distance * 2);
        final offset = (sin(distance * .75 + seed) * (1 + distance * .08)).round();
        for (var x = 0; x < width; x++) {
          final source = out[sourceY * width + (x + offset).clamp(0, width - 1)];
          final fade = .65 * (1 - distance / max(1, water));
          out[y * width + x] =
              source == 0 ? waterColor : _cityMix(waterColor, source, fade * (distance % 3 == 0 ? .45 : 1));
        }
      }
      painter.rect(0, shore, width, 1, palette.trim);
    }

    if (weather == 1) {
      for (var y = 0; y < height; y++) {
        final fog = .08 + .28 * y / height;
        for (var x = 0; x < width; x++) {
          final i = y * width + x;
          if (out[i] != 0) out[i] = _cityMix(out[i], palette.horizon, fog);
        }
      }
    } else if (weather == 2) {
      final rain = Random(seed ^ 0x7a19);
      for (var i = 0; i < width * height ~/ 65; i++) {
        final x = rain.nextInt(width);
        final y = rain.nextInt(height);
        for (var j = 0; j < 3 * unit; j++) {
          final px = x - j ~/ 3;
          final py = y + j;
          // Transparent exports keep atmosphere confined to existing content.
          if (px >= 0 && px < width && py < height && out[py * width + px] != 0) {
            painter.dot(px, py, _cityMix(out[py * width + px], palette.horizon, .4));
          }
        }
      }
    }
    return out;
  }

  double _district(double x, int seed) {
    switch (_choice('districtLayout', 2)) {
      case 1:
        return max(exp(-pow((x - .28) * 6, 2)), exp(-pow((x - .73) * 6, 2))).toDouble();
      case 2:
        return .3 + .7 * pow(.5 + .5 * sin(x * pi * 5 + seed % 7), 2);
      default:
        final center = .42 + .14 * sin(seed.toDouble());
        return exp(-pow((x - center) * 3.5, 2));
    }
  }

  void _drawDistrict(_CityRaster p, int width, int baseline, int unit, int seed, int layer, int layers,
      _CityPalette palette, int weather) {
    final random = Random(seed ^ ((layer + 3) * 0x45d9));
    final depth = layer < 0 ? 0.0 : (layer + 1) / layers;
    final far = layer < 0;
    final density = _unit('buildingDensity');
    final averageWidth = max(3, (width * (.025 + _unit('buildingWidth') * .065) * (.55 + depth * .6)).round());
    final low = min(_unit('minHeight'), _unit('maxHeight'));
    final high = max(_unit('minHeight'), _unit('maxHeight'));
    var x = -averageWidth ~/ 2;
    var index = 0;
    while (x < width) {
      final bw = max(2, (averageWidth * (.65 + random.nextDouble() * .7)).round());
      final jitter = random.nextDouble();
      final district = _district((x + bw / 2) / width, seed);
      final variation = _unit('heightVariation');
      final profile = (district * (1 - variation * .55) + jitter * variation * .55).clamp(0.0, 1.0);
      // Foreground is lower so the distant skyline remains visible.
      final depthScale = far ? .7 : .98 - depth * .38;
      var bh = max(1, (baseline * (low + (high - low) * profile) * depthScale).round());
      final landmark = !far && layer == 0 && district > .85 && index % 3 == 0;
      if (landmark) bh = (bh * (1 + _unit('landmarkStrength') * .32)).round();
      bh = bh.clamp(1, max(1, baseline - 2 * unit));
      final style = _choice('buildingStyle', 5);
      final selectedStyle = style == 3 ? random.nextInt(6) : style;
      final buildingSeed = random.nextInt(0x7fffffff);
      final haze = far ? .72 : (1 - depth) * (weather == 1 ? .65 : .43);
      final facade = _cityMix(palette.facade, palette.horizon, haze);
      _drawTower(
          p, x, baseline - bh, bw, bh, unit, selectedStyle, Random(buildingSeed), palette, facade, haze, far, landmark);
      // Every depth layer has its own ordered lots; density controls alley width.
      x += bw + max(1, ((1 - density) * averageWidth * 1.5).round());
      index++;
    }
  }

  void _drawTower(_CityRaster p, int x, int y, int w, int h, int unit, int style, Random random, _CityPalette palette,
      int facade, double haze, bool silhouette, bool landmark) {
    final floor = max(3, 4 * unit);
    final floors = max(1, h ~/ floor);
    final stepped = style == 4 || style == 2 || landmark;
    final pitched = style == 1;
    final roofHeight = min(h ~/ 4, max(1, w ~/ 3));
    final shade = _cityMix(facade, palette.shadow, .46);
    final trim = _cityMix(facade, palette.trim, .48);
    final side = (_unit('perspective') * w * .3).round();
    final tint = random.nextDouble();
    final body = _cityMix(facade, tint < .5 ? palette.trim : palette.shadow, .08 + tint * .12);
    // Per-scanline silhouette allows setbacks and pitched roofs without windows
    // or facade details spilling outside the architecture.
    for (var row = 0; row < h; row++) {
      var inset = 0;
      if (stepped) {
        if (row < h ~/ 7) {
          inset = w ~/ 4;
        } else if (row < h ~/ 3) {
          inset = w ~/ 7;
        }
      } else if (pitched && row < roofHeight) {
        inset = ((roofHeight - row) / max(1, roofHeight) * w / 2).floor();
      }
      final left = x + inset;
      final right = x + w - inset;
      if (right <= left) continue;
      p.rect(left, y + row, right - left, 1, body);
      p.rect(max(left, right - side), y + row, min(side, right - left), 1, shade);
      p.dot(left, y + row, trim);
      if (row == 0 || (stepped && (row == h ~/ 7 || row == h ~/ 3))) {
        p.rect(left, y + row, right - left, 1, trim);
      }
      if (silhouette ||
          row <
              max(
                  2 * unit,
                  stepped
                      ? h ~/ 3
                      : pitched
                          ? roofHeight
                          : 0)) {
        continue;
      }
      if (row % floor == 0 && (style == 1 || style == 4)) {
        p.rect(left + 1, y + row, max(0, right - left - side - 2), 1, shade);
      }
    }
    if (silhouette) return;

    final windowMode = _choice('windowStyle', 3);
    final windows = windowMode == 3 ? random.nextInt(3) : windowMode;
    final windowW = windows == 1 ? 2 * unit : unit;
    final windowH = windows == 2 ? unit : 2 * unit;
    final pitch = windowW + (style == 1 ? 2 : 1) * unit;
    final startY = y +
        max(
            2 * unit,
            stepped
                ? h ~/ 3 + unit
                : pitched
                    ? roofHeight + unit
                    : 2 * unit);
    final accent = style == 5 && random.nextBool() ? palette.secondary : palette.light;
    for (var wy = startY.toInt(); wy + windowH < y + h - unit; wy += floor) {
      // Shared occupancy per floor yields offices and apartments, not white noise.
      final occupancy = .55 + random.nextDouble() * .45;
      for (var wx = x + 2 * unit; wx + windowW < x + w - side - unit; wx += pitch) {
        final exists = random.nextDouble();
        final lit = random.nextDouble();
        if (exists > _unit('windowDensity')) continue;
        final color = lit < _unit('litWindowRatio') * occupancy
            ? _cityMix(accent, palette.horizon, haze * .6)
            : _cityMix(shade, palette.sky, .18);
        p.rect(wx, wy, windowW, windowH, color);
      }
    }
    // Ground-floor entrances and awnings make the street read at larger sizes.
    if (w >= 8 * unit && h >= 10 * unit) {
      p.rect(x + w ~/ 2, y + h - 3 * unit, 2 * unit, 3 * unit, shade);
      if (style == 1 || style == 5) {
        p.rect(x + unit, y + h - 4 * unit, w - side - 2 * unit, unit, accent);
      }
    }
    if (style == 5 && w > 7 * unit && h > 12 * unit) {
      p.rect(x + w - side - 2 * unit, y + h ~/ 3, unit, min(h ~/ 3, 10 * unit), palette.secondary);
    }
    final detailRoll = random.nextDouble();
    if (detailRoll < _unit('antennasAndDetails') && h > floor * 2) {
      final roofX = x + w ~/ 2;
      final antenna = max(2, min(h ~/ 5, (landmark ? 9 : 5) * unit));
      p.rect(roofX, y - antenna, unit, antenna, trim);
      p.dot(roofX, y - antenna, palette.secondary);
      if (w > 9 * unit && !stepped && !pitched) {
        p.rect(x + 2 * unit, y - 2 * unit, 3 * unit, 2 * unit, shade);
        p.rect(x + 2 * unit, y - 2 * unit, 3 * unit, unit, trim);
      }
    }
    if (style == 2 && floors > 4) {
      p.rect(x + w ~/ 3, y + h ~/ 3, max(1, w ~/ 3), unit, accent);
    }
  }
}

int _cityMix(int a, int b, double amount) {
  final t = amount.clamp(0.0, 1.0);
  int channel(int shift) => (((a >> shift) & 255) * (1 - t) + ((b >> shift) & 255) * t).round();
  return 0xff000000 | channel(16) << 16 | channel(8) << 8 | channel(0);
}

/// Small clipped integer rasterizer: all architecture stays on the pixel grid.
class _CityRaster {
  final Uint32List pixels;
  final int width, height;
  _CityRaster(this.pixels, this.width, this.height);

  void dot(int x, int y, int color) {
    if (x >= 0 && y >= 0 && x < width && y < height) pixels[y * width + x] = color;
  }

  void rect(int x, int y, int w, int h, int color) {
    final endX = min(width, x + w);
    final endY = min(height, y + h);
    for (var py = max(0, y); py < endY; py++) {
      for (var px = max(0, x); px < endX; px++) {
        pixels[py * width + px] = color;
      }
    }
  }
}

class _CityPalette {
  final int sky, horizon, facade, shadow, trim, light, secondary;
  const _CityPalette(this.sky, this.horizon, this.facade, this.shadow, this.trim, this.light, this.secondary);

  static _CityPalette forScheme(int scheme, bool night) {
    const palettes = [
      _CityPalette(0xff506b91, 0xffc7c8b8, 0xff526375, 0xff202d40, 0xff91a0aa, 0xffffd998, 0xffe57868),
      _CityPalette(0xff100e2b, 0xff633052, 0xff29203f, 0xff100f23, 0xff57446a, 0xff68e5ed, 0xfff46aba),
      _CityPalette(0xff373b43, 0xffb3b9bb, 0xff666c74, 0xff22262e, 0xffa0a6aa, 0xffe0e4de, 0xffbfc5c8),
      _CityPalette(0xff393354, 0xffeda475, 0xff67475d, 0xff302d46, 0xffaa7277, 0xffffdd9a, 0xfff29483),
      _CityPalette(0xff071c1b, 0xff49745a, 0xff1b3b32, 0xff091b1a, 0xff46715b, 0xff8fe5a2, 0xff42bd8e),
      _CityPalette(0xff352552, 0xffefa0af, 0xff543767, 0xff241e3d, 0xffa56b9d, 0xff85e3ed, 0xfff57ac5),
    ];
    final p = palettes[scheme];
    if (!night) return p;
    return _CityPalette(_cityMix(p.sky, 0xff050b20, .75), _cityMix(p.horizon, 0xff18243b, .8),
        _cityMix(p.facade, 0xff10182a, .55), p.shadow, _cityMix(p.trim, 0xff2b354c, .5), p.light, p.secondary);
  }
}
