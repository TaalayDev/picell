part of 'tileset_generator.dart';

/// How materials are grouped in pickers. Categories are added with the materials that need them.
enum TilesetMaterialCategory {
  earth('Earth'),
  road('Road'),
  liquid('Liquid'),
  dungeon('Dungeon'),
  tech('Tech'),
  roof('Roof'),
  fabric('Fabric'),
  stone('Stone'),
  tile('Tile'),
  wood('Wood'),
  custom('Custom');

  const TilesetMaterialCategory(this.label);
  final String label;
}

/// Everything a surface texture may read for one pixel.
///
/// Neighbouring tiles share their edge pixels, so a texture must be a pure
/// function of this value. [x] and [y] are wrapped (the last row and column equal
/// the first) and edge pixels receive a [noise] value that does not depend on the
/// tile or its variation. Staying inside that contract is what keeps every
/// connection seamless; the registry test checks it for every material.
class MaterialPixel {
  const MaterialPixel(
      {required this.x,
      required this.y,
      required this.size,
      required this.noise,
      required this.density,
      required this.palette,
      required this.perspective,
      this.seed = 0,
      this.variant = 0,
      this.boundary = false,
      this.col = 0,
      this.row = 0,
      this.mask = 255});
  final int x, y, size, noise, density;

  /// Set seed, tile variation (0 on border pixels), and the pixel's unwrapped
  /// position and connection mask. Only layered surfaces read these; they keep
  /// to the seam rules by never letting neighbour data reach border pixels.
  final int seed, variant, col, row, mask;
  final bool boundary;
  final List<int> palette;
  final TilesetPerspective perspective;

  /// Width of the border region shared with neighbouring tiles.
  int get band => size ~/ 8;
}

typedef MaterialShader = int Function(MaterialPixel pixel);

/// A surface a set can be made of. Add a material by declaring it in
/// [TilesetMaterials] and listing it in [TilesetMaterials.all]; the registry
/// tests then cover it for every base, perspective and tile size it supports.
class TilesetMaterial {
  const TilesetMaterial(
      {required this.id,
      required this.label,
      required this.category,
      required this.bases,
      required this.shade,
      this.primaryFor = const {},
      this.palettePreset = 'Grass & Dirt',
      this.faceMortar = false,
      this.spec});

  /// Stable key stored in documents. Never change one that has shipped.
  final String id, label;
  final TilesetMaterialCategory category;
  final Set<TilesetBase> bases;

  /// Bases for which this is the first material offered.
  final Set<TilesetBase> primaryFor;

  /// Entry of [materialPalettes] suggested when a new set picks this material.
  final String palettePreset;

  /// Isometric side faces show mortar lines.
  final bool faceMortar;
  final MaterialShader shade;

  /// Set for surfaces the user built from layers; see [TilesetMaterial.custom].
  final TilesetSurfaceSpec? spec;

  /// A user-built surface. It can build every base and takes its colours from the set palette.
  factory TilesetMaterial.custom(TilesetSurfaceSpec spec) => TilesetMaterial(
      id: 'custom',
      label: spec.name,
      category: TilesetMaterialCategory.custom,
      bases: TilesetBase.values.toSet(),
      shade: spec.shade,
      spec: spec);

  bool supports(TilesetBase base) => bases.contains(base);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || spec != null && other is TilesetMaterial && other.spec == spec;
  @override
  int get hashCode => spec?.hashCode ?? identityHashCode(this);
}

int _shadeEarth(MaterialPixel q) => q.palette[q.noise % 100 < q.density ~/ 3
    ? 4
    : q.noise % 101 < q.density ~/ 12
        ? 7
        : 5];

int _shadeStone(MaterialPixel q) => q.palette[q.noise % 11 == 0
    ? 7
    : q.noise % 4 == 0
        ? 4
        : 5];

int _shadeSand(MaterialPixel q) => q.palette[q.noise % 8 == 0 ? 4 : 7];

/// Short blades: a mid green field with lighter tips and darker roots.
int _shadeGrass(MaterialPixel q) => q.palette[q.noise % 7 == 0
    ? 1
    : q.x % 3 == 0 && q.noise % 4 == 0
        ? 3
        : q.noise % 5 == 0
            ? 3
            : 2];

/// Mostly white with cool shadow flecks and rare sparkles.
int _shadeSnow(MaterialPixel q) => q.palette[q.noise % 41 == 0
    ? 7
    : q.noise % 9 == 0
        ? 3
        : q.noise % 4 == 0
            ? 2
            : 1];

/// Smooth, smeared horizontal layers with rare cracks and wet highlights.
int _shadeClay(MaterialPixel q) => q.palette[q.noise % 23 == 0
    ? 6
    : q.noise % 31 == 0
        ? 7
        : (q.y + q.noise % 3) % 5 == 0
            ? 4
            : 5];

