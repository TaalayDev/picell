part of 'effects.dart';

/// Smart silhouette- and artwork-aware natural wood grain effect.
///
/// Simulates organic growth rings with asymmetric latewood transitions, realistic
/// knot distortion where grain bends smoothly around branch inclusions, medullary
/// rays, fine cellular vessel pores, 3D silhouette edge bevels, and bas-relief
/// detail carving from source artwork.
class WoodEffect extends Effect {
  WoodEffect([Map<String, dynamic>? params])
      : super(EffectType.wood, {..._defaults, ...?params});

  static const woodTypeOptions = <int, String>{
    0: 'Oak',
    1: 'Pine',
    2: 'Walnut',
    3: 'Cherry',
    4: 'Mahogany',
    5: 'Birch / Maple',
    6: 'Charred Ebony',
  };

  static const _defaults = <String, dynamic>{
    'woodType': 0,
    'grainDirection': 90.0,
    'grainIntensity': 0.7,
    'ringSpacing': 8.0,
    'knotCount': 1,
    'knotSize': 10.0,
    'colorVariation': 0.4,
    'roughness': 0.35,
    'bevelWidth': 2.5,
    'detailCarving': 0.35,
    'varnish': 0.5,
    'weathering': 0.2,
    'lightAngle': 225.0,
    'woodColor': 0xFFD4B07B,
    'darkColor': 0xFF784824,
    'seed': 42,
    'opacity': 1.0,
    'preserveAlpha': true,
  };

  @override
  Map<String, dynamic> getDefaultParameters() => Map.of(_defaults);

  @override
  Map<String, dynamic> getMetadata() => {
        'woodType': <String, dynamic>{
          'label': 'Wood Species',
          'description': 'Wood species grain structure and botanical color palette.',
          'type': 'select',
          'options': woodTypeOptions,
        },
        for (final spec in [
          ('grainDirection', 'Grain Direction', 0.0, 360.0),
          ('grainIntensity', 'Grain Contrast', 0.0, 1.0),
          ('ringSpacing', 'Growth Ring Width', 2.0, 32.0),
          ('knotCount', 'Knots', 0, 8),
          ('knotSize', 'Knot Size', 4.0, 24.0),
          ('colorVariation', 'Tone Variation', 0.0, 1.0),
          ('roughness', 'Fiber & Pore Texture', 0.0, 1.0),
          ('bevelWidth', 'Smart Edge Bevel', 0.0, 8.0),
          ('detailCarving', 'Smart Detail Carving', 0.0, 1.0),
          ('varnish', 'Varnish & Sheen', 0.0, 1.0),
          ('weathering', 'Weathering & Aging', 0.0, 1.0),
          ('lightAngle', 'Light Direction', 0.0, 360.0),
          ('seed', 'Grain Seed', 0, 9999),
          ('opacity', 'Opacity', 0.0, 1.0),
        ])
          spec.$1: <String, dynamic>{
            'label': spec.$2,
            'type': 'slider',
            'min': spec.$3,
            'max': spec.$4,
            'divisions': spec.$3 is int ? (spec.$4 - spec.$3).toInt() : 100,
          },
        'woodColor': <String, dynamic>{
          'label': 'Base Wood Color',
          'type': 'color',
        },
        'darkColor': <String, dynamic>{
          'label': 'Latewood & Knot Color',
          'type': 'color',
        },
        'preserveAlpha': <String, dynamic>{
          'label': 'Preserve Alpha',
          'type': 'bool',
          'description':
              'Carve within the sprite silhouette; disable to fill the canvas.',
        },
      };

  double _number(String key, double min, double max) {
    final value = (parameters[key] as num?)?.toDouble();
    return (value != null && value.isFinite
            ? value
            : (_defaults[key] as num).toDouble())
        .clamp(min, max);
  }

  int _color(String key) {
    final value = parameters[key];
    return value is num ? value.toInt() : (_defaults[key] as int);
  }

  int _resolveWoodType() {
    final raw = parameters['woodType'];
    if (raw is num && raw.isFinite) return raw.round().clamp(0, 6);
    return switch (raw?.toString().toLowerCase()) {
      'oak' => 0,
      'pine' => 1,
      'walnut' => 2,
      'cherry' => 3,
      'mahogany' => 4,
      'birch' || 'maple' => 5,
      'charred' || 'ebony' => 6,
      _ => 0,
    };
  }

