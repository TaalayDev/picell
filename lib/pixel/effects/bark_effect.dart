part of 'effects.dart';

/// Shape-aware tree bark.
///
/// Instead of tiling a fixed pattern, the bark reads the sprite's silhouette:
///  * the grain direction follows the limb axis (estimated from a smoothed
///    distance-field structure tensor), so furrows bend with trunks and branches;
///  * limbs are shaded as cylinders (rim distance relative to local thickness);
///  * the artwork's hue can tint the bark and its edges/dark lines carve
///    crevices, so existing pixel art keeps its identity.
///
/// Eight species recipes are built from flow-aligned noise "streaks".
class TreeBarkEffect extends Effect {
  TreeBarkEffect([Map<String, dynamic>? params]) : super(EffectType.treeBark, {..._defaults, ...?params});

  static const barkTypeOptions = <int, String>{
    0: 'Oak (Rugged Furrows)',
    1: 'Birch (Peeling Paper)',
    2: 'Pine (Scaly Plates)',
    3: 'Redwood (Fibrous Flutes)',
    4: 'Willow (Diamond Ridges)',
    5: 'Palm (Ringed Husks)',
    6: 'Cherry (Satin Lenticels)',
    7: 'Eucalyptus (Patchwork)',
  };

  static const _defaults = <String, dynamic>{
    'barkType': 0,
    'scale': 8.0,
    'followShape': 0.85,
    'grooving': 0.6,
    'roughness': 0.4,
    'crackiness': 0.35,
    'peeling': 0.25,
    'depth': 0.65,
    'bevelWidth': 2.5,
    'detailCarving': 0.35,
    'keepArtwork': 0.3,
    'mossAmount': 0.15,
    'weathering': 0.35,
    'colorVariation': 0.4,
    'lightDirection': 225.0,
    'barkColor': 0xFF5D4037,
    'creviceColor': 0xFF2B1B14,
    'mossColor': 0xFF4B6E36,
    'seed': 42,
    'opacity': 1.0,
    'preserveAlpha': true,
  };

  @override
  Map<String, dynamic> getDefaultParameters() => Map.of(_defaults);