/// Angular facets with dark joints and pale chips.
int _shadeRock(MaterialPixel q) {
  final cell = q.band * 2, facet = (q.x ~/ cell + (q.y ~/ cell) * 3) % 4;
  if ((q.x % cell == 0 || q.y % cell == 0) && q.noise % 2 == 0) return q.palette[6];
  if (q.noise % 13 == 0) return q.palette[7];
  return q.palette[facet == 0 ? 4 : 5];
}

/// Large cut blocks, two courses per tile, each block slightly lighter or darker.
int _shadeMasonry(MaterialPixel q) {
  final course = q.y ~/ (q.band * 4), half = q.size ~/ 2;
  final bx = (q.x + (course.isOdd ? q.size ~/ 4 : 0)) % q.size;
  if (q.y % (q.band * 4) == 0 || bx % half == 0) return q.palette[6];
  if (q.noise % 17 == 0) return q.palette[7];
  return q.palette[(bx ~/ half + course) % 2 == 0 ? 5 : (q.noise % 3 == 0 ? 5 : 4)];
}

/// Smooth painted wall: flat colour, faint mottling and hairline cracks.
int _shadePlaster(MaterialPixel q) => q.palette[q.noise % 53 == 0
    ? 6
    : q.noise % 7 == 0
        ? 4
        : q.noise % 29 == 0
            ? 7
            : 5];

/// Square tiles in a checker of two tones separated by grout lines.
int _shadeTiles(MaterialPixel q) {
  final t = q.band * 4;
  if (q.x % t == 0 || q.y % t == 0) return q.palette[6];
  if (q.noise % 19 == 0) return q.palette[7];
  return q.palette[(q.x ~/ t + q.y ~/ t).isEven ? 5 : 4];
}

/// Horizontal boards with staggered end joints.
int _shadePlanks(MaterialPixel q) {
  final h = q.band * 2, board = q.y ~/ h;
  if (q.y % h == 0 || (q.x + board * q.band * 3) % q.size == 0) return q.palette[6];
  return q.palette[q.noise % 11 == 0
      ? 7
      : q.noise % 4 == 0
          ? 4
          : 5];
}

/// Rounded paving stones in offset rows.
int _shadeCobble(MaterialPixel q) {
  final cell = q.band * 2, row = q.y ~/ cell, ox = (q.x + (row.isOdd ? q.band : 0)) % q.size;
  final cx = ox % cell, cy = q.y % cell;
  final corner = (cx == 1 || cx == cell - 1) && (cy == 1 || cy == cell - 1);
  if (cx == 0 || cy == 0 || corner) return q.palette[6];
  if (q.noise % 11 == 0) return q.palette[7];
  return q.palette[(ox ~/ cell + row * 2) % 3 == 0 ? 4 : 5];
}

/// Trodden dirt with two wheel ruts and a few pebbles.
int _shadeTrail(MaterialPixel q) {
  final rut = q.y % (q.band * 4) == q.band;
  if (rut && q.noise % 100 < 75) return q.palette[6];
  if (q.noise % 37 == 0) return q.palette[7];
  return q.palette[q.noise % 5 == 0 ? 4 : 5];
}

/// Loose small stones in four tones.
int _shadeGravel(MaterialPixel q) => switch (q.noise % 7) {
      0 => q.palette[7],
      1 => q.palette[6],
      2 || 3 => q.palette[4],
      _ => q.palette[5],
    };

/// Irregular paving slabs with a lit top-left bevel.
int _shadeFlagstone(MaterialPixel q) {
  final h = q.band * 4, row = q.y ~/ h, sx = (q.x + row * q.band * 3) % (q.band * 4);
  if (q.y % h == 0 || sx == 0) return q.palette[6];
  if (q.y % h == 1 || sx == 1) return q.palette[7];
  return q.palette[q.noise % 9 == 0 ? 4 : 5];
}

/// Dark tarmac with grit.
int _shadeAsphalt(MaterialPixel q) => q.palette[q.noise % 23 == 0
    ? 7
    : q.noise % 4 == 0
        ? 4
        : 5];

/// Still water: staggered short ripple lines and the odd foam fleck.
int _shadeWater(MaterialPixel q) {
  final row = q.y ~/ (q.band * 2);
  if (q.y % (q.band * 2) == 0 && (q.x + row * q.band * 2) % (q.band * 4) < q.band * 2) return q.palette[4];
  if (q.noise % 43 == 0) return q.palette[7];
  return q.palette[q.noise % 8 == 0 ? 6 : 5];
}

