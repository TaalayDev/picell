part of 'effects.dart';

/// Print-style halftone: a rotated screen of dots whose size follows the tone
/// of the artwork underneath.
///
/// It is silhouette- and artwork-aware:
///  * cell tones come only from opaque pixels, so edges don't read as darker or
///    lighter because of transparency, and dots are clipped to the silhouette;
///  * `autoLevels` stretches the artwork's tonal range so flat or low-contrast
///    sprites still use the full dot-size range;
///  * `keepOutlines` leaves dark, high-contrast lines solid so line art isn't
///    broken up by the screen.
class HalftoneEffect extends Effect {
  HalftoneEffect([Map<String, dynamic>? parameters]) : super(EffectType.halftone, {..._defaults, ...?parameters});

  static const _defaults = <String, dynamic>{
    'dotSize': 0.5,
    'spacing': 0.5,
    'angle': 0.0,
    'style': 0,
    'inkMode': 0,
    'inkColor': 0xFF1A1A1A,
    'paperMode': 0,
    'paperColor': 0xFFF5EBD8,
    'autoLevels': true,
    'keepOutlines': 0.4,
    'invert': false,
  };

  @override
  Map<String, dynamic> getDefaultParameters() => Map.of(_defaults);

  @override
  Map<String, dynamic> getMetadata() => {
        'style': {
          'label': 'Dot Style',
          'description': 'Shape of the screen elements.',
          'type': 'select',
          'options': {0: 'Circle', 1: 'Square', 2: 'Line', 3: 'Cross', 4: 'Diamond'},
        },
        'spacing': {
          'label': 'Dot Spacing',
          'description': 'Distance between screen cells (2 to 8 pixels).',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 100,
        },
        'dotSize': {
          'label': 'Dot Size',
          'description': 'How strongly tone grows the dots.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 100,
        },
        'angle': {
          'label': 'Screen Angle',
          'description': 'Rotation of the whole screen (0 to 360 degrees).',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 100,
        },
        'inkMode': {
          'label': 'Ink',
          'description': 'Use each cell\'s own color or a single ink color.',
          'type': 'select',
          'options': {0: 'Source Color', 1: 'Single Ink'},
        },
        'inkColor': {'label': 'Ink Color', 'type': 'color'},
        'paperMode': {
          'label': 'Paper',
          'description': 'What shows between the dots.',
          'type': 'select',
          'options': {0: 'Transparent', 1: 'Paper Color', 2: 'Faded Original'},
        },
        'paperColor': {'label': 'Paper Color', 'type': 'color'},
        'autoLevels': {
          'label': 'Auto Levels',
          'description': 'Stretch the artwork\'s tones to the full dot-size range.',
          'type': 'bool',
        },
        'keepOutlines': {
          'label': 'Keep Outlines',
          'description': 'Keep dark, high-contrast lines solid instead of dotting them.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 100,
        },
        'invert': {
          'label': 'Light Dots',
          'description': 'Dots grow with brightness instead of darkness (for dark paper).',
          'type': 'bool',
        },
      };

  double _number(String key, double min, double max) {
    final value = (parameters[key] as num?)?.toDouble();
    return (value != null && value.isFinite ? value : (_defaults[key] as num).toDouble()).clamp(min, max);
  }

  int _color(String key) {
    final value = parameters[key];
    return value is num ? value.toInt() : (_defaults[key] as int);
  }

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    final result = Uint32List(pixels.length);
    if (width <= 0 || height <= 0 || pixels.length < width * height) return result;

    final dotSize = _number('dotSize', 0, 1);
    final cell = 2 + _number('spacing', 0, 1) * 6;
    // Legacy projects stored the angle as a [0, 1] turn.
    final angle = _number('angle', 0, 1) * 2 * pi;
    final style = _number('style', 0, 4).round();
    final singleInk = _number('inkMode', 0, 1).round() == 1;
    final inkColor = _color('inkColor') | 0xFF000000;
    final paperMode = _number('paperMode', 0, 2).round();
    final paperColor = _color('paperColor') | 0xFF000000;
    final keepOutlines = _number('keepOutlines', 0, 1);
    final invert = parameters['invert'] == true;
    final cosA = cos(angle), sinA = sin(angle);

