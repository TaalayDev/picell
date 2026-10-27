import 'dart:typed_data';
import 'dart:math' as math;

/// Diagonals only affect topology when both adjoining cardinal cells exist.
/// Bits: N E S W NE SE SW NW. A set bit means connected terrain.
int normalizeTileMask(int mask) {
  mask &= 255;
  const corners = [(1, 2, 16), (2, 4, 32), (4, 8, 64), (8, 1, 128)];
  for (final (a, b, diagonal) in corners) {
    if (mask & a == 0 || mask & b == 0) mask &= ~diagonal;
  }
  return mask;
}

final platformMasks = List<int>.unmodifiable(
  {for (var m = 0; m < 256; m++) normalizeTileMask(m)}.toList()..sort(),
);

int tileMaskAt(List<int> cells, int columns, int rows, int x, int y) {
  bool solid(int dx, int dy) =>
      x + dx >= 0 && x + dx < columns && y + dy >= 0 && y + dy < rows && cells[(y + dy) * columns + x + dx] != 0;
  const offsets = [(0, -1), (1, 0), (0, 1), (-1, 0), (1, -1), (1, 1), (-1, 1), (-1, -1)];
  var mask = 0;
  for (var i = 0; i < offsets.length; i++) {
    if (solid(offsets[i].$1, offsets[i].$2)) mask |= 1 << i;
  }
  return normalizeTileMask(mask);
}

String tileGroup(int mask) {
  final count = [1, 2, 4, 8].where((b) => mask & b != 0).length;
  if (count == 4) return mask == 255 ? 'Fill' : 'Inner Corners';
  if (count == 3) return 'Edges';
  if (count == 2) return mask & 15 == 5 || mask & 15 == 10 ? 'Isolated Platforms' : 'Outer Corners';
  return count == 1 ? 'End Caps' : 'Isolated Platforms';
}

String platformTileName(int mask) {
  if (mask == 255) return 'Center fill';
  final exposed = <String>[
    if (mask & 1 == 0) 'top',
    if (mask & 2 == 0) 'right',
    if (mask & 4 == 0) 'bottom',
    if (mask & 8 == 0) 'left',
  ];
  if (exposed.length == 4) return 'Single block';
  if (exposed.length == 3) {
    final direction = mask & 1 != 0
        ? 'Bottom'
        : mask & 2 != 0
            ? 'Left'
            : mask & 4 != 0
                ? 'Top'
                : 'Right';
    return '$direction end cap';
  }
  if (mask & 15 == 10) return 'Horizontal strip';
  if (mask & 15 == 5) return 'Vertical strip';
  final inner = <String>[
    if (mask & 9 == 9 && mask & 128 == 0) 'top-left',
    if (mask & 3 == 3 && mask & 16 == 0) 'top-right',
    if (mask & 12 == 12 && mask & 64 == 0) 'bottom-left',
    if (mask & 6 == 6 && mask & 32 == 0) 'bottom-right',
  ];
  final outer = exposed.isEmpty ? '' : '${exposed.join('/')} ${exposed.length == 1 ? 'edge' : 'corner'}';
  return [if (outer.isNotEmpty) outer, if (inner.isNotEmpty) '${inner.join('/')} inner corner'].join(' + ');
}

const materialPalettes = <String, List<int>>{
  'Grass & Dirt': [0xff1c1420, 0xffb8f060, 0xff5cc04a, 0xff2f8a3c, 0xffa8693f, 0xff80482f, 0xff5a3224, 0xffcfa77a],
  'Snow & Ice': [0xff161d2e, 0xffffffff, 0xffd5ecff, 0xff8fb8e0, 0xff7f95c4, 0xff586c9c, 0xff3a4878, 0xffb6c9e8],
  'Desert Sand': [0xff2a1810, 0xfffff0b0, 0xfff0c870, 0xffc8944a, 0xffdcae66, 0xffb27c42, 0xff845428, 0xfff6dca0],
  'Mossy Cave Stone': [0xff14121a, 0xff8fd0b8, 0xff4f9a86, 0xff2e6560, 0xff9088a0, 0xff665e76, 0xff463f56, 0xffbdb4c8],
};

