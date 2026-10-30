part of 'effects.dart';

/// Smart silhouette- and artwork-aware stone surface effect.
///
/// Chisels the sprite silhouette with 3D directional bevels, carves source
/// artwork luminance and edge gradients into bas-relief engravings, and layers
/// Voronoi rock fracture planes with geological mineral textures.
class StoneEffect extends Effect {
  StoneEffect([Map<String, dynamic>? params])
      : super(EffectType.stone, {..._defaults, ...?params});

  static const stoneTypeOptions = <int, String>{
    0: 'Marble',
    1: 'Granite',
    2: 'Sandstone',
    3: 'Slate',
    4: 'Limestone',
    5: 'Obsidian',
    6: 'Basalt',
  };

  static const _defaults = <String, dynamic>{
    'stoneType': 1,
    'scale': 14,
    'irregularity': 0.75,
    'relief': 0.65,
    'bevelDepth': 3.0,
    'detailCarving': 0.5,
    'sourceBlend': 0.15,
    'cracks': 0.35,
    'roughness': 0.4,
    'variation': 0.35,
    'weathering': 0.25,
    'lightAngle': 225.0,
    'stoneColor': 0xFF82878C,
    'creviceColor': 0xFF34383D,
    'mossColor': 0xFF566B40,
    'seed': 42,
    'opacity': 1.0,
    'preserveAlpha': true,
  };

  @override
  Map<String, dynamic> getDefaultParameters() => Map.of(_defaults);