  @override
  Map<String, dynamic> getMetadata() => {
        'barkType': <String, dynamic>{
          'label': 'Bark Type',
          'description': 'Botanical bark morphology.',
          'type': 'select',
          'options': barkTypeOptions,
        },
        for (final spec in [
          ('scale', 'Texture Scale', 4.0, 48.0),
          ('followShape', 'Grain Follows Shape', 0.0, 1.0),
          ('grooving', 'Furrow Depth', 0.0, 1.0),
          ('crackiness', 'Cracks & Fissures', 0.0, 1.0),
          ('peeling', 'Peeling & Flakes', 0.0, 1.0),
          ('roughness', 'Surface Roughness', 0.0, 1.0),
          ('depth', 'Relief Lighting', 0.0, 1.0),
          ('bevelWidth', 'Trunk Roundness', 0.0, 8.0),
          ('detailCarving', 'Artwork Carving', 0.0, 1.0),
          ('keepArtwork', 'Artwork Tint', 0.0, 1.0),
          ('mossAmount', 'Moss & Lichen', 0.0, 1.0),
          ('weathering', 'Weathering', 0.0, 1.0),
          ('colorVariation', 'Color Variation', 0.0, 1.0),
          ('lightDirection', 'Light Direction', 0.0, 360.0),
          ('seed', 'Pattern Seed', 0, 9999),
          ('opacity', 'Opacity', 0.0, 1.0),
        ])
          spec.$1: <String, dynamic>{
            'label': spec.$2,
            'type': 'slider',
            'min': spec.$3,
            'max': spec.$4,
            'divisions': spec.$3 is int ? (spec.$4 - spec.$3).toInt() : 100,
          },
        'barkColor': <String, dynamic>{'label': 'Bark Color', 'type': 'color'},
        'creviceColor': <String, dynamic>{'label': 'Crevice Color', 'type': 'color'},
        'mossColor': <String, dynamic>{'label': 'Moss Color', 'type': 'color'},
        'preserveAlpha': <String, dynamic>{
          'label': 'Preserve Alpha',
          'type': 'bool',
          'description': 'Apply bark only inside the artwork silhouette; disable to fill the canvas.',
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

  int _resolveBarkType() {
    final raw = parameters['barkType'];
    if (raw is num && raw.isFinite) return raw.round().clamp(0, 7);
    const names = ['oak', 'birch', 'pine', 'redwood', 'willow', 'palm', 'cherry', 'eucalyptus'];
    final index = names.indexOf(raw?.toString().toLowerCase() ?? '');
    return index < 0 ? 0 : index;
  }

  double _resolveScale() {
    final raw = (parameters['scale'] as num?)?.toDouble();
    if (raw == null || !raw.isFinite) return 8.0;
    // Legacy projects stored a normalized [0, 1] scale.
    if (raw > 0.0 && raw <= 1.0) return 4.0 + (1.0 - raw) * 20.0;
    return raw.clamp(4.0, 48.0);
  }

  double _resolveLightAngle() {
    final raw = ((parameters['lightDirection'] ?? parameters['lightAngle']) as num?)?.toDouble();
    if (raw == null || !raw.isFinite) return 225.0 * math.pi / 180.0;
    // Legacy projects stored the angle as a [0, 1] turn.
    if (raw > 0.0 && raw <= 1.0) return raw * 2.0 * math.pi;
    return raw * math.pi / 180.0;
  }

  int _resolveSeed() {
    final raw = parameters['seed'] ?? parameters['randomSeed'];
    return raw is num && raw.isFinite ? raw.round().clamp(0, 9999) : 42;
  }

  static (int base, int dark, int light, int crevice) _palette(int type) => switch (type) {
        1 => (0xFFE9E5DA, 0xFF8C867C, 0xFFFFFFFF, 0xFF181615), // birch
        2 => (0xFFB9703F, 0xFF70381B, 0xFFE0A36F, 0xFF3F1B0B), // pine
        3 => (0xFF9A4529, 0xFF5A1E14, 0xFFC87656, 0xFF34100B), // redwood
        4 => (0xFF6B665F, 0xFF383633, 0xFF9C968D, 0xFF1E1C1A), // willow
        5 => (0xFF8C7456, 0xFF54412C, 0xFFBBA382, 0xFF30230F), // palm
        6 => (0xFF7A3D24, 0xFF47200F, 0xFFC27A54, 0xFF2D0F05), // cherry
        7 => (0xFFC9C0A4, 0xFF5F7A5E, 0xFFEFE8D2, 0xFF3A463A), // eucalyptus
        _ => (0xFF5D4037, 0xFF352019, 0xFF8D6E63, 0xFF241510), // oak
      };

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    final output = Uint32List.fromList(pixels);
    if (width <= 0 || height <= 0 || pixels.length < width * height) return output;
    final opacity = _number('opacity', 0, 1);
    if (opacity == 0) return output;

    final type = _resolveBarkType();
    final s = _resolveScale();
    final follow = _number('followShape', 0, 1);
    final grooving = _number('grooving', 0, 1);
    final roughness = _number('roughness', 0, 1);
    final crackiness = _number('crackiness', 0, 1);
    final peeling = _number('peeling', 0, 1);
    final depth = _number('depth', 0, 1);
    final bevelWidth = _number('bevelWidth', 0, 8);
    final detailCarving = _number('detailCarving', 0, 1);
    final keepArtwork = _number('keepArtwork', 0, 1);
    final mossAmount = _number('mossAmount', 0, 1);
    final weathering = _number('weathering', 0, 1);
    final colorVariation = _number('colorVariation', 0, 1);
    final lightAngle = _resolveLightAngle();
    final lx = math.cos(lightAngle), ly = math.sin(lightAngle);
    final seed = _resolveSeed();
    final preserve = parameters['preserveAlpha'] != false;
    final mossColor = _color('mossColor');

    final pal = _palette(type);
    final userBark = _color('barkColor');
    final customBark = userBark != (_defaults['barkColor'] as int);
    final base = customBark ? userBark : pal.$1;
    final dark = customBark ? _textureBlendColor(userBark, 0xFF000000, 0.42, 255) : pal.$2;
    final light = customBark ? _textureBlendColor(userBark, 0xFFFFFFFF, 0.32, 255) : pal.$3;
    final userCrevice = _color('creviceColor');
    final crevice = userCrevice != (_defaults['creviceColor'] as int) ? userCrevice : pal.$4;
    int ramp(double t) =>
        t < 0.5 ? _textureBlendColor(dark, base, t * 2, 255) : _textureBlendColor(base, light, (t - 0.5) * 2, 255);

    final count = width * height;
    final inside = Uint8List(count);
    for (var i = 0; i < count; i++) {
      inside[i] = !preserve || (pixels[i] >>> 24) != 0 ? 1 : 0;
    }
    final shape = _silhouetteShape(inside, width, height, bevelWidth, follow);

    // Species constants.
    final valleyWeight = switch (type) { 1 => 0.25, 6 => 0.2, 7 => 0.4, _ => 1.0 };
    final fissureWeight = switch (type) { 1 => 0.3, 6 => 0.25, 7 => 0.5, _ => 1.0 };
    final peelAcross = type == 1 || type == 6 || type == 7;
    final lenticelLight = type == 6;
    const spread = 0.6; // rad, half-angle of willow's crossing ridges
    final cs = math.cos(spread), sn = math.sin(spread);

    double streak(double x, double y, double dx, double dy, double cell, double length, int salt) {
      final inv = 1.0 / math.max(cell, 0.5);
      // Tap spacing stays below the noise correlation length so the average is a
      // continuous streak rather than uncorrelated speckle.
      final ratio = length * inv;
      final taps = (ratio * 1.3).ceil().clamp(3, 13);
      final step = length / (taps - 1);
      var sum = 0.0;
      for (var k = 0; k < taps; k++) {
        final t = (k - (taps - 1) / 2) * step;
        sum += _textureNoise((x + dx * t) * inv, (y + dy * t) * inv, seed + salt);
      }
      final gain = (0.95 * math.sqrt(math.max(ratio, 1.0)) + 0.3).clamp(1.2, 3.2);
      return ((sum / taps - 0.5) * gain + 0.5).clamp(0.0, 1.0);
    }

    // Pass 1: species fields (height, crack, tone, lenticel, flake edge, flake shadow).
    final heightMap = Float32List(count);
    final crackMap = Float32List(count);
    final toneMap = Float32List(count);
    final lentMap = Float32List(count);
    final edgeMap = Float32List(count);
    final castMap = Float32List(count);

    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final i = y * width + x;
        if (inside[i] == 0) continue;
        final px = x + 0.5, py = y + 0.5;
        final wx = px + (_textureNoise(px / (s * 3), py / (s * 3), seed + 5) - 0.5) * s * 0.6;
        final wy = py + (_textureNoise(px / (s * 3) + 7.3, py / (s * 3) + 3.1, seed + 6) - 0.5) * s * 0.6;
        final fx = shape.fiberX[i], fy = shape.fiberY[i];
        final cx = -fy, cy = fx;
        double along(double cell, double len, int salt) => streak(wx, wy, fx, fy, cell, len, salt);
        double across(double cell, double len, int salt) => streak(wx, wy, cx, cy, cell, len, salt);

        var h = 0.5, tone = 0.5, lent = 0.0, seam = 0.0;
        switch (type) {
          case 0: // Oak: broken vertical ridges
            final a = along(s * 0.55, s * 2.6, 11);
            final b = along(s * 0.2, s * 1.1, 13);
            final blocks = across(s * 0.8, s * 1.0, 17);
            h = _textureStep(0.28, 0.72, a * 0.7 + b * 0.3);
            h *= 1 - 0.45 * (1 - _textureStep(0.25, 0.55, blocks));
            tone = h * 0.7 + (b - 0.5) * 0.4 + 0.15;
          case 1: // Birch: pale paper, dark horizontal lenticels
            final paper = across(s * 1.4, s * 3.0, 23);
            h = 0.72 + (paper - 0.5) * 0.22;
            tone = 0.8 + (paper - 0.5) * 0.35;
            final l = across(s * 0.3, s * 1.6, 29);
            lent = _textureStep(0.40, 0.30, l) * _textureStep(0.35, 0.5, _textureNoise(wx / (s * 4), wy / (s * 4), seed + 31));
          case 2: // Pine: interlocking plates
            final a = along(s * 0.6, s * 1.9, 37);
            final b = across(s * 0.5, s * 1.3, 41);
            final plate = math.min(_textureStep(0.34, 0.58, a), _textureStep(0.34, 0.58, b));
            final id = _textureNoise(wx / (s * 1.1), wy / (s * 0.8), seed + 43);
            h = plate;
            tone = 0.3 + plate * 0.3 + (id - 0.5) * 0.55;
          case 3: // Redwood: long stringy fibres
            final a = along(s * 0.35, s * 5.0, 47);
            final b = along(s * 0.14, s * 3.0, 53);
            final tear = across(s * 1.4, s * 1.0, 59);
            h = _textureStep(0.3, 0.7, a * 0.6 + b * 0.4);
            h *= 1 - 0.35 * (1 - _textureStep(0.2, 0.5, tear));
            tone = 0.25 + h * 0.5 + (b - 0.5) * 0.3;
          case 4: // Willow: crossing diagonal ridges
            final ra = streak(wx, wy, fx * cs - fy * sn, fx * sn + fy * cs, s * 0.5, s * 1.7, 61);
            final rb = streak(wx, wy, fx * cs + fy * sn, -fx * sn + fy * cs, s * 0.5, s * 1.7, 67);
            h = math.min(_textureStep(0.36, 0.6, ra), _textureStep(0.36, 0.6, rb));
            tone = 0.3 + h * 0.4 + (ra - rb) * 0.2;
          case 5: // Palm: stacked rings with hairy fibres
            final ring = across(s * 0.5, s * 7.0, 71);
            final hairs = along(s * 0.12, s * 1.6, 73);
            h = _textureStep(0.3, 0.75, ring) * 0.75 + hairs * 0.25;
            tone = 0.35 + h * 0.3 + (hairs - 0.5) * 0.5;
          case 6: // Cherry: satin copper, light horizontal lenticels
            final sat = across(s * 1.8, s * 3.0, 79);
            h = 0.7 + (sat - 0.5) * 0.2;
            tone = 0.55 + (sat - 0.5) * 0.5;
            final l = across(s * 0.28, s * 1.5, 83);
            lent = _textureStep(0.42, 0.32, l) * _textureStep(0.3, 0.5, _textureNoise(wx / (s * 4), wy / (s * 4), seed + 85));
          case 7: // Eucalyptus: patchwork of smooth stepped plates
            final m = along(s * 1.0, s * 2.6, 89) * 0.75 + _textureNoise(wx / (s * 1.4), wy / (s * 1.4), seed + 97) * 0.25;
            final band = m * 5;
            final id = band.floor();
            final fr = band - id;
            final idHash = _textureHash(id, 0, seed + 101);
            tone = idHash * 0.9 + 0.05;
            h = 0.6 + (idHash - 0.5) * 0.3;
            seam = _textureStep(0.14, 0.0, math.min(fr, 1 - fr));
        }

        // Generic fissures: thin level-set lines along the grain in cracked zones.
        final cr = along(s * 0.45, s * 3.4, 107);
        final line = _textureStep(0.015 + 0.05 * crackiness, 0.0, (cr - 0.5).abs());
        final zone = crackiness <= 0
            ? 0.0
            : _textureStep(
                0.9 - crackiness * 0.9, 1.0 - crackiness * 0.9,
                _textureFbm(wx / (s * 2), wy / (s * 2), seed + 109),
              );
        final fissure = line * zone * fissureWeight;
        final valley = math.pow(1 - h, 1.6).toDouble() * grooving * valleyWeight * 0.9;
        var crack = math.max(valley, math.max(fissure * 0.9, seam * (0.4 + 0.6 * grooving)));

        var flake = 0.0;
        if (peeling > 0) {
          final dx = peelAcross ? cx : fx, dy = peelAcross ? cy : fy;
          final cell = s * (peelAcross ? 1.0 : 0.9), len = s * (peelAcross ? 2.6 : 1.6);
          final thr = 1 - peeling * 0.42;
          final v = streak(wx, wy, dx, dy, cell, len, 113);
          flake = _textureStep(thr, thr + 0.05, v);
          final shadowed = _textureStep(thr, thr + 0.05, streak(wx + lx * 2.2, wy + ly * 2.2, dx, dy, cell, len, 113));
          castMap[i] = shadowed * (1 - flake);
          edgeMap[i] = flake * (1 - _textureStep(thr + 0.05, thr + 0.12, v));
          tone = peelAcross ? _textureMix(tone, 0.9, flake * 0.8) : tone + flake * 0.22;
          crack *= 1 - flake * 0.7;
        }

        heightMap[i] = ((h - 0.5) * (0.25 + 0.75 * grooving) + flake * 0.3 - crack * 0.15).toDouble();
        crackMap[i] = crack.clamp(0.0, 1.0);
        toneMap[i] = tone.clamp(0.0, 1.0);
        lentMap[i] = lent.clamp(0.0, 1.0);
      }
    }