enum TilesetPerspective {
  side('side', 'Side View'),
  topDown('top', 'Top-Down'),
  isometric('iso', 'Isometric');

  const TilesetPerspective(this.id, this.label);
  final String id, label;
  static TilesetPerspective parse(String value) =>
      values.firstWhere((p) => p.id == value, orElse: () => throw const FormatException('Unsupported perspective'));
}

enum TilesetType {
  platforms('Platforms'),
  terrain('Terrain'),
  ground('Ground'),
  walls('Walls'),
  paths('Paths'),
  floors('Floors'),
  raisedBlocks('Raised Blocks');

  const TilesetType(this.label);
  final String label;
  static TilesetType parse(String value) =>
      values.firstWhere((t) => t.name == value, orElse: () => throw const FormatException('Unsupported tileset type'));
}

TilesetType defaultTilesetType(TilesetPerspective perspective) => switch (perspective) {
      TilesetPerspective.side => TilesetType.platforms,
      TilesetPerspective.topDown => TilesetType.terrain,
      TilesetPerspective.isometric => TilesetType.ground,
    };

List<TilesetType> supportedTilesetTypes(TilesetPerspective perspective) => switch (perspective) {
      TilesetPerspective.side => const [TilesetType.platforms, TilesetType.ground, TilesetType.walls],
      TilesetPerspective.topDown => const [
          TilesetType.terrain,
          TilesetType.paths,
          TilesetType.walls,
          TilesetType.floors
        ],
      TilesetPerspective.isometric => const [TilesetType.ground, TilesetType.raisedBlocks, TilesetType.walls],
    };

String tilesetTypeDescription(TilesetPerspective perspective, TilesetType type) => switch (type) {
      TilesetType.platforms => 'Grass caps and exposed platform sides.',
      TilesetType.ground => perspective == TilesetPerspective.isometric
          ? 'Diamond ground tiles on a 2:1 grid.'
          : 'Solid earth with continuous sediment layers.',
      TilesetType.terrain => 'Continuous terrain surfaces with boundary rims.',
      TilesetType.paths => 'Gravel paths with connected bends and junctions.',
      TilesetType.walls => perspective == TilesetPerspective.isometric
          ? 'Raised stone walls with shaded masonry faces.'
          : perspective == TilesetPerspective.side
              ? 'Staggered brick courses for vertical walls.'
              : 'Stone wall caps viewed from above.',
      TilesetType.floors => 'Tiled floors for rooms, corridors, and interiors.',
      TilesetType.raisedBlocks => 'Raised diamond blocks with exposed earth faces.',
    };

List<String> tilesetGroups(TilesetPerspective perspective, {TilesetType? type}) => [
      'Fill',
      'Edges',
      'Outer Corners',
      'Inner Corners',
      'End Caps',
      isolatedTileGroup(perspective, type ?? defaultTilesetType(perspective)),
    ];

String isolatedTileGroup(TilesetPerspective perspective, TilesetType type) => switch (type) {
      TilesetType.platforms => 'Isolated Platforms',
      TilesetType.terrain => 'Isolated Terrain',
      TilesetType.ground => 'Isolated Ground',
      TilesetType.paths => 'Isolated Paths',
      TilesetType.walls => 'Isolated Walls',
      TilesetType.floors => 'Isolated Floors',
      TilesetType.raisedBlocks => 'Isolated Blocks',
    };