/// Molten rock: dark crust plates over a glowing body, with hot veins.
int _shadeLava(MaterialPixel q) {
  final cell = q.band * 2, plate = (q.x ~/ cell * 2 + q.y ~/ cell * 3) % 5 == 0;
  if (plate && q.noise % 5 != 0) return q.palette[6];
  return q.palette[q.noise % 9 == 0 ? 4 : 5];
}

/// Murky swamp water with algae and rising bubbles.
int _shadeSwamp(MaterialPixel q) => q.palette[q.noise % 53 == 0
    ? 7
    : q.noise % 5 == 0
        ? 6
        : q.noise % 7 == 0
            ? 4
            : 5];

/// Frozen surface with diagonal glints, cracks and sparkles.
int _shadeIce(MaterialPixel q) {
  if ((q.x + q.y) % (q.band * 3) == 0 && q.noise % 100 < 60) return q.palette[4];
  if ((q.x * 2 + q.size - q.y) % (q.band * 5) == 0 && q.noise % 100 < 40) return q.palette[6];
  return q.palette[q.noise % 37 == 0 ? 7 : 5];
}

/// Heavy dark bricks, half a tile wide, with a lit top edge.
int _shadeDungeonBrick(MaterialPixel q) {
  final h = q.band * 2, course = q.y ~/ h, bx = (q.x + (course.isOdd ? q.size ~/ 4 : 0)) % (q.size ~/ 2);
  if (q.y % h == 0 || bx == 0) return q.palette[6];
  if (q.y % h == 1) return q.palette[7];
  return q.palette[q.noise % 7 == 0 ? 4 : 5];
}

/// Rough cave rock built from lumpy blocks of three depths.
int _shadeCaveWall(MaterialPixel q) {
  final lump = (q.x ~/ q.band * 5 + q.y ~/ q.band * 3 + (q.noise % 3 == 0 ? 1 : 0)) % 4;
  if (q.noise % 11 == 0) return q.palette[7];
  return q.palette[lump == 0
      ? 4
      : lump == 3
          ? 6
          : 5];
}

/// Packed dirt and rubble.
int _shadeCaveFloor(MaterialPixel q) => q.palette[q.noise % 6 == 0
    ? 6
    : q.noise % 10 == 1
        ? 4
        : q.noise % 19 == 0
            ? 7
            : 5];

/// Faceted crystal: diagonal facets in three tones with bright edges.
int _shadeCrystal(MaterialPixel q) {
  final d = q.x * 2 + q.y, w = q.band * 5;
  if (d % w == 0) return q.palette[1];
  if (q.noise % 41 == 0) return q.palette[7];
  return q.palette[switch ((d ~/ w) % 3) {
    0 => 4,
    1 => 5,
    _ => 3,
  }];
}

/// Volcanic glass: near black with a diagonal sheen.
int _shadeObsidian(MaterialPixel q) {
  if ((q.x - q.y + q.size) % (q.band * 6) < q.band && q.noise % 100 < 80) return q.palette[4];
  if (q.noise % 29 == 0) return q.palette[7];
  return q.palette[q.noise % 6 == 0 ? 6 : 5];
}

/// Bolted steel panels with a lit bevel and a rivet in each corner.
int _shadeMetalPlate(MaterialPixel q) {
  final p = q.band * 4, cx = q.x % p, cy = q.y % p;
  if (cx == 0 || cy == 0) return q.palette[6];
  if (cx == 1 || cy == 1) return q.palette[7];
  if (cx == 3 && cy == 3 && q.band > 2 || cx == 2 && cy == 2 && q.band <= 2) return q.palette[1];
  return q.palette[q.noise % 13 == 0 ? 4 : 5];
}

/// Diamond mesh: bright bars over dark openings.
int _shadeGrate(MaterialPixel q) {
  final w = q.band * 2;
  return (q.x + q.y) % w < 1 || (q.x - q.y + q.size) % w < 1 ? q.palette[4] : q.palette[q.noise % 9 == 0 ? 5 : 6];
}

/// Circuit board: green traces on a dark board with bright solder pads.
int _shadeCircuit(MaterialPixel q) {
  final lane = q.band * 4, v = q.x % lane == q.band, h = q.y % lane == q.band * 3;
  if (v && h) return q.palette[7];
  if (v || h) return q.palette[2];
  if (q.noise % 31 == 0) return q.palette[1];
  return q.palette[q.noise % 6 == 0 ? 6 : 5];
}

/// Diagonal warning stripes, worn in places.
int _shadeHazard(MaterialPixel q) {
  final stripe = ((q.x + q.y) ~/ (q.band * 2)).isEven;
  if (q.noise % 17 == 0) return q.palette[5];
  return q.palette[stripe ? 4 : 6];
}

/// Poured concrete with a mid-tile expansion joint.
int _shadeConcrete(MaterialPixel q) {
  if (q.y % (q.size ~/ 2) == 0) return q.palette[6];
  if (q.noise % 47 == 0) return q.palette[7];
  return q.palette[q.noise % 13 == 0
      ? 6
      : q.noise % 3 == 0
          ? 4
          : 5];
}