    double heightAt(int x, int y, double fallback) {
      if (x < 0 || y < 0 || x >= width || y >= height) return fallback;
      final j = y * width + x;
      return inside[j] == 1 ? heightMap[j] : fallback;
    }

    double sampleLum(int sx, int sy, double fallback) {
      if (sx < 0 || sy < 0 || sx >= width || sy >= height) return fallback;
      final p = pixels[sy * width + sx];
      return (p >>> 24) == 0 ? fallback : _textureLuminance(p);
    }

    // Pass 2: compose colour and lighting.
    const sinE = 0.766, cosE = 0.643;
    final roundGain = 0.3 + 0.35 * depth;
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final i = y * width + x;
        if (inside[i] == 0) continue;
        final source = pixels[i];
        final alpha = source >>> 24;
        final px = x + 0.5, py = y + 0.5;

        var color = ramp(toneMap[i]);

        if (keepArtwork > 0 && alpha > 0) {
          final k = (_textureLuminance(color) / math.max(_textureLuminance(source), 0.08)).clamp(0.0, 4.0);
          int tc(int shift) => (_textureChannel(source, shift) * k).round().clamp(0, 255);
          final tinted = 0xFF000000 | (tc(16) << 16) | (tc(8) << 8) | tc(0);
          color = _textureBlendColor(color, tinted, keepArtwork * 0.7, 255);
        }

