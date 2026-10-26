part of 'effects.dart';

/// Seeded summit chains with geological faces, altitude snow and depth planes.
class MountainRangeEffect extends Effect {
  static const _defaults = <String, dynamic>{
    'layers': 3,
    'style': 0,
    'heightVariation': 0.55,
    'baseHeight': 0.0,
    'colorScheme': 0,
    'atmosphericHaze': 0.5,
    'sunPosition': 0.7,
    'mistIntensity': 0.3,
    'mistHeight': 0.28,
    'snowCaps': 0.2,
    'detailLevel': 0.6,
    'ridgeStrength': 0.55,
    'edgeSoftness': 0.7,
    'parallaxScroll': true,
    'time': 0.0,
    'preserveAlpha': false,
    'randomSeed': 42,
    'peakSpacing': .5,
    'startY': 0.0,
  };
  MountainRangeEffect([Map<String, dynamic>? parameters])
      : super(EffectType.mountainRange, {..._defaults, ...?parameters});

  @override
  Map<String, dynamic> getDefaultParameters() => {..._defaults};

  @override
  bool get isSeamlessLoop => true;

  @override
  Map<String, dynamic> getMetadata() => {
        'startY': {
          'label': 'Start Y',
          'description': 'Top of the generation area: 0 is the canvas top, 1 is the bottom.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 100
        },
        'layers': {
          'label': 'Mountain Layers',
          'description': 'Number of mountain layers for depth effect.',
          'type': 'slider',
          'min': 1,
          'max': 5,
          'divisions': 4,
        },
        'style': {
          'label': 'Mountain Style',
          'description': 'Style of mountain peaks and ridges.',
          'type': 'select',
          'options': {
            0: 'Smooth Ridges',
            1: 'Jagged Peaks',
            2: 'Rolling Hills',
            3: 'Sharp Alpine',
            4: 'Volcanic',
          },
        },
        'heightVariation': {
          'label': 'Height Variation',
          'description': 'How much mountain heights vary across the range.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 100,
        },
        'baseHeight': {
          'label': 'Mountain Height',
          'description': 'Overall height of the mountain range.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 100,
        },
        'colorScheme': {
          'label': 'Color Scheme',
          'description': 'Color palette for the mountain range.',
          'type': 'select',
          'options': {
            0: 'Blue Gradient',
            1: 'Sunset',
            2: 'Monochrome',
            3: 'Forest Green',
            4: 'Desert',
            5: 'Arctic',
          },
        },
        'atmosphericHaze': {
          'label': 'Atmospheric Haze',
          'description': 'Depth via atmospheric perspective on far layers.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 100,
        },
        'snowCaps': {
          'label': 'Snow Caps',
          'description': 'Amount of snow coverage on high peaks.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 100,
        },
        'mistIntensity': {
          'label': 'Mist Intensity',
          'description': 'Amount of low-lying windblown valley fog.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 100,
        },
        'sunPosition': {
          'label': 'Light Direction',
          'description': 'Direction of light on mountain faces.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 100,
        },
        'parallaxScroll': {
          'label': 'Parallax Scrolling',
          'description': 'Scroll layers with multi-plane depth parallax over time.',
          'type': 'bool',
        },
        'time': {
          'label': 'Animation Time',
          'description': 'Timeline progress for parallax scroll and mist drift.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 100,
        },
        'preserveAlpha': {
          'label': 'Preserve Transparency',
          'description': 'Restrict mountain range to existing sprite silhouette.',
          'type': 'bool',
        },
      };