/// Rows of wooden shingles, staggered by half a shingle, alternating in tone.
int _shadeShingles(MaterialPixel q) {
  final h = q.band * 2, row = q.y ~/ h, w = q.band * 4, sx = (q.x + (row.isOdd ? q.band * 2 : 0)) % q.size;
  if (q.y % h == h - 1) return q.palette[6];
  if (sx % w == 0) return q.palette[6];
  if (q.y % h == 0) return q.palette[7];
  return q.palette[(sx ~/ w + row).isEven ? (q.noise % 5 == 0 ? 5 : 4) : 5];
}

/// Barrel tiles: vertical ridges with a lit crest and shaded valley, in courses.
int _shadeTerracotta(MaterialPixel q) {
  final w = q.band * 2, cx = q.x % w;
  if (q.y % (q.band * 4) == 0 || cx == 0) return q.palette[6];
  if (cx == 1) return q.palette[7];
  return q.palette[cx < q.band ? 5 : (q.noise % 11 == 0 ? 5 : 4)];
}

/// Bundled straw: slanted dark gaps with light and mid strands.
int _shadeThatch(MaterialPixel q) {
  if ((q.x + q.y * 3) % 7 == 0) return q.palette[6];
  return q.palette[q.noise % 4 == 0
      ? 7
      : q.noise % 3 == 0
          ? 4
          : 5];
}

/// Overlapping slate slabs with a shadow under each course.
int _shadeSlate(MaterialPixel q) {
  final h = q.band * 2, row = q.y ~/ h, w = q.band * 3, sx = (q.x + row * q.band * 2) % q.size;
  if (q.y % h == h - 1 || sx % w == 0) return q.palette[6];
  if (q.y % h == 0) return q.palette[7];
  if (q.noise % 13 == 0) return q.palette[4];
  return q.palette[(sx ~/ w + row) % 3 == 0 ? 4 : 5];
}

/// Woven rug: pile rows, a gold trim line and worn flecks.
int _shadeCarpet(MaterialPixel q) {
  if (q.y % (q.band * 4) == q.band * 2) return q.palette[7];
  if (q.noise % 9 == 0) return q.palette[6];
  return q.palette[(q.y + q.x ~/ 3) % 2 == 0 ? 4 : 5];
}

/// Coarse canvas weave in 2x2 blocks with a stitched seam.
int _shadeCanvas(MaterialPixel q) {
  if (q.y % (q.band * 4) == 0 && q.x % 2 == 0) return q.palette[6];
  if (q.noise % 17 == 0) return q.palette[7];
  return q.palette[(q.x ~/ 2 + q.y ~/ 2).isEven ? 5 : 4];
}

int _shadeBrick(MaterialPixel q) {
  final course = q.y ~/ (q.band * 2), bx = (q.x + (course.isOdd ? q.size ~/ 2 : 0)) % q.size;
  return q.y % (q.band * 2) == 0 || bx == 0 ? q.palette[6] : q.palette[q.noise % 5 == 0 ? 4 : 5];
}

int _shadeWood(MaterialPixel q) => q.x % (q.band * 2) == 0
    ? q.palette[6]
    : q.palette[q.noise % 9 == 0
        ? 7
        : q.noise % 3 == 0
            ? 4
            : 5];

