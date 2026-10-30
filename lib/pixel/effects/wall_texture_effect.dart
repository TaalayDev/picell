part of 'effects.dart';

/// Procedural masonry and wall surfaces applied inside the artwork silhouette.
///
/// Walls are generated per pixel from joint/bevel/tone fields (so relief is lit
/// from a real height map) and are shape-aware:
///  * courses start at the artwork's top-left corner (`snapToArtwork`), so a
///    wall piece begins with a whole block instead of a random slice;
///  * silhouette edges get a lit lip, grime, and crumbling (`edgeWear`,
///    `weathering`);
///  * the original shading and outlines can show through (`keepArtwork`).
class WallTextureEffect extends Effect {
  WallTextureEffect([Map<String, dynamic>? parameters]) : super(EffectType.wallTexture, {..._defaults, ...?parameters});

  static const _defaults = <String, dynamic>{
    'wallType': 0,
    'textureScale': 0.5,
    'colorVariation': 0.6,
    'roughness': 0.7,
    'baseColor': 0xFF888888,
    'accentColor': 0xFFAAAAAA,
    'shadowColor': 0xFF555555,
    'mortarColor': 0xFF666666,
    'weathering': 0.3,
    'lighting': 0.5,
    'lightAngle': 0.25,
    'randomSeed': 42,
    'blendAmount': 0.7,
    'edgeWear': 0.5,
    'keepArtwork': 0.25,
    'snapToArtwork': true,
  };

  static const _wallNames = <int, String>{
    0: 'Stone Wall',
    1: 'Brick Wall',
    2: 'Concrete Wall',
    3: 'Cobblestone',
    4: 'Marble Wall',
    5: 'Granite Wall',
    6: 'Sandstone Wall',
    7: 'Modern Brick',
    8: 'Castle Stone',
  };

  /// Built-in palettes (shadow, base, accent, mortar). A colour control left at
  /// its default takes the wall type's own colour; changing it overrides it.
  static const _palettes = <int, (int, int, int, int)>{
    0: (0xFF4A4C4E, 0xFF84878A, 0xFFB0B3B5, 0xFF5A5650),
    1: (0xFF6E2A1E, 0xFF9C4632, 0xFFC2644A, 0xFF9A9486),
    2: (0xFF6A6B6A, 0xFF8E8F8D, 0xFFB4B5B2, 0xFF4C4D4C),
    3: (0xFF3A3D42, 0xFF666A70, 0xFF93989F, 0xFF25272A),
    4: (0xFFB4B4BC, 0xFFDCDCE2, 0xFFFFFFFF, 0xFF5A5A66),
    5: (0xFF55575A, 0xFF8D8F92, 0xFFC8C4BE, 0xFF3A3A3C),
    6: (0xFF9B7A4A, 0xFFC9A468, 0xFFE6CC94, 0xFF7C6238),
    7: (0xFF5B3A32, 0xFF7F5547, 0xFFA6735F, 0xFF3C3A38),
    8: (0xFF3E4046, 0xFF6C7078, 0xFF9AA0A8, 0xFF2A2C30),
  };

  @override
  Map<String, dynamic> getDefaultParameters() => Map.of(_defaults);