  @override
  Map<String, dynamic> getMetadata() => {
        'stoneType': <String, dynamic>{
          'label': 'Stone Type',
          'description': 'Geological rock structure and mineral composition.',
          'type': 'select',
          'options': stoneTypeOptions,
        },
        for (final spec in [
          ('scale', 'Stone Scale', 4, 64),
          ('irregularity', 'Fracture Irregularity', 0.0, 1.0),
          ('relief', 'Facet & Chisel Relief', 0.0, 1.0),
          ('bevelDepth', 'Smart Edge Bevel', 0.0, 10.0),
          ('detailCarving', 'Smart Detail Carving', 0.0, 1.0),
          ('sourceBlend', 'Artwork Color Tint', 0.0, 1.0),
          ('cracks', 'Cracks & Fissures', 0.0, 1.0),
          ('roughness', 'Mineral Roughness', 0.0, 1.0),
          ('variation', 'Block Variation', 0.0, 1.0),
          ('weathering', 'Weathering & Moss', 0.0, 1.0),
          ('lightAngle', 'Light Direction', 0.0, 360.0),
          ('seed', 'Random Seed', 0, 9999),
          ('opacity', 'Opacity', 0.0, 1.0),
        ])
          spec.$1: <String, dynamic>{
            'label': spec.$2,
            'type': 'slider',
            'min': spec.$3,
            'max': spec.$4,
            'divisions': spec.$3 is int ? (spec.$4 - spec.$3).toInt() : 100,
          },
        'stoneColor': <String, dynamic>{
          'label': 'Stone Color',
          'type': 'color',
        },
        'creviceColor': <String, dynamic>{
          'label': 'Crevice & Crack Color',
          'type': 'color',
        },
        'mossColor': <String, dynamic>{
          'label': 'Weathering Moss Color',
          'type': 'color',
        },
        'preserveAlpha': <String, dynamic>{
          'label': 'Preserve Alpha',
          'type': 'bool',
          'description':
              'Sculpt within the sprite silhouette; disable to fill the canvas.',
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

  int _resolveStoneType() {
    final raw = parameters['stoneType'];
    if (raw is num && raw.isFinite) return raw.round().clamp(0, 6);
    return switch (raw?.toString().toLowerCase()) {
      'marble' => 0,
      'granite' => 1,
      'sandstone' => 2,
      'slate' => 3,
      'limestone' => 4,
      'obsidian' => 5,
      'basalt' || 'cobblestone' => 6,
      _ => 1,
    };
  }

  double _resolveScale() {
    final raw = (parameters['scale'] as num?)?.toDouble();
    if (raw == null || !raw.isFinite) return 14.0;
    // Support legacy normalized [0.1, 1.0] scale values from old saved stacks.
    if (raw > 0.0 && raw <= 1.0) {
      return (4.0 + (1.0 - raw) * 20.0).clamp(4.0, 64.0);
    }
    return raw.clamp(4.0, 64.0);
  }

  static int _typeMineralTint(int stoneType) => switch (stoneType) {
        0 => 0xFFF2EFE9, // Marble warm calcite
        1 => 0xFF82878C, // Granite neutral grey
        2 => 0xFFD2A36C, // Sandstone warm ochre
        3 => 0xFF5C6B78, // Slate blue-grey
        4 => 0xFFE2D6C1, // Limestone buff cream
        5 => 0xFF282A34, // Obsidian volcanic glass
        6 => 0xFF4B4E54, // Basalt dark iron-grey
        _ => 0xFF82878C,
      };

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    final output = Uint32List.fromList(pixels);
    if (width <= 0 || height <= 0 || pixels.length < width * height) {
      return output;
    }
    final opacity = _number('opacity', 0, 1);
    if (opacity == 0) return output;

    final stoneType = _resolveStoneType();
    final size = _resolveScale();
    final jitter = _number('irregularity', 0, 1) * 0.35;
    final relief = _number('relief', 0, 1);
    final bevelDepth = _number('bevelDepth', 0, 10);
    final detailCarving = _number('detailCarving', 0, 1);
    final sourceBlend = _number('sourceBlend', 0, 1);
    final cracks = _number('cracks', 0, 1);
    final roughness = _number('roughness', 0, 1);
    final variation = _number('variation', 0, 1);
    final weathering = _number('weathering', 0, 1);
    final angle = _number('lightAngle', 0, 360) * math.pi / 180.0;
    final lx = math.cos(angle), ly = math.sin(angle);
    final seed = _number('seed', 0, 9999).round();
    final stoneColor = _color('stoneColor');
    final creviceColor = _color('creviceColor');
    final mossColor = _color('mossColor');
    final preserve = parameters['preserveAlpha'] != false;

    // Blend user stoneColor with the geological mineral signature so both
    // stoneType and stoneColor always contribute to the palette.
    final baseStone = _textureBlendColor(
      stoneColor,
      _typeMineralTint(stoneType),
      stoneType == 1 ? 0.0 : 0.55,
      255,
    );

    // Step 1: Smart 2-pass Chamfer distance transform over the alpha silhouette.
    // If the canvas has no transparent pixels, bevel relative to the canvas
    // perimeter so solid tiles also receive a chiseled 3D stone block frame.
    var hasTransparent = false;
    if (preserve) {
      for (var i = 0; i < width * height; i++) {
        if (pixels[i] >>> 24 == 0) {
          hasTransparent = true;
          break;
        }
      }
    }
    final dist = Float32List(width * height);
    if (bevelDepth > 0 || weathering > 0) {
      for (var y = 0; y < height; y++) {
        final borderY = y == 0 || y == height - 1;
        for (var x = 0; x < width; x++) {
          final i = y * width + x;
          if (preserve && (pixels[i] >>> 24) == 0) {
            dist[i] = 0.0;
          } else if (borderY || x == 0 || x == width - 1) {
            dist[i] = 1.0;
          } else {
            dist[i] = 1e6;
          }
        }
      }
      if (hasTransparent || bevelDepth > 0 || weathering > 0) {
        for (var y = 0; y < height; y++) {
          for (var x = 0; x < width; x++) {
            final i = y * width + x;
            var d = dist[i];
            if (d <= 1.0) continue;
            if (x > 0) d = math.min(d, dist[i - 1] + 1.0);
            if (y > 0) {
              d = math.min(d, dist[i - width] + 1.0);
              if (x > 0) d = math.min(d, dist[i - width - 1] + 1.4142);
              if (x + 1 < width) d = math.min(d, dist[i - width + 1] + 1.4142);
            }
            dist[i] = d;
          }
        }
        for (var y = height - 1; y >= 0; y--) {
          for (var x = width - 1; x >= 0; x--) {
            final i = y * width + x;
            var d = dist[i];
            if (d <= 1.0) continue;
            if (x + 1 < width) d = math.min(d, dist[i + 1] + 1.0);
            if (y + 1 < height) {
              d = math.min(d, dist[i + width] + 1.0);
              if (x > 0) d = math.min(d, dist[i + width - 1] + 1.4142);
              if (x + 1 < width) d = math.min(d, dist[i + width + 1] + 1.4142);
            }
            dist[i] = d;
          }
        }
      }
    }

    // Step 2: Precompute Voronoi fracture sites with 3D facet normals and tones.
    final cols = (width / size).ceil() + 6;
    final rows = (height / size).ceil() + 6;
    final sites = List.generate(cols * rows, (index) {
      final cx = index % cols - 3, cy = index ~/ cols - 3;
      final facetAngle = _textureHash(cx, cy, seed + 19) * math.pi * 2;
      final facetTilt = 0.25 + _textureHash(cx, cy, seed + 23) * 0.75;
      return (
        x: (cx + 0.5 + (_textureHash(cx, cy, seed) * 2 - 1) * jitter) * size,
        y: (cy + 0.5 + (_textureHash(cx, cy, seed + 11) * 2 - 1) * jitter) *
            size,
        nx: math.cos(facetAngle) * facetTilt,
        ny: math.sin(facetAngle) * facetTilt,
        tone: (_textureHash(cx, cy, seed + 29) - 0.5) * variation * 0.65,
        fracture: _textureHash(cx, cy, seed + 37),
      );
    });

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
        var neighborFracture = 0.0;
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
              neighborFracture = (center.fracture + site.fracture) * 0.5;
            }
          }
        }

        // Coherent warp keeps rock fractures jagged rather than polygonal.
        final warp = (_textureNoise(px * 0.32, py * 0.32, seed + 41) - 0.5) *
            (0.6 + roughness * 1.4);
        final warpedEdge = math.max(0.0, edge + warp);

        final microGrain = _textureHash(x, y, seed + 53) - 0.5;
        final coarseNoise =
            _textureNoise(px / (size * 0.35), py / (size * 0.35), seed + 59) -
                0.5;

        // Geological pattern & specular characteristics per stoneType.
        var geoShade = 0.0;
        var specular = 0.0;
        var veinCrevice = 0.0;
        switch (stoneType) {
          case 0: // Marble: flowing metamorphic veins
            final fbm = _textureFbm(px / size, py / size, seed + 61);
            final wave =
                (math.sin((px / size * 1.8 + py / size * 0.9 + fbm * 3.2) *
                            math.pi)
                        .abs());
            veinCrevice = math.pow(1.0 - wave, 4).toDouble() * 0.75;
            geoShade = (wave - 0.35) * 0.22;
          case 1: // Granite: crystalline feldspar, dark mica & quartz speckles
            final crystal = _textureHash(x, y, seed + 67);
            final cluster =
                _textureNoise(px * 0.55, py * 0.55, seed + 71) - 0.5;
            if (crystal > 0.78) {
              geoShade = 0.18 + (crystal - 0.78) * 0.5;
            } else if (crystal < 0.22) {
              geoShade = -0.22 - (0.22 - crystal) * 0.4;
            } else {
              geoShade = cluster * 0.2;
            }
          case 2: // Sandstone: horizontal cross-bedded sedimentary strata
            final bedWarp =
                _textureNoise(px / size * 1.4, py / size * 0.5, seed + 79) *
                    1.8;
            final strata =
                math.sin((py / size * 4.5 + bedWarp) * math.pi) * 0.5 + 0.5;
            geoShade = (strata - 0.5) * 0.32 + microGrain * 0.14;
          case 3: // Slate: diagonal foliated cleavage planes
            final diag = (px * 0.65 + py) / (size * 0.32) +
                _textureNoise(px / size, py / size, seed + 83) * 0.9;
            final sheet = diag - diag.floor();
            geoShade = (sheet - 0.5) * 0.34;
            if (sheet < 0.12) veinCrevice = 0.45;
          case 4: // Limestone: fossiliferous ooids and dissolved karst pores
            final ooid = _textureNoise(px * 0.45, py * 0.45, seed + 89);
            final pore = _textureHash(x, y, seed + 97);
            if (pore < 0.08 + roughness * 0.08) {
              veinCrevice = 0.65;
              geoShade = -0.25;
            } else if (ooid > 0.68) {
              geoShade = (ooid - 0.68) * 0.65;
            }
          case 5: // Obsidian: glassy conchoidal fracture flow + sharp specular
            final flow = math.sin(
                _textureFbm(px / size * 1.3, py / size * 1.8, seed + 101) *
                    math.pi *
                    3.0);
            geoShade = flow * 0.18;
            final facetDot =
                (center.nx * lx + center.ny * ly).clamp(0.0, 1.0);
            specular = math.pow(facetDot, 4).toDouble() * 0.55;
          case 6: // Basalt: dark columnar volcanic planes with sharp ridges
          default:
            final ridge =
                (1.0 - (warpedEdge / (size * 0.28)).clamp(0.0, 1.0)) * 0.24;
            geoShade = ridge - 0.08 + coarseNoise * 0.18;
        }

        // Facet 3D lighting: flat rock plane tilt + chiseled step at cell edges.
        final facetLight = center.nx * lx + center.ny * ly;
        final edgeSlope =
            (1.0 - (warpedEdge / (size * 0.28)).clamp(0.0, 1.0));
        final edgeLight = (enx * lx + eny * ly) * edgeSlope;
        var shade = 1.0 +
            center.tone +
            geoShade +
            relief * (facetLight * 0.26 + edgeLight * 0.34) +
            (microGrain * 0.24 + coarseNoise * 0.28) * roughness;

        // Smart Silhouette 3D Chiseled Bevel.
        var silhouetteEdgeFactor = 0.0;
        if (bevelDepth > 0) {
          final d = dist[i];
          if (d <= bevelDepth) {
            final dL = x > 0 ? dist[i - 1] : 0.0;
            final dR = x + 1 < width ? dist[i + 1] : 0.0;
            final dT = y > 0 ? dist[i - width] : 0.0;
            final dB = y + 1 < height ? dist[i + width] : 0.0;
            var dx = (dL - dR) * 0.5;
            var dy = (dT - dB) * 0.5;
            if (dx == 0.0 && dy == 0.0) {
              dx = px - width * 0.5;
              dy = py - height * 0.5;
            }
            final len = math.sqrt(dx * dx + dy * dy);
            final bnx = len > 0 ? dx / len : 0.0;
            final bny = len > 0 ? dy / len : 0.0;
            silhouetteEdgeFactor =
                ((bevelDepth - d + 0.65) / math.max(bevelDepth, 1.0))
                    .clamp(0.0, 1.0);
            final rimDot = bnx * lx + bny * ly;
            shade += rimDot * silhouetteEdgeFactor * (0.28 + relief * 0.34);
          }
        }

        // Smart Artwork Detail Carving: preserve internal sprite forms as
        // bas-relief stone engravings and highlights without leaking alpha.
        var engravedCrevice = 0.0;
        if (detailCarving > 0 && alpha > 0) {
          final lum = _textureLuminance(source);
          final gxLum =
              (sampleLum(x + 1, y, lum) - sampleLum(x - 1, y, lum)) * 0.5;
          final gyLum =
              (sampleLum(x, y + 1, lum) - sampleLum(x, y - 1, lum)) * 0.5;
          final emboss = -(gxLum * lx + gyLum * ly) * 1.65;
          shade += detailCarving * ((lum - 0.5) * 0.55 + emboss);
          if (lum < 0.35) {
            engravedCrevice =
                ((0.35 - lum) / 0.35 * detailCarving * 0.75).clamp(0.0, 1.0);
          }
        }

        // Fracture Cracks & Fissures along Voronoi bisectors.
        final crackWidth = cracks * (0.55 + neighborFracture * 1.35);
        final isCrack = cracks > 0 && warpedEdge < crackWidth;
        var crackStrength = 0.0;
        if (isCrack) {
          crackStrength =
              (1.0 - warpedEdge / math.max(crackWidth, 0.001)).clamp(0.25, 1.0);
          shade *= 1.0 - crackStrength * 0.45;
        } else if (cracks > 0 && warpedEdge < crackWidth + 1.2) {
          // Sunlit chiseled lip immediately bordering a fracture fissure.
          final lip = 1.0 - (warpedEdge - crackWidth) / 1.2;
          shade += (enx * lx + eny * ly).clamp(-0.5, 1.0) * lip * cracks * 0.28;
        }

        var color = baseStone;
        if (sourceBlend > 0 && alpha > 0) {
          color = _textureBlendColor(color, source, sourceBlend, 255);
        }

        final creviceAmount = math.max(
          crackStrength,
          math.max(veinCrevice * (0.4 + cracks * 0.6), engravedCrevice),
        );
        if (creviceAmount > 0) {
          color = _textureBlendColor(
            color,
            creviceColor,
            creviceAmount.clamp(0.0, 1.0),
            255,
          );
        }

        // Weathering: erosion pitting and damp moss settling in joints/edges.
        if (weathering > 0) {
          final mossPatch =
              _textureNoise(px / size * 2.2, py / size * 2.2, seed + 113);
          final nearJoint =
              (1.0 - warpedEdge / (size * 0.22)).clamp(0.0, 1.0);
          final nearRim = dist[i] > 0 && dist[i] <= 2.5 ? 0.55 : 0.0;
          final receptivity = math.max(nearJoint, nearRim);
          final mossAmount =
              ((mossPatch - (1.0 - weathering * 0.85)) * 2.6).clamp(0.0, 1.0) *
                  receptivity;
          if (mossAmount > 0) {
            color = _textureBlendColor(color, mossColor, mossAmount, 255);
          }
          if (_textureHash(x, y, seed + 127) < weathering * 0.1) {
            shade *= 0.74;
          }
        }

        int channel(int shift) =>
            (_textureChannel(color, shift) * shade + specular * 140)
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