abstract final class TilesetMaterials {
  static const earth = TilesetMaterial(
      id: 'earth',
      label: 'Earth',
      category: TilesetMaterialCategory.earth,
      bases: {TilesetBase.ground, TilesetBase.path},
      primaryFor: {TilesetBase.ground, TilesetBase.path},
      shade: _shadeEarth);
  static const stone = TilesetMaterial(
      id: 'stone',
      label: 'Stone',
      category: TilesetMaterialCategory.stone,
      bases: {TilesetBase.ground, TilesetBase.path, TilesetBase.wall, TilesetBase.floor},
      primaryFor: {TilesetBase.floor},
      palettePreset: 'Mossy Cave Stone',
      shade: _shadeStone);
  static const sand = TilesetMaterial(
      id: 'sand',
      label: 'Sand',
      category: TilesetMaterialCategory.earth,
      bases: {TilesetBase.ground, TilesetBase.path},
      palettePreset: 'Desert Sand',
      shade: _shadeSand);
  static const grass = TilesetMaterial(
      id: 'grass',
      label: 'Grass',
      category: TilesetMaterialCategory.earth,
      bases: {TilesetBase.ground, TilesetBase.path},
      shade: _shadeGrass);
  static const snow = TilesetMaterial(
      id: 'snow',
      label: 'Snow',
      category: TilesetMaterialCategory.earth,
      bases: {TilesetBase.ground, TilesetBase.path},
      palettePreset: 'Snow & Ice',
      shade: _shadeSnow);
  static const clay = TilesetMaterial(
      id: 'clay',
      label: 'Clay',
      category: TilesetMaterialCategory.earth,
      bases: {TilesetBase.ground, TilesetBase.path},
      palettePreset: 'Red Clay',
      shade: _shadeClay);
  static const rock = TilesetMaterial(
      id: 'rock',
      label: 'Rock',
      category: TilesetMaterialCategory.earth,
      bases: {TilesetBase.ground, TilesetBase.wall},
      palettePreset: 'Granite Rock',
      shade: _shadeRock);
  static const masonry = TilesetMaterial(
      id: 'masonry',
      label: 'Masonry',
      category: TilesetMaterialCategory.stone,
      bases: {TilesetBase.wall, TilesetBase.floor},
      palettePreset: 'Mossy Cave Stone',
      faceMortar: true,
      shade: _shadeMasonry);
  static const plaster = TilesetMaterial(
      id: 'plaster',
      label: 'Plaster',
      category: TilesetMaterialCategory.stone,
      bases: {TilesetBase.wall},
      palettePreset: 'Plaster',
      shade: _shadePlaster);
  static const tiles = TilesetMaterial(
      id: 'tiles',
      label: 'Floor tiles',
      category: TilesetMaterialCategory.tile,
      bases: {TilesetBase.floor},
      palettePreset: 'Slate Tile',
      shade: _shadeTiles);
  static const planks = TilesetMaterial(
      id: 'planks',
      label: 'Planks',
      category: TilesetMaterialCategory.wood,
      bases: {TilesetBase.wall, TilesetBase.floor, TilesetBase.path},
      palettePreset: 'Oak Planks',
      shade: _shadePlanks);
  static const cobble = TilesetMaterial(
      id: 'cobble',
      label: 'Cobblestone',
      category: TilesetMaterialCategory.stone,
      bases: {TilesetBase.ground, TilesetBase.path, TilesetBase.floor},
      palettePreset: 'Granite Rock',
      shade: _shadeCobble);
  static const trail = TilesetMaterial(
      id: 'trail',
      label: 'Dirt trail',
      category: TilesetMaterialCategory.earth,
      bases: {TilesetBase.path},
      shade: _shadeTrail);
  static const gravel = TilesetMaterial(
      id: 'gravel',
      label: 'Gravel',
      category: TilesetMaterialCategory.road,
      bases: {TilesetBase.path, TilesetBase.ground},
      palettePreset: 'Gravel',
      shade: _shadeGravel);
  static const flagstone = TilesetMaterial(
      id: 'flagstone',
      label: 'Flagstone',
      category: TilesetMaterialCategory.road,
      bases: {TilesetBase.path, TilesetBase.floor},
      palettePreset: 'Granite Rock',
      shade: _shadeFlagstone);
  static const asphalt = TilesetMaterial(
      id: 'asphalt',
      label: 'Asphalt',
      category: TilesetMaterialCategory.road,
      bases: {TilesetBase.path, TilesetBase.floor},
      palettePreset: 'Asphalt',
      shade: _shadeAsphalt);
  static const water = TilesetMaterial(
      id: 'water',
      label: 'Water',
      category: TilesetMaterialCategory.liquid,
      bases: {TilesetBase.ground, TilesetBase.floor},
      palettePreset: 'Deep Water',
      shade: _shadeWater);
  static const lava = TilesetMaterial(
      id: 'lava',
      label: 'Lava',
      category: TilesetMaterialCategory.liquid,
      bases: {TilesetBase.ground, TilesetBase.floor},
      palettePreset: 'Lava',
      shade: _shadeLava);
  static const swamp = TilesetMaterial(
      id: 'swamp',
      label: 'Swamp',
      category: TilesetMaterialCategory.liquid,
      bases: {TilesetBase.ground, TilesetBase.floor},
      palettePreset: 'Swamp',
      shade: _shadeSwamp);
  static const ice = TilesetMaterial(
      id: 'ice',
      label: 'Ice',
      category: TilesetMaterialCategory.liquid,
      bases: {TilesetBase.ground, TilesetBase.floor, TilesetBase.path},
      palettePreset: 'Snow & Ice',
      shade: _shadeIce);
  static const dungeonBrick = TilesetMaterial(
      id: 'dungeonbrick',
      label: 'Dungeon brick',
      category: TilesetMaterialCategory.dungeon,
      bases: {TilesetBase.wall, TilesetBase.floor, TilesetBase.path},
      palettePreset: 'Dungeon Stone',
      faceMortar: true,
      shade: _shadeDungeonBrick);
  static const caveWall = TilesetMaterial(
      id: 'cavewall',
      label: 'Cave wall',
      category: TilesetMaterialCategory.dungeon,
      bases: {TilesetBase.wall, TilesetBase.ground},
      palettePreset: 'Cave Brown',
      shade: _shadeCaveWall);
  static const caveFloor = TilesetMaterial(
      id: 'cavefloor',
      label: 'Cave floor',
      category: TilesetMaterialCategory.dungeon,
      bases: {TilesetBase.floor, TilesetBase.ground, TilesetBase.path},
      palettePreset: 'Cave Brown',
      shade: _shadeCaveFloor);
  static const crystal = TilesetMaterial(
      id: 'crystal',
      label: 'Crystal',
      category: TilesetMaterialCategory.dungeon,
      bases: {TilesetBase.wall, TilesetBase.floor, TilesetBase.ground},
      palettePreset: 'Crystal',
      shade: _shadeCrystal);
  static const obsidian = TilesetMaterial(
      id: 'obsidian',
      label: 'Obsidian',
      category: TilesetMaterialCategory.dungeon,
      bases: {TilesetBase.wall, TilesetBase.floor, TilesetBase.ground},
      palettePreset: 'Obsidian',
      shade: _shadeObsidian);
  static const metalPlate = TilesetMaterial(
      id: 'metalplate',
      label: 'Metal plate',
      category: TilesetMaterialCategory.tech,
      bases: {TilesetBase.wall, TilesetBase.floor},
      palettePreset: 'Steel',
      shade: _shadeMetalPlate);
  static const grate = TilesetMaterial(
      id: 'grate',
      label: 'Grate',
      category: TilesetMaterialCategory.tech,
      bases: {TilesetBase.floor, TilesetBase.path},
      palettePreset: 'Steel',
      shade: _shadeGrate);
  static const circuit = TilesetMaterial(
      id: 'circuit',
      label: 'Circuit',
      category: TilesetMaterialCategory.tech,
      bases: {TilesetBase.wall, TilesetBase.floor},
      palettePreset: 'Circuit',
      shade: _shadeCircuit);
  static const hazard = TilesetMaterial(
      id: 'hazard',
      label: 'Hazard stripes',
      category: TilesetMaterialCategory.tech,
      bases: {TilesetBase.wall, TilesetBase.floor, TilesetBase.path},
      palettePreset: 'Hazard',
      shade: _shadeHazard);
  static const concrete = TilesetMaterial(
      id: 'concrete',
      label: 'Concrete',
      category: TilesetMaterialCategory.tech,
      bases: {TilesetBase.wall, TilesetBase.floor, TilesetBase.ground, TilesetBase.path},
      palettePreset: 'Concrete',
      shade: _shadeConcrete);
  static const shingles = TilesetMaterial(
      id: 'shingles',
      label: 'Shingles',
      category: TilesetMaterialCategory.roof,
      bases: {TilesetBase.wall, TilesetBase.floor},
      palettePreset: 'Roof Shingle',
      shade: _shadeShingles);
  static const terracotta = TilesetMaterial(
      id: 'terracotta',
      label: 'Terracotta',
      category: TilesetMaterialCategory.roof,
      bases: {TilesetBase.wall, TilesetBase.floor},
      palettePreset: 'Terracotta',
      shade: _shadeTerracotta);
  static const thatch = TilesetMaterial(
      id: 'thatch',
      label: 'Thatch',
      category: TilesetMaterialCategory.roof,
      bases: {TilesetBase.wall, TilesetBase.floor},
      palettePreset: 'Thatch',
      shade: _shadeThatch);
  static const slate = TilesetMaterial(
      id: 'slate',
      label: 'Slate',
      category: TilesetMaterialCategory.roof,
      bases: {TilesetBase.wall, TilesetBase.floor},
      palettePreset: 'Slate Roof',
      shade: _shadeSlate);
  static const carpet = TilesetMaterial(
      id: 'carpet',
      label: 'Carpet',
      category: TilesetMaterialCategory.fabric,
      bases: {TilesetBase.floor, TilesetBase.path},
      palettePreset: 'Red Carpet',
      shade: _shadeCarpet);
  static const canvas = TilesetMaterial(
      id: 'canvas',
      label: 'Canvas',
      category: TilesetMaterialCategory.fabric,
      bases: {TilesetBase.wall, TilesetBase.floor},
      palettePreset: 'Canvas',
      shade: _shadeCanvas);
  static const brick = TilesetMaterial(
      id: 'brick',
      label: 'Brick',
      category: TilesetMaterialCategory.stone,
      bases: {TilesetBase.wall, TilesetBase.floor, TilesetBase.path},
      primaryFor: {TilesetBase.wall},
      faceMortar: true,
      shade: _shadeBrick);
  static const wood = TilesetMaterial(
      id: 'wood',
      label: 'Wood',
      category: TilesetMaterialCategory.wood,
      bases: {TilesetBase.wall, TilesetBase.floor},
      shade: _shadeWood);