  double _resolveGrainAngle() {
    final raw = (parameters['grainDirection'] as num?)?.toDouble();
    if (raw == null || !raw.isFinite) return math.pi * 0.5;
    // Support legacy [0.0, 1.0] fractional turn mapping:
    if (raw > 0.0 && raw <= 1.0) {
      return raw * 2.0 * math.pi;
    }
    return raw * math.pi / 180.0;
  }

  int _resolveSeed() {
    final raw = parameters['seed'] ?? parameters['randomSeed'];
    if (raw is num && raw.isFinite) return raw.round().clamp(0, 9999);
    return 42;
  }

  static (int base, int dark, int light) _speciesPalette(int species) =>
      switch (species) {
        0 => (0xFFD4B07B, 0xFF784824, 0xFFEEDBB7), // Oak
        1 => (0xFFF4DFBA, 0xFFA86326, 0xFFFFFAEB), // Pine
        2 => (0xFF6F4B34, 0xFF382216, 0xFF977358), // Walnut
        3 => (0xFFBC5838, 0xFF6D2415, 0xFFE48F70), // Cherry
        4 => (0xFF8D3722, 0xFF49190F, 0xFFBD5838), // Mahogany
        5 => (0xFFEFE4D0, 0xFFB29878, 0xFFFFF9EE), // Birch / Maple
        6 => (0xFF2F3034, 0xFF141518, 0xFF585C64), // Charred Ebony
        _ => (0xFFD4B07B, 0xFF784824, 0xFFEEDBB7),
      };

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    final output = Uint32List.fromList(pixels);
    if (width <= 0 || height <= 0 || pixels.length < width * height) {
      return output;
    }
    final opacity = _number('opacity', 0, 1);
    if (opacity == 0) return output;

    final species = _resolveWoodType();
    final grainAngle = _resolveGrainAngle();
    final grainIntensity = _number('grainIntensity', 0, 1);
    final ringSpacing = _number('ringSpacing', 2, 32);
    final knotCount = _number('knotCount', 0, 8).round();
    final knotBaseSize = _number('knotSize', 4, 24);
    final variation = _number('colorVariation', 0, 1);
    final roughness = _number('roughness', 0, 1);
    final bevelWidth = _number('bevelWidth', 0, 8);
    final detailCarving = _number('detailCarving', 0, 1);
    final varnish = _number('varnish', 0, 1);
    final weathering = _number('weathering', 0, 1);
    final lightAngle = _number('lightAngle', 0, 360) * math.pi / 180.0;
    final lx = math.cos(lightAngle), ly = math.sin(lightAngle);
    final seed = _resolveSeed();
    final userWoodColor = _color('woodColor');
    final userDarkColor = _color('darkColor');
    final preserve = parameters['preserveAlpha'] != false;

    // Harmonize user color selections with the authentic botanical species tone.
    final (palBase, palDark, palLight) = _speciesPalette(species);
    final baseWood = _textureBlendColor(
      palBase,
      userWoodColor,
      userWoodColor == (_defaults['woodColor'] as int) ? 0.0 : 0.65,
      255,
    );
    final lateWood = _textureBlendColor(
      palDark,
      userDarkColor,
      userDarkColor == (_defaults['darkColor'] as int) ? 0.0 : 0.65,
      255,
    );
    final earlyWood = palLight;

    // Step 1: Smart 2-pass Chamfer distance transform for carved edge bevels.
    final distances = Uint8List(width * height);
    if (bevelWidth > 0 || weathering > 0) {
      for (var y = 0; y < height; y++) {
        for (var x = 0; x < width; x++) {
          final i = y * width + x;
          if (preserve && (pixels[i] >>> 24) == 0) continue;
          var d =
              x == 0 || y == 0 || x == width - 1 || y == height - 1 ? 1 : 10;
          if (x > 0) d = math.min(d, distances[i - 1] + 1);
          if (y > 0) {
            d = math.min(d, distances[i - width] + 1);
            if (x > 0) d = math.min(d, distances[i - width - 1] + 1);
            if (x + 1 < width) d = math.min(d, distances[i - width + 1] + 1);
          }
          distances[i] = d;
        }
      }
      for (var y = height - 1; y >= 0; y--) {
        for (var x = width - 1; x >= 0; x--) {
          final i = y * width + x;
          if (preserve && (pixels[i] >>> 24) == 0) continue;
          var d = distances[i];
          if (x + 1 < width) d = math.min(d, distances[i + 1] + 1);
          if (y + 1 < height) {
            d = math.min(d, distances[i + width] + 1);
            if (x > 0) d = math.min(d, distances[i + width - 1] + 1);
            if (x + 1 < width) d = math.min(d, distances[i + width + 1] + 1);
          }
          distances[i] = d;
        }
      }
    }
    double distanceAt(int x, int y) =>
        x < 0 || y < 0 || x >= width || y >= height
            ? 0.0
            : distances[y * width + x].toDouble();

