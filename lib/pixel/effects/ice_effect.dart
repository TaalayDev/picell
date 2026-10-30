part of 'effects.dart';

/// Smart silhouette-aware ice and frost material with Voronoi crystal facets,
/// optical artwork refraction, trapped air bubbles, internal stress fractures,
/// and directional 3D rim bevels.
class IceEffect extends Effect {
  IceEffect([Map<String, dynamic>? params])
      : super(EffectType.ice, {..._defaults, ...?params});

  static const iceTypeOptions = <int, String>{
    0: 'Clear Ice',
    1: 'Frosted Ice',
    2: 'Crystal Ice',
    3: 'Glacial Ice',
    4: 'Black Ice',
    5: 'Snow Ice',
  };

  static const _defaults = <String, dynamic>{
    'iceType': 0,
    'scale': 14,
    'transparency': 0.35,
    'thickness': 0.5,
    'frostiness': 0.35,
    'crackIntensity': 0.35,
    'bubbleAmount': 0.25,
    'refractionStrength': 0.4,
    'crystallization': 0.5,
    'shininess': 0.75,
    'temperature': 0.2,
    'iceAge': 0.3,
    'bevelWidth': 3.0,
    'lightAngle': 225.0,
    'iceColor': 0xFF9CE8FF,
    'frostColor': 0xFFF2FBFF,
    'deepColor': 0xFF1E5C8A,
    'randomSeed': 42,
    'opacity': 1.0,
    'preserveAlpha': true,
  };

  @override
  Map<String, dynamic> getDefaultParameters() => Map.of(_defaults);