  /// Every material, in the order pickers list them.
  static const all = <TilesetMaterial>[
    earth,
    grass,
    sand,
    snow,
    clay,
    rock,
    stone,
    cobble,
    trail,
    gravel,
    flagstone,
    asphalt,
    water,
    lava,
    swamp,
    ice,
    dungeonBrick,
    caveWall,
    caveFloor,
    crystal,
    obsidian,
    metalPlate,
    grate,
    circuit,
    hazard,
    concrete,
    shingles,
    terracotta,
    thatch,
    slate,
    carpet,
    canvas,
    brick,
    masonry,
    plaster,
    tiles,
    planks,
    wood
  ];

  static TilesetMaterial byId(String id) =>
      all.firstWhere((m) => m.id == id, orElse: () => throw FormatException('Unknown tileset material "$id"'));

  /// Materials that can build [base], the base's default first.
  static List<TilesetMaterial> forBase(TilesetBase base) {
    final usable = all.where((m) => m.supports(base)).toList();
    return [...usable.where((m) => m.primaryFor.contains(base)), ...usable.where((m) => !m.primaryFor.contains(base))];
  }
}

enum TilesetModifierGroup {
  structure('Structure'),
  wear('Wear'),
  cover('Cover');

  const TilesetModifierGroup(this.label);
  final String label;
}