    // Step 2: Seeded knots with organic deflection radii.
    final cosG = math.cos(grainAngle);
    final sinG = math.sin(grainAngle);
    final knots = List.generate(knotCount, (k) {
      final kx = (_textureHash(k * 7, 13, seed + 101) * 0.8 + 0.1) * width;
      final ky = (_textureHash(k * 11, 29, seed + 103) * 0.8 + 0.1) * height;
      final kSize = knotBaseSize *
          (0.7 + _textureHash(k * 17, 37, seed + 107) * 0.6);
      final intensity = 0.5 + _textureHash(k * 19, 43, seed + 109) * 0.5;
      return (x: kx, y: ky, size: kSize, intensity: intensity);
    });

    // Simulated virtual tree pith center (creates natural concentric arching).
    final pithAngle = grainAngle + math.pi * 0.5;
    final pithDist = width * 0.75 + (_textureHash(seed, 53) - 0.5) * width * 0.4;
    final pithX = width * 0.5 - math.cos(pithAngle) * pithDist;
    final pithY = height * 0.5 - math.sin(pithAngle) * pithDist;

    double sampleLum(int sx, int sy, double fallback) {
      final cx = sx.clamp(0, width - 1);
      final cy = sy.clamp(0, height - 1);
      final p = pixels[cy * width + cx];
      return (p >>> 24) == 0 ? fallback : _textureLuminance(p);
    }

    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final i = y * width + x;
        final source = pixels[i];
        final alpha = source >>> 24;
        if (preserve && alpha == 0) continue;

        var px = x + 0.5;
        var py = y + 0.5;

        // Realistic knot grain deflection: grain flows smoothly around knots.
        var maxKnotInfluence = 0.0;
        var knotCore = 0.0;
        for (var k = 0; k < knotCount; k++) {
          final knot = knots[k];
          final dx = px - knot.x;
          final dy = py - knot.y;
          final d = math.sqrt(dx * dx + dy * dy);
          final r = knot.size;
          if (d < r * 2.8) {
            final w = math.max(0.0, 1.0 - d / (r * 2.8));
            final push = (r * r / math.max(d, r * 0.35)) * 0.55 * w;
            px += (dx / math.max(d, 0.001)) * push;
            py += (dy / math.max(d, 0.001)) * push;
            if (d < r) {
              final coreT = 1.0 - d / r;
              knotCore = math.max(knotCore, coreT * knot.intensity);
            }
            maxKnotInfluence = math.max(maxKnotInfluence, w * knot.intensity);
          }
        }

        // Coordinate transformation along the grain orientation.
        final u = px * cosG - py * sinG;
        final v = px * sinG + py * cosG;

        // Multi-octave organic grain ripple & wave distortion.
        final wave = (_textureNoise(u * 0.02, v * 0.12, seed + 11) * 0.5 +
                _textureNoise(u * 0.06, v * 0.04, seed + 17) * 0.3 +
                _textureNoise(u * 0.14, v * 0.02, seed + 23) * 0.2);

        // Distance from tree pith combined with grain distortion.
        final dxPith = px - pithX;
        final dyPith = py - pithY;
        final distPith = math.sqrt(dxPith * dxPith + dyPith * dyPith);
        final effectiveDist = distPith + wave * ringSpacing * 1.6;

        // Asymmetric growth ring profile (gradual springwood -> sharp summerwood edge).
        final ringPhase = (effectiveDist / ringSpacing) % 1.0;
        final latewoodFactor = math.pow(ringPhase, 1.8).toDouble();
        final ringIntensity =
            (latewoodFactor * 0.65 + wave * 0.35).clamp(0.0, 1.0) *
                grainIntensity;

        // Fine wood pores (micro-cellular tracheid tubes parallel to grain).
        final poreNoise = _textureHash((u * 1.8).floor(), (v * 0.25).floor(), seed + 31);
        final finePore = poreNoise > 0.72 ? (poreNoise - 0.72) / 0.28 : 0.0;

