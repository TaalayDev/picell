part of 'tileset_generator.dart';

/// The shapes a layer can repeat. Each is a pure function of the wrapped tile
/// position, so every pattern is periodic over the tile and joins its neighbours.
enum TilesetPattern {
  solid('Solid', 'Flat fill, one color'),
  bricks('Bricks', 'Offset rows of blocks'),
  planks('Planks', 'Long boards with seams'),
  tiles('Tiles', 'Square slabs with grout'),
  diagonal('Diagonal stripes', 'Slanted bands'),
  cobble('Cobble', 'Rounded irregular stones'),
  scales('Scales', 'Overlapping fish scales'),
  mesh('Mesh', 'Crossed wire grid'),
  waves('Waves', 'Gentle flowing ripples'),
  dots('Dots', 'Evenly spaced studs'),
  cells('Cells', 'Organic puzzle pieces'),
  checker('Checker', 'Alternating squares');

  const TilesetPattern(this.label, this.description);
  final String label, description;
}

enum TilesetNoiseType {
  speckle('Speckle'),
  blotch('Blotch'),
  streak('Streak'),
  grain('Grain');

  const TilesetNoiseType(this.label);
  final String label;
}

/// Where a layer may draw. Areas that depend on neighbours only ever paint
/// inside the tile, away from the border shared with the next tile.
enum TilesetLayerArea {
  all('Everywhere'),
  interior('Interior'),
  border('Border'),
  top('Exposed top'),
  sides('Exposed sides');

  const TilesetLayerArea(this.label);
  final String label;
}

enum TilesetLayerBlend {
  replace('Replace', 'Paint over what is below'),
  dark('Only on dark', 'Paint only where the surface below is dark'),
  light('Only on light', 'Paint only where the surface below is light'),
  tint('Tint', 'Mix half-transparent with what is below');

  const TilesetLayerBlend(this.label, this.description);
  final String label, description;
}

/// Palette slots a pattern paints with: middle, dark, light and highlight.
class TilesetLayerColors {
  const TilesetLayerColors({this.mid = 5, this.dark = 6, this.light = 4, this.highlight = 7});
  final int mid, dark, light, highlight;

  TilesetLayerColors copyWith({int? mid, int? dark, int? light, int? highlight}) => TilesetLayerColors(
      mid: mid ?? this.mid,
      dark: dark ?? this.dark,
      light: light ?? this.light,
      highlight: highlight ?? this.highlight);

  int slotFor(int role) => switch (role) {
        1 => dark,
        2 => light,
        3 => highlight,
        _ => mid,
      };

  Map<String, dynamic> toJson() => {'m': mid, 'd': dark, 'l': light, 'h': highlight};
  factory TilesetLayerColors.fromJson(Map<String, dynamic> json) {
    int slot(String key, int fallback) {
      final value = json[key] ?? fallback;
      if (value is! int || value < 0 || value > 7) throw const FormatException('Invalid palette slot');
      return value;
    }

    return TilesetLayerColors(mid: slot('m', 5), dark: slot('d', 6), light: slot('l', 4), highlight: slot('h', 7));
  }

  @override
  bool operator ==(Object other) =>
      other is TilesetLayerColors &&
      other.mid == mid &&
      other.dark == dark &&
      other.light == light &&
      other.highlight == highlight;
  @override
  int get hashCode => Object.hash(mid, dark, light, highlight);
}

class TilesetNoise {
  const TilesetNoise(
      {this.type = TilesetNoiseType.speckle,
      this.scale = 4,
      this.strength = 0.5,
      this.threshold = 0.55,
      this.seed = 1});
  final TilesetNoiseType type;

  /// 1-16, in tile-16 pixels.
  final int scale;

  /// 0-1.
  final double strength, threshold;
  final int seed;