  @override
  List<UIField> getFields() => [
        const SliderField(
            key: 'startY',
            label: 'Start Y',
            description: 'Top of the generation area: 0 is the canvas top, 1 is the bottom.',
            min: 0,
            max: 1,
            divisions: 100),
        const SliderField(
          key: 'layers',
          label: 'Mountain Layers',
          description: 'Number of depth layers.',
          min: 1,
          max: 5,
          divisions: 4,
          isInteger: true,
        ),
        const SelectField(
          key: 'style',
          label: 'Mountain Style',
          description: 'Peak and ridge morphology.',
          options: {
            0: 'Smooth Ridges',
            1: 'Jagged Peaks',
            2: 'Rolling Hills',
            3: 'Sharp Alpine',
            4: 'Volcanic',
          },
        ),
        const SliderField(
          key: 'heightVariation',
          label: 'Height Variation',
          description: 'Peak elevation disparity.',
          min: 0.0,
          max: 1.0,
          divisions: 100,
        ),
        const SliderField(
          key: 'baseHeight',
          label: 'Mountain Height',
          description: 'Overall ridge elevation.',
          min: 0.0,
          max: 1.0,
          divisions: 100,
        ),
        const SelectField(
          key: 'colorScheme',
          label: 'Color Scheme',
          description: 'Atmospheric color palette.',
          options: {
            0: 'Blue Gradient',
            1: 'Sunset',
            2: 'Monochrome',
            3: 'Forest Green',
            4: 'Desert',
            5: 'Arctic',
          },
        ),
        const SliderField(
          key: 'atmosphericHaze',
          label: 'Atmospheric Haze',
          description: 'Far layer depth mist.',
          min: 0.0,
          max: 1.0,
          divisions: 100,
        ),
        const SliderField(
          key: 'snowCaps',
          label: 'Snow Caps',
          description: 'Alpine summit snowline.',
          min: 0.0,
          max: 1.0,
          divisions: 100,
        ),
        const SliderField(
          key: 'mistIntensity',
          label: 'Mist Intensity',
          description: 'Valley fog and clouds.',
          min: 0.0,
          max: 1.0,
          divisions: 100,
        ),
        const SliderField(
          key: 'sunPosition',
          label: 'Light Direction',
          description: 'Direction of light on mountain faces.',
          min: 0.0,
          max: 1.0,
          divisions: 100,
        ),
        const BoolField(
          key: 'parallaxScroll',
          label: 'Parallax Scrolling',
          description: 'Multi-plane camera scroll.',
        ),
        const SliderField(
          key: 'time',
          label: 'Animation Time',
          description: 'Parallax and mist animation cycle.',
          min: 0.0,
          max: 1.0,
          divisions: 100,
        ),
        const SliderField(key: 'randomSeed', label: 'Random Seed', min: 1, max: 999, divisions: 998, isInteger: true),
        const SliderField(
            key: 'peakSpacing',
            label: 'Peak Spacing',
            description: 'Distance between major summits.',
            min: 0,
            max: 1,
            divisions: 100),
        const SliderField(
            key: 'detailLevel',
            label: 'Rock Detail',
            description: 'Erosion channels and fractured rock strata.',
            min: 0,
            max: 1,
            divisions: 100),
        const SliderField(
            key: 'ridgeStrength',
            label: 'Ridge Definition',
            description: 'Contrast between illuminated faces and shaded gullies.',
            min: 0,
            max: 1,
            divisions: 100),
        const SliderField(
            key: 'edgeSoftness',
            label: 'Ridge Softness',
            description: 'Blend angular ridges into rounded slopes.',
            min: 0,
            max: 1,
            divisions: 100),
        const SliderField(key: 'mistHeight', label: 'Valley Mist Height', min: .05, max: .6, divisions: 55),
        const BoolField(
          key: 'preserveAlpha',
          label: 'Preserve Transparency',
          description: 'Restrict to existing sprite silhouette.',
        ),
      ];

  double _value(String key) {
    final value = parameters[key];
    return value is num && value.isFinite ? value.toDouble() : (_defaults[key] as num).toDouble();
  }

