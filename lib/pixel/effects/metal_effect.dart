part of 'effects.dart';

/// Directional metal shading with seeded material wear and silhouette bevels.
/// The original parameter names and finish IDs remain valid in saved projects.
class MetalEffect extends Effect {
  MetalEffect([Map<String, dynamic>? params]) : super(EffectType.metal, {..._defaults, ...?params});

  static const finishOptions = <int, String>{
    0: 'Brushed',
    1: 'Polished',
    2: 'Rusted',
    3: 'Patinated',
    4: 'Hammered',
    5: 'Diamond Plate',
  };
  static const _defaults = <String, dynamic>{
    'metalType': 0,
    'reflectivity': 0.7,
    'scratchIntensity': 0.2,
    'color': 0xFFB6C4CE,
    'roughness': 0.3,
    'oxidation': 0.2,
    'anisotropy': 0.65,
    'lightDirection': 0.625,
    'grainDirection': 0.0,
    'scale': 16,
    'bevelWidth': 2.0,
    'bevelStrength': 0.5,
    'sourceDetail': 0.35,
    'shadeSteps': 8,
    'seed': 42,
    'opacity': 1.0,
    'preserveAlpha': true,
  };

  @override
  Map<String, dynamic> getDefaultParameters() => Map.of(_defaults);