class TilesetSettings {
  TilesetSettings(
      {this.perspective = TilesetPerspective.side,
      TilesetType? type,
      this.size = 16,
      this.seed = 48213,
      this.density = 45,
      this.variations = 4,
      this.material = 'Grass & Dirt',
      List<int>? palette})
      : type = type ?? defaultTilesetType(perspective),
        palette = List.unmodifiable(palette ?? materialPalettes[material] ?? materialPalettes.values.first) {
    if (!supportedTilesetTypes(perspective).contains(this.type)) {
      throw ArgumentError('Unsupported perspective and tileset type combination');
    }
    if (![16, 32, 48].contains(size) ||
        variations < 1 ||
        variations > 6 ||
        density < 0 ||
        density > 100 ||
        this.palette.length != 8 ||
        seed < 0 ||
        seed > 0x7fffffff) {
      throw ArgumentError('Invalid tileset settings');
    }
  }

  /// Size is the logical diamond height in isometric mode; sprites also
  /// include any vertical faces, separately from the grid's spacing.
  int get spriteWidth => perspective == TilesetPerspective.isometric ? size * 2 : size;
  int get elevation => perspective != TilesetPerspective.isometric
      ? 0
      : switch (type) {
          TilesetType.raisedBlocks => size ~/ 2,
          TilesetType.walls => size,
          _ => 0,
        };
  int get spriteHeight => size + elevation;
  final TilesetPerspective perspective;
  final TilesetType type;
  final int size, seed, density, variations;
  final String material;
  final List<int> palette;
  Map<String, dynamic> toJson() => {
        'perspective': perspective.id,
        'type': type.name,
        'size': size,
        'seed': seed,
        'density': density,
        'variations': variations,
        'material': material,
        'palette': palette
      };
  factory TilesetSettings.fromJson(Map<String, dynamic> json) => TilesetSettings(
      perspective: TilesetPerspective.parse(json['perspective'] as String? ?? 'side'),
      type: json['type'] == null ? null : TilesetType.parse(json['type'] as String),
      size: json['size'] as int,
      seed: json['seed'] as int,
      density: json['density'] as int,
      variations: json['variations'] as int,
      material: json['material'] as String,
      palette: (json['palette'] as List).cast<int>());
}

class GeneratedTile {
  GeneratedTile(
      {required this.mask, required this.variation, required this.pixels, this.revision = 0, this.protected = false});
  final int mask, variation, revision;
  final Uint32List pixels;
  final bool protected;
  String get id => '$mask:$variation';
  String get group => tileGroup(mask);
  String get name => platformTileName(mask);
  String groupFor(TilesetPerspective perspective, {TilesetType? type}) =>
      group == 'Isolated Platforms' ? isolatedTileGroup(perspective, type ?? defaultTilesetType(perspective)) : group;
  String nameFor(TilesetPerspective perspective, {TilesetType? type}) {
    final selectedType = type ?? defaultTilesetType(perspective);
    if (mask != 0 || selectedType == TilesetType.platforms) return name;
    return switch (selectedType) {
      TilesetType.terrain => 'Single terrain patch',
      TilesetType.paths => 'Single path tile',
      TilesetType.walls => 'Single wall block',
      TilesetType.floors => 'Single floor tile',
      TilesetType.ground => 'Single ground block',
      TilesetType.raisedBlocks => 'Single raised block',
      TilesetType.platforms => name,
    };
  }

  GeneratedTile copyWith({Uint32List? pixels, bool? protected}) => GeneratedTile(
      mask: mask,
      variation: variation,
      revision: revision,
      pixels: pixels ?? this.pixels,
      protected: protected ?? this.protected);
  Map<String, dynamic> toJson() =>
      {'mask': mask, 'variation': variation, 'revision': revision, 'protected': protected, 'pixels': pixels.toList()};
  factory GeneratedTile.fromJson(Map<String, dynamic> json, TilesetSettings settings) {
    final mask = json['mask'] as int, variation = json['variation'] as int;
    final pixels = (json['pixels'] as List).cast<int>();
    final revision = json['revision'] as int;
    if (!platformMasks.contains(mask) ||
        variation < 0 ||
        variation >= settings.variations ||
        pixels.length != settings.spriteWidth * settings.spriteHeight ||
        revision < 0) {
      throw const FormatException('Invalid tile');
    }
    return GeneratedTile(
        mask: mask,
        variation: variation,
        revision: revision,
        protected: json['protected'] as bool,
        pixels: Uint32List.fromList(pixels));
  }
}

