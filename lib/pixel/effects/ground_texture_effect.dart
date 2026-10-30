part of 'effects.dart';

/// Procedural ground surfaces applied inside the artwork silhouette.
///
/// Each surface is a small generator producing tone, height and a palette mix
/// per pixel (bricks, cobbles, grass, lava cracks, ...). It is shape-aware:
///  * silhouette edges get a lit lip on the light side and grime on the other
///    (`edgeWear`), so a ground slab reads as a solid chunk;
///  * the artwork's own luminance and edges can modulate the surface
///    (`keepArtwork`), keeping the sprite's form readable through the texture.
class GroundTextureEffect extends Effect {
  GroundTextureEffect([Map<String, dynamic>? parameters]) : super(EffectType.groundTexture, {..._defaults, ...?parameters});

  static const _defaults = <String, dynamic>{
    'textureType': 0,
    'scale': 16.0,
    'blend': 0.75,
    'blendMode': 0,
    'offsetX': 0.0,
    'offsetY': 0.0,
    'noiseAmount': 0.1,
    'rotation': 0,
    'depthIntensity': 0.5,
    'colorTint': 0,
    'edgeWear': 0.5,
    'keepArtwork': 0.3,
    'lightDirection': 225.0,
    'seed': 42,
  };

  /// Surface name and five-stop palettes (dark to light). `b` is the secondary
  /// palette the generator mixes in (mortar, moss, lava, ...).
  static const _surfaces = <int, _GroundSurface>{
    0: _GroundSurface('Dirt & Rocks', [0xFF2E2118, 0xFF4A3A2C, 0xFF5C4739, 0xFF8A7A6A, 0xFFB5A590]),
    1: _GroundSurface(
      'Mossy Stone',
      [0xFF2A2C2B, 0xFF4B4E4C, 0xFF6E726F, 0xFF979B96, 0xFFB9BDB6],
      [0xFF1E3318, 0xFF2F5220, 0xFF4A7A30, 0xFF6FA043, 0xFF9CC95F],
    ),
    2: _GroundSurface('Rich Sand', [0xFF9A7E4E, 0xFFB99A62, 0xFFD2B77C, 0xFFE4CC96, 0xFFF2E0B0]),
    3: _GroundSurface('Pebble Gravel', [0xFF2B2824, 0xFF55504A, 0xFF807A70, 0xFFA8A296, 0xFFCFC8B8]),
    4: _GroundSurface('Terracotta Clay', [0xFF7A3A22, 0xFF9C4E2E, 0xFFB9633A, 0xFFD07F52, 0xFFE39B6E]),
    5: _GroundSurface(
      'Red Bricks',
      [0xFF4F211A, 0xFF7A3226, 0xFFA2442F, 0xFFBF5A40, 0xFFD7785A],
      [0xFF5E5A52, 0xFF7C776C, 0xFF9A9486, 0xFFB4AE9F, 0xFFCEC8B8],
    ),
    6: _GroundSurface(
      'Stone Blocks',
      [0xFF3A3D40, 0xFF5A5E62, 0xFF7B8086, 0xFF9CA1A7, 0xFFBDC2C8],
      [0xFF1E2024, 0xFF2C2F34, 0xFF3B3F45, 0xFF4C5158, 0xFF5E636B],
    ),
    7: _GroundSurface('Cracked Ice', [0xFF5A88B0, 0xFF86B4D8, 0xFFB0D8F0, 0xFFD6F0FC, 0xFFFFFFFF]),
    8: _GroundSurface('Dark Cobblestone', [0xFF0F1114, 0xFF22262B, 0xFF363B42, 0xFF4D535C, 0xFF69707A]),
    9: _GroundSurface(
      'Sandy Gravel',
      [0xFF9A7E4E, 0xFFB99A62, 0xFFD2B77C, 0xFFE4CC96, 0xFFF2E0B0],
      [0xFF2B2824, 0xFF55504A, 0xFF807A70, 0xFFA8A296, 0xFFCFC8B8],
    ),
    10: _GroundSurface(
      'Volcanic Rock',
      [0xFF0E0C0C, 0xFF1E1A19, 0xFF302A28, 0xFF473F3B, 0xFF625852],
      [0xFF5A0E00, 0xFFA81E00, 0xFFE8480A, 0xFFFF8A1E, 0xFFFFD060],
    ),
    11: _GroundSurface(
      'Grass',
      [0xFF1D3F12, 0xFF2F6320, 0xFF428A2C, 0xFF62B03F, 0xFF93D460],
      [0xFF5A5A20, 0xFF84802E, 0xFFAAA040, 0xFFC8BE5A, 0xFFE4DC84],
    ),
    12: _GroundSurface('Wood Planks', [0xFF3A2414, 0xFF5C3A1F, 0xFF7E5230, 0xFFA06E40, 0xFFC48E58]),
    13: _GroundSurface('Water/Waves', [0xFF0E3A6B, 0xFF18589A, 0xFF2B7DC2, 0xFF5CA6E0, 0xFFC4EAFF]),
    14: _GroundSurface('Snow', [0xFF8FA5C4, 0xFFB5C7E0, 0xFFD8E4F4, 0xFFEEF4FC, 0xFFFFFFFF]),
    15: _GroundSurface(
      'Marble',
      [0xFFA8A8AE, 0xFFC8C8CE, 0xFFE0E0E4, 0xFFF0F0F2, 0xFFFFFFFF],
      [0xFF3A3A44, 0xFF55555F, 0xFF77777F, 0xFF9A9AA2, 0xFFBBBBC2],
    ),
    16: _GroundSurface('Concrete', [0xFF5E5E5C, 0xFF777774, 0xFF8E8E8A, 0xFFA4A4A0, 0xFFBABAB5]),
    17: _GroundSurface('Mud', [0xFF1E140C, 0xFF35261A, 0xFF4D3A28, 0xFF6A503A, 0xFF8D7456]),
    18: _GroundSurface(
      'Autumn Leaves',
      [0xFF7A2E0A, 0xFFB04A12, 0xFFD8741E, 0xFFEDA03A, 0xFFF7C860],
      [0xFF4E0E0A, 0xFF7E1A12, 0xFFA8281A, 0xFFCC4426, 0xFFE8683C],
    ),
    19: _GroundSurface('Metal Grate', [0xFF121416, 0xFF2A2F34, 0xFF4A5159, 0xFF6E7781, 0xFF9AA4AE]),
    20: _GroundSurface('Hex Tiles', [0xFF2E3A4A, 0xFF46576B, 0xFF5F7590, 0xFF7C94B0, 0xFF9DB5CF]),
  };