  TilesetNoise copyWith({TilesetNoiseType? type, int? scale, double? strength, double? threshold, int? seed}) =>
      TilesetNoise(
          type: type ?? this.type,
          scale: scale ?? this.scale,
          strength: strength ?? this.strength,
          threshold: threshold ?? this.threshold,
          seed: seed ?? this.seed);

  Map<String, dynamic> toJson() =>
      {'type': type.name, 'scale': scale, 'strength': strength, 'threshold': threshold, 'seed': seed};
  factory TilesetNoise.fromJson(Map<String, dynamic> json) {
    final type = TilesetNoiseType.values.where((t) => t.name == json['type']);
    final scale = json['scale'], strength = json['strength'], threshold = json['threshold'], seed = json['seed'];
    if (type.isEmpty ||
        scale is! int ||
        scale < 1 ||
        scale > 16 ||
        strength is! num ||
        strength < 0 ||
        strength > 1 ||
        threshold is! num ||
        threshold < 0 ||
        threshold > 1 ||
        seed is! int ||
        seed < 0 ||
        seed > 0x7fffffff) {
      throw const FormatException('Invalid noise');
    }
    return TilesetNoise(
        type: type.first, scale: scale, strength: strength.toDouble(), threshold: threshold.toDouble(), seed: seed);
  }

  @override
  bool operator ==(Object other) =>
      other is TilesetNoise &&
      other.type == type &&
      other.scale == scale &&
      other.strength == strength &&
      other.threshold == threshold &&
      other.seed == seed;
  @override
  int get hashCode => Object.hash(type, scale, strength, threshold, seed);
}

class TilesetLayer {
  const TilesetLayer(
      {this.pattern = TilesetPattern.solid,
      this.colors = const TilesetLayerColors(),
      this.noise,
      this.area = TilesetLayerArea.all,
      this.density = 1,
      this.blend = TilesetLayerBlend.replace,
      this.visible = true,
      this.invert = false,
      this.cell = 0,
      this.gap = 1});
  final TilesetPattern pattern;
  final TilesetLayerColors colors;
  final TilesetNoise? noise;
  final TilesetLayerArea area;

  /// Share of pixels allowed to draw, 0-1.
  final double density;
  final TilesetLayerBlend blend;
  final bool visible, invert;

  /// Pattern cell size: -1 smaller, 0 normal, 1 larger. Every step keeps the
  /// pattern periodic over the 16 px grid, so tiles still join.
  final int cell;

  /// Width in pixels (1-2) of the grout lines in bricks, planks and tiles.
  final int gap;

  TilesetLayer copyWith(
          {TilesetPattern? pattern,
          TilesetLayerColors? colors,
          Object? noise = _keep,
          TilesetLayerArea? area,
          double? density,
          TilesetLayerBlend? blend,
          bool? visible,
          bool? invert,
          int? cell,
          int? gap}) =>
      TilesetLayer(
          pattern: pattern ?? this.pattern,
          colors: colors ?? this.colors,
          noise: identical(noise, _keep) ? this.noise : noise as TilesetNoise?,
          area: area ?? this.area,
          density: density ?? this.density,
          blend: blend ?? this.blend,
          visible: visible ?? this.visible,
          invert: invert ?? this.invert,
          cell: cell ?? this.cell,
          gap: gap ?? this.gap);

  static const _keep = Object();

