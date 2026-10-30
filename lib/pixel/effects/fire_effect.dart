part of 'effects.dart';

/// Pixel-art fire that burns the artwork.
///
/// Flames rise from every upward-facing surface of the sprite (or from the
/// bottom of the canvas in ground mode), break into tongues that taper and
/// flicker, and are drawn in a few crisp colour bands. The artwork is
/// aware-lit by the fire, and smoke and embers rise above it.
///
///  * Flame height is measured up from the nearest opaque pixel below, so
///    ledges, overhangs and gaps each get their own flames.
///  * Tongue noise is periodic in the rise direction and scrolls a whole
///    number of periods per loop, so the animation is a seamless loop
///    (`time` in [0, 1)).
///  * Heat glow tints the sprite's surface and haloes the transparent area.
class FireEffect extends Effect {
  FireEffect([Map<String, dynamic>? parameters]) : super(EffectType.fire, {..._defaults, ...?parameters});

  static const _defaults = <String, dynamic>{
    'source': 0,
    'intensity': 0.8,
    'flameHeight': 0.7,
    'flameWidth': 0.5,
    'flare': 0.6,
    'ash': 0.4,
    'smoke': 0.5,
    'embers': 0.4,
    'glow': 0.5,
    'wind': 0.0,
    'palette': 0,
    'bands': 5,
    'speed': 1,
    'seed': 42,
    'time': 0.0,
    'animated': true,
  };

  @override
  bool get isSeamlessLoop => true;

  @override
  int? get preferredFrameCount => 12;

  /// Five stops from the cool edge of the flame to its hot core.
  static const _palettes = <int, List<int>>{
    0: [0xFF7A1208, 0xFFC8280C, 0xFFF26A10, 0xFFFFB820, 0xFFFFF0A0],
    1: [0xFF10206A, 0xFF1F4FD0, 0xFF38A0F0, 0xFF9CE0FF, 0xFFF4FFFF],
    2: [0xFF0C4A14, 0xFF1C8A22, 0xFF4CD030, 0xFFB4F050, 0xFFF4FFC0],
    3: [0xFF3A0C5C, 0xFF6C1CA8, 0xFFB040E0, 0xFFE890FF, 0xFFFFF0FF],
  };

  @override
  Map<String, dynamic> getDefaultParameters() => Map.of(_defaults);

  @override
  Map<String, dynamic> getMetadata() => {
        'source': {
          'label': 'Fire Source',
          'description': 'Burn the artwork, or light a fire along the bottom of the canvas.',
          'type': 'select',
          'options': {0: 'Burning Artwork', 1: 'Ground Fire'},
        },
        'palette': {
          'label': 'Flame Color',
          'type': 'select',
          'options': {0: 'Classic', 1: 'Blue Gas', 2: 'Witch Green', 3: 'Violet'},
        },
        for (final spec in [
          ('intensity', 'Intensity', 'Brightness and density of the fire.', 0.0, 1.0),
          ('flameHeight', 'Flame Height', 'How far the flames reach.', 0.0, 1.0),
          ('flameWidth', 'Tongue Width', 'Width of individual flame tongues.', 0.0, 1.0),
          ('flare', 'Flare', 'Size of the white-hot core.', 0.0, 1.0),
          ('ash', 'Ash & Soot', 'Dark specks flickering in the flames.', 0.0, 1.0),
          ('smoke', 'Smoke', 'Smoke rising above the flames.', 0.0, 1.0),
          ('embers', 'Embers', 'Sparks drifting upward.', 0.0, 1.0),
          ('glow', 'Heat Glow', 'Firelight on the artwork and a halo around it.', 0.0, 1.0),
          ('wind', 'Wind', 'Leans flames, smoke and sparks sideways.', -1.0, 1.0),
          ('bands', 'Color Bands', 'Number of flat colors in the flame.', 3, 8),
          ('speed', 'Flicker Speed', 'Rise cycles per loop.', 1, 3),
          ('seed', 'Pattern Seed', null, 0, 9999),
        ])
          spec.$1: {
            'label': spec.$2,
            if (spec.$3 != null) 'description': spec.$3,
            'type': 'slider',
            'min': spec.$4,
            'max': spec.$5,
            'divisions': spec.$4 is int ? (spec.$5 - spec.$4).toInt() : 100,
          },
        'animated': {'label': 'Animated', 'description': 'Enables or disables the fire animation.', 'type': 'bool'},
      };

  double _number(String key, double min, double max) {
    final value = (parameters[key] as num?)?.toDouble();
    return (value != null && value.isFinite ? value : (_defaults[key] as num).toDouble()).clamp(min, max);
  }