  @override
  Map<String, dynamic> getDefaultParameters() => Map.of(_defaults);

  @override
  Map<String, dynamic> getMetadata() => {
        'textureType': {
          'label': 'Texture Type',
          'description': 'Selects the ground surface.',
          'type': 'select',
          'options': {for (final e in _surfaces.entries) e.key: e.value.name},
        },
        'scale': {
          'label': 'Scale',
          'description': 'Size of the surface pattern.',
          'type': 'slider',
          'min': 2.0,
          'max': 64.0,
          'divisions': 62,
        },
        'blend': {
          'label': 'Blend Intensity',
          'description': 'How much the surface replaces the original image.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 100,
        },
        'blendMode': {
          'label': 'Blend Mode',
          'description': 'How the surface combines with the original.',
          'type': 'select',
          'options': {
            0: 'Normal',
            1: 'Multiply',
            2: 'Overlay',
            3: 'Soft Light',
            4: 'Hard Light',
            5: 'Color Burn',
            6: 'Screen',
          },
        },
        'offsetX': {
          'label': 'Offset X',
          'description': 'Horizontal offset of the pattern.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 100,
        },
        'offsetY': {
          'label': 'Offset Y',
          'description': 'Vertical offset of the pattern.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 100,
        },
        'rotation': {
          'label': 'Rotation',
          'description': 'Rotates the pattern.',
          'type': 'select',
          'options': {0: '0°', 1: '45°', 2: '90°', 3: '135°', 4: '180°'},
        },
        'noiseAmount': {
          'label': 'Noise/Variation',
          'description': 'Per-pixel grain that breaks up repetition.',
          'type': 'slider',
          'min': 0.0,
          'max': 0.5,
          'divisions': 50,
        },
        'depthIntensity': {
          'label': 'Depth/Relief',
          'description': 'Strength of the lit relief.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 100,
        },
        'edgeWear': {
          'label': 'Smart Edge Wear',
          'description': 'Lit lip and grime along the artwork silhouette.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 100,
        },
        'keepArtwork': {
          'label': 'Artwork Influence',
          'description': 'Lets the original shading and outlines show through the surface.',
          'type': 'slider',
          'min': 0.0,
          'max': 1.0,
          'divisions': 100,
        },
        'lightDirection': {
          'label': 'Light Direction',
          'type': 'slider',
          'min': 0.0,
          'max': 360.0,
          'divisions': 100,
        },
        'colorTint': {
          'label': 'Color Tint',
          'description': 'Apply a color tint to the surface.',
          'type': 'select',
          'options': {0: 'None', 1: 'Warm', 2: 'Cool', 3: 'Sepia', 4: 'Green', 5: 'Blue'},
        },
        'seed': {
          'label': 'Pattern Seed',
          'type': 'slider',
          'min': 0,
          'max': 9999,
          'divisions': 9999,
        },
      };