  Map<String, dynamic> toJson() => {
        'pattern': pattern.name,
        'colors': colors.toJson(),
        if (noise != null) 'noise': noise!.toJson(),
        'area': area.name,
        'density': density,
        'blend': blend.name,
        'visible': visible,
        'invert': invert,
        if (cell != 0) 'cell': cell,
        if (gap != 1) 'gap': gap,
      };
  factory TilesetLayer.fromJson(Map<String, dynamic> json) {
    T named<T extends Enum>(List<T> values, Object? name, String what) {
      for (final value in values) {
        if (value.name == name) return value;
      }
      throw FormatException('Unsupported layer $what');
    }

    final density = json['density'] ?? 1;
    if (density is! num || density < 0 || density > 1) throw const FormatException('Invalid layer density');
    final cell = json['cell'] ?? 0, gap = json['gap'] ?? 1;
    if (cell is! int || cell < -1 || cell > 1) throw const FormatException('Invalid layer cell size');
    if (gap is! int || gap < 1 || gap > 2) throw const FormatException('Invalid layer gap');
    return TilesetLayer(
        pattern: named(TilesetPattern.values, json['pattern'], 'pattern'),
        colors: TilesetLayerColors.fromJson((json['colors'] as Map?)?.cast<String, dynamic>() ?? const {}),
        noise: json['noise'] == null ? null : TilesetNoise.fromJson((json['noise'] as Map).cast<String, dynamic>()),
        area: named(TilesetLayerArea.values, json['area'] ?? 'all', 'area'),
        density: density.toDouble(),
        blend: named(TilesetLayerBlend.values, json['blend'] ?? 'replace', 'blend'),
        visible: json['visible'] as bool? ?? true,
        invert: json['invert'] as bool? ?? false,
        cell: cell,
        gap: gap);
  }

  @override
  bool operator ==(Object other) =>
      other is TilesetLayer &&
      other.pattern == pattern &&
      other.colors == colors &&
      other.noise == noise &&
      other.area == area &&
      other.density == density &&
      other.blend == blend &&
      other.visible == visible &&
      other.invert == invert &&
      other.cell == cell &&
      other.gap == gap;
  @override
  int get hashCode => Object.hash(pattern, colors, noise, area, density, blend, visible, invert, cell, gap);
}

const tilesetMaxLayers = 6;

