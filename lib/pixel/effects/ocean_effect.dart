part of 'effects.dart';

/// Perspective ocean surface with coherent swell trains and crest-bound foam.
/// Background above the water horizon stays transparent.
class OceanEffect extends Effect {
  static const _defaults = <String, dynamic>{
    'waveFrequency': .5,
    'waveAmplitude': .5,
    'waveDirection': .3,
    'waveComplexity': .5,
    'foamIntensity': .6,
    'foamSpread': .4,
    'colorScheme': 0,
    'waterClarity': .5,
    'waterDepth': .6,
    'sunPosition': .5,
    'sunElevation': .7,
    'sunGlare': .7,
    'horizonHaze': .5,
    'windSpeed': .5,
    'storminess': 0.0,
    'timeOfDay': .5,
    'randomSeed': 42,
    'time': 0.0,
    'startY': .4,
    'endY': 1.0,
    'coast': false,
    'oceanStyle': 0,
    'perspective': .75,
  };
  OceanEffect([Map<String, dynamic>? parameters])
      : super(EffectType.ocean, {
          ..._defaults,
          if (parameters?['horizonLevel'] is num) 'startY': parameters!['horizonLevel'],
          ...?parameters,
        });

  @override
  Map<String, dynamic> getDefaultParameters() => {..._defaults};

  @override
  bool get isSeamlessLoop => true;