  /// Value noise that repeats every [period] lattice cells along v.
  static double _periodic(double u, double v, int period, int seed) {
    final u0 = u.floor(), v0 = v.floor();
    final tu = u - u0, tv = v - v0;
    final su = tu * tu * (3 - 2 * tu), sv = tv * tv * (3 - 2 * tv);
    double h(int i, int j) => _textureHash(i, ((j % period) + period) % period, seed);
    final top = h(u0, v0) + (h(u0 + 1, v0) - h(u0, v0)) * su;
    final bottom = h(u0, v0 + 1) + (h(u0 + 1, v0 + 1) - h(u0, v0 + 1)) * su;
    return top + (bottom - top) * sv;
  }

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    final result = Uint32List.fromList(pixels);
    if (width <= 0 || height <= 0 || pixels.length < width * height) return result;
    final intensity = _number('intensity', 0, 1);
    if (intensity == 0) return result;

    final ground = _number('source', 0, 1).round() == 1;
    final flameHeight = _number('flameHeight', 0, 1);
    final flameWidth = _number('flameWidth', 0, 1);
    final flare = _number('flare', 0, 1);
    final ash = _number('ash', 0, 1);
    final smoke = _number('smoke', 0, 1);
    final embers = _number('embers', 0, 1);
    final glow = _number('glow', 0, 1);
    final wind = _number('wind', -1, 1);
    final stops = _palettes[_number('palette', 0, 3).round()]!;
    final bands = _number('bands', 3, 8).round();
    final speed = _number('speed', 1, 3).round();
    final seed = _number('seed', 0, 9999).round();
    final time = parameters['animated'] == false ? 0.0 : (_number('time', -1000, 1000) % 1.0);

    int ramp(double t) {
      final p = t.clamp(0.0, 1.0) * (stops.length - 1);
      final k = min(p.floor(), stops.length - 2);
      return _textureBlendColor(stops[k], stops[k + 1], p - k, 255);
    }

    final count = width * height;
    final solid = Uint8List(count);
    for (var i = 0; i < count; i++) {
      if ((pixels[i] >>> 24) != 0) solid[i] = 1;
    }

    // Height above the nearest fuel (opaque pixel) below, per pixel.
    const far = 1e6;
    final rise = Float32List(count);
    final root = List<int>.filled(width, -1); // top of the fuel in each column
    for (var x = 0; x < width; x++) {
      var d = ground ? 0.0 : far;
      for (var y = height - 1; y >= 0; y--) {
        final i = y * width + x;
        if (ground) {
          d += 1;
        } else if (solid[i] == 1) {
          d = 0;
          root[x] = y;
        } else if (d < far) {
          d += 1;
        }
        rise[i] = d;
      }
      if (ground) root[x] = height - 1;
    }

    // Tongues are fatter at the sides of fuel, and lean with the wind.
    double riseAt(int x, int y) {
      final i = y * width + x;
      var d = rise[i];
      if (!ground) {
        for (var dx = -2; dx <= 2; dx++) {
          final xx = x + dx;
          if (dx == 0 || xx < 0 || xx >= width) continue;
          d = min(d, rise[y * width + xx] + dx.abs() * 1.0);
        }
      }
      return d;
    }

    final reach = max(6.0, height * (0.15 + flameHeight * 0.45));
    final tongue = 3 + flameWidth * 8;
    final flicker = 1 + 0.08 * sin(2 * pi * time * speed);
    final scroll2 = time * 8 * speed, scroll3 = time * 16 * speed, scroll4 = time * 6 * speed;
    final frameCell = (time * 8 * speed).floor() % (8 * speed);

    // Pass 1: flame intensity and smoke density per pixel.
    final flame = Float32List(count), smokeMap = Float32List(count);
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final i = y * width + x;
        if (!ground && solid[i] == 1) continue;
        // Lean: look up the fuel column the flame leans away from.
        var xs = x;
        if (wind != 0) {
          final d0 = rise[i];
          if (d0 < far) xs = (x - wind * 0.45 * min(d0, reach)).round().clamp(0, width - 1);
        }
        final d = riseAt(xs, y);
        if (d >= far) continue;

        final colHeight = reach * (0.55 + 0.9 * _periodic(x / (tongue * 1.3), time * 4 * speed, 4, seed + 7)) * flicker;
        final t = d / colHeight;
        final u = x / tongue;
        final n2 = _periodic(u, y / (tongue * 1.6) + scroll2, 8, seed + 11);
        final n3 = _periodic(u * 2.1, y / (tongue * 0.9) + scroll3, 16, seed + 13);
        final tongueNoise = n2 * 0.65 + n3 * 0.35;