/// Small bounded arithmetic keeps seed behavior identical on Dart VM and web.
int tileHash(int x, int y, int seed) {
  var h = (seed % 65521 + x * 131 + y * 977) % 65521;
  h = (h * 251 + 13849) % 65521;
  return (h * h + 17431) % 65521;
}

GeneratedTile generatePlatformTile(TilesetSettings s, int mask, int variation, {int revision = 0}) {
  if (s.perspective != TilesetPerspective.side ||
      s.type != TilesetType.platforms ||
      !platformMasks.contains(mask) ||
      variation < 0 ||
      variation >= s.variations) {
    throw ArgumentError('Unsupported tile identity');
  }
  final n = s.size, p = s.palette, pixels = Uint32List(s.size * s.size);
  final band = n ~/ 8;
  for (var y = 0; y < n; y++) {
    for (var x = 0; x < n; x++) {
      var distance = n;
      var top = n;
      if (mask & 1 == 0) {
        distance = y;
        top = y;
      }
      if (mask & 2 == 0 && n - 1 - x < distance) distance = n - 1 - x;
      if (mask & 4 == 0 && n - 1 - y < distance) distance = n - 1 - y;
      if (mask & 8 == 0 && x < distance) distance = x;
      // Round exposed convex corners, and carve concave diagonal notches.
      var transparent = false;
      for (final (a, b, diagonal, cx, cy) in [
        (1, 8, 128, x, y),
        (1, 2, 16, n - 1 - x, y),
        (4, 8, 64, x, n - 1 - y),
        (4, 2, 32, n - 1 - x, n - 1 - y),
      ]) {
        if (mask & a == 0 && mask & b == 0 && cx + cy < band) transparent = true;
        if (mask & a != 0 && mask & b != 0 && mask & diagonal == 0 && cx < band && cy < band) {
          distance = 0;
        }
      }
      if (transparent) continue;
      // A shared perimeter texture prevents variant-specific seam changes.
      final boundary = x < band || y < band || x >= n - band || y >= n - band;
      final noise = tileHash(x, y, s.seed + (boundary ? 0 : variation * 193 + revision * 997));
      var color = noise % 100 < s.density ~/ 3
          ? p[4]
          : noise % 100 > 100 - s.density ~/ 3
              ? p[6]
              : p[5];
      if (noise % 101 < s.density ~/ 12) color = p[7];
      if (top < band * 2) {
        color = top == 0
            ? p[0]
            : top == 1
                ? p[1]
                : p[2];
      }
      if (top == band * 2) color = p[3];
      if (distance == 0) color = p[0];
      pixels[y * n + x] = color;
    }
  }
  return GeneratedTile(mask: mask, variation: variation, revision: revision, pixels: pixels);
}

List<GeneratedTile> generatePlatformTileset(TilesetSettings settings) => [
      for (final mask in platformMasks)
        for (var v = 0; v < settings.variations; v++) generatePlatformTile(settings, mask, v),
    ];