  @override
  Map<String, dynamic> getMetadata() => {
        'metalType': <String, dynamic>{'label': 'Surface Finish', 'type': 'select', 'options': finishOptions},
        for (final spec in [
          ('reflectivity', 'Reflectivity', 0.0, 1.0),
          ('roughness', 'Surface Roughness', 0.0, 1.0),
          ('anisotropy', 'Directional Reflection', 0.0, 1.0),
          ('lightDirection', 'Light Direction (Turns)', 0.0, 1.0),
          ('grainDirection', 'Grain Direction', 0.0, 360.0),
          ('scale', 'Surface Detail Size', 4, 64),
          ('scratchIntensity', 'Scratches', 0.0, 1.0),
          ('oxidation', 'Oxidation Coverage', 0.0, 1.0),
          ('bevelWidth', 'Silhouette Bevel Width', 0.0, 6.0),
          ('bevelStrength', 'Silhouette Bevel Strength', 0.0, 1.0),
          ('sourceDetail', 'Original Artwork Detail', 0.0, 1.0),
          ('shadeSteps', 'Shading Levels', 2, 24),
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
        'color': <String, dynamic>{'label': 'Metal Color', 'type': 'color'},
        'preserveAlpha': <String, dynamic>{
          'label': 'Preserve Alpha',
          'type': 'bool',
          'description': 'Keep the artwork silhouette; disable to fill the canvas.'
        },
      };

  double _number(String key, double min, double max) {
    final value = (parameters[key] as num?)?.toDouble();
    return (value != null && value.isFinite ? value : (_defaults[key] as num).toDouble()).clamp(min, max);
  }

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    final result = Uint32List.fromList(pixels);
    if (width <= 0 || height <= 0) return result;
    final opacity = _number('opacity', 0, 1);
    if (opacity == 0) return result;
    final finish = _number('metalType', 0, 5).round();
    final reflectivity = _number('reflectivity', 0, 1);
    final roughness = _number('roughness', 0, 1);
    final anisotropy = _number('anisotropy', 0, 1);
    final scratches = _number('scratchIntensity', 0, 1);
    final oxidation = _number('oxidation', 0, 1);
    final scale = _number('scale', 4, 64);
    final light = _number('lightDirection', 0, 1) * math.pi * 2;
    final lx = math.cos(light), ly = math.sin(light);
    final grainAngle = _number('grainDirection', 0, 360) * math.pi / 180;
    final gc = math.cos(grainAngle), gs = math.sin(grainAngle);
    final bevel = _number('bevelWidth', 0, 6);
    final bevelStrength = _number('bevelStrength', 0, 1);
    final sourceDetail = _number('sourceDetail', 0, 1);
    final steps = _number('shadeSteps', 2, 24).round();
    final seed = _number('seed', 0, 9999).round();
    final color = (parameters['color'] as num).toInt();
    final preserve = parameters['preserveAlpha'] != false;

    // Capped distance transform of the original silhouette (including holes).
    // Linear cost avoids scanning a large neighborhood for each bevel pixel.
    final distances = Uint8List(width * height);
    if (bevel > 0 && bevelStrength > 0) {
      for (var y = 0; y < height; y++) {
        for (var x = 0; x < width; x++) {
          final i = y * width + x;
          if (pixels[i] >>> 24 == 0) continue;
          var d = x == 0 || y == 0 || x == width - 1 || y == height - 1 ? 1 : 8;
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
          if (pixels[i] >>> 24 == 0) continue;
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
        x < 0 || y < 0 || x >= width || y >= height ? 0 : distances[y * width + x].toDouble();

    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final i = y * width + x, source = pixels[y * width + x];
        final alpha = source >>> 24;
        if (preserve && alpha == 0) continue;
        final u = (x + 0.5) * gc + (y + 0.5) * gs;
        final v = -(x + 0.5) * gs + (y + 0.5) * gc;
        final grain = _textureNoise(u / (scale * (1 + anisotropy * 8)), v * 0.8, seed);
        final micro = _textureHash(x, y, seed + 13) - 0.5;
        final projection = ((x + 0.5) * lx + (y + 0.5) * ly) / (scale * 2);
        final band = math.cos(projection * math.pi * 2);
        // Rough metal spreads the highlight; polished metal has narrow bright
        // reflections alternating with dark environment bands.
        final exponent = 2 + (1 - roughness) * (finish == 1 ? 30 : 12);
        final highlight = math.pow(math.max(band, 0.0), exponent).toDouble();
        var shade = 0.64 + reflectivity * (highlight * (0.9 - roughness * 0.35) + band * 0.16);
        shade += micro * roughness * 0.14;
        if (finish == 0) shade += (grain - 0.5) * (0.12 + anisotropy * 0.38);
        if (finish == 1) shade += (grain - 0.5) * anisotropy * roughness * 0.08;
        if (finish == 4) {
          // Each hammer mark is a seeded shallow bowl with a directional rim.
          final px = u / scale * 3, py = v / scale * 3;
          final cx = px.floor(), cy = py.floor();
          var nearest = double.infinity, nx = 0.0, ny = 0.0;
          for (var oy = -1; oy <= 1; oy++) {
            for (var ox = -1; ox <= 1; ox++) {
              final dx = px - (cx + ox + 0.5 + (_textureHash(cx + ox, cy + oy, seed + 41) - 0.5) * 0.5);
              final dy = py - (cy + oy + 0.5 + (_textureHash(cx + ox, cy + oy, seed + 43) - 0.5) * 0.5);
              final d = dx * dx + dy * dy;
              if (d < nearest) {
                nearest = d;
                nx = dx;
                ny = dy;
              }
            }
          }
          shade += ((nx * gc - ny * gs) * lx + (nx * gs + ny * gc) * ly) * 0.75;
          shade -= math.max(0.0, 1 - math.sqrt(nearest) * 2) * 0.1;
        }
        if (finish == 5) {
          final tx = u / scale, ty = v / scale;
          final a = tx - tx.floor() - 0.5, b = ty - ty.floor() - 0.5;
          final sign = (tx.floor() + ty.floor()).isEven ? 1.0 : -1.0;
          final along = (a + b * sign) * 0.7071;
          final across = (a - b * sign) * 0.7071;
          if (along.abs() < 0.36 && across.abs() < 0.1) {
            final normalLight = ((gc + sign * gs) * lx + (gs - sign * gc) * ly) * 0.7071;
            shade += 0.15 + (across < 0 ? -normalLight : normalLight) * 0.4;
          }
        }
        // Sparse elongated cuts, stable under masking and canvas-size changes.
        final scratchNoise = _textureNoise(u / scale * 0.6, v * 1.7, seed + 59);
        if (scratches > 0 && scratchNoise > 1 - scratches * 0.35) {
          shade += (grain > 0.5 ? 0.22 : -0.28) * scratches;
        }
        if (alpha > 0) shade += (_textureLuminance(source) - 0.5) * sourceDetail * 0.65;
        if (bevel > 0 && bevelStrength > 0 && alpha > 0 && distances[i] <= bevel) {
          final nx = distanceAt(x - 1, y) - distanceAt(x + 1, y);
          final ny = distanceAt(x, y - 1) - distanceAt(x, y + 1);
          final length = math.sqrt(nx * nx + ny * ny);
          if (length > 0) {
            shade += (nx * lx + ny * ly) / length * bevelStrength * (1 - (distances[i] - 1) / bevel) * 0.65;
          }
        }
        shade = (shade.clamp(0.12, 1.6) * (steps - 1)).round() / (steps - 1);
        int channel(int shift) => (_textureChannel(color, shift) * shade).round().clamp(0, 255);
        var metal = 0xFF000000 | channel(16) << 16 | channel(8) << 8 | channel(0);
        if (oxidation > 0) {
          final patch = _textureFbm(x / scale * 1.4, y / scale * 1.4, seed + 83);
          final threshold = (1 - oxidation) * (finish == 2 || finish == 3 ? 0.78 : 1.0);
          final coverage = ((patch - threshold) * 5).clamp(0.0, 1.0);
          final corrosion = finish == 3 ? 0xFF4B9984 : 0xFFA05A2E;
          final dark = finish == 3 ? 0xFF284E48 : 0xFF4A2D20;
          final rust = _textureBlendColor(dark, corrosion, (0.4 + patch * 0.6 + micro * 0.2), 255);
          metal = _textureBlendColor(metal, rust, coverage * (finish == 2 || finish == 3 ? 1.0 : 0.7), 255);
        }
        final outAlpha = preserve ? alpha : (alpha + (255 - alpha) * opacity).round();
        result[i] = _textureBlendColor(source, metal, opacity, outAlpha);
      }
    }
    return result;
  }
}