  double _unit(String key) => _value(key).clamp(0.0, 1.0);

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    if (width <= 0 || height <= 0) return Uint32List(pixels.length);
    if (pixels.length != width * height) throw ArgumentError('Mountain canvas dimensions must match the pixel buffer.');
    final result = Uint32List(pixels.length);
    final start = (_unit('startY') * height).round();
    if (start >= height) return result;
    final offset = start * width;
    result.setRange(offset, result.length, _render(Uint32List.sublistView(pixels, offset), width, height - start));
    return result;
  }

  Uint32List _render(Uint32List pixels, int width, int height) {
    final out = Uint32List(pixels.length);
    final seed = _value('randomSeed').round();
    final style = _value('style').round().clamp(0, 4);
    final layers = _value('layers').round().clamp(1, 5);
    final pal = _SummitPalette.schemes[_value('colorScheme').round().clamp(0, 5)];
    final time = _value('time') - _value('time').floorToDouble();
    final sunX = _unit('sunPosition');
    for (var layer = 0; layer < layers; layer++) {
      final depth = (layer + 1) / layers;
      final layerSeed = seed ^ ((layer + 1) * 0x45d9);
      final random = Random(layerSeed);
      final count = (3 + (1 - _unit('peakSpacing')) * 5).round();
      final peaks = List<_Summit>.generate(count, (i) {
        final center = (i + .2 + random.nextDouble() * .6) / count;
        final elevation = .4 + random.nextDouble() * .6;
        return _Summit(center, elevation, (.8 + random.nextDouble() * .55) / count, (random.nextDouble() - .5) * .65);
      });
      // Rear ranges rise above the lower foothills in front of them.
      final baseline = .88 + depth * .12;
      final amplitude = (.57 + _unit('baseHeight') * .23) * (1.12 - depth * .27);
      final haze = (1 - depth) * _unit('atmosphericHaze') * .85;
      final base = _summitMix(pal.rock, pal.haze, haze);
      final dark = _summitMix(pal.shadow, pal.haze, haze);
      final light = _summitMix(pal.light, pal.haze, haze);
      final snow = _summitMix(pal.snow, pal.haze, haze * .6);
      final snowShadow = _summitMix(pal.snow, pal.shadow, .33);
      final shift = parameters['parallaxScroll'] == true ? time * (layer + 1) : 0.0;
      for (var x = 0; x < width; x++) {
        final worldX = (x / width + shift) % 1;
        var silhouette = 0.0;
        var owner = peaks.first;
        var signedDistance = 0.0;
        for (final peak in peaks) {
          var distance = worldX - peak.x;
          distance -= (distance + .5).floorToDouble();
          final n = distance.abs() / peak.spread;
          final angular = max(0.0, 1 - n);
          final round = n < 1 ? (.5 + .5 * cos(n * pi)) : 0.0;
          double shape;
          switch (style) {
            case 1:
              shape = pow(angular, .8).toDouble();
              break;
            case 2:
              shape = round;
              break;
            case 3:
              shape = pow(angular, 1.45).toDouble();
              break;
            case 4:
              // A flattened rim with a depression at the summit, not a cone.
              shape = max(0.0, 1 - n * .9);
              if (n < .22) shape -= (.22 - n) * 1.1;
              break;
            default:
              shape = angular * (1 - _unit('edgeSoftness')) + round * _unit('edgeSoftness');
          }
          final elevation = shape * (1 - _unit('heightVariation') + peak.height * _unit('heightVariation'));
          if (elevation > silhouette) {
            silhouette = elevation;
            owner = peak;
            signedDistance = distance;
          }
        }
        final roughness = (style == 1 || style == 3 ? .032 : .012) * _unit('detailLevel');
        final crags =
            sin(worldX * pi * 2 * 37 + layerSeed % 19) * sin(worldX * pi * 2 * 19 + layerSeed % 7) * roughness;
        final top = ((baseline - amplitude * (silhouette + crags + .13)) * height).round().clamp(0, height - 1);
        final summitY =
            (baseline - amplitude * (1 - _unit('heightVariation') + owner.height * _unit('heightVariation') + .13)) *
                height;
        for (var y = top; y < height; y++) {
          final descent = (y - summitY) / max(1, height);
          final ridge = owner.x + owner.lean * descent * .4 + sin(descent * 12 + owner.height * 8) * descent * .06;
          var faceX = worldX - ridge;
          faceX -= (faceX + .5).floorToDouble();
          final litFace = sunX < .5 ? faceX < 0 : faceX > 0;
          final channel = sin((signedDistance / owner.spread * 6 + descent * (owner.lean + 1) * 16) * pi);
          final secondary = sin(worldX * pi * 2 * 71 + descent * 36);
          final detail = (channel * .7 + secondary * .3) * _unit('detailLevel');
          var shade = .34 + (litFace ? 1 : -1) * (.12 + .18 * _unit('ridgeStrength')) + detail * .28;
          shade = (shade.clamp(0.0, 1.0) * 12).round() / 12;
          var color = shade > .4 ? _summitMix(base, light, (shade - .4) * 1.6) : _summitMix(dark, base, shade * 2);
          // Snow collects above a common altitude and down sheltered gullies.
          final snowLine = height * (.28 + _unit('snowCaps') * .55 - depth * .1);
          final ragged = channel * height * .025 * _unit('detailLevel');
          final stableSlope = style != 3 || litFace || detail > -.2;
          if (_unit('snowCaps') > 0 && y < snowLine + ragged && stableSlope && style != 4) {
            color = litFace ? snow : _summitMix(snowShadow, pal.haze, haze);
          }
          if (style == 4 && silhouette > .65 && descent < .14 && channel > .92) {
            color = _summitMix(color, 0xffe38751, .65 * _unit('detailLevel'));
          }
          // Broad strata follow the hillside rather than forming screen noise.
          if (style != 2 && _unit('detailLevel') > .3 && sin((y / height + worldX * .07) * 125) > .96) {
            color = _summitMix(color, dark, .12 * _unit('detailLevel'));
          }
          final foot = y / height;
          final mistBand = exp(-pow((foot - (baseline - .08)) / max(.03, _unit('mistHeight')), 2));
          final mist = mistBand * _unit('mistIntensity') * (.2 + (1 - depth) * .25);
          out[y * width + x] = _summitMix(color, pal.haze, mist);
        }
      }
    }
    if (parameters['preserveAlpha'] == true) {
      for (var i = 0; i < out.length; i++) {
        final alpha = pixels[i] >> 24;
        out[i] = alpha == 0 || out[i] == 0 ? 0 : (out[i] & 0xffffff) | (alpha << 24);
      }
    }
    return out;
  }
}