/// Top-down terrain has one continuous surface, with a rim around exposed
/// cardinal and diagonal boundaries. No platform grass-cap/dirt-side shading.
GeneratedTile generateTerrainTile(TilesetSettings s, int mask, int variation, {int revision = 0}) {
  if (s.perspective != TilesetPerspective.topDown ||
      s.type != TilesetType.terrain ||
      !platformMasks.contains(mask) ||
      variation < 0 ||
      variation >= s.variations ||
      revision < 0) {
    throw ArgumentError('Unsupported terrain tile identity');
  }
  final n = s.size, band = n ~/ 8, p = s.palette;
  final pixels = Uint32List(n * n);
  for (var y = 0; y < n; y++) {
    for (var x = 0; x < n; x++) {
      var distance = n;
      if (mask & 1 == 0) distance = math.min(distance, y);
      if (mask & 2 == 0) distance = math.min(distance, n - 1 - x);
      if (mask & 4 == 0) distance = math.min(distance, n - 1 - y);
      if (mask & 8 == 0) distance = math.min(distance, x);
      var transparent = false;
      for (final (a, b, diagonal, cx, cy) in [
        (1, 8, 128, x, y),
        (1, 2, 16, n - 1 - x, y),
        (4, 8, 64, x, n - 1 - y),
        (4, 2, 32, n - 1 - x, n - 1 - y),
      ]) {
        if (mask & a == 0 && mask & b == 0 && cx + cy < band - 1) transparent = true;
        if (mask & diagonal == 0) {
          distance = math.min(distance, math.sqrt(cx * cx + cy * cy).floor());
        }
      }
      if (transparent) continue;
      // Opposite connected borders share periodic texture coordinates. Variants
      // and regeneration can only change the interior, not their shared rim.
      final boundary = x < band || y < band || x >= n - band || y >= n - band;
      final hx = x == n - 1 ? 0 : x, hy = y == n - 1 ? 0 : y;
      final noise = tileHash(hx, hy, s.seed + (boundary ? 0 : variation * 193 + revision * 997));
      var color = p[2];
      if (noise % 100 < s.density ~/ 3) color = p[3];
      if (noise % 101 > 100 - s.density ~/ 4) color = p[1];
      if (distance < band + 1) color = p[1];
      if (distance < band) color = p[3];
      if (distance == 0) color = p[0];
      pixels[y * n + x] = color;
    }
  }
  return GeneratedTile(mask: mask, variation: variation, revision: revision, pixels: pixels);
}