    // Tone range for auto levels (2nd to 98th percentile of opaque luminance).
    var lo = 0.0, hi = 1.0;
    if (parameters['autoLevels'] != false) {
      final histogram = List<int>.filled(256, 0);
      var total = 0;
      for (var i = 0; i < width * height; i++) {
        if ((pixels[i] >>> 24) == 0) continue;
        histogram[(_textureLuminance(pixels[i]) * 255).round().clamp(0, 255)]++;
        total++;
      }
      if (total > 0) {
        var acc = 0;
        var lowBin = 0, highBin = 255;
        for (var b = 0; b < 256; b++) {
          acc += histogram[b];
          if (acc >= total * 0.02) {
            lowBin = b;
            break;
          }
        }
        acc = 0;
        for (var b = 255; b >= 0; b--) {
          acc += histogram[b];
          if (acc >= total * 0.02) {
            highBin = b;
            break;
          }
        }
        if (highBin - lowBin >= 8) {
          lo = lowBin / 255;
          hi = highBin / 255;
        }
      }
    }

    double lumAt(int x, int y, double fallback) {
      if (x < 0 || y < 0 || x >= width || y >= height) return fallback;
      final p = pixels[y * width + x];
      return (p >>> 24) == 0 ? fallback : _textureLuminance(p);
    }

    // Per-cell tone/colour cache so each screen cell is sampled once.
    final cache = <int, (double, int)?>{};
    (double, int)? sampleCell(int ci, int cj) {
      final key = (cj + 4096) * 8192 + (ci + 4096);
      if (cache.containsKey(key)) return cache[key];
      final cu = (ci + 0.5) * cell, cv = (cj + 0.5) * cell;
      var r = 0, g = 0, b = 0, n = 0;
      var lum = 0.0;
      for (var oj = -1; oj <= 1; oj++) {
        for (var oi = -1; oi <= 1; oi++) {
          final su = cu + oi * cell * 0.3, sv = cv + oj * cell * 0.3;
          final x = (su * cosA - sv * sinA).floor(), y = (su * sinA + sv * cosA).floor();
          if (x < 0 || y < 0 || x >= width || y >= height) continue;
          final p = pixels[y * width + x];
          if ((p >>> 24) == 0) continue;
          r += (p >> 16) & 0xFF;
          g += (p >> 8) & 0xFF;
          b += p & 0xFF;
          lum += _textureLuminance(p);
          n++;
        }
      }
      final value = n == 0 ? null : (lum / n, 0xFF000000 | ((r ~/ n) << 16) | ((g ~/ n) << 8) | (b ~/ n));
      cache[key] = value;
      return value;
    }

    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final i = y * width + x;
        final source = pixels[i];
        final alpha = source >>> 24;
        if (alpha == 0) continue;

        final px = x + 0.5, py = y + 0.5;
        final u = px * cosA + py * sinA, v = -px * sinA + py * cosA;
        final ci = (u / cell).floor(), cj = (v / cell).floor();
        final pu = u / cell - ci - 0.5, pv = v / cell - cj - 0.5; // -0.5..0.5 within the cell

        final ownLum = _textureLuminance(source);
        final sample = sampleCell(ci, cj) ?? (ownLum, source | 0xFF000000);
        final tone = ((sample.$1 - lo) / (hi - lo)).clamp(0.0, 1.0);
        final coverage = ((invert ? tone : 1 - tone) * (0.4 + dotSize * 1.2)).clamp(0.0, 1.2);

        final ink = switch (style) {
          1 => max(pu.abs(), pv.abs()) <= sqrt(coverage) / 2,
          2 => pv.abs() <= coverage / 2,
          3 => () {
              final w = 1 - sqrt((1 - coverage).clamp(0.0, 1.0));
              return pu.abs() <= w / 2 || pv.abs() <= w / 2;
            }(),
          4 => pu.abs() + pv.abs() <= sqrt(coverage / 2),
          _ => sqrt(pu * pu + pv * pv) <= sqrt(coverage / pi),
        };

        // Dark, high-contrast line art stays solid.
        var outline = false;
        if (keepOutlines > 0 && ownLum < 0.4) {
          // Difference to each neighbour (not central), so 1px lines register.
          final gx = max((lumAt(x + 1, y, ownLum) - ownLum).abs(), (lumAt(x - 1, y, ownLum) - ownLum).abs());
          final gy = max((lumAt(x, y + 1, ownLum) - ownLum).abs(), (lumAt(x, y - 1, ownLum) - ownLum).abs());
          if (max(gx, gy) > 0.35 - keepOutlines * 0.27) outline = true;
        }

        int out;
        if (outline) {
          out = source;
        } else if (ink) {
          out = ((singleInk ? inkColor : sample.$2) & 0x00FFFFFF) | (alpha << 24);
        } else {
          out = switch (paperMode) {
            1 => (paperColor & 0x00FFFFFF) | (alpha << 24),
            2 => (_textureBlendColor(source, paperColor, 0.75, 255) & 0x00FFFFFF) | (alpha << 24),
            _ => 0,
          };
        }
        result[i] = out;
      }
    }
    return result;
  }
}