class _Summit {
  final double x, height, spread, lean;
  const _Summit(this.x, this.height, this.spread, this.lean);
}

int _summitMix(int a, int b, double t) {
  t = t.clamp(0.0, 1.0);
  int c(int shift) => (((a >> shift) & 255) * (1 - t) + ((b >> shift) & 255) * t).round();
  return 0xff000000 | c(16) << 16 | c(8) << 8 | c(0);
}

class _SummitPalette {
  final int haze, rock, shadow, light, snow;
  const _SummitPalette(this.haze, this.rock, this.shadow, this.light, this.snow);
  static const schemes = [
    _SummitPalette(0xffb7ccce, 0xff526e88, 0xff263c59, 0xff91a6b5, 0xffe4eeea),
    _SummitPalette(0xffe6ac91, 0xff786175, 0xff3c384f, 0xffc59a91, 0xffffe4bf),
    _SummitPalette(0xffc7cece, 0xff777d85, 0xff343b48, 0xffaeb7bb, 0xffedf0e8),
    _SummitPalette(0xffc1d2b4, 0xff587465, 0xff2b4644, 0xff92a183, 0xffe1e8d0),
    _SummitPalette(0xffedc8a0, 0xffaf7b5d, 0xff644954, 0xffdbb082, 0xffffe7bb),
    _SummitPalette(0xffd5e6e3, 0xff819eae, 0xff3e5c7b, 0xffb1cecf, 0xfff1f5eb),
  ];
}