/// Earth strata, gravel, brick courses, wall caps and floor tiles share the
/// same topology, but each uses its own material pattern and edge treatment.
GeneratedTile _generateStructuredTile(TilesetSettings s, int mask, int variation, {int revision = 0}) {
  if (!platformMasks.contains(mask) || variation < 0 || variation >= s.variations || revision < 0) {
    throw ArgumentError('Unsupported structured tile identity');
  }
  final n = s.size, band = n ~/ 8, p = s.palette;
  final pixels = Uint32List(n * n);
  for (var y = 0; y < n; y++) {
    for (var x = 0; x < n; x++) {
      var distance = n;
      if (mask & 1 == 0) distance = math.min(distance, y);
      if (mask & 2 == 0) distance = math.min(distance, n - 1 - x);
      if (mask & 4 == 0) distance = math.min(distance, n - 1 - y);
      if (mask & 8 == 0) distance = math.min(distance, x);
      var transparent = false;
      for (final (a, b, diagonal, cx, cy) in [
        (1, 8, 128, x, y),
        (1, 2, 16, n - 1 - x, y),
        (4, 8, 64, x, n - 1 - y),
        (4, 2, 32, n - 1 - x, n - 1 - y),
      ]) {
        if (mask & a == 0 && mask & b == 0 && cx + cy < band - 1) transparent = true;
        if (mask & diagonal == 0) distance = math.min(distance, math.sqrt(cx * cx + cy * cy).floor());
      }
      if (transparent) continue;
      final boundary = x < band || y < band || x >= n - band || y >= n - band;
      final hx = x == n - 1 ? 0 : x, hy = y == n - 1 ? 0 : y;
      final noise = tileHash(hx, hy, s.seed + (boundary ? 0 : variation * 193 + revision * 997));
      int color;
      switch (s.type) {
        case TilesetType.ground:
          final stratum = (hy ~/ band + s.seed % 3) % 3;
          color = p[[5, 4, 6][stratum]];
          if (noise % 100 < s.density ~/ 4) color = p[5];
          if (noise % 101 < s.density ~/ 16) color = p[7];
        case TilesetType.paths:
          color = p[4];
          if (noise % 100 < s.density ~/ 3) color = p[5];
          if (noise % 101 > 100 - s.density ~/ 4) color = p[7];
          if (distance < band + 1) color = p[7];
        case TilesetType.walls:
          if (s.perspective == TilesetPerspective.side) {
            final course = hy ~/ (band * 2);
            final bx = (hx + (course.isOdd ? n ~/ 2 : 0)) % n;
            final by = hy % (band * 2);
            color = p[5];
            if (noise % 100 < s.density ~/ 3) color = p[4];
            if (by == 0 || bx == 0) {
              color = p[6];
            } else if (by == 1 || bx == 1) {
              color = p[7];
            }
          } else {
            final bx = hx % (band * 4), by = hy % (band * 4);
            color = p[7];
            if (noise % 100 < s.density ~/ 3) color = p[4];
            if (bx == 0 || by == 0) {
              color = p[6];
            } else if (bx == 1 || by == 1) {
              color = p[4];
            }
          }
        case TilesetType.floors:
          final row = hy ~/ (band * 4), col = hx ~/ (band * 4);
          color = p[(row + col).isEven ? 4 : 5];
          if (noise % 100 < s.density ~/ 3) color = p[7];
          if (hx % (band * 4) == 0 || hy % (band * 4) == 0) color = p[6];
        case TilesetType.raisedBlocks:
        case TilesetType.platforms:
        case TilesetType.terrain:
          throw ArgumentError('Use the specialized platform/terrain renderer');
      }
      if (distance < band) color = p[6];
      if (distance == 0) color = p[0];
      pixels[y * n + x] = color;
    }
  }
  return GeneratedTile(mask: mask, variation: variation, revision: revision, pixels: pixels);
}

GeneratedTile generateIsometricTile(TilesetSettings s, int mask, int variation, {int revision = 0}) {
  if (s.perspective != TilesetPerspective.isometric ||
      !platformMasks.contains(mask) ||
      variation < 0 ||
      variation >= s.variations ||
      revision < 0) {
    throw ArgumentError('Unsupported isometric tile');
  }
  final surface = TilesetSettings(
      perspective: TilesetPerspective.topDown,
      type: s.type == TilesetType.walls ? TilesetType.walls : TilesetType.terrain,
      size: s.size,
      seed: s.seed,
      density: s.density,
      variations: s.variations,
      material: s.material,
      palette: s.palette);
  final top = generateTilesetTile(surface, mask, variation, revision: revision);
  final n = s.size, width = s.spriteWidth, height = s.spriteHeight, depth = s.elevation;
  final pixels = Uint32List(width * height);
  // Draw only the south/east faces; connected neighbors suppress internal faces.
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final right = x >= n;
      if ((right ? mask & 2 : mask & 4) != 0) continue;
      final edgeY = right ? (3 * n - x - 0.5) / 2 : (n + x + 0.5) / 2;
      final faceY = y + 0.5 - edgeY;
      if (faceY < 0 || faceY >= depth) continue;
      final distance = math.min(math.min(faceY, depth - 1 - faceY), math.min(x, width - 1 - x));
      final noise = tileHash(x, faceY.floor(), s.seed + (distance < 2 ? 0 : variation * 193 + revision * 997));
      var color = s.palette[right ? 6 : 5];
      if (noise % 100 < s.density ~/ 4) color = s.palette[right ? 5 : 4];
      if (s.type == TilesetType.walls &&
          (faceY.floor() % (n ~/ 4) == 0 || (x + ((faceY.floor() ~/ (n ~/ 4)).isOdd ? n ~/ 4 : 0)) % (n ~/ 2) == 0)) {
        color = s.palette[0];
      }
      if (faceY >= depth - 1) color = s.palette[0];
      pixels[y * width + x] = color;
    }
  }
  for (var y = 0; y < n; y++) {
    for (var x = 0; x < width; x++) {
      final u = y + 0.5 + (x + 0.5 - n) / 2;
      final v = y + 0.5 - (x + 0.5 - n) / 2;
      if (u < 0 || v < 0 || u >= n || v >= n) continue;
      final color = top.pixels[v.floor() * n + u.floor()];
      if (color >> 24 != 0) pixels[y * width + x] = color;
    }
  }
  return GeneratedTile(mask: mask, variation: variation, revision: revision, pixels: pixels);
}