  double _number(String key, double min, double max) {
    final value = (parameters[key] as num?)?.toDouble();
    return (value != null && value.isFinite ? value : (_defaults[key] as num).toDouble()).clamp(min, max);
  }

  int _int(String key, int min, int max) => _number(key, min.toDouble(), max.toDouble()).round();

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    final result = Uint32List.fromList(pixels);
    if (width <= 0 || height <= 0 || pixels.length < width * height) return result;
    final type = _int('textureType', 0, 1 << 20);
    final surface = _surfaces[type];
    if (surface == null) return result;

    final scale = _number('scale', 1, 256);
    final blend = _number('blend', 0, 1);
    final blendMode = _int('blendMode', 0, 6);
    final rotation = _int('rotation', 0, 7);
    final noiseAmount = _number('noiseAmount', 0, 1);
    final depth = _number('depthIntensity', 0, 1);
    final edgeWear = _number('edgeWear', 0, 1);
    final keepArtwork = _number('keepArtwork', 0, 1);
    final tint = _int('colorTint', 0, 5);
    final seed = _int('seed', 0, 9999);
    final angle = _number('lightDirection', 0, 360) * pi / 180;
    final lx = cos(angle), ly = sin(angle);
    if (blend == 0) return result;

    final count = width * height;
    final inside = Uint8List(count);
    for (var i = 0; i < count; i++) {
      inside[i] = (pixels[i] >>> 24) != 0 ? 1 : 0;
    }
    final shape = _silhouetteShape(inside, width, height, edgeWear > 0 ? 2.0 : 0.0, 0.0);