        if (lentMap[i] > 0) {
          color = _textureBlendColor(color, lenticelLight ? light : crevice, lentMap[i] * (lenticelLight ? 0.7 : 0.9), 255);
        }

        // Artwork carving: its edges become crevices and its tones emboss.
        var crack = crackMap[i];
        var artShade = 0.0;
        if (detailCarving > 0 && alpha > 0) {
          final lum = _textureLuminance(source);
          final gx = (sampleLum(x + 1, y, lum) - sampleLum(x - 1, y, lum)) * 0.5;
          final gy = (sampleLum(x, y + 1, lum) - sampleLum(x, y - 1, lum)) * 0.5;
          crack = math.max(crack, math.min(1.0, math.sqrt(gx * gx + gy * gy) * detailCarving * 3));
          artShade = detailCarving * ((lum - 0.5) * 0.45 - (gx * lx + gy * ly) * 1.5);
        }
        if (crack > 0) color = _textureBlendColor(color, crevice, crack * 0.9, 255);
        if (edgeMap[i] > 0) color = _textureBlendColor(color, crevice, edgeMap[i] * 0.55, 255);

        if (colorVariation > 0) {
          final v = (_textureNoise(px / (s * 2.5), py / (s * 2.5), seed + 89) - 0.5) * colorVariation * 0.6;
          color = v > 0
              ? _textureBlendColor(color, light, v.clamp(0.0, 1.0), 255)
              : _textureBlendColor(color, dark, (-v).clamp(0.0, 1.0), 255);
        }