        final dense = (1 - t) * 1.15 + (tongueNoise - 0.5) * 1.2 - 0.3;
        var value = dense * (0.6 + intensity * 0.6);
        if (value > 0.1) {
          // Soot flickers out single pixels at the cool edge.
          if (ash > 0 && value < 0.55 && _textureHash(x, y, seed + 31 + frameCell) < ash * 0.22) value -= 0.25;
          if (value > 0.1) flame[i] = value.clamp(0.0, 1.0);
        }

        if (smoke > 0 && t > 0.7 && t < 1.7) {
          final puff = _periodic(x / (tongue * 1.6) - wind * t * 2, y / (tongue * 2.2) + scroll4, 6, seed + 17);
          final fall = 1 - (t - 1.0).abs() / 0.7;
          smokeMap[i] = (smoke * fall.clamp(0.0, 1.0) * (puff - 0.35) * 2.2).clamp(0.0, 1.0);
        }
      }
    }

    // Heat glow: blurred flame light.
    final glowMap = glow > 0 ? _silhouetteBlur(flame, width, height, 3) : flame;

    // Pass 2: composite.
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final i = y * width + x;
        final source = pixels[i];
        final onArt = solid[i] == 1;
        final f = flame[i];

        if (f > 0) {
          // Most of the flame stays orange; only the core runs yellow to white.
          var heat = pow(f, 1.6).toDouble() * 0.95 + flare * 0.25 * f * f * f;
          if (ash > 0) heat -= ash * 0.04;
          final band = (heat.clamp(0.0, 0.999) * bands).floor();
          final color = ramp(band / (bands - 1));
          final alpha = band == 0 ? 175 : 255;
          result[i] = onArt || (source >>> 24) != 0 ? _firePut(source, color, alpha / 255) : (alpha << 24) | (color & 0xFFFFFF);
          continue;
        }

        final s = smokeMap[i];
        if (s > 0) {
          // Two flat smoke tones, dithered at their edges.
          final level = s > 0.5 ? 2 : 1;
          if (s > 0.14 && _textureHash(x, y, seed + 41) < s * 1.4) {
            final shade = level == 2 ? 0x3A : 0x55;
            final alpha = level == 2 ? 120 : 80;
            final color = 0xFF000000 | (shade << 16) | (shade << 8) | shade;
            result[i] = _firePut(source, color, alpha / 255);
            continue;
          }
        }

        final g = glowMap[i] * glow;
        if (g > 0.03) {
          final warm = ramp(0.45 + g * 0.5);
          if (onArt) {
            result[i] = _firePut(source, warm, (g * 1.3).clamp(0.0, 0.6));
          } else {
            final alpha = (g * 190).round().clamp(0, 140);
            if (alpha >= 18) result[i] = (alpha << 24) | (warm & 0xFFFFFF);
          }
        }
      }
    }

    // Embers rise in loops, fading as they cool.
    if (embers > 0) {
      final n = (embers * width / 2).round().clamp(0, 60);
      for (var k = 0; k < n; k++) {
        final x0 = (_textureHash(k, 1, seed + 51) * width).floor().clamp(0, width - 1);
        if (root[x0] < 0) continue;
        final cycles = (1 + (_textureHash(k, 2, seed + 51) * 2).floor()) * speed;
        final phase = _textureHash(k, 3, seed + 51);
        final p = (time * cycles + phase) % 1.0;
        final travel = reach * (1.2 + _textureHash(k, 4, seed + 51) * 0.9);
        final y = (root[x0] - 1 - p * travel).round();
        final x = (x0 + sin((p + phase) * 4 * pi) * 2 + wind * p * 8).round();
        if (x < 0 || y < 0 || x >= width || y >= height) continue;
        final i = y * width + x;
        if (!ground && solid[i] == 1) continue;
        final color = ramp(0.75 - p * 0.55);
        final alpha = pow(1 - p, 0.7).toDouble();
        if (alpha > 0.1) result[i] = _firePut(result[i], color, alpha);
      }
    }
    return result;
  }

  /// Draws [color] over [base] at [alpha]; fully transparent bases take the
  /// colour with that alpha.
  static int _firePut(int base, int color, double alpha) {
    final baseAlpha = base >>> 24;
    if (baseAlpha == 0) return ((alpha * 255).round().clamp(0, 255) << 24) | (color & 0xFFFFFF);
    return (_textureBlendColor(base, color, alpha, baseAlpha) & 0x00FFFFFF) | (baseAlpha << 24);
  }
}