bool _sameLayers(List<TilesetLayer> a, List<TilesetLayer> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// A surface built from stacked layers, bottom first. The first layer fills the
/// whole tile; later layers paint only where their pattern is not the plain
/// "middle" role, so they read as detail over the layers below.
class TilesetSurfaceSpec {
  TilesetSurfaceSpec({this.name = 'My surface', List<TilesetLayer>? layers})
      : layers = List.unmodifiable(layers ?? const [TilesetLayer()]) {
    if (this.layers.isEmpty || this.layers.length > tilesetMaxLayers || name.trim().isEmpty || name.length > 60) {
      throw ArgumentError('Invalid surface');
    }
  }
  final String name;
  final List<TilesetLayer> layers;

  TilesetSurfaceSpec copyWith({String? name, List<TilesetLayer>? layers}) =>
      TilesetSurfaceSpec(name: name ?? this.name, layers: layers ?? this.layers);

  Map<String, dynamic> toJson() => {'name': name, 'layers': layers.map((l) => l.toJson()).toList()};
  factory TilesetSurfaceSpec.fromJson(Map<String, dynamic> json) {
    final raw = json['layers'], name = json['name'];
    if (raw is! List || raw.isEmpty || raw.length > tilesetMaxLayers || name is! String) {
      throw const FormatException('Invalid surface');
    }
    return TilesetSurfaceSpec(
        name: name.trim().isEmpty ? 'My surface' : name,
        layers: [for (final layer in raw) TilesetLayer.fromJson((layer as Map).cast<String, dynamic>())]);
  }

  /// One pixel of this surface. Every input is either a wrapped tile coordinate
  /// or noise that ignores the tile and its variation on border pixels, so
  /// the result at a shared edge never depends on which tile is drawing it.
  int shade(MaterialPixel q) {
    var color = q.palette[layers.first.colors.mid];
    for (var index = 0; index < layers.length; index++) {
      final layer = layers[index];
      if (!layer.visible) continue;
      final base = index == 0;
      final role = _patternRole(layer, q);
      if (!base && role == 0) continue;
      if (!_inArea(layer, q)) continue;
      final salt = q.seed * 7919 + index * 7727 + 9;
      if (layer.density < 1 && tileHash(q.x, q.y, salt + q.variant) % 1000 >= (layer.density * 1000).round()) continue;
      var alpha = 1.0;
      if (!base) {
        final light = _luminance(color) >= 90;
        if (layer.blend == TilesetLayerBlend.dark && light) continue;
        if (layer.blend == TilesetLayerBlend.light && !light) continue;
        if (layer.blend == TilesetLayerBlend.tint) alpha = 0.55;
      }
      color = _mix(color, q.palette[layer.colors.slotFor(role)], alpha);
      final noise = layer.noise;
      if (noise != null) color = _applyNoise(noise, layer.colors, q, color, index);
    }
    return color;
  }

  /// The plain surface as an [size]x[size] image, for swatches and live
  /// previews. [variant] picks a tile variation; border pixels ignore it.
  Uint32List renderSample(List<int> palette, {int size = 16, int seed = 1, int variant = 0}) {
    final pixels = Uint32List(size * size), band = size ~/ 8;
    for (var y = 0; y < size; y++) {
      for (var x = 0; x < size; x++) {
        final hx = x == size - 1 ? 0 : x, hy = y == size - 1 ? 0 : y;
        final boundary = x < band || y < band || x >= size - band || y >= size - band;
        final extra = boundary ? 0 : variant * 193;
        pixels[y * size + x] = shade(MaterialPixel(
            x: hx,
            y: hy,
            size: size,
            noise: tileHash(hx, hy, seed + extra),
            density: 45,
            palette: palette,
            perspective: TilesetPerspective.topDown,
            seed: seed,
            variant: extra,
            boundary: boundary,
            col: x,
            row: y));
      }
    }
    return pixels;
  }

  /// Whether the layers below [index] leave light and dark pixels for a layer to sit on.
  ({bool light, bool dark}) toneBelow(List<int> palette, int index, {int size = 16}) {
    if (index <= 0) return (light: false, dark: false);
    final below = TilesetSurfaceSpec(name: name, layers: layers.sublist(0, index.clamp(1, layers.length)));
    var light = false, dark = false;
    for (final pixel in below.renderSample(palette, size: size)) {
      if (_luminance(pixel) >= 90) {
        light = true;
      } else {
        dark = true;
      }
    }
    return (light: light, dark: dark);
  }

  /// True when two variations of this surface agree on every shared border
  /// pixel and each border wraps onto its opposite side.
  bool isSeamless(List<int> palette, {int size = 16, int seed = 1}) {
    final a = renderSample(palette, size: size, seed: seed),
        b = renderSample(palette, size: size, seed: seed, variant: 1);
    for (var i = 0; i < size; i++) {
      if (a[i] != a[(size - 1) * size + i] || a[i * size] != a[i * size + size - 1]) return false;
      if (a[i] != b[i] || a[(size - 1) * size + i] != b[(size - 1) * size + i]) return false;
      if (a[i * size] != b[i * size] || a[i * size + size - 1] != b[i * size + size - 1]) return false;
    }
    return true;
  }

  bool _inArea(TilesetLayer layer, MaterialPixel q) {
    final band = q.band;
    final inside = switch (layer.area) {
      TilesetLayerArea.all => true,
      TilesetLayerArea.interior => !q.boundary,
      TilesetLayerArea.border => q.boundary,
      TilesetLayerArea.top => !q.boundary && q.mask & 1 == 0 && q.row < band * 3,
      TilesetLayerArea.sides =>
        !q.boundary && (q.mask & 8 == 0 && q.col < band * 3 || q.mask & 2 == 0 && q.col >= q.size - band * 3),
    };
    if (!layer.invert) return inside;
    // Neighbour-dependent areas may never touch the shared border.
    final dependsOnNeighbours = layer.area == TilesetLayerArea.top || layer.area == TilesetLayerArea.sides;
    return dependsOnNeighbours ? !q.boundary && !inside : !inside;
  }

  static int _luminance(int argb) =>
      (((argb >> 16) & 255) * 0.3 + ((argb >> 8) & 255) * 0.59 + (argb & 255) * 0.11).round();

  static int _mix(int below, int above, double alpha) {
    if (alpha >= 1) return 0xff000000 | (above & 0xffffff);
    int channel(int shift) =>
        (((below >> shift) & 255) * (1 - alpha) + ((above >> shift) & 255) * alpha).round().clamp(0, 255);
    return 0xff000000 | channel(16) << 16 | channel(8) << 8 | channel(0);
  }

  int _applyNoise(TilesetNoise noise, TilesetLayerColors colors, MaterialPixel q, int color, int index) {
    final seed = noise.seed * 131 + index, dark = q.palette[colors.dark], light = q.palette[colors.light];
    final pick = tileHash(q.x, q.y, seed + q.variant), second = tileHash(q.y, q.x, seed * 3 + q.variant);
    final strength = noise.strength;
    switch (noise.type) {
      case TilesetNoiseType.speckle:
        if (pick / 65521 < strength * 0.35) return _mix(color, second % 100 < 55 ? dark : light, 1);
      case TilesetNoiseType.grain:
        if (pick / 65521 < strength * 0.8) return _mix(color, second.isEven ? dark : light, 0.4);
      case TilesetNoiseType.streak:
        final length = (2 + noise.scale ~/ 2) * (q.size ~/ 16);
        final shift = tileHash(0, q.y, seed) % length, segment = (q.x + shift) ~/ length;
        final chance = (strength * 14 * length / 256).clamp(0.0, 1.0);
        final roll = tileHash(segment, q.y, seed * 5 + q.variant) / 65521;
        if (roll < chance) {
          return _mix(color, tileHash(segment, q.y, seed * 7) % 100 < 50 ? dark : light, 1);
        }
      case TilesetNoiseType.blotch:
        final cells = (16 / noise.scale).round().clamp(2, 16), cell = q.size / cells;
        final fx = q.x / cell, fy = q.y / cell, x0 = fx.floor(), y0 = fy.floor();
        double smooth(double t) => t * t * (3 - 2 * t);
        double lattice(int i, int j) => tileHash(i % cells, j % cells, seed) / 65521;
        final tx = smooth(fx - x0), ty = smooth(fy - y0);
        final value = (lattice(x0, y0) * (1 - tx) + lattice(x0 + 1, y0) * tx) * (1 - ty) +
            (lattice(x0, y0 + 1) * (1 - tx) + lattice(x0 + 1, y0 + 1) * tx) * ty;
        final roll = pick / 65521;
        if (value > noise.threshold && roll < 0.5 + strength * 0.5) return _mix(color, dark, 1);
        if (value < 1 - noise.threshold - 0.3 && roll < strength) return _mix(color, light, 1);
    }
    return color;
  }

  @override
  bool operator ==(Object other) =>
      other is TilesetSurfaceSpec && other.name == name && _sameLayers(other.layers, layers);
  @override
  int get hashCode => Object.hash(name, Object.hashAll(layers));
}

/// Role of a pattern pixel: 0 middle, 1 dark, 2 light, 3 highlight.
int _patternRole(TilesetLayer layer, MaterialPixel q) {
  var a = q.x * 16 ~/ q.size, y = q.y * 16 ~/ q.size;
  final cell = layer.cell, gap = layer.gap;
  if (cell > 0) {
    a ~/= 2;
    y ~/= 2;
  } else if (cell < 0) {
    a = a * 2 % 16;
    y = y * 2 % 16;
  }
  switch (layer.pattern) {
    case TilesetPattern.solid:
      return 0;
    case TilesetPattern.bricks:
      final u = (a + (y >> 2) % 2 * 4) % 8, v = y % 4;
      return v > 3 - gap || u > 7 - gap
          ? 1
          : v == 0
              ? 2
              : 0;
    case TilesetPattern.planks:
      final v = y % 4;
      if (v > 3 - gap) return 1;
      if (v == 0) return 2;
      return a == ((y >> 2) * 5 + 3) % 16 && v == 1 ? 1 : 0;
    case TilesetPattern.tiles:
      final u = a % 8, v = y % 8;
      if (u > 7 - gap || v > 7 - gap) return 1;
      if (u == 0 && v == 0) return 3;
      return u == 0 || v == 0 ? 2 : 0;
    case TilesetPattern.diagonal:
      final t = (a + y) % 8;
      return t == 0
          ? 2
          : t < 4
              ? 0
              : 1;
    case TilesetPattern.cobble:
      final (edge, shade) = _voronoi(4 - cell, 7, (q.x + 0.5) * 16 / q.size, (q.y + 0.5) * 16 / q.size);
      if (edge < 1.15) return 1;
      return shade > 0.7 ? 2 : 0;
    case TilesetPattern.scales:
      final u = (a + (y >> 2) % 2 * 4) % 8, v = y % 4;
      if (v == 3 && u > 1 && u < 6) return 1;
      if (v == 2 && (u == 1 || u == 6)) return 1;
      if (v == 1 && (u == 0 || u == 7)) return 1;
      return v == 0 && u > 1 && u < 6 ? 2 : 0;
    case TilesetPattern.mesh:
      final p = (a + y) % 4 == 0, r = ((a - y) % 4 + 4) % 4 == 0;
      return p && r
          ? 2
          : p || r
              ? 1
              : 0;
    case TilesetPattern.waves:
      final v = (y + (math.sin(a / 16 * math.pi * 4) * 1.5 + 0.5).floor() + 16) % 4;
      return v == 0
          ? 2
          : v == 1
              ? 1
              : 0;
    case TilesetPattern.dots:
      if (a % 4 == 1 && y % 4 == 1) return 2;
      return a % 4 == 2 && y % 4 == 2 ? 1 : 0;
    case TilesetPattern.cells:
      final (edge, shade) = _voronoi(3 - cell, 3, (q.x + 0.5) * 16 / q.size, (q.y + 0.5) * 16 / q.size);
      if (edge < 0.9) return 1;
      return shade > 0.5 ? 2 : 0;
    case TilesetPattern.checker:
      return ((a >> 2) + (y >> 2)) % 2 == 1 ? 1 : 0;
  }
}

final _voronoiPoints = <int, List<(double, double, double)>>{};

/// Distance gap between the nearest two feature points and the nearest one's
/// shade, on a 16x16 torus so the pattern repeats across tiles.
(double, double) _voronoi(int count, int seed, double x, double y) {
  final points = _voronoiPoints.putIfAbsent(count * 1000 + seed, () {
    final cell = 16 / count;
    double unit(int i, int salt) => tileHash(i, salt, seed * 53 + count) / 65521;
    return [
      for (var j = 0; j < count; j++)
        for (var i = 0; i < count; i++)
          (
            i * cell + cell / 2 + (unit(j * count + i, 1) - 0.5) * cell * 0.8,
            j * cell + cell / 2 + (unit(j * count + i, 2) - 0.5) * cell * 0.8,
            unit(j * count + i, 3)
          )
    ];
  });
  var first = 99.0, second = 99.0, shade = 0.0;
  for (final point in points) {
    for (var ox = -1; ox <= 1; ox++) {
      for (var oy = -1; oy <= 1; oy++) {
        final d = math.sqrt(math.pow(x - (point.$1 + ox * 16), 2) + math.pow(y - (point.$2 + oy * 16), 2));
        if (d < first) {
          second = first;
          first = d;
          shade = point.$3;
        } else if (d < second) {
          second = d;
        }
      }
    }
  }
  return (second - first, shade);
}