  @override
  Map<String, dynamic> getMetadata() {
    return {
      'startY': {
        'label': 'Start Y',
        'description': 'Water horizon: 0 is the canvas top, 1 is the bottom.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100
      },
      'endY': {
        'label': 'End Y',
        'description': 'Bottom of the ocean area: 0 is the canvas top, 1 is the bottom.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
      'coast': {
        'label': 'Coast',
        'description': 'Adds a sandy shore with animated surf near End Y.',
        'type': 'bool',
      },
      'oceanStyle': {
        'label': 'Ocean Style',
        'description': 'Character of the water surface.',
        'type': 'select',
        'options': {0: 'Open Swells', 1: 'Calm Lagoon', 2: 'Breaking Surf', 3: 'Storm Sea'}
      },
      'perspective': {
        'label': 'Perspective',
        'description': 'Compresses distant waves toward the horizon.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100
      },
      'waveFrequency': {
        'label': 'Wave Frequency',
        'description': 'The density and scale of the waves.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
      'waveAmplitude': {
        'label': 'Wave Amplitude',
        'description': 'The height and intensity of the waves.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
      'waveDirection': {
        'label': 'Wave Direction',
        'description': 'Primary direction waves travel from.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
      'waveComplexity': {
        'label': 'Wave Complexity',
        'description': 'Number of overlapping wave patterns.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
      'foamIntensity': {
        'label': 'Foam Intensity',
        'description': 'The amount of foam on wave crests.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
      'foamSpread': {
        'label': 'Foam Spread',
        'description': 'How far foam spreads from wave crests.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
      'colorScheme': {
        'label': 'Color Scheme',
        'description': 'Color palette for the water.',
        'type': 'select',
        'options': {
          0: 'Tropical Paradise',
          1: 'Deep Atlantic',
          2: 'Sunset/Sunrise',
          3: 'Stormy Seas',
          4: 'Arctic',
          5: 'Mediterranean',
          6: 'Night Ocean',
          7: 'Alien World',
        },
      },
      'waterClarity': {
        'label': 'Water Clarity',
        'description': 'How clear or murky the water appears.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
      'waterDepth': {
        'label': 'Water Depth',
        'description': 'Perceived depth affecting color darkness.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
      'sunPosition': {
        'label': 'Reflection Position',
        'description': 'Horizontal position of the sun.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
      'sunElevation': {
        'label': 'Sun Elevation',
        'description': 'Height of the sun above the horizon.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
      'sunGlare': {
        'label': 'Sun Glare',
        'description': 'Intensity of sun reflection on water.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
      'horizonHaze': {
        'label': 'Horizon Haze',
        'description': 'Atmospheric haze near the horizon.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
      'windSpeed': {
        'label': 'Wind Speed',
        'description': 'Affects wave choppiness and foam.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
      'storminess': {
        'label': 'Storm Intensity',
        'description': 'Overall storm conditions.',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
      'timeOfDay': {
        'label': 'Time of Day',
        'description': 'Affects lighting and colors (0=midnight, 0.5=noon).',
        'type': 'slider',
        'min': 0.0,
        'max': 1.0,
        'divisions': 100,
      },
      'randomSeed': {
        'label': 'Random Seed',
        'description': 'Changes wave and cloud patterns.',
        'type': 'slider',
        'min': 1,
        'max': 100,
        'divisions': 99,
      },
      'time': {
        'label': 'Animation Time',
        'description': 'Animates waves and clouds.',
        'type': 'slider',
        'min': 0.0,
        'max': 100.0,
        'divisions': 1000,
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
    if (pixels.length != width * height) throw ArgumentError('Ocean canvas dimensions must match the pixel buffer.');
    final out = Uint32List(pixels.length);
    final start = (_unit('startY') * height).round();
    final end = (_unit('endY') * height).round();
    if (start >= end) return out;
    final waterHeight = end - start;
    final coast = parameters['coast'] == true;
    final style = _value('oceanStyle').round().clamp(0, 3);
    final palette = _SwellPalette.schemes[_value('colorScheme').round().clamp(0, 7)];
    final random = Random(_value('randomSeed').round());
    final phase = random.nextDouble() * pi * 2;
    final crossPhase = random.nextDouble() * pi * 2;
    final time = (_value('time') - _value('time').floorToDouble()) * pi * 2;
    final storm = max(_unit('storminess'), style == 3 ? .8 : 0.0);
    final strength = _unit('waveAmplitude') * (style == 1 ? .25 : 1.0) * (.65 + storm * .65);
    final wind = _unit('windSpeed');
    final angle = _unit('waveDirection') * pi * 2;
    final frequency = 3 + _unit('waveFrequency') * 12;
    final perspective = _unit('perspective');
    final night = ((.5 + .5 * cos(_unit('timeOfDay') * pi * 2)) * .6).clamp(0.0, .6);
    final baseDeep = _swellMix(palette.deep, 0xff111b30, night + storm * .12);
    final baseShallow = _swellMix(palette.shallow, palette.deep, _unit('waterDepth') * .65 + storm * .2);
    final foamColor = _swellMix(palette.foam, palette.horizon, night * .45);
    final glareColor = _swellMix(palette.glint, foamColor, _unit('sunElevation') * .35);
    for (var y = start; y < end; y++) {
      final depth = (y - start) / max(1, waterHeight - 1);
      // Logarithmic projection concentrates fine wave bands at the horizon.
      final projected = depth * (1 - perspective) + log(1 + depth * 18) / log(19) * perspective;
      final distanceColor = _swellMix(baseDeep, baseShallow, pow(depth, .65).toDouble() * _unit('waterClarity'));
      for (var x = 0; x < width; x++) {
        final u = x / max(1, width);
        final bend = sin(u * pi * 4 + phase) * (.08 + wind * .12);
        final travel = projected * frequency * pi * 2 + u * sin(angle) * 3 + bend;
        final swell = sin(travel - time + phase);
        final crossing = sin(projected * frequency * 1.7 * pi * 2 + u * 13 + time * 2 + crossPhase);
        final ripple =
            sin(u * (40 + wind * 65) + projected * 23 - time * 3 + phase) * sin(projected * 77 + u * 17 + time * 2);
        final complexity = _unit('waveComplexity');
        final surface = (swell * .75 + crossing * .22 * complexity + ripple * .12 * wind) * strength;
        // Quantized ramps keep large areas clean and readable at sprite scale.
        final light = ((.48 + surface * .42).clamp(0.0, 1.0) * 9).round() / 9;
        var color = light < .45
            ? _swellMix(baseDeep, distanceColor, light / .45)
            : _swellMix(distanceColor, palette.crest, (light - .45) * 1.3);
        final crest = sin(travel - time + phase + .35);
        final breakup = .5 + .3 * sin(u * 31 + projected * 19 + phase) + .2 * sin(u * 83 - time + crossPhase);
        final foamWidth = .018 + _unit('foamSpread') * .16;
        final breaking = crest > 1 - foamWidth * strength &&
            breakup > 1 - _unit('foamIntensity') * (.7 + storm * .25) &&
            strength > .01;
        if (breaking) {
          color = _swellMix(color, foamColor, (.65 + depth * .35) * _unit('foamIntensity'));
        }
        if (style == 2 && depth > .63) {
          final surf = sin(projected * 32 - time + bend * 2);
          if (surf > .86 - _unit('foamSpread') * .14 && breakup > .25 && _unit('foamIntensity') > 0) {
            color = _swellMix(color, foamColor, _unit('foamIntensity') * (.6 + depth * .4));
          }
        }
        // Broken horizontal glints follow the same surface rather than white noise.
        final reflectionWidth = .025 + depth * (.06 + _unit('sunElevation') * .12);
        final reflectionCenter = _unit('sunPosition') + sin(projected * 40 + phase - time) * depth * .025;
        final glare = exp(-pow((u - reflectionCenter) / reflectionWidth, 2)) * _unit('sunGlare');
        if (swell + ripple * .2 > .25 && breakup > .25) {
          color = _swellMix(color, glareColor, glare * (.3 + depth * .55));
        }
        final haze = pow(1 - depth, 4).toDouble() * _unit('horizonHaze') * .7;
        color = _swellMix(color, palette.horizon, haze);
        if (coast) {
          // A curved shore, with periodic swash and a wet-sand transition.
          final shore = .82 + sin(u * pi * 2 + phase) * .035 + sin(u * pi * 5 + crossPhase) * .012;
          final swash = sin(time + u * 3 + phase) * .025;
          final edge = shore + swash;
          final sand = _swellMix(0xffd8bd88, palette.horizon, night * .35);
          final wetSand = _swellMix(sand, baseDeep, .28);
          if (depth >= edge) {
            final dry = ((depth - edge) / .09).clamp(0.0, 1.0);
            color = _swellMix(wetSand, sand, dry);
            final grain = sin(x * 13.7 + y * 37.1 + phase) * sin(x * 3.1 - y * 9.3);
            if (grain > .76) color = _swellMix(color, palette.foam, .15);
          } else if (depth > edge - .14) {
            final shallows = (depth - edge + .14) / .14;
            color = _swellMix(color, _swellMix(baseShallow, wetSand, .3), shallows * .65);
          }
          final foamDistance = edge - depth;
          final foamBand = .012 + _unit('foamSpread') * .035;
          if (foamDistance >= 0 && foamDistance < foamBand && breakup > .12 && _unit('foamIntensity') > 0) {
            color = _swellMix(color, foamColor, (1 - foamDistance / foamBand) * _unit('foamIntensity'));
          }
        }
        out[y * width + x] = color;
      }
    }
    return out;
  }
}

int _swellMix(int a, int b, double t) {
  t = t.clamp(0.0, 1.0);
  int c(int shift) => (((a >> shift) & 255) * (1 - t) + ((b >> shift) & 255) * t).round();
  return 0xff000000 | c(16) << 16 | c(8) << 8 | c(0);
}

class _SwellPalette {
  final int deep, shallow, crest, foam, horizon, glint;
  const _SwellPalette(this.deep, this.shallow, this.crest, this.foam, this.horizon, this.glint);
  static const schemes = [
    _SwellPalette(0xff14516b, 0xff35b4ab, 0xff7bd9c5, 0xffe2f4db, 0xff8ab7c1, 0xffffe8b1),
    _SwellPalette(0xff152d51, 0xff356b92, 0xff729fbc, 0xffd8e6e9, 0xff718ca6, 0xffe6e5cb),
    _SwellPalette(0xff443a62, 0xff996475, 0xffcc968c, 0xffffd6b0, 0xffbca0aa, 0xffffc588),
    _SwellPalette(0xff243543, 0xff526b71, 0xff8a9e9e, 0xffd4dfd4, 0xff839496, 0xffc7d1c4),
    _SwellPalette(0xff28475d, 0xff729da7, 0xffa8d2d0, 0xffeff6e8, 0xffa2c0c4, 0xffedf1dc),
    _SwellPalette(0xff163b6b, 0xff397faf, 0xff70b8cf, 0xffe7efdd, 0xff8bb3ce, 0xffffe9ad),
    _SwellPalette(0xff0c182f, 0xff244359, 0xff52788b, 0xffa6c4cd, 0xff415c78, 0xffc5d8de),
    _SwellPalette(0xff32245d, 0xff785a9a, 0xffb28bb7, 0xffe5e6b6, 0xff8b88ae, 0xffb6f1ce),
  ];
}