    // Pass 1: surface fields in texel space (one tile is 8 texels across `scale` px).
    final unit = scale / 8;
    final rot = rotation * pi / 4;
    final cosR = cos(rot), sinR = sin(rot);
    final cx = width / 2, cy = height / 2;
    final ox = (_number('offsetX', 0, 1) * 8), oy = (_number('offsetY', 0, 1) * 8);
    final toneMap = Float32List(count), heightMap = Float32List(count), mixMap = Float32List(count);
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final i = y * width + x;
        if (inside[i] == 0) continue;
        final dx = x + 0.5 - cx, dy = y + 0.5 - cy;
        final rx = cx + dx * cosR - dy * sinR, ry = cy + dx * sinR + dy * cosR;
        final s = _sample(type, rx / unit + ox, ry / unit + oy, seed);
        toneMap[i] = s.$1.clamp(0.0, 1.0);
        heightMap[i] = s.$2.clamp(0.0, 1.0);
        mixMap[i] = s.$3.clamp(0.0, 1.0);
      }
    }

    double heightAt(int x, int y, double fallback) {
      if (x < 0 || y < 0 || x >= width || y >= height) return fallback;
      final j = y * width + x;
      return inside[j] == 1 ? heightMap[j] : fallback;
    }

    double lumAt(int x, int y, double fallback) {
      if (x < 0 || y < 0 || x >= width || y >= height) return fallback;
      final p = pixels[y * width + x];
      return (p >>> 24) == 0 ? fallback : _textureLuminance(p);
    }

    // Pass 2: colour, lighting, and blend with the original.
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final i = y * width + x;
        if (inside[i] == 0) continue;
        final orig = pixels[i];
        final h = heightMap[i];
        final lum = _textureLuminance(orig);

        var tex = _ramp(surface.a, toneMap[i]);
        final b = surface.b;
        if (b != null && mixMap[i] > 0) tex = _textureBlendColor(tex, _ramp(b, toneMap[i]), mixMap[i], 255);
        if (noiseAmount > 0) {
          final off = ((_textureHash(x, y, seed + 977) - 0.5) * 2 * noiseAmount * 50).round();
          tex = 0xFF000000 |
              ((_textureChannel(tex, 16) + off).clamp(0, 255) << 16) |
              ((_textureChannel(tex, 8) + off).clamp(0, 255) << 8) |
              (_textureChannel(tex, 0) + off).clamp(0, 255);
        }
        if (tint > 0) tex = _tint(tex, tint);

        // Lighting: height-gradient relief, edge lip/grime, artwork shading.
        final relief = -((heightAt(x + 1, y, h) - heightAt(x - 1, y, h)) * lx +
                (heightAt(x, y + 1, h) - heightAt(x, y - 1, h)) * ly) *
            depth;
        var shade = 1.0 + relief.clamp(-0.5, 0.5) * 0.9 + (h - 0.5) * depth * 0.3;
        if (edgeWear > 0) {
          final u = shape.rim[i];
          final facing = shape.normalX[i] * lx + shape.normalY[i] * ly;
          shade += edgeWear * u * (facing * 0.4 - 0.12);
          tex = _textureBlendColor(tex, surface.a.first, edgeWear * u * u * 0.4, 255);
        }
        if (keepArtwork > 0) {
          final gx = (lumAt(x + 1, y, lum) - lumAt(x - 1, y, lum)) * 0.5;
          final gy = (lumAt(x, y + 1, lum) - lumAt(x, y - 1, lum)) * 0.5;
          shade += keepArtwork * ((lum - 0.5) * 0.7 - (gx * lx + gy * ly) * 1.2);
          shade -= keepArtwork * min(1.0, sqrt(gx * gx + gy * gy) * 2) * 0.25;
        }
        shade = shade.clamp(0.2, 1.8);

        int channel(int shift) {
          final o = _textureChannel(orig, shift), t = _textureChannel(tex, shift);
          final mixed = _blendChannel(blendMode, o, t);
          return (o * (1 - blend) + (mixed * shade) * blend).round().clamp(0, 255);
        }

        result[i] = (orig & 0xFF000000) | (channel(16) << 16) | (channel(8) << 8) | channel(0);
      }
    }
    return result;
  }

  static int _ramp(List<int> stops, double t) {
    final p = t.clamp(0.0, 1.0) * (stops.length - 1);
    final k = min(p.floor(), stops.length - 2);
    return _textureBlendColor(stops[k], stops[k + 1], p - k, 255);
  }

  static int _blendChannel(int mode, int base, int tex) {
    switch (mode) {
      case 1:
        return (base * tex / 255).round();
      case 2:
        return base < 128
            ? (2 * base * tex / 255).round().clamp(0, 255)
            : (255 - 2 * (255 - base) * (255 - tex) / 255).round().clamp(0, 255);
      case 3:
        if (tex < 128) return (base - (255 - 2 * tex) * base * (255 - base) / 255 / 255).round().clamp(0, 255);
        final d = base < 64 ? ((16 * base - 12) * base + 4) * base / 255 : sqrt(base / 255) * 255;
        return (base + (2 * tex - 255) * (d - base) / 255).round().clamp(0, 255);
      case 4:
        return _blendChannel(2, tex, base);
      case 5:
        return tex == 0 ? 0 : max(0, 255 - ((255 - base) * 255 / tex).round());
      case 6:
        return 255 - ((255 - base) * (255 - tex) / 255).round();
      default:
        return tex;
    }
  }

  static int _tint(int c, int type) {
    final r = _textureChannel(c, 16), g = _textureChannel(c, 8), b = _textureChannel(c, 0);
    final (nr, ng, nb) = switch (type) {
      1 => (r + 15, g + 5, b - 10),
      2 => (r - 10, g + 5, b + 15),
      3 => ((r * 0.393 + g * 0.769 + b * 0.189).round(), (r * 0.349 + g * 0.686 + b * 0.168).round(), (r * 0.272 + g * 0.534 + b * 0.131).round()),
      4 => (r - 15, g + 20, b - 10),
      5 => (r - 15, g - 5, b + 25),
      _ => (r, g, b),
    };
    return 0xFF000000 | (nr.clamp(0, 255) << 16) | (ng.clamp(0, 255) << 8) | nb.clamp(0, 255);
  }

  /// Surface generator: (tone, height, secondary-palette mix), all in 0..1.
  /// Coordinates are texels; features are sized in texels so `scale` stretches them.
  static (double, double, double) _sample(int type, double x, double y, int seed) {
    double n(double a, double b, int k) => _textureNoise(a, b, seed + k);
    double f(double a, double b, int k) => _textureFbm(a, b, seed + k);
    double frac(double v) => v - v.floor();

    switch (type) {
      case 0: // Dirt & rocks
        final dirt = f(x * 0.45, y * 0.45, 1);
        final c = _textureCell(x / 2.6, y / 2.6, seed + 3, 0.85);
        final rock = c.id < 0.42 ? _textureStep(0.34, 0.26, c.f1) : 0.0;
        final dome = rock * (1 - c.f1 / 0.34).clamp(0.0, 1.0);
        final tone = _textureMix(0.12 + dirt * 0.38 + n(x * 3, y * 3, 2) * 0.1, 0.55 + c.id * 0.35 + dome * 0.15, rock);
        return (tone, rock * (0.55 + dome * 0.45) + dirt * 0.2, 0.0);
      case 1: // Mossy stone
        final c = _textureCell(x / 3.2, y / 3.2, seed + 11, 1.0);
        final joint = _textureStep(0.14, 0.04, c.f2 - c.f1);
        final bump = f(x * 0.7, y * 0.7, 12);
        final moss = _textureStep(0.5, 0.72, f(x * 0.35, y * 0.35, 13) + joint * 0.25);
        return (0.35 + c.id * 0.3 + bump * 0.25 - joint * 0.35, (1 - joint) * (0.6 + bump * 0.4), moss);
      case 2: // Sand ripples
        final warp = f(x * 0.2, y * 0.2, 21) * 3;
        final rip = 0.5 + 0.5 * sin(x * 0.35 + y * 0.25 + warp * 2);
        final grain = n(x * 4, y * 4, 22);
        return (0.35 + rip * 0.3 + grain * 0.2 + f(x * 0.3, y * 0.3, 23) * 0.15, rip * 0.5 + grain * 0.1, 0.0);
      case 3: // Pebble gravel
        final c = _textureCell(x / 1.7, y / 1.7, seed + 31, 0.9);
        final solid = _textureStep(0.04, 0.2, c.f2 - c.f1);
        return (_textureMix(0.03, 0.3 + c.id * 0.5 + solid * 0.15, solid), solid * (0.4 + solid * 0.6), 0.0);
      case 4: // Terracotta clay
        final base = f(x * 0.35, y * 0.35, 41);
        final c = _textureCell(x / 3.5, y / 3.5, seed + 42, 1.0);
        final crack = _textureStep(0.07, 0.0, c.f2 - c.f1) * _textureStep(0.3, 0.55, n(x * 0.4, y * 0.4, 43));
        return (0.35 + base * 0.45 + n(x * 3, y * 3, 44) * 0.08 - crack * 0.3, 0.5 + base * 0.3 - crack * 0.5, 0.0);
      case 5: // Red bricks with mortar
        final row = (y / 2).floor();
        final bx = x / 4 + (row.isOdd ? 0.5 : 0.0);
        final col = bx.floor();
        final fx = bx - col, fy = y / 2 - row;
        final id = _textureHash(col, row, seed + 51);
        if (fy < 0.18 || fx < 0.09) return (0.35 + n(x * 3, y * 3, 52) * 0.4, 0.0, 1.0);
        return (0.3 + id * 0.35 + n(x * 3, y * 3, 52) * 0.25 - (fy > 0.8 ? 0.1 : 0.0), 0.6 + id * 0.2, 0.0);
      case 6: // Stone blocks
        final row = (y / 3).floor();
        final bw = 3 + _textureHash(row, 0, seed + 61) * 3;
        final bx = (x + _textureHash(row, 1, seed + 61) * bw) / bw;
        final col = bx.floor();
        final fx = bx - col, fy = y / 3 - row;
        final id = _textureHash(col, row, seed + 62);
        final chip = n(x * 1.5, y * 1.5, 63) > 0.8 ? 0.12 : 0.0;
        if (fy < 0.12 || fx < 0.06 * 4 / bw) return (0.3 + n(x * 2, y * 2, 64) * 0.4, 0.0, 1.0);
        return (0.3 + id * 0.4 + f(x * 0.6, y * 0.6, 65) * 0.3 - chip, 0.6 + id * 0.2 - chip, 0.0);
      case 7: // Cracked ice
        final c = _textureCell(x / 3.5, y / 3.5, seed + 71, 1.0);
        final c2 = _textureCell(x / 1.6, y / 1.6, seed + 73, 1.0);
        final crack = max(_textureStep(0.09, 0.02, c.f2 - c.f1), _textureStep(0.06, 0.01, c2.f2 - c2.f1) * 0.4);
        final tone = 0.55 + c.id * 0.25 + f(x * 0.3, y * 0.3, 72) * 0.2;
        return (_textureMix(tone, 0.98, crack * 0.8), 0.5 - crack * 0.3 + c.id * 0.1, 0.0);
      case 8: // Dark cobblestone
        final c = _textureCell(x / 2.4, y / 2.4, seed + 81, 0.8);
        final solid = _textureStep(0.03, 0.22, c.f2 - c.f1);
        return (_textureMix(0.02, 0.25 + c.id * 0.45 + solid * 0.2, solid), solid * (0.4 + solid * 0.6), 0.0);
      case 9: // Sandy gravel
        final sand = 0.4 + n(x * 4, y * 4, 92) * 0.25 + f(x * 0.3, y * 0.3, 93) * 0.25;
        final c = _textureCell(x / 1.4, y / 1.4, seed + 91, 0.9);
        final peb = c.id < 0.28 ? _textureStep(0.38, 0.28, c.f1) : 0.0;
        return (_textureMix(sand, 0.25 + c.id * 1.5, peb), peb * 0.7 + sand * 0.15, peb);
      case 10: // Volcanic rock with lava seams
        final ridge = 1 - (2 * f(x * 0.3, y * 0.3, 101) - 1).abs();
        final crack = _textureStep(0.88, 0.97, ridge);
        final rock = 0.15 + f(x * 0.8, y * 0.8, 102) * 0.5;
        return (_textureMix(rock, 0.5 + crack * 0.5, crack), (1 - crack * 0.8) * (0.5 + rock * 0.5), crack);
      case 11: // Grass
        final blade = n(x * 2.2, y * 0.45, 111), blade2 = n(x * 4 + 3, y * 0.9, 112);
        final tone = 0.25 + blade * 0.4 + blade2 * 0.3 + (_textureHash(x.floor(), y.floor(), seed + 114) - 0.5) * 0.12;
        return (tone, tone, _textureStep(0.55, 0.8, f(x * 0.2, y * 0.2, 113)) * 0.8);
      case 12: // Wood planks
        final row = (y / 3).floor();
        final off = _textureHash(row, 0, seed + 121) * 8;
        final px = (x + off) / 8;
        final col = px.floor();
        final seamY = y / 3 - row < 0.1, seamX = px - col < 0.04;
        final grain = n(x * 0.35, y * 2.2 + row * 3.7, 122);
        final id = _textureHash(col, row, seed + 123);
        if (seamY || seamX) return (0.02, 0.0, 0.0);
        return (0.3 + grain * 0.45 + id * 0.2, 0.6 + grain * 0.1, 0.0);
      case 13: // Water
        final wave = 0.5 + 0.5 * sin((x + f(x * 0.3, y * 0.3, 131) * 3) * 0.6 + y * 0.35);
        final c = _textureCell(x / 2.6, y / 2.6, seed + 132, 1.0);
        final caustic = _textureStep(0.18, 0.02, c.f2 - c.f1);
        return (0.3 + wave * 0.3 + caustic * 0.35 + f(x * 0.5, y * 0.5, 133) * 0.1, wave, 0.0);
      case 14: // Snow
        final base = f(x * 0.3, y * 0.3, 141);
        final sparkle = _textureHash(x.floor(), y.floor(), seed + 142) > 0.97;
        return (sparkle ? 1.0 : 0.65 + base * 0.3, base * 0.5 + 0.25, 0.0);
      case 15: // Marble slabs
        final warp = f(x * 0.2, y * 0.2, 151) * 4;
        final v = sin((x * 0.28 + y * 0.18 + warp) * pi).abs();
        final vein = max(_textureStep(0.12, 0.0, v), _textureStep(0.06, 0.0, sin((x * 0.6 - y * 0.4 + warp * 2) * pi).abs()) * 0.5);
        final joint = frac(x / 8) < 0.03 || frac(y / 8) < 0.03;
        if (joint) return (0.2, 0.0, 1.0);
        return (0.72 + f(x * 0.4, y * 0.4, 152) * 0.25 - vein * 0.4, 0.55, vein * 0.85);
      case 16: // Concrete
        final pore = _textureHash(x.floor(), y.floor(), seed + 163) > 0.965 ? 0.3 : 0.0;
        final joint = frac(x / 8) < 0.04 || frac(y / 8) < 0.04;
        final tone = 0.4 + n(x * 3, y * 3, 161) * 0.15 + f(x * 0.3, y * 0.3, 162) * 0.4 - pore - (joint ? 0.3 : 0.0);
        return (tone, joint ? 0.0 : 0.55 - pore, 0.0);
      case 17: // Mud
        final r = f(x * 0.25, y * 0.25, 171);
        final puddle = _textureStep(0.62, 0.72, r);
        final shine = puddle > 0.5 && n(x * 2, y * 2, 173) > 0.8;
        return (shine ? 0.95 : 0.2 + r * 0.4 + puddle * 0.25 + n(x * 2, y * 2, 172) * 0.1, r * 0.4 + 0.3 - puddle * 0.2, 0.0);
      case 18: // Autumn leaves
        final c = _textureCell(x / 1.9, y / 1.9, seed + 181, 0.95);
        final leaf = _textureStep(0.5, 0.36, c.f1);
        final tone = 0.35 + c.id * 0.45 + (1 - c.f1) * 0.15;
        return (_textureMix(0.04, tone, leaf), leaf * (0.4 + c.id * 0.4), _textureStep(0.45, 0.55, c.id));
      case 19: // Metal grate
        final gx = frac(x / 2.5), gy = frac(y / 2.5);
        if (gx > 0.3 && gy > 0.3) return (0.03 + n(x, y, 191) * 0.05, 0.0, 0.0);
        final rivet = sqrt((gx - 0.15) * (gx - 0.15) + (gy - 0.15) * (gy - 0.15)) < 0.1;
        final edge = gx < 0.12 || gy < 0.12 ? 0.2 : 0.0;
        return (rivet ? 0.95 : 0.55 + n(x * 2, y * 2, 192) * 0.2 + edge, 0.8, 0.0);
      case 20: // Hex tiles
        final hx = _groundHex(x / 2.4, y / 2.4, seed + 201);
        final bevel = _textureStep(0.0, 0.22, hx.edge);
        if (hx.edge < 0.07) return (0.02, 0.0, 0.0);
        return (0.3 + hx.id * 0.3 + bevel * 0.25 + f(x * 0.4, y * 0.4, 202) * 0.15, bevel, 0.0);
    }
    return (0.5, 0.5, 0.0);
  }

  /// Flat-top hexagon grid: `edge` is 0 on the border and 1 at the center.
  static ({double edge, double id}) _groundHex(double x, double y, int seed) {
    final root3 = sqrt(3.0);
    final q = 2 / 3 * x, r = -1 / 3 * x + root3 / 3 * y;
    var rq = q.round(), rr = r.round(), rs = (-q - r).round();
    final dq = (rq - q).abs(), dr = (rr - r).abs(), ds = (rs - (-q - r)).abs();
    if (dq > dr && dq > ds) {
      rq = -rr - rs;
    } else if (dr > ds) {
      rr = -rq - rs;
    }
    final cx = 1.5 * rq, cy = root3 * (rr + rq / 2);
    final dx = (x - cx).abs(), dy = (y - cy).abs();
    final m = max(dy, dx * root3 / 2 + dy * 0.5) / (root3 / 2);
    return (edge: (1 - m).clamp(0.0, 1.0), id: _textureHash(rq, rr, seed));
  }
}

class _GroundSurface {
  const _GroundSurface(this.name, this.a, [this.b]);

  final String name;
  final List<int> a;
  final List<int>? b;
}