  @override
  Map<String, dynamic> getMetadata() => {
        'wallType': {
          'label': 'Wall Type',
          'description': 'Type of wall to generate.',
          'type': 'select',
          'options': _wallNames,
        },
        for (final spec in [
          ('textureScale', 'Texture Scale', 'Size of blocks and surface details.', 0.0, 1.0, 100),
          ('colorVariation', 'Color Variation', 'Tone differences between blocks and across the wall.', 0.0, 1.0, 100),
          ('roughness', 'Surface Roughness', 'Grain and bumpiness of the surface.', 0.0, 1.0, 100),
          ('weathering', 'Weathering', 'Rain stains, cracks, and crumbling edges.', 0.0, 1.0, 100),
          ('lighting', 'Lighting Intensity', 'Strength of the lit relief.', 0.0, 1.0, 100),
          ('lightAngle', 'Light Direction', 'Light from the left (0), top (0.5), or right (1).', 0.0, 1.0, 100),
          ('edgeWear', 'Smart Edge Wear', 'Lit lip and grime along the artwork silhouette.', 0.0, 1.0, 100),
          ('keepArtwork', 'Artwork Influence', 'Lets the original shading and outlines show through.', 0.0, 1.0, 100),
          ('randomSeed', 'Texture Seed', 'Changes the random pattern.', 1, 100, 99),
          ('blendAmount', 'Blend Amount', 'How much the wall replaces the original layer.', 0.0, 1.0, 100),
        ])
          spec.$1: {
            'label': spec.$2,
            'description': spec.$3,
            'type': 'slider',
            'min': spec.$4,
            'max': spec.$5,
            'divisions': spec.$6,
          },
        'baseColor': {'label': 'Base Color', 'description': 'Primary color of the wall.', 'type': 'color'},
        'accentColor': {'label': 'Accent Color', 'description': 'Highlights and lighter blocks.', 'type': 'color'},
        'shadowColor': {'label': 'Shadow Color', 'description': 'Darker blocks and depth.', 'type': 'color'},
        'mortarColor': {'label': 'Mortar Color', 'description': 'Joints, seams, and veins.', 'type': 'color'},
        'snapToArtwork': {
          'label': 'Snap to Artwork',
          'description': 'Start courses at the artwork corner so edges begin with whole blocks.',
          'type': 'toggle',
        },
      };

  double _number(String key, double min, double max) {
    final value = (parameters[key] as num?)?.toDouble();
    return (value != null && value.isFinite ? value : (_defaults[key] as num).toDouble()).clamp(min, max);
  }

  int _color(String key, int builtIn) {
    final value = parameters[key];
    final v = value is num ? value.toInt() : (_defaults[key] as int);
    return v == (_defaults[key] as int) ? builtIn : v;
  }

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    final result = Uint32List.fromList(pixels);
    if (width <= 0 || height <= 0 || pixels.length < width * height) return result;
    final blendAmount = _number('blendAmount', 0, 1);
    if (blendAmount == 0) return result;

    final rawType = (parameters['wallType'] as num?)?.round() ?? 0;
    final type = _wallNames.containsKey(rawType) ? rawType : 0;
    final scale = _number('textureScale', 0, 1);
    final colorVar = _number('colorVariation', 0, 1);
    final roughness = _number('roughness', 0, 1);
    final weathering = _number('weathering', 0, 1);
    final lighting = _number('lighting', 0, 1);
    final edgeWear = _number('edgeWear', 0, 1);
    final keepArtwork = _number('keepArtwork', 0, 1);
    final seed = _number('randomSeed', 0, 9999).round();
    final angle = (180 + _number('lightAngle', 0, 1) * 180) * pi / 180;
    final lx = cos(angle), ly = sin(angle);
    final pal = _palettes[type]!;
    final shadowC = _color('shadowColor', pal.$1);
    final baseC = _color('baseColor', pal.$2);
    final accentC = _color('accentColor', pal.$3);
    final mortarC = _color('mortarColor', pal.$4);
    int ramp(double t) => t < 0.5
        ? _textureBlendColor(shadowC, baseC, t * 2, 255)
        : _textureBlendColor(baseC, accentC, (t - 0.5) * 2, 255);

