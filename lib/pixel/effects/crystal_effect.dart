part of 'effects.dart';

/// Seeded interlocking crystal cells with planar faces and directional optics.
/// Legacy optical parameter names remain readable by saved effect stacks.
class CrystalEffect extends Effect {
  CrystalEffect([Map<String, dynamic>? params]) : super(EffectType.crystal, {..._defaults, ...?params});

  static const _defaults = <String, dynamic>{
    'scale': 16,
    'growth': 1.6,
    'direction': 0.0,
    'facets': 6,
    'irregularity': 0.75,
    'facetContrast': 0.65,
    'edgeWidth': 0.65,
    'lightAngle': 225.0,
    'refraction': 0.35,
    'clarity': 0.35,
    'color': 0xFF88DDFF,
    'innerGlow': 0.25,
    'surfaceReflection': 0.6,
    'prismEffect': 0.25,
    'seed': 42,
    'opacity': 1.0,
    'preserveAlpha': true,
  };

  @override
  Map<String, dynamic> getDefaultParameters() => Map.of(_defaults);

  @override
  Map<String, dynamic> getMetadata() => {
        for (final spec in [
          ('scale', 'Crystal Size', 4, 64),
          ('growth', 'Crystal Elongation', 0.5, 4.0),
          ('direction', 'Growth Direction', 0.0, 360.0),
          ('facets', 'Faces per Crystal', 3, 12),
          ('irregularity', 'Growth Irregularity', 0.0, 1.0),
          ('facetContrast', 'Facet Contrast', 0.0, 1.0),
          ('edgeWidth', 'Crystal Seams', 0.0, 3.0),
          ('lightAngle', 'Light Direction', 0.0, 360.0),
          ('refraction', 'Artwork Refraction', 0.0, 1.0),
          ('clarity', 'Artwork Visibility', 0.0, 1.0),
          ('innerGlow', 'Inner Glow', 0.0, 1.0),
          ('surfaceReflection', 'Surface Reflection', 0.0, 1.0),
          ('prismEffect', 'Prismatic Color', 0.0, 1.0),
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
        'color': <String, dynamic>{'label': 'Crystal Color', 'type': 'color'},
        'preserveAlpha': <String, dynamic>{
          'label': 'Preserve Alpha',
          'type': 'bool',
          'description': 'Texture the complete artwork silhouette; disable to fill the canvas.'
        },
      };

  double _number(String key, double min, double max) {
    final value = (parameters[key] as num?)?.toDouble();
    return (value != null && value.isFinite ? value : (_defaults[key] as num).toDouble()).clamp(min, max);
  }

  @override
  Uint32List apply(Uint32List pixels, int width, int height) {
    final output = Uint32List.fromList(pixels);
    if (width <= 0 || height <= 0) return output;
    final opacity = _number('opacity', 0, 1);
    if (opacity == 0) return output;
    final size = _number('scale', 4, 64);
    final growth = _number('growth', 0.5, 4);
    final direction = _number('direction', 0, 360) * math.pi / 180;
    final cs = math.cos(direction), sn = math.sin(direction);
    final facets = _number('facets', 3, 12).round();
    final jitter = _number('irregularity', 0, 1) * 0.35;
    final contrast = _number('facetContrast', 0, 1);
    final seam = _number('edgeWidth', 0, 3);
    final light = _number('lightAngle', 0, 360) * math.pi / 180;
    final refraction = _number('refraction', 0, 1);
    final clarity = _number('clarity', 0, 1);
    final glow = _number('innerGlow', 0, 1);
    final reflection = _number('surfaceReflection', 0, 1);
    final prism = _number('prismEffect', 0, 1);
    final seed = _number('seed', 0, 9999).round();
    final tint = (parameters['color'] as num).toInt();
    final preserve = parameters['preserveAlpha'] != false;
    final sector = math.pi * 2 / facets;

    // Cache cell neighborhoods rather than allocate or hash sites per pixel.
    // Unbounded integer coordinates also support rotated, narrow canvases.
    final neighborhoods = <(int, int), List<({double x, double y, double phase, double tone})>>{};
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final i = y * width + x, source = pixels[y * width + x];
        final alpha = source >>> 24;
        if (preserve && alpha == 0) continue;
        final px = ((x + 0.5) * cs + (y + 0.5) * sn) / growth;
        final py = -(x + 0.5) * sn + (y + 0.5) * cs;
        final gx = (px / size).floor(), gy = (py / size).floor();
        final sites = neighborhoods.putIfAbsent(
            (gx, gy),
            () => [
                  for (var oy = -2; oy <= 2; oy++)
                    for (var ox = -2; ox <= 2; ox++)
                      (
                        x: (gx + ox + 0.5 + (_textureHash(gx + ox, gy + oy, seed) * 2 - 1) * jitter) * size,
                        y: (gy + oy + 0.5 + (_textureHash(gx + ox, gy + oy, seed + 11) * 2 - 1) * jitter) * size,
                        phase: _textureHash(gx + ox, gy + oy, seed + 23) * math.pi * 2,
                        tone: _textureHash(gx + ox, gy + oy, seed + 37),
                      ),
                ]);
        var winner = 0, nearest = double.infinity;
        for (var j = 0; j < sites.length; j++) {
          final dx = px - sites[j].x, dy = py - sites[j].y;
          final distance = dx * dx + dy * dy;
          if (distance < nearest) {
            nearest = distance;
            winner = j;
          }
        }
        final center = sites[winner];
        var edge = double.infinity;
        for (var j = 0; j < sites.length; j++) {
          if (j == winner) continue;
          final dx = sites[j].x - center.x, dy = sites[j].y - center.y;
          // Transform the bisector normal back to canvas units so seam width
          // stays consistent when crystals are stretched or rotated.
          final normalLength = math.sqrt(dx * dx / (growth * growth) + dy * dy);
          final distance =
              (((sites[j].x + center.x) / 2 - px) * dx + ((sites[j].y + center.y) / 2 - py) * dy) / normalLength;
          edge = math.min(edge, distance);
        }
        final dx = px - center.x, dy = py - center.y;
        final faceAngle = ((math.atan2(dy, dx) - center.phase) / sector).floor() * sector + sector / 2 + center.phase;
        // A constant normal per sector gives real flat faces, not soft radial stripes.
        final localX = math.cos(faceAngle) / growth, localY = math.sin(faceAngle);
        final length = math.sqrt(localX * localX + localY * localY);
        final nx = (localX * cs - localY * sn) / length;
        final ny = (localX * sn + localY * cs) / length;
        final diffuse = nx * math.cos(light) + ny * math.sin(light);
        final radius = math.sqrt(nearest) / size;
        final core = (1 - radius * 1.5).clamp(0.0, 1.0);
        var shade = 0.75 + diffuse * contrast * 0.45 + (center.tone - 0.5) * contrast * 0.18;
        shade += glow * core * 0.35;
        final specular = math.pow(math.max(diffuse, 0.0), 12).toDouble() * reflection;
        final seamShade = edge < seam ? 0.4 : 1.0;
        int channel(int shift) {
          final dispersion = (math.sin(faceAngle + center.phase + shift * 0.13) * 0.5 + 0.5) * prism;
          final base = _textureChannel(tint, shift);
          return ((base * shade + dispersion * 65 + specular * 100) * seamShade).round().clamp(0, 255);
        }

        var crystal = 0xFF000000 | channel(16) << 16 | channel(8) << 8 | channel(0);
        if (clarity > 0 && alpha > 0) {
          final sx = (x + nx * refraction * size * 0.3).round().clamp(0, width - 1);
          final sy = (y + ny * refraction * size * 0.3).round().clamp(0, height - 1);
          final sampled = pixels[sy * width + sx];
          // Transparent neighbors must never introduce dark halos or change alpha.
          final artwork = _textureBlendColor(source, sampled, (sampled >>> 24) / 255, 255);
          crystal = _textureBlendColor(crystal, artwork, clarity * 0.75, 255);
        }
        final outAlpha = preserve ? alpha : (alpha + (255 - alpha) * opacity).round();
        output[i] = _textureBlendColor(source, crystal, opacity, outAlpha);
      }
    }
    return output;
  }
}