        // Cylinder shading from the silhouette.
        final u = shape.rim[i];
        final nx = shape.normalX[i], ny = shape.normalY[i];
        var roundShade = 0.0;
        if (bevelWidth > 0) {
          final lambert = (nx * lx + ny * ly) * u * cosE + math.sqrt(math.max(0.0, 1 - u * u)) * sinE;
          roundShade = (lambert - 0.62) * roundGain;
        }

        if (mossAmount > 0) {
          final noise = _textureFbm(px / (s * 0.9), py / (s * 0.9), seed + 127);
          final shaded = math.max(0.0, -(nx * lx + ny * ly)) * u;
          final receptivity = (1 - toneMap[i]) * 0.3 + crack * 0.4 + shaded * 0.35;
          final mask = ((noise + receptivity * 0.45 - (1.05 - mossAmount * 0.9)) * 3).clamp(0.0, 1.0);
          if (mask > 0) {
            final tone = _textureBlendColor(_textureBlendColor(mossColor, 0xFF000000, 0.35, 255), mossColor, noise, 255);
            color = _textureBlendColor(color, tone, mask * 0.8, 255);
          }
        }

        if (weathering > 0) {
          final patch = 0.35 + 0.65 * _textureNoise(px / (s * 3), py / (s * 3), seed + 131);
          final ridge = (heightMap[i] * 2 + 0.6).clamp(0.2, 1.0);
          final luma = (_textureLuminance(color) * 255).round();
          final silver = _textureBlendColor(0xFF000000 | (luma << 16) | (luma << 8) | luma, light, 0.25, 255);
          color = _textureBlendColor(color, silver, weathering * 0.5 * patch * ridge, 255);
        }