  @override
  Map<String, dynamic> getMetadata() => {
        'iceType': <String, dynamic>{
          'label': 'Ice Type',
          'description': 'Optical and structural ice formation.',
          'type': 'select',
          'options': iceTypeOptions,
        },
        for (final spec in [
          ('scale', 'Crystal Scale', 4, 64),
          ('transparency', 'Artwork Clarity', 0.0, 1.0),
          ('thickness', 'Ice Thickness', 0.0, 1.0),
          ('frostiness', 'Surface & Rim Frost', 0.0, 1.0),
          ('crackIntensity', 'Internal Fractures', 0.0, 1.0),
          ('bubbleAmount', 'Trapped Air Bubbles', 0.0, 1.0),
          ('refractionStrength', 'Light Refraction', 0.0, 1.0),
          ('crystallization', 'Crystal Facets', 0.0, 1.0),
          ('shininess', 'Specular Gloss', 0.0, 1.0),
          ('temperature', 'Temperature', 0.0, 1.0),
          ('iceAge', 'Glacial Weathering', 0.0, 1.0),
          ('bevelWidth', 'Smart Rim Bevel', 0.0, 8.0),
          ('lightAngle', 'Light Direction', 0.0, 360.0),
          ('randomSeed', 'Pattern Seed', 0, 9999),
          ('opacity', 'Opacity', 0.0, 1.0),
        ])
          spec.$1: <String, dynamic>{
            'label': spec.$2,
            'type': 'slider',
            'min': spec.$3,
            'max': spec.$4,
            'divisions': spec.$3 is int ? (spec.$4 - spec.$3).toInt() : 100,
          },
        'iceColor': <String, dynamic>{
          'label': 'Ice Color',
          'type': 'color',
        },
        'frostColor': <String, dynamic>{
          'label': 'Frost & Fracture Color',
          'type': 'color',
        },
        'deepColor': <String, dynamic>{
          'label': 'Deep Glacial Color',
          'type': 'color',
        },
        'preserveAlpha': <String, dynamic>{
          'label': 'Preserve Alpha',
          'type': 'bool',
          'description':
              'Freeze within the artwork silhouette; disable to fill the canvas.',
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

  static int _typeTint(int iceType) => switch (iceType) {
        0 => 0xFFB8F0FF, // Clear ice pale cyan
        1 => 0xFFDCEEFF, // Frosted ice milky blue-white
        2 => 0xFF88DCFF, // Crystal ice bright sky cyan
        3 => 0xFF4CA8E0, // Glacial ice compressed cerulean
        4 => 0xFF283A52, // Black ice dark abyssal slate-blue
        5 => 0xFFF2F8FF, // Snow ice crisp neve white
        _ => 0xFFB8F0FF,
      };

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    final output = Uint32List.fromList(pixels);
    if (width <= 0 || height <= 0 || pixels.length < width * height) {
      return output;
    }
    final opacity = _number('opacity', 0, 1);
    if (opacity == 0) return output;

    final iceType = _number('iceType', 0, 5).round();
    final size = _number('scale', 4, 64);
    final clarity = _number('transparency', 0, 1);
    final thickness = _number('thickness', 0, 1);
    final frostiness = _number('frostiness', 0, 1);
    final cracks = _number('crackIntensity', 0, 1);
    final bubbles = _number('bubbleAmount', 0, 1);
    final refraction = _number('refractionStrength', 0, 1);
    final crystallization = _number('crystallization', 0, 1);
    final shininess = _number('shininess', 0, 1);
    final temperature = _number('temperature', 0, 1);
    final iceAge = _number('iceAge', 0, 1);
    final bevelWidth = _number('bevelWidth', 0, 8);
    final angle = _number('lightAngle', 0, 360) * math.pi / 180.0;
    final lx = math.cos(angle), ly = math.sin(angle);
    final seed =
        ((parameters['randomSeed'] ?? parameters['seed']) as num?)?.round() ??
            42;
    final clampedSeed = seed.clamp(0, 9999);
    final iceColor = _color('iceColor');
    final frostColor = _color('frostColor');
    final deepColor = _color('deepColor');
    final preserve = parameters['preserveAlpha'] != false;

    // Combine user iceColor with the optical signature of the selected iceType
    // and temperature (colder = deeper cyan/cobalt, warmer = clearer melt tint).
    final typeMixed = _textureBlendColor(
      iceColor,
      _typeTint(iceType),
      iceType == 0 ? 0.25 : 0.6,
      255,
    );
    final baseIce = _textureBlendColor(
      deepColor,
      typeMixed,
      (0.72 - thickness * 0.35 + temperature * 0.18).clamp(0.15, 0.95),
      255,
    );

    // Step 1: Capped silhouette distance transform (including transparent holes).
    final distances = Uint8List(width * height);
    if (bevelWidth > 0 || frostiness > 0) {
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

    // Step 2: Seeded Voronoi crystal cells with 3D optical normals and bubbles.
    final jitter = 0.15 + crystallization * 0.22;
    final cols = (width / size).ceil() + 6;
    final rows = (height / size).ceil() + 6;
    final sites = List.generate(cols * rows, (index) {
      final cx = index % cols - 3, cy = index ~/ cols - 3;
      final facetAngle = _textureHash(cx, cy, clampedSeed + 17) * math.pi * 2;
      final facetTilt = 0.2 + _textureHash(cx, cy, clampedSeed + 23) * 0.8;
      return (
        x: (cx + 0.5 + (_textureHash(cx, cy, clampedSeed) * 2 - 1) * jitter) *
            size,
        y: (cy +
                0.5 +
                (_textureHash(cx, cy, clampedSeed + 11) * 2 - 1) * jitter) *
            size,
        nx: math.cos(facetAngle) * facetTilt,
        ny: math.sin(facetAngle) * facetTilt,
        tone: _textureHash(cx, cy, clampedSeed + 31) - 0.5,
        stress: _textureHash(cx, cy, clampedSeed + 43),
      );
    });

    final bubbleScale = math.max(4.0, size * 0.55);

    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final i = y * width + x;
        final source = pixels[i];
        final alpha = source >>> 24;
        if (preserve && alpha == 0) continue;

        final px = x + 0.5, py = y + 0.5;
        final gx = (px / size).floor() + 3, gy = (py / size).floor() + 3;

        var nearest = double.infinity;
        var winner = 0;
        for (var oy = -2; oy <= 2; oy++) {
          for (var ox = -2; ox <= 2; ox++) {
            final idx = (gy + oy) * cols + gx + ox;
            final site = sites[idx];
            final dx = px - site.x, dy = py - site.y;
            final d2 = dx * dx + dy * dy;
            if (d2 < nearest) {
              nearest = d2;
              winner = idx;
            }
          }
        }
        final center = sites[winner];
        var edge = double.infinity;
        var enx = 0.0, eny = 0.0;
        var pairStress = 0.0;
        for (var oy = -2; oy <= 2; oy++) {
          for (var ox = -2; ox <= 2; ox++) {
            final idx = (gy + oy) * cols + gx + ox;
            if (idx == winner) continue;
            final site = sites[idx];
            final dx = site.x - center.x, dy = site.y - center.y;
            final len = math.sqrt(dx * dx + dy * dy);
            if (len == 0) continue;
            final d = ((site.x + center.x) * 0.5 - px) * dx / len +
                ((site.y + center.y) * 0.5 - py) * dy / len;
            if (d < edge) {
              edge = d;
              enx = dx / len;
              eny = dy / len;
              pairStress = (center.stress + site.stress) * 0.5;
            }
          }
        }

        // Jagged fracture perturbation scaled by iceAge.
        final warp = (_textureNoise(px * 0.28, py * 0.28, clampedSeed + 59) -
                0.5) *
            (0.4 + iceAge * 1.6);
        final warpedEdge = math.max(0.0, edge + warp);

        // Combined surface normal from crystal facet + silhouette bevel.
        var nx = center.nx * (0.35 + crystallization * 0.65);
        var ny = center.ny * (0.35 + crystallization * 0.65);
        var rimFactor = 0.0;
        var rimDot = 0.0;
        if (bevelWidth > 0 && distances[i] > 0 && distances[i] <= bevelWidth) {
          final bnx = distanceAt(x - 1, y) - distanceAt(x + 1, y);
          final bny = distanceAt(x, y - 1) - distanceAt(x, y + 1);
          final blen = math.sqrt(bnx * bnx + bny * bny);
          rimFactor = 1.0 - (distances[i] - 1) / bevelWidth;
          if (blen > 0) {
            rimDot = (bnx * lx + bny * ly) / blen;
            nx += (bnx / blen) * rimFactor * 0.85;
            ny += (bny / blen) * rimFactor * 0.85;
          } else {
            rimDot = ((px - width * 0.5) * lx + (py - height * 0.5) * ly) >= 0
                ? 0.5
                : -0.5;
          }
        }

        final facetDot = center.nx * lx + center.ny * ly;
        final ridgeSlope =
            (1.0 - (warpedEdge / (size * 0.26)).clamp(0.0, 1.0));
        final ridgeDot = (enx * lx + eny * ly) * ridgeSlope;
        final micro = _textureHash(x, y, clampedSeed + 71) - 0.5;

        // Type-specific structural modulation.
        var typeShade = 0.0;
        var extraFrost = 0.0;
        switch (iceType) {
          case 0: // Clear Ice: smooth optical bands
            typeShade =
                (_textureNoise(px / size, py / size, clampedSeed + 79) - 0.5) *
                    0.12;
          case 1: // Frosted Ice: dendritic surface frost blooms
            extraFrost = 0.28;
            typeShade = micro * 0.14;
          case 2: // Crystal Ice: angular faceted contrast
            typeShade =
                (facetDot * 0.32 + center.tone * 0.25) *
                    (0.5 + crystallization * 0.5);
          case 3: // Glacial Ice: compressed horizontal/diagonal strata
            final strata = math.sin(
                (py / (size * 0.45) +
                        _textureNoise(
                                px / size, py / size, clampedSeed + 83) *
                            1.5) *
                    math.pi);
            typeShade = strata * (0.16 + iceAge * 0.18) - thickness * 0.12;
          case 4: // Black Ice: dark abyssal base with high-contrast sheen
            typeShade = -0.22 + facetDot * 0.18;
          case 5: // Snow Ice: packed granular neve sparkle
          default:
            extraFrost = 0.45;
            typeShade = 0.12 + micro * 0.22;
        }

        // Glacial weathering compression bands & surface etching from iceAge.
        final ageBand = (_textureFbm(
                    px / (size * 0.8), py / (size * 1.4), clampedSeed + 89) -
                0.5) *
            iceAge *
            0.32;

        var shade = 0.88 +
            typeShade +
            ageBand +
            center.tone * (0.12 + crystallization * 0.28) +
            facetDot * (0.14 + crystallization * 0.26) +
            ridgeDot * (0.15 + thickness * 0.2) +
            rimDot * rimFactor * 0.42;

        // Specular reflection across facets and beveled silhouette rims.
        final lightAlign = math.max(
          0.0,
          facetDot * 0.65 + ridgeDot * 0.55 + rimDot * rimFactor * 0.85,
        );
        final specExp = iceType == 4 ? 8.0 : (4.0 + (1.0 - frostiness) * 6.0);
        var specular =
            math.pow(lightAlign, specExp).toDouble() * shininess * 0.85;
        if (rimDot > 0 && rimFactor > 0) {
          specular += rimDot * rimFactor * shininess * 0.45;
        }

        var color = baseIce;
        // Deep glacial absorption in shadow-facing bevels and thick interiors.
        final deepAmount = ((1.0 - shade) * (0.35 + thickness * 0.55) +
                (rimDot < 0 ? -rimDot * rimFactor * 0.45 : 0.0))
            .clamp(0.0, 0.85);
        if (deepAmount > 0) {
          color = _textureBlendColor(color, deepColor, deepAmount, 255);
        }

        // Trapped sub-surface spherical air bubbles with upper-light glint.
        if (bubbles > 0) {
          final bx = (px / bubbleScale).floor();
          final by = (py / bubbleScale).floor();
          final cellChance = _textureHash(bx, by, clampedSeed + 101);
          if (cellChance > 1.0 - bubbles * 0.75) {
            final cx = (bx +
                    0.25 +
                    _textureHash(bx, by, clampedSeed + 103) * 0.5) *
                bubbleScale;
            final cy = (by +
                    0.25 +
                    _textureHash(bx, by, clampedSeed + 107) * 0.5) *
                bubbleScale;
            final radius = (0.16 +
                    _textureHash(bx, by, clampedSeed + 109) * 0.22) *
                bubbleScale;
            final dx = px - cx, dy = py - cy;
            final distBubble = math.sqrt(dx * dx + dy * dy);
            if (distBubble <= radius) {
              final normR = distBubble / math.max(radius, 0.001);
              final rim = normR > 0.62 ? 0.75 : 0.35;
              final glint = (dx * lx + dy * ly) < 0 ? 0.25 : 0.0;
              color = _textureBlendColor(
                color,
                frostColor,
                (rim + glint) * bubbles,
                255,
              );
              specular += glint * shininess * 0.5;
            }
          }
        }

        // Internal stress fractures: bright white/cyan reflection seam + dark shadow edge.
        final crackWidth =
            cracks * (0.45 + pairStress * 1.15 + iceAge * 0.45);
        if (cracks > 0 && warpedEdge < crackWidth) {
          final t =
              (1.0 - warpedEdge / math.max(crackWidth, 0.001)).clamp(0.0, 1.0);
          color = _textureBlendColor(
            color,
            frostColor,
            (t * (0.55 + cracks * 0.4)).clamp(0.0, 1.0),
            255,
          );
          shade += t * 0.22;
        } else if (cracks > 0 && warpedEdge < crackWidth + 0.9) {
          color = _textureBlendColor(color, deepColor, cracks * 0.35, 255);
          shade *= 0.88;
        }

        // Surface & silhouette rim hoarfrost crystals.
        final effectiveFrost = (frostiness + extraFrost).clamp(0.0, 1.0);
        if (effectiveFrost > 0) {
          final frostNoise = _textureFbm(
            px / (size * 0.45),
            py / (size * 0.45),
            clampedSeed + 131,
          );
          final jointBoost =
              (1.0 - warpedEdge / (size * 0.22)).clamp(0.0, 1.0) * 0.3;
          final rimBoost = rimFactor * 0.45;
          final frostMask = ((frostNoise +
                      jointBoost +
                      rimBoost +
                      micro * 0.15 -
                      (1.0 - effectiveFrost * 0.85)) *
                  2.4)
              .clamp(0.0, 1.0);
          if (frostMask > 0) {
            color = _textureBlendColor(
              color,
              frostColor,
              (frostMask * (0.45 + effectiveFrost * 0.45)).clamp(0.0, 1.0),
              255,
            );
            shade += frostMask * 0.12;
          }
        }

        int channel(int shift) =>
            (_textureChannel(color, shift) * shade + specular * 155)
                .round()
                .clamp(0, 255);
        var icePixel =
            0xFF000000 | (channel(16) << 16) | (channel(8) << 8) | channel(0);

        // Optical artwork refraction & clarity: displace within solid pixels
        // and never leak RGB from transparent neighbors.
        if (alpha > 0) {
          final disp = refraction * size * 0.28;
          final sx = (x + nx * disp).round().clamp(0, width - 1);
          final sy = (y + ny * disp).round().clamp(0, height - 1);
          final sampled = pixels[sy * width + sx];
          final artwork = _textureBlendColor(
            source,
            sampled,
            (sampled >>> 24) / 255.0,
            255,
          );
          final artLum = _textureLuminance(artwork);
          final effectiveClarity =
              (clarity * (1.0 - thickness * 0.35 - effectiveFrost * 0.25))
                  .clamp(0.0, 0.92);
          if (effectiveClarity > 0) {
            icePixel = _textureBlendColor(
              icePixel,
              artwork,
              effectiveClarity,
              255,
            );
          }
          // Preserve subtle frozen silhouette details even at low transparency.
          final detailRelief = (artLum - 0.5) * 0.18;
          if (detailRelief != 0) {
            icePixel = _textureBlendColor(
              icePixel,
              detailRelief > 0 ? frostColor : deepColor,
              detailRelief.abs(),
              255,
            );
          }
        }

        final outAlpha =
            preserve ? alpha : (alpha + (255 - alpha) * opacity).round();
        output[i] = _textureBlendColor(source, icePixel, opacity, outAlpha);
      }
    }
    return output;
  }
}
