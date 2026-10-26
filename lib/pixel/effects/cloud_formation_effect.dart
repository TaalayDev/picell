part of 'effects.dart';

/// Seeded cloud banks assembled from connected lobes, shaded as volumes.
/// The generator paints only cloud pixels; it never fills the sky.
class CloudFormationEffect extends Effect {
  static const _defaults = <String, dynamic>{
    'layers': 3,
    'style': 0,
    'density': .5,
    'coverage': .5,
    'baseHeight': .3,
    'colorScheme': 0,
    'atmosphericHaze': .3,
    'sunPosition': .5,
    'mistIntensity': .2,
    'randomSeed': 42,
    'detailLevel': .6,
    'startY': 0.0,
    'cloudScale': .5,
    'windShear': .3,
  };
  CloudFormationEffect([Map<String, dynamic>? parameters])
      : super(EffectType.cloudFormation, {..._defaults, ...?parameters});

  @override
  Map<String, dynamic> getDefaultParameters() => {..._defaults};

  @override
  Map<String, dynamic> getMetadata() {
    return {
      'startY': {
        'label': 'Start Y',
        'description': 'Top of the generation area: 0 is the canvas top, 1 is the bottom.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100
      },
      'cloudScale': {
        'label': 'Cloud Size',
        'description': 'Size of individual cloud formations.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100
      },
      'windShear': {
        'label': 'Wind Shear',
        'description': 'Sweeps cloud tops sideways and stretches wisps.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100
      },
      'layers': {
        'label': 'Cloud Layers',
        'description': 'Number of cloud layers for depth effect.',
        'type': 'slider',
        'min': 1,
        'max': 5,
        'divisions': 4,
      },
      'style': {
        'label': 'Cloud Style',
        'description': 'Style of cloud formations.',
        'type': 'select',
        'options': {
          0: 'Fluffy Cumulus',
          1: 'Wispy Cirrus',
          2: 'Stormy Nimbus',
          3: 'Layered Stratus',
          4: 'Scattered',
        },
      },
      'density': {
        'label': 'Cloud Density',
        'description': 'How dense the individual clouds are.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
      'coverage': {
        'label': 'Sky Coverage',
        'description': 'How much of the sky is covered by clouds.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
      'baseHeight': {
        'label': 'Base Height',
        'description': 'Position of clouds from the top.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
      'colorScheme': {
        'label': 'Color Scheme',
        'description': 'Color palette for the clouds.',
        'type': 'select',
        'options': {
          0: 'Daytime Blue',
          1: 'Sunset Orange',
          2: 'Stormy Gray',
          3: 'Night Dark',
          4: 'Pastel',
        },
      },
      'atmosphericHaze': {
        'label': 'Atmospheric Haze',
        'description': 'Creates depth with atmospheric perspective.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
      'sunPosition': {
        'label': 'Light Direction',
        'description': 'Position of the sun for lighting effects (0=left, 1=right).',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
      'mistIntensity': {
        'label': 'Mist Intensity',
        'description': 'Amount of low-lying mist or fog.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
      'randomSeed': {
        'label': 'Random Seed',
        'description': 'Changes the cloud pattern and layout.',
        'type': 'slider',
        'min': 1,
        'max': 100,
        'divisions': 99,
      },
      'detailLevel': {
        'label': 'Detail Level',
        'description': 'Level of detail in cloud features.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
    };
  }

  double _value(String key) {
    final value = parameters[key];
    return value is num && value.isFinite ? value.toDouble() : (_defaults[key] as num).toDouble();
  }

  double _unit(String key) => _value(key).clamp(0.0, 1.0);

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    if (width <= 0 || height <= 0) return Uint32List(pixels.length);
    if (pixels.length != width * height) throw ArgumentError('Cloud canvas dimensions must match the pixel buffer.');
    final out = Uint32List(pixels.length);
    final start = (_unit('startY') * height).round();
    final available = height - start;
    if (available <= 0 || _unit('coverage') == 0 || _unit('density') == 0) return out;
    final seed = _value('randomSeed').round();
    final layers = _value('layers').round().clamp(1, 5);
    final style = _value('style').round().clamp(0, 4);
    final palette = _CloudBankPalette.schemes[_value('colorScheme').round().clamp(0, 4)];
    for (var layer = 0; layer < layers; layer++) {
      final depth = (layer + 1) / layers;
      final random = Random(seed ^ ((layer + 1) * 0x45d9));
      final scale = (.65 + depth * .55) * (.55 + _unit('cloudScale') * .95);
      final radius = max(2.0, min(width * .19, available * .43) * scale * (style == 4 ? .65 : 1));
      final spacing = max(4.0, radius * (style == 3 ? 2.1 : 2.8));
      final count = max(1, (width / spacing * (.4 + _unit('coverage') * 1.6)).ceil());
      final haze = (1 - depth) * _unit('atmosphericHaze') * .65;
      // Each layer occupies a broad altitude band, rather than independent noise.
      final band = _unit('baseHeight') * available + (depth - .5) * available * .34;
      for (var i = 0; i < count; i++) {
        final cx = (i + .25 + random.nextDouble() * .5) / count * width;
        final cy = (band + (random.nextDouble() - .5) * available * .27).clamp(0.0, available - 1.0);
        final size = radius * (.7 + random.nextDouble() * .55);
        final cloudSeed = random.nextInt(0x7fffffff);
        _drawBank(out, width, height, start, cx, cy + start, size, style, cloudSeed, haze, palette);
      }
    }
    return out;
  }

  void _drawBank(Uint32List out, int width, int height, int start, double cx, double cy, double radius, int style,
      int seed, double haze, _CloudBankPalette palette) {
    final random = Random(seed);
    final lobes = <_CloudLobe>[];
    final shear = _unit('windShear');
    final flat = cy + radius * (style == 2 ? .65 : .24);
    final count = style == 1
        ? 6
        : style == 3
            ? 5
            : style == 4
                ? 5
                : 9;
    for (var i = 0; i < count; i++) {
      final u = count == 1 ? .5 : i / (count - 1);
      final arch = sin(u * pi);
      var x = cx + (u - .5) * radius * 2.5;
      var y = cy - arch * radius * (.4 + random.nextDouble() * .3);
      var rx = radius * (.32 + random.nextDouble() * .22);
      var ry = rx * (.7 + random.nextDouble() * .3);
      if (style == 1) {
        x = cx + (u - .5) * radius * 4;
        y = cy - u * radius * .7 * shear;
        rx = radius * .95;
        ry = max(.7, radius * (.06 + arch * .09));
      } else if (style == 2) {
        // Broad anvil plus a raised convective column and heavy lower body.
        y = cy - arch * radius * 1.05;
        rx *= 1.1;
        ry *= 1.4;
      } else if (style == 3) {
        x = cx + (u - .5) * radius * 3.6;
        y = cy + sin(u * pi * 2) * radius * .06;
        rx = radius * .85;
        ry = radius * (.17 + random.nextDouble() * .08);
      }
      x += (cy - y) * shear * .7;
      lobes.add(_CloudLobe(x, y, max(.7, rx), max(.7, ry)));
    }
    if (style == 2) {
      lobes.add(_CloudLobe(cx, cy + radius * .08, radius * 1.3, radius * .58));
      lobes.add(_CloudLobe(cx + radius * shear * .6, cy - radius * 1.05, radius * 1.1, radius * .26));
    }
    var left = width, right = 0, top = height, bottom = start;
    for (final lobe in lobes) {
      left = min(left, (lobe.x - lobe.rx - 2).floor());
      right = max(right, (lobe.x + lobe.rx + 2).ceil());
      top = min(top, (lobe.y - lobe.ry - 2).floor());
      bottom = max(bottom, (lobe.y + lobe.ry + 2).ceil());
    }
    final litColor = _cloudBankMix(palette.light, palette.haze, haze);
    final midColor = _cloudBankMix(palette.body, palette.haze, haze);
    final shadeColor = _cloudBankMix(palette.shadow, palette.haze, haze);
    for (var y = max(start, top); y < min(height, bottom); y++) {
      for (var x = max(0, left); x < min(width, right); x++) {
        var field = -double.infinity;
        var nx = 0.0, ny = 0.0;
        for (final lobe in lobes) {
          final dx = (x + .5 - lobe.x) / lobe.rx;
          final dy = (y + .5 - lobe.y) / lobe.ry;
          final f = 1 - dx * dx - dy * dy;
          if (f > field) {
            field = f;
            nx = dx;
            ny = dy;
          }
        }
        final texture = _cloudBankNoise(x / max(1.5, radius * .12), y / max(1.5, radius * .12), seed);
        final erosion = (texture - .5) * .16 * _unit('detailLevel');
        if (field + erosion <= 0) continue;
        // Flatten the bases of cumulus and storm clouds without rectangular sides.
        if (style != 1 && style != 3 && y > flat + texture * radius * .05) continue;
        final lightX = (_unit('sunPosition') - .5) * 1.4;
        final normalLight = (-ny * .65 + nx * lightX + .22).clamp(0.0, 1.0);
        var illumination = (normalLight + (texture - .5) * _unit('detailLevel') * .24).clamp(0.0, 1.0);
        // A compact ramp creates readable puff shapes at small pixel sizes.
        illumination = (illumination * 5).round() / 5;
        var color = illumination < .4
            ? _cloudBankMix(shadeColor, midColor, illumination / .4)
            : _cloudBankMix(midColor, litColor, (illumination - .4) / .6);
        final lower = ((y - cy) / max(1, radius) + .5).clamp(0.0, 1.0);
        color = _cloudBankMix(color, palette.haze, lower * _unit('mistIntensity') * .25);
        final edge = (field * radius * .8).clamp(0.0, 1.0);
        final opacity = (.25 + .75 * _unit('density')) * edge * (style == 1 ? .65 : 1.0);
        final alpha = (opacity * 255).round();
        if (alpha > 0) {
          final index = y * width + x;
          out[index] = _cloudBankOver(out[index], color, alpha);
        }
      }
    }
  }
}

class _CloudLobe {
  final double x, y, rx, ry;
  const _CloudLobe(this.x, this.y, this.rx, this.ry);
}

int _cloudBankMix(int a, int b, double t) {
  t = t.clamp(0.0, 1.0);
  int c(int shift) => (((a >> shift) & 255) * (1 - t) + ((b >> shift) & 255) * t).round();
  return 0xff000000 | c(16) << 16 | c(8) << 8 | c(0);
}

/// Straight-alpha source-over keeps transparent exports free of dark fringes.
int _cloudBankOver(int background, int foreground, int alpha) {
  final a = alpha / 255;
  final b = (background >> 24) / 255 * (1 - a);
  final combined = a + b;
  int c(int shift) => ((((foreground >> shift) & 255) * a + ((background >> shift) & 255) * b) / combined).round();
  return (combined * 255).round() << 24 | c(16) << 16 | c(8) << 8 | c(0);
}

double _cloudBankNoise(double x, double y, int seed) {
  double hash(int x, int y) {
    var h = (seed ^ x * 374761393 ^ y * 668265263) & 0x7fffffff;
    h = ((h ^ h >> 13) * 1274126177) & 0x7fffffff;
    return (h ^ h >> 16) / 2147483647;
  }

  final ix = x.floor(), iy = y.floor();
  final fx = x - ix, fy = y - iy;
  final sx = fx * fx * (3 - 2 * fx), sy = fy * fy * (3 - 2 * fy);
  final a = hash(ix, iy) * (1 - sx) + hash(ix + 1, iy) * sx;
  final b = hash(ix, iy + 1) * (1 - sx) + hash(ix + 1, iy + 1) * sx;
  return a * (1 - sy) + b * sy;
}

class _CloudBankPalette {
  final int light, body, shadow, haze;
  const _CloudBankPalette(this.light, this.body, this.shadow, this.haze);
  static const schemes = [
    _CloudBankPalette(0xfffff8df, 0xffdce6e4, 0xff8297ad, 0xffbbd4dd),
    _CloudBankPalette(0xffffe5b7, 0xffe9ab9b, 0xff966f90, 0xffddb6b5),
    _CloudBankPalette(0xffb7c2ca, 0xff768396, 0xff3c465e, 0xffa1abb5),
    _CloudBankPalette(0xffb2c9d8, 0xff657c9d, 0xff303c60, 0xff7c90ad),
    _CloudBankPalette(0xffffebdf, 0xffe0c3db, 0xffa398bf, 0xffd2d0e3),
  ];
}