    final count = width * height;
    final inside = Uint8List(count);
    var minX = width, minY = height;
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        if ((pixels[y * width + x] >>> 24) == 0) continue;
        inside[y * width + x] = 1;
        if (x < minX) minX = x;
        if (y < minY) minY = y;
      }
    }
    if (minX == width) return result;
    final originX = parameters['snapToArtwork'] == false ? 0 : minX;
    final originY = parameters['snapToArtwork'] == false ? 0 : minY;
    final shape = _silhouetteShape(inside, width, height, edgeWear > 0 || weathering > 0 ? 2.0 : 0.0, 0.0);

    // Pass 1: wall fields (tone, height, mortar mix) with weathering baked in.
    final u = 1.5 + scale * 5;
    final toneMap = Float32List(count), heightMap = Float32List(count), mixMap = Float32List(count);
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final i = y * width + x;
        if (inside[i] == 0) continue;
        final px = (x - originX) + 0.5, py = (y - originY) + 0.5;
        var (tone, h, mix) = _sample(type, px, py, u, seed);
        tone = 0.5 + (tone - 0.5) * (0.35 + 0.9 * colorVar);
        if (colorVar > 0) tone += (_textureFbm(px / (u * 6), py / (u * 6), seed + 21) - 0.5) * colorVar * 0.3;

        if (weathering > 0) {
          final stain = _textureStep(0.55, 0.8, _textureNoise(px / (u * 1.3), py / (u * 8), seed + 31)) * weathering;
          tone -= stain * 0.35;
          if (weathering > 0.3) {
            final v = (_textureFbm(px / (u * 3), py / (u * 3), seed + 41) - 0.5).abs();
            final crack = _textureStep(0.012 + 0.012 * weathering, 0.0, v) * _textureStep(0.3, 0.6, weathering);
            tone -= crack * 0.5;
            h -= crack * 0.6;
          }
        }
        toneMap[i] = tone.clamp(0.0, 1.0);
        heightMap[i] = h.clamp(0.0, 1.0);
        mixMap[i] = mix.clamp(0.0, 1.0);
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

    // Pass 2: colour, lighting, blend.
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final i = y * width + x;
        if (inside[i] == 0) continue;
        final orig = pixels[i];
        final h = heightMap[i];
        final lum = _textureLuminance(orig);

        var wall = ramp(toneMap[i]);
        if (mixMap[i] > 0) {
          final mortar = _textureBlendColor(mortarC, 0xFF000000, (0.55 - toneMap[i]).clamp(0.0, 1.0) * 0.5, 255);
          wall = _textureBlendColor(wall, mortar, mixMap[i], 255);
        }

        final relief = -((heightAt(x + 1, y, h) - heightAt(x - 1, y, h)) * lx +
                (heightAt(x, y + 1, h) - heightAt(x, y - 1, h)) * ly) *
            lighting *
            (0.6 + roughness * 0.8);
        var shade = 1.0 + relief.clamp(-0.5, 0.5) * 0.9 + (h - 0.5) * lighting * 0.25;
        shade += (_textureHash(x, y, seed + 977) - 0.5) * roughness * 0.2;

        final rim = shape.rim[i];
        if (rim > 0) {
          final facing = shape.normalX[i] * lx + shape.normalY[i] * ly;
          shade += edgeWear * rim * (facing * 0.4 - 0.12);
          wall = _textureBlendColor(wall, shadowC, edgeWear * rim * rim * 0.35, 255);
          if (weathering > 0) {
            final crumble = _textureStep(0.5, 0.75, _textureNoise(x * 0.9, y * 0.9, seed + 777)) * rim * weathering;
            wall = _textureBlendColor(wall, shadowC, crumble * 0.7, 255);
            shade -= crumble * 0.2;
          }
        }
        if (keepArtwork > 0) {
          final gx = (lumAt(x + 1, y, lum) - lumAt(x - 1, y, lum)) * 0.5;
          final gy = (lumAt(x, y + 1, lum) - lumAt(x, y - 1, lum)) * 0.5;
          shade += keepArtwork * ((lum - 0.5) * 0.7 - (gx * lx + gy * ly) * 1.2);
          shade -= keepArtwork * min(1.0, sqrt(gx * gx + gy * gy) * 2) * 0.25;
        }
        shade = shade.clamp(0.2, 1.8);

        int channel(int shift) {
          final o = _textureChannel(orig, shift);
          final t = (_textureChannel(wall, shift) * shade).clamp(0.0, 255.0);
          return (o + (t - o) * blendAmount).round().clamp(0, 255);
        }

        result[i] = (orig & 0xFF000000) | (channel(16) << 16) | (channel(8) << 8) | channel(0);
      }
    }
    return result;
  }

  /// Wall generator: (tone, height, mortar mix), each 0..1. `u` is the base
  /// feature size in pixels.
  static (double, double, double) _sample(int type, double x, double y, double u, int seed) {
    double n(double a, double b, int k) => _textureNoise(a, b, seed + k);
    double f(double a, double b, int k) => _textureFbm(a, b, seed + k);
    double frac(double v) => v - v.floor();
    double bevel(double edge, double width) => _textureStep(0.0, max(width, 1.0), edge);
    int joint(double v) => max(1, (v).round());

    switch (type) {
      case 0: // Stone wall: irregular ashlar
        final wx = x + (n(x / u, y / u, 1) - 0.5) * 1.6, wy = y + (n(x / u + 9, y / u + 4, 2) - 0.5) * 1.6;
        final c = _courses(wx, wy, 3 * u, 4 * u, 8 * u, joint(u * 0.3).toDouble(), seed + 3);
        if (c.joint) return (0.3 + n(x, y, 4) * 0.3, 0.0, 1.0);
        final chip = n(x / u * 1.5, y / u * 1.5, 5) > 0.82 ? 0.15 : 0.0;
        final b = bevel(c.edge, u * 0.5);
        return (0.3 + c.id * 0.45 + f(x / u * 0.5, y / u * 0.5, 6) * 0.25 - chip, b * (0.7 + n(x / u, y / u, 7) * 0.3), 0.0);
      case 1: // Brick wall: running bond
        final c = _courses(x, y, 1.5 * u, 3 * u, 3 * u, joint(u * 0.22).toDouble(), seed + 11);
        if (c.joint) return (0.35 + n(x, y, 12) * 0.3, 0.0, 1.0);
        final pit = n(x * 0.9, y * 0.9, 13) > 0.85 ? 0.12 : 0.0;
        return (0.3 + c.id * 0.4 + n(x * 0.7, y * 0.7, 14) * 0.2 - pit, bevel(c.edge, u * 0.3) * (0.8 + n(x, y, 15) * 0.2), 0.0);
      case 2: // Concrete: formed panels with tie holes
        final pw = 8 * u, ph = 6 * u;
        final lxp = x - (x / pw).floor() * pw, lyp = y - (y / ph).floor() * ph;
        if (lxp < 1 || lyp < 1) return (0.3, 0.0, 1.0);
        var tone = 0.45 + f(x / (u * 3), y / (u * 3), 21) * 0.35 + n(x * 0.8, y * 0.8, 22) * 0.1;
        if (frac(y / (1.5 * u)) < 0.08) tone -= 0.06;
        if (_textureHash(x.floor(), y.floor(), seed + 23) > 0.97) tone -= 0.25;
        var h = 0.55;
        for (final hx in [0.25, 0.75]) {
          final d = sqrt(pow(lxp - hx * pw, 2) + pow(lyp - 0.5 * ph, 2));
          if (d < 0.35 * u) return (0.08, 0.0, 0.0);
          if (d < 0.6 * u) {
            h = 0.9;
            tone += 0.08;
          }
        }
        return (tone, h, 0.0);
      case 3: // Cobblestone
        final c = _textureCell(x / (2.4 * u), y / (2.4 * u), seed + 31, 0.85);
        final solid = _textureStep(0.03, 0.2, c.f2 - c.f1);
        return (_textureMix(0.1, 0.3 + c.id * 0.5 + f(x / u, y / u, 32) * 0.15, solid), solid * (0.4 + solid * 0.6), 1 - solid);
      case 4: // Marble slabs with veins
        final pw = 7 * u;
        final col = (x / pw).floor(), row = (y / pw).floor();
        if (x - col * pw < 1 || y - row * pw < 1) return (0.3, 0.0, 1.0);
        final id = _textureHash(col, row, seed + 41);
        final a = id * 2 * pi;
        final warp = f(x / (u * 3), y / (u * 3), 42) * 4;
        final v = sin(((x * cos(a) + y * sin(a)) / (u * 2.2) + warp) * pi).abs();
        final vein = _textureStep(0.1, 0.0, v);
        return (0.6 + (id - 0.5) * 0.1 + f(x / (u * 1.5), y / (u * 1.5), 43) * 0.25 - vein * 0.3, 0.55, vein * 0.85);
      case 5: // Granite: speckled, polished slabs
        final pw = 10 * u, ph = 6 * u;
        if (x - (x / pw).floor() * pw < 1 || y - (y / ph).floor() * ph < 1) return (0.3, 0.0, 0.7);
        var tone = 0.5 + (f(x / (u * 2), y / (u * 2), 51) - 0.5) * 0.4;
        final dark = n(x * 1.6, y * 1.6, 52) > 0.78, light = n(x * 1.6 + 30, y * 1.6, 53) > 0.8;
        if (dark) tone = 0.08 + n(x, y, 54) * 0.15;
        if (light) tone = 0.95;
        return (tone, 0.5 + n(x, y, 55) * 0.1, 0.0);
      case 6: // Sandstone: strata and blocks
        final c = _courses(x, y, 2.6 * u, 5 * u, 9 * u, joint(u * 0.3).toDouble(), seed + 61);
        if (c.joint) return (0.3 + n(x, y, 62) * 0.25, 0.0, 1.0);
        final warp = f(x / (u * 4), y / (u * 4), 63) * 3;
        final band = sin(y / (u * 0.7) + warp * 3) * 0.5 + 0.5;
        final pit = n(x * 0.8, y * 0.8, 64) > 0.85 ? 0.15 : 0.0;
        return (0.3 + c.id * 0.2 + band * 0.25 + f(x / u, y / u, 65) * 0.2 - pit, bevel(c.edge, u * 0.4) * 0.9, 0.0);
      case 7: // Modern brick: tidy stretcher bond
        final c = _courses(x, y, 1.2 * u, 3.4 * u, 3.4 * u, joint(u * 0.18).toDouble(), seed + 71);
        if (c.joint) return (0.35, 0.0, 1.0);
        return (0.45 + c.id * 0.25 + n(x, y, 72) * 0.1, bevel(c.edge, u * 0.25), 0.0);
      case 8: // Castle stone: large rough blocks
        final wx = x + (n(x / u * 0.6, y / u * 0.6, 81) - 0.5) * 2.5, wy = y + (n(x / u * 0.6 + 5, y / u * 0.6, 82) - 0.5) * 2.5;
        final c = _courses(wx, wy, 4 * u, 5 * u, 11 * u, joint(u * 0.45).toDouble(), seed + 83);
        if (c.joint) return (0.25 + n(x, y, 84) * 0.25, 0.0, 1.0);
        final chip = n(x / u * 1.2, y / u * 1.2, 85) > 0.78 ? 0.15 : 0.0;
        return (0.25 + c.id * 0.4 + f(x / u * 0.7, y / u * 0.7, 86) * 0.35 - chip, bevel(c.edge, u * 0.9) * (0.6 + f(x / u, y / u, 87) * 0.4), 0.0);
    }
    return (0.5, 0.5, 0.0);
  }

  /// Coursed masonry: rows of blocks, either fixed width in running bond
  /// (`minW == maxW`) or per-row random widths and offsets. `edge` is the
  /// distance inside the block from its joints.
  static ({bool joint, double id, double edge}) _courses(
      double x, double y, double rowH, double minW, double maxW, double jw, int seed) {
    final row = (y / rowH).floor();
    final fixed = maxW <= minW;
    final bw = fixed ? minW : minW + _textureHash(row, 3, seed) * (maxW - minW);
    final off = fixed ? (row.isOdd ? bw / 2 : 0.0) : _textureHash(row, 5, seed) * bw;
    final bx = (x + off) / bw;
    final col = bx.floor();
    final lx = (bx - col) * bw, ly = y - row * rowH;
    return (
      joint: lx < jw || ly < jw,
      id: _textureHash(col, row, seed + 9),
      edge: min(min(lx - jw, bw - lx), min(ly - jw, rowH - ly)),
    );
  }
}