/// One pixel as seen by a modifier, after the material has shaded it.
class ModifierPixel {
  const ModifierPixel(
      {required this.pixel, required this.row, required this.mask, required this.boundary, required this.intensity});
  final MaterialPixel pixel;

  /// Row inside the tile (not wrapped), top to bottom.
  final int row;
  final int mask, intensity;

  /// Inside the border region shared with neighbours. Modifiers that only touch
  /// the interior can never break a seam.
  final bool boundary;
  bool get exposedTop => mask & 1 == 0;
}

typedef ModifierShader = int Function(ModifierPixel pixel, int color);

/// A change applied on top of a material. Modifiers run in registry order.
class TilesetModifier {
  const TilesetModifier(
      {required this.id,
      required this.label,
      required this.group,
      required this.description,
      required this.unavailable,
      required this.applies,
      required this.shade,
      this.intensityLabel,
      this.defaultIntensity = 100});
  final String id, label, description, unavailable;
  final TilesetModifierGroup group;
  final bool Function(TilesetBase base, TilesetPerspective perspective) applies;
  final ModifierShader shade;

  /// Set for modifiers with a 0-100 slider, e.g. "density".
  final String? intensityLabel;
  final int defaultIntensity;
  bool get hasIntensity => intensityLabel != null;
}

int _shadePlatform(ModifierPixel q, int color) {
  final p = q.pixel.palette, band = q.pixel.band;
  if (!q.boundary && q.exposedTop && q.row < band * 3) return p[q.row == band ? 7 : 4];
  return color;
}

int _shadeVegetation(ModifierPixel q, int color) {
  final px = q.pixel;
  if (px.noise % 100 < q.intensity &&
      (px.perspective != TilesetPerspective.side || (!q.boundary && q.exposedTop && q.row < px.band * 3))) {
    return px.palette[px.noise.isEven ? 1 : 2];
  }
  return color;
}

/// Diagonal hairline fractures. Positions come from wrapped coordinates, so
/// they match on both sides of a seam.
int _shadeCracks(ModifierPixel q, int color) {
  final px = q.pixel, period = px.band * 6 + 1;
  final line = (px.x + px.y * 2) % period == 0 || (px.x * 3 + px.y + px.size) % (period + 4) == 0;
  return line && px.noise % 100 < q.intensity ? px.palette[6] : color;
}

/// Dark streaks running down from the top, as left by water.
int _shadeStains(ModifierPixel q, int color) {
  final px = q.pixel, lane = px.x % (px.band * 3);
  if (lane == 1 && px.y % (px.band * 5) < px.band * 3 && px.noise % 100 < q.intensity + 30) return px.palette[6];
  return px.noise % 100 < q.intensity ~/ 10 ? px.palette[6] : color;
}

/// Clumps of low moss, denser where the noise is high.
int _shadeMoss(ModifierPixel q, int color) {
  final px = q.pixel, clump = (px.x ~/ 2 + px.y ~/ 2 * 3) % 4 < 2;
  if (clump && px.noise % 100 < q.intensity ~/ 2) return px.palette[px.noise.isEven ? 2 : 3];
  return color;
}