        // Medullary ray flecks (perpendicular to growth rings, characteristic of oak).
        final rayNoise = _textureNoise(u * 0.35, v * 0.04, seed + 43);
        final medullaryRay = species == 0 && rayNoise > 0.68
            ? (rayNoise - 0.68) / 0.32
            : 0.0;

        // Tone variation & species figure modulation.
        final toneVary = (_textureNoise(px * 0.025, py * 0.025, seed + 53) - 0.5) *
            variation *
            0.5;

        // Base wood color interpolation.
        var color = _textureBlendColor(
          baseWood,
          earlyWood,
          (1.0 - ringIntensity * 0.8 + medullaryRay * 0.5).clamp(0.0, 1.0),
          255,
        );
        if (ringIntensity > 0.35) {
          final lateT = ((ringIntensity - 0.35) / 0.65).clamp(0.0, 1.0);
          color = _textureBlendColor(color, lateWood, lateT * 0.9, 255);
        }

        // Apply dark resinous knot core.
        if (knotCore > 0) {
          color = _textureBlendColor(color, lateWood, knotCore * 0.85, 255);
        }

        // Smart 3D Silhouette Edge Bevel (carved wooden figurine / rounded routed edge).
        var bevelShade = 0.0;
        var rimDot = 0.0;
        var rimFactor = 0.0;
        if (bevelWidth > 0 && distances[i] > 0 && distances[i] <= bevelWidth) {
          final bnx = distanceAt(x - 1, y) - distanceAt(x + 1, y);
          final bny = distanceAt(x, y - 1) - distanceAt(x, y + 1);
          final blen = math.sqrt(bnx * bnx + bny * bny);
          rimFactor = 1.0 - (distances[i] - 1) / bevelWidth;
          if (blen > 0) {
            rimDot = (bnx * lx + bny * ly) / blen;
          } else {
            rimDot = ((px - width * 0.5) * lx + (py - height * 0.5) * ly) >= 0
                ? 0.5
                : -0.5;
          }
          bevelShade = rimDot * rimFactor * 0.45;
        }

        // Smart Detail Carving: bas-relief emboss of existing sprite artwork.
        var artCarveShade = 0.0;
        if (detailCarving > 0 && alpha > 0) {
          final lum = _textureLuminance(source);
          final gxLum =
              (sampleLum(x + 1, y, lum) - sampleLum(x - 1, y, lum)) * 0.5;
          final gyLum =
              (sampleLum(x, y + 1, lum) - sampleLum(x, y - 1, lum)) * 0.5;
          final emboss = -(gxLum * lx + gyLum * ly) * 1.5;
          artCarveShade = detailCarving * ((lum - 0.5) * 0.55 + emboss);
        }

        // Anisotropic varnish sheen: highlight aligns with longitudinal grain.
        final grainNormalX = -sinG;
        final grainNormalY = cosG;
        final grainLightAlign =
            math.max(0.0, grainNormalX * lx + grainNormalY * ly);
        final specular =
            math.pow(grainLightAlign, 6).toDouble() * varnish * 0.35 +
                (rimDot > 0 ? rimDot * rimFactor * varnish * 0.5 : 0.0);

        // Overall lighting shade.
        var shade = 1.0 +
            toneVary +
            bevelShade +
            artCarveShade +
            (medullaryRay * 0.18) -
            (finePore * roughness * 0.22) -
            (ringIntensity * 0.12);

        // Weathering: surface graying, loss of varnish, and micro-drying checks.
        if (weathering > 0) {
          final grayAmount = weathering * 0.45;
          final luma = _textureLuminance(color);
          final grayColor =
              0xFF000000 | ((luma * 255).round() << 16) | ((luma * 255).round() << 8) | (luma * 255).round();
          color = _textureBlendColor(color, grayColor, grayAmount, 255);

          // Hairline surface checks along grain.
          final checkNoise = _textureHash((u * 0.4).floor(), (v * 4.0).floor(), seed + 77);
          if (checkNoise > 0.96 - weathering * 0.05) {
            shade *= 0.72;
            color = _textureBlendColor(color, lateWood, 0.6, 255);
          }
        }

        int channel(int shift) =>
            ((_textureChannel(color, shift) * shade + specular * 135))
                .round()
                .clamp(0, 255);

        final textured =
            0xFF000000 | (channel(16) << 16) | (channel(8) << 8) | channel(0);
        final outAlpha =
            preserve ? alpha : (alpha + (255 - alpha) * opacity).round();
        output[i] = _textureBlendColor(source, textured, opacity, outAlpha);
      }
    }
    return output;
  }
}