        final hc = heightMap[i];
        final relief = -((heightAt(x + 1, y, hc) - heightAt(x - 1, y, hc)) * lx +
                (heightAt(x, y + 1, hc) - heightAt(x, y - 1, hc)) * ly) *
            depth *
            2.4;
        final micro = (_textureHash(x, y, seed + 79) - 0.5) * roughness * 0.3;
        final shade = (1.0 +
                relief.clamp(-0.6, 0.6) +
                roundShade +
                artShade -
                crack * 0.25 -
                castMap[i] * 0.3 +
                micro)
            .clamp(0.15, 1.8);

        int channel(int shift) => (_textureChannel(color, shift) * shade).round().clamp(0, 255);
        final textured = 0xFF000000 | (channel(16) << 16) | (channel(8) << 8) | channel(0);
        final outAlpha = preserve ? alpha : (alpha + (255 - alpha) * opacity).round();
        output[i] = _textureBlendColor(source, textured, opacity, outAlpha);
      }
    }
    return output;
  }
}

/// Per-pixel silhouette analysis (shared by shape-aware effects): grain
/// direction, outward normal, and rim factor.
class _SilhouetteShape {
  _SilhouetteShape(int n)
      : fiberX = Float32List(n),
        fiberY = Float32List(n),
        normalX = Float32List(n),
        normalY = Float32List(n),
        rim = Float32List(n),
        distance = Float32List(n);

  /// Unit vector along the limb axis (the grain direction).
  final Float32List fiberX, fiberY;

  /// Unit outward silhouette normal; zero away from edges.
  final Float32List normalX, normalY;

  /// 0 at the limb's center line, approaching 1 at its rim.
  final Float32List rim;

  /// Chamfer distance in pixels to the nearest transparent pixel (1 at edges).
  final Float32List distance;
}