/// Snow resting on exposed tops; in top-down and isometric views it speckles the surface.
int _shadeSnowCap(ModifierPixel q, int color) {
  final px = q.pixel;
  if (px.perspective == TilesetPerspective.side) {
    if (!q.boundary && q.exposedTop && q.row < px.band * 2 + px.band * q.intensity ~/ 50) {
      return px.palette[q.row == px.band ? 2 : 1];
    }
    return px.noise % 100 < q.intensity ~/ 12 ? px.palette[2] : color;
  }
  return px.noise % 100 < q.intensity ~/ 2 ? px.palette[px.noise % 5 == 0 ? 2 : 1] : color;
}

/// Hanging strands of ivy. In the side view they drop from the lip of an exposed
/// top (never through the shared border); other views get creeping tendrils.
int _shadeVines(ModifierPixel q, int color) {
  final px = q.pixel, band = px.band;
  if (px.perspective == TilesetPerspective.side) {
    final strand = px.x % (band * 2) == band && (px.x ~/ (band * 2)) * 7 % 5 < 3;
    final length = band * (2 + (px.x ~/ (band * 2)) % 4);
    final depth = q.row - band;
    if (strand && !q.boundary && q.exposedTop && depth >= 0 && depth < length * q.intensity ~/ 50) {
      return px.palette[depth % 4 == 3 ? 1 : 3];
    }
    return color;
  }
  final tendril = (px.x + px.y * 2) % (band * 3) == 0;
  if (tendril && px.noise % 100 < q.intensity + 20) return px.palette[3];
  return tendril && px.noise % 100 < q.intensity + 40 ? px.palette[2] : color;
}

abstract final class TilesetModifiers {
  static const platform = TilesetModifier(
      id: 'platform',
      label: 'Platform',
      group: TilesetModifierGroup.structure,
      description: 'Exposed sides and a raised surface',
      unavailable: 'Requires Ground in Side View or Isometric',
      applies: _platformApplies,
      shade: _shadePlatform);
  static const vegetation = TilesetModifier(
      id: 'vegetation',
      label: 'Vegetation',
      group: TilesetModifierGroup.cover,
      description: 'Add grass and moss to exposed surfaces',
      unavailable: 'Available for Ground and Path',
      applies: _vegetationApplies,
      shade: _shadeVegetation,
      intensityLabel: 'density',
      defaultIntensity: 45);

  static const cracks = TilesetModifier(
      id: 'cracks',
      label: 'Cracks',
      group: TilesetModifierGroup.wear,
      description: 'Hairline fractures across the surface',
      unavailable: 'Available for every base',
      applies: _anyBase,
      shade: _shadeCracks,
      intensityLabel: 'amount',
      defaultIntensity: 60);
  static const stains = TilesetModifier(
      id: 'stains',
      label: 'Stains',
      group: TilesetModifierGroup.wear,
      description: 'Dark streaks and grime',
      unavailable: 'Available for every base',
      applies: _anyBase,
      shade: _shadeStains,
      intensityLabel: 'amount',
      defaultIntensity: 40);
  static const moss = TilesetModifier(
      id: 'moss',
      label: 'Moss',
      group: TilesetModifierGroup.cover,
      description: 'Low clumps of moss',
      unavailable: 'Available for every base',
      applies: _anyBase,
      shade: _shadeMoss,
      intensityLabel: 'density',
      defaultIntensity: 40);
  static const snowCap = TilesetModifier(
      id: 'snowcap',
      label: 'Snow cover',
      group: TilesetModifierGroup.cover,
      description: 'Snow on exposed tops and scattered over the surface',
      unavailable: 'Not available for Floor',
      applies: _snowCapApplies,
      shade: _shadeSnowCap,
      intensityLabel: 'depth',
      defaultIntensity: 50);
  static const vines = TilesetModifier(
      id: 'vines',
      label: 'Vines',
      group: TilesetModifierGroup.cover,
      description: 'Hanging or creeping ivy',
      unavailable: 'Available for every base',
      applies: _anyBase,
      shade: _shadeVines,
      intensityLabel: 'length',
      defaultIntensity: 50);

  static const all = <TilesetModifier>[platform, cracks, stains, vegetation, moss, snowCap, vines];

  static TilesetModifier byId(String id) =>
      all.firstWhere((m) => m.id == id, orElse: () => throw FormatException('Unknown tileset modifier "$id"'));
}

bool _platformApplies(TilesetBase base, TilesetPerspective perspective) =>
    base == TilesetBase.ground && perspective != TilesetPerspective.topDown;

bool _vegetationApplies(TilesetBase base, TilesetPerspective perspective) =>
    base == TilesetBase.ground || base == TilesetBase.path;

bool _anyBase(TilesetBase base, TilesetPerspective perspective) => true;

bool _snowCapApplies(TilesetBase base, TilesetPerspective perspective) => base != TilesetBase.floor;