GeneratedTile generateTilesetTile(TilesetSettings settings, int mask, int variation, {int revision = 0}) {
  if (settings.perspective == TilesetPerspective.isometric) {
    return generateIsometricTile(settings, mask, variation, revision: revision);
  }
  return switch (settings.type) {
    TilesetType.platforms => generatePlatformTile(settings, mask, variation, revision: revision),
    TilesetType.terrain => generateTerrainTile(settings, mask, variation, revision: revision),
    _ => _generateStructuredTile(settings, mask, variation, revision: revision),
  };
}

List<GeneratedTile> generateTileset(TilesetSettings settings) => [
      for (final mask in platformMasks)
        for (var variation = 0; variation < settings.variations; variation++)
          generateTilesetTile(settings, mask, variation),
    ];

class TilesetDocument {
  TilesetDocument(
      {required this.name,
      required this.settings,
      required this.tiles,
      required this.cells,
      this.columns = 24,
      this.rows = 14});
  final String name;
  final TilesetSettings settings;
  final List<GeneratedTile> tiles;
  final List<int> cells;
  final int columns, rows;
  Map<String, dynamic> toJson() => {
        'version': settings.perspective == TilesetPerspective.isometric ? 3 : 2,
        'generatorVersion': 1,
        'perspective': settings.perspective.id,
        'type': settings.type.name,
        'name': name,
        'settings': settings.toJson(),
        'columns': columns,
        'rows': rows,
        'cells': cells,
        'tiles': tiles.map((t) => t.toJson()).toList()
      };
  factory TilesetDocument.fromJson(Map<String, dynamic> json) {
    if (![1, 2, 3].contains(json['version']) || json['generatorVersion'] != 1) {
      throw const FormatException('Unsupported tileset document');
    }
    final settings = TilesetSettings.fromJson(json['settings'] as Map<String, dynamic>);
    if (json['perspective'] != settings.perspective.id ||
        json['type'] != settings.type.name ||
        (json['version'] == 1 &&
            (settings.perspective != TilesetPerspective.side || settings.type != TilesetType.platforms))) {
      throw const FormatException('Conflicting tileset perspective/type metadata');
    }
    if (settings.perspective == TilesetPerspective.isometric && json['version'] != 3) {
      throw const FormatException('Isometric documents require version 3');
    }
    final columns = json['columns'] as int, rows = json['rows'] as int;
    final cells = (json['cells'] as List).cast<int>();
    final tiles =
        (json['tiles'] as List).map((t) => GeneratedTile.fromJson(t as Map<String, dynamic>, settings)).toList();
    if (columns < 1 ||
        rows < 1 ||
        columns > 128 ||
        rows > 128 ||
        cells.length != columns * rows ||
        cells.any((v) => v != 0 && v != 1) ||
        tiles.length != 47 * settings.variations ||
        tiles.map((t) => t.id).toSet().length != tiles.length) {
      throw const FormatException('Incomplete tileset document');
    }
    return TilesetDocument(
        name: json['name'] as String,
        settings: settings,
        tiles: tiles,
        cells: List.of(cells),
        columns: columns,
        rows: rows);
  }
}