_SilhouetteShape _silhouetteShape(Uint8List inside, int w, int h, double bevelWidth, double follow) {
  final n = w * h;
  final shape = _SilhouetteShape(n);

  // Chamfer distance to the nearest transparent pixel.
  final dist = Float32List(n);
  for (var i = 0; i < n; i++) {
    dist[i] = inside[i] == 1 ? 1e6 : 0;
  }
  const diag = 1.4142;
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final i = y * w + x;
      if (inside[i] == 0) continue;
      var v = dist[i];
      if (x > 0) v = math.min(v, dist[i - 1] + 1);
      if (y > 0) {
        v = math.min(v, dist[i - w] + 1);
        if (x > 0) v = math.min(v, dist[i - w - 1] + diag);
        if (x + 1 < w) v = math.min(v, dist[i - w + 1] + diag);
      }
      dist[i] = v;
    }
  }
  for (var y = h - 1; y >= 0; y--) {
    for (var x = w - 1; x >= 0; x--) {
      final i = y * w + x;
      if (inside[i] == 0) continue;
      var v = dist[i];
      if (x + 1 < w) v = math.min(v, dist[i + 1] + 1);
      if (y + 1 < h) {
        v = math.min(v, dist[i + w] + 1);
        if (x > 0) v = math.min(v, dist[i + w - 1] + diag);
        if (x + 1 < w) v = math.min(v, dist[i + w + 1] + diag);
      }
      dist[i] = v;
    }
  }

  shape.distance.setAll(0, dist);

  // Rim factor relative to local limb half-width.
  final rimRadius = bevelWidth * 2.0;
  if (rimRadius > 0) {
    final limited = Float32List(n);
    for (var i = 0; i < n; i++) {
      limited[i] = math.min(dist[i], rimRadius);
    }
    final halfWidth = _silhouetteMax(limited, w, h, rimRadius.ceil().clamp(1, 16));
    for (var i = 0; i < n; i++) {
      if (inside[i] == 0) continue;
      final t = ((dist[i] - 0.5) / math.max(halfWidth[i], 1.0)).clamp(0.0, 1.0);
      shape.rim[i] = 1 - t;
    }
  }

  // Grain direction from the smoothed gradient's structure tensor. Only the
  // first ~10px from an edge carry a gradient, so open areas default to vertical.
  final capped = Float32List(n);
  for (var i = 0; i < n; i++) {
    capped[i] = inside[i] == 1 ? math.min(dist[i], 10.0) : 0;
  }
  final smooth = _silhouetteBlur(capped, w, h, 1);
  double at(int x, int y) => smooth[y.clamp(0, h - 1) * w + x.clamp(0, w - 1)];
  final ta = Float32List(n), tb = Float32List(n);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final i = y * w + x;
      if (inside[i] == 0) continue;
      final gx = at(x + 1, y) - at(x - 1, y);
      final gy = at(x, y + 1) - at(x, y - 1);
      final len = math.sqrt(gx * gx + gy * gy);
      if (len < 0.05) continue;
      final ux = gx / len, uy = gy / len;
      ta[i] = ux * ux - uy * uy;
      tb[i] = 2 * ux * uy;
      shape.normalX[i] = -ux;
      shape.normalY[i] = -uy;
    }
  }
  final blurA = _silhouetteBlur(ta, w, h, 4);
  final blurB = _silhouetteBlur(tb, w, h, 4);
  final prior = 0.05 + (1 - follow) * (1 - follow) * 6.0;
  for (var i = 0; i < n; i++) {
    if (inside[i] == 0) continue;
    final alpha = 0.5 * math.atan2(blurB[i], blurA[i] + prior);
    shape.fiberX[i] = -math.sin(alpha);
    shape.fiberY[i] = math.cos(alpha);
  }
  return shape;
}

Float32List _silhouetteBlur(Float32List src, int w, int h, int r) => _silhouetteBox(src, w, h, r, false);

Float32List _silhouetteMax(Float32List src, int w, int h, int r) => _silhouetteBox(src, w, h, r, true);

/// Separable box average (or maximum) with clamped edges.
Float32List _silhouetteBox(Float32List src, int w, int h, int r, bool useMax) {
  final tmp = Float32List(src.length), out = Float32List(src.length);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      var acc = useMax ? 0.0 : 0.0, cnt = 0;
      for (var k = -r; k <= r; k++) {
        final xx = x + k;
        if (xx < 0 || xx >= w) continue;
        final v = src[y * w + xx];
        acc = useMax ? math.max(acc, v) : acc + v;
        cnt++;
      }
      tmp[y * w + x] = useMax ? acc : acc / cnt;
    }
  }
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      var acc = 0.0, cnt = 0;
      for (var k = -r; k <= r; k++) {
        final yy = y + k;
        if (yy < 0 || yy >= h) continue;
        final v = tmp[yy * w + x];
        acc = useMax ? math.max(acc, v) : acc + v;
        cnt++;
      }
      out[y * w + x] = useMax ? acc : acc / cnt;
    }
  }
  return out;
}
