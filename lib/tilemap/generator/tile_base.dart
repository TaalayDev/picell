import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'tile_palette.dart';
import 'tiles/terrain.dart';
import 'tiles/structure.dart';
import 'tiles/liquid.dart';
import 'tiles/nature.dart';
import 'tiles/special.dart';
import 'tiles/stone.dart';
import 'tiles/extended_stone.dart';

/// Base class for all tile types with powerful abstraction
abstract class TileBase {
  TileBase(this.id);

  /// Unique identifier for this tile type
  String id;

  /// Display name
  String get name;

  /// Description of the tile
  String get description;

  /// Category for grouping (Terrain, Structure, Nature, etc.)
  TileCategory get category;

  /// Icon name for UI display
  String get iconName;

  /// The color palette used for generation
  TilePalette get palette;

  /// Whether this tile can be rotated
  bool get supportsRotation => false;

  /// Whether this tile supports edge variations
  bool get supportsEdgeVariations => false;

  /// Whether this tile can connect to adjacent tiles
  bool get supportsAutoTiling => false;

  /// Tags for filtering and search
  List<String> get tags;

  /// Whether this tile is animated
  bool get animated => false;

  /// Number of animation frames
  int get frameCount => 1;

  /// Duration of each frame in milliseconds
  int get frameSpeed => 100;

  /// Generate a specific frame for animated tiles
  Uint32List generateFrame({
    required int width,
    required int height,
    int seed = 0,
    TileVariation variation = TileVariation.standard,
    int frameIndex = 0,
  }) {
    return generate(
      width: width,
      height: height,
      seed: seed,
      variation: variation,
    );
  }

  /// Generate pixel data for a tile
  Uint32List generate({
    required int width,
    required int height,
    int seed,
    TileVariation variation,
  });

  /// Generate multiple variants
  List<Uint32List> generateVariants({
    required int width,
    required int height,
    int count = 4,
    int? baseSeed,
  }) {
    final random = Random(baseSeed);
    return List.generate(count, (i) {
      return generate(
        width: width,
        height: height,
        seed: random.nextInt(1000000),
        variation: TileVariation.values[i % TileVariation.values.length],
      );
    });
  }

  /// Helper to convert Color to ARGB int
  int colorToInt(Color color) {
    return color.value;
  }

  /// Helper to blend two colors
  int blendColors(Color c1, Color c2, double t) {
    final r = (c1.red + (c2.red - c1.red) * t).round();
    final g = (c1.green + (c2.green - c1.green) * t).round();
    final b = (c1.blue + (c2.blue - c1.blue) * t).round();
    final a = (c1.alpha + (c2.alpha - c1.alpha) * t).round();
    return (a << 24) | (r << 16) | (g << 8) | b;
  }

  /// Helper to add noise variation to a color
  int addNoise(Color baseColor, Random random, double intensity) {
    final variation = ((random.nextDouble() - 0.5) * 2 * intensity * 255).round();
    final r = (baseColor.red + variation).clamp(0, 255);
    final g = (baseColor.green + variation).clamp(0, 255);
    final b = (baseColor.blue + variation).clamp(0, 255);
    return (baseColor.alpha << 24) | (r << 16) | (g << 8) | b;
  }

  /// Generate Perlin-like noise value
  double noise2D(double x, double y, int octaves) {
    double value = 0;
    double amplitude = 1;
    double frequency = 1;
    double maxValue = 0;

    for (int i = 0; i < octaves; i++) {
      value += amplitude * _smoothNoise(x * frequency, y * frequency);
      maxValue += amplitude;
      amplitude *= 0.5;
      frequency *= 2;
    }

    return value / maxValue;
  }

  double _smoothNoise(double x, double y) {
    final ix = x.floor();
    final iy = y.floor();
    final fx = x - ix;
    final fy = y - iy;

    double hash(int x, int y) {
      final n = x + y * 57;
      final h = (n * (n * n * 15731 + 789221) + 1376312589) & 0x7fffffff;
      return h / 0x7fffffff;
    }

    final v1 = hash(ix, iy);
    final v2 = hash(ix + 1, iy);
    final v3 = hash(ix, iy + 1);
    final v4 = hash(ix + 1, iy + 1);

    final i1 = v1 + fx * (v2 - v1);
    final i2 = v3 + fx * (v4 - v3);

    return i1 + fy * (i2 - i1);
  }
}

/// Tile categories for organization
enum TileCategory {
  terrain('Terrain', 'Ground surfaces like grass, dirt, sand'),
  structure('Structure', 'Man-made structures like walls, floors'),
  nature('Nature', 'Natural elements like rocks, trees'),
  liquid('Liquid', 'Water, lava, and other fluids'),
  special('Special', 'Magical and special effect tiles'),
  decoration('Decoration', 'Decorative elements'),
  dungeon('Dungeon', 'Dungeon and cave tiles');

  final String name;
  final String description;
  const TileCategory(this.name, this.description);
}

/// Tile variations for generation diversity
enum TileVariation {
  standard,
  weathered,
  mossy,
  cracked,
  pristine,
  frozen,
  overgrown,
}

// ============================================================================
// TILE REGISTRY
// ============================================================================

/// Registry of all available tile types
class TileRegistry {
  TileRegistry._();
  static final instance = TileRegistry._();

  /// All registered tile types
  final Map<String, TileBase Function()> _registry = {
    // =========================================================================
    // TERRAIN TILES
    // =========================================================================
    'grass': () => GrassTile('grass'),
    'grass_flowers': () => GrassTile('grass_flowers', includeFlowers: true),
    'dirt': () => DirtTile('dirt'),
    'sand': () => SandTile('sand'),
    'snow': () => SnowTile('snow'),

    // =========================================================================
    // STRUCTURE TILES
    // =========================================================================
    'wall_brick': () => WallTile('wall_brick', style: WallStyle.brick),
    'wall_stone': () => WallTile('wall_stone', style: WallStyle.stone),
    'wall_dark': () => WallTile('wall_dark', style: WallStyle.darkBrick),
    'wall_cobble': () => WallTile('wall_cobble', style: WallStyle.cobblestone),
    'floor_wood': () => FloorTile('floor_wood', style: FloorStyle.wood),
    'floor_stone': () => FloorTile('floor_stone', style: FloorStyle.stone),
    'floor_tile': () => FloorTile('floor_tile', style: FloorStyle.tile),

    // =========================================================================
    // LIQUID TILES
    // =========================================================================
    'water': () => WaterTile('water'),
    'lava': () => LavaTile('lava'),

    // =========================================================================
    // NATURE TILES
    // =========================================================================
    'stone': () => StoneTile('stone'),
    'stone_mossy': () => StoneTile('stone_mossy', addMoss: true),

    // =========================================================================
    // SPECIAL TILES
    // =========================================================================
    'crystal': () => CrystalTile('crystal'),

    // =========================================================================
    // STONE/DUNGEON TILES (NEW - from reference image)
    // =========================================================================

    // --- Horizontal Stone Brick Variants (Row 1) ---
    'horizontal_stone_brick': () => HorizontalStoneBrickTile('horizontal_stone_brick'),
    'horizontal_stone_brick_light': () => HorizontalStoneBrickTile(
          'horizontal_stone_brick_light',
          style: HorizontalBrickStyle.light,
        ),
    'horizontal_stone_brick_worn': () => HorizontalStoneBrickTile(
          'horizontal_stone_brick_worn',
          style: HorizontalBrickStyle.worn,
        ),
    'horizontal_stone_brick_detailed': () => HorizontalStoneBrickTile(
          'horizontal_stone_brick_detailed',
          style: HorizontalBrickStyle.detailed,
        ),

    // --- Cobblestone & Textured Stone (Row 2) ---
    'irregular_cobblestone': () => IrregularCobblestoneTile('irregular_cobblestone'),
    'vine_covered_stone': () => VineCoveredStoneTile('vine_covered_stone'),
    'rough_textured_stone': () => RoughTexturedStoneTile('rough_textured_stone'),
    'stone_brick_transition': () => StoneBrickTransitionTile('stone_brick_transition'),

    // --- Column & Decorative Stone (Row 3) ---
    'vertical_stone_column': () => VerticalStoneColumnTile('vertical_stone_column'),
    'stone_with_grass_top': () => StoneWithGrassTopTile('stone_with_grass_top'),
    'ornate_stone_block': () => OrnateStoneBlockTile('ornate_stone_block'),
    'large_stone_blocks': () => LargeStoneBlocksTile('large_stone_blocks'),

    // --- Special Stone Types (Row 4) ---
    'dark_vertical_planks': () => DarkVerticalPlanksTile('dark_vertical_planks'),
    'ice_frost_stone': () => IceFrostStoneTile('ice_frost_stone'),
    'large_brick_pattern': () => LargeBrickPatternTile('large_brick_pattern'),
    'stone_with_door': () => StoneWithDoorTile('stone_with_door'),

    // --- Additional Stone Variants ---
    'cracked_stone_floor': () => CrackedStoneFloorTile('cracked_stone_floor'),
    'mossy_dungeon_wall': () => MossyDungeonWallTile('mossy_dungeon_wall'),
    'ancient_ruin_stone': () => AncientRuinStoneTile('ancient_ruin_stone'),
    'carved_stone_tile': () => CarvedStoneTileTile('carved_stone_tile'),

    // =========================================================================
    // EXTENDED GRAY STONE TILES (from second reference image)
    // =========================================================================

    // --- Row 1: Cobblestone and Floor Variants ---
    'small_cobblestone_floor': () => SmallCobblestoneFloorTile('small_cobblestone_floor'),
    'medium_cobblestone_floor': () => MediumCobblestoneFloorTile('medium_cobblestone_floor'),
    'rough_stone_floor': () => RoughStoneFloorTile('rough_stone_floor'),
    'vine_stone_floor': () => VineStoneFloorTile('vine_stone_floor'),
    'regular_stone_brick': () => RegularStoneBrickTile('regular_stone_brick'),

    // --- Row 2: Decorative Patterns ---
    'vertical_stone_stripes': () => VerticalStoneStripesTile('vertical_stone_stripes'),
    'concentric_square_stone': () => ConcentricSquareStoneTile('concentric_square_stone'),
    'cross_hatch_stone': () => CrossHatchStoneTile('cross_hatch_stone'),

    // --- Row 3: Large Blocks ---
    'large_bordered_stone_block': () => LargeBorderedStoneBlockTile('large_bordered_stone_block'),
    'horizontal_stone_slab': () => HorizontalStoneSlabTile('horizontal_stone_slab'),
    'mossy_large_stone': () => MossyLargeStoneTile('mossy_large_stone'),
    'inset_square_stone': () => InsetSquareStoneTile('inset_square_stone'),

    // --- Row 4: More Decorative ---
    'striped_border_stone': () => StripedBorderStoneTile('striped_border_stone'),
    'horizontal_lined_stone': () => HorizontalLinedStoneTile('horizontal_lined_stone'),

    // =========================================================================
    // EXTENDED BROWN BRICK TILES (from second reference image)
    // =========================================================================

    // --- Row 5: Brown Brick Basics ---
    'rough_brown_brick_floor': () => RoughBrownBrickFloorTile('rough_brown_brick_floor'),
    'horizontal_brown_brick': () => HorizontalBrownBrickTile('horizontal_brown_brick'),
    'diagonal_brown_brick': () => DiagonalBrownBrickTile('diagonal_brown_brick'),
    'vine_brown_brick': () => VineBrownBrickTile('vine_brown_brick'),
    'standard_brown_brick_wall': () => StandardBrownBrickWallTile('standard_brown_brick_wall'),

    // --- Row 6: Brown Brick Decorative ---
    'grid_brown_brick': () => GridBrownBrickTile('grid_brown_brick'),
    'large_bordered_brown_brick': () => LargeBorderedBrownBrickTile('large_bordered_brown_brick'),
    'horizontal_brown_brick_slab': () => HorizontalBrownBrickSlabTile('horizontal_brown_brick_slab'),
  };

  /// Get all registered tile IDs
  List<String> get allIds => _registry.keys.toList();

  /// Get a tile instance by ID
  TileBase? getTile(String id) {
    final factory = _registry[id];
    return factory?.call();
  }

  /// Get all tiles in a category
  List<TileBase> getTilesInCategory(TileCategory category) {
    return _registry.values.map((f) => f()).where((t) => t.category == category).toList();
  }

  /// Get all categories with tiles
  Map<TileCategory, List<TileBase>> get tilesByCategory {
    final result = <TileCategory, List<TileBase>>{};
    for (final category in TileCategory.values) {
      final tiles = getTilesInCategory(category);
      if (tiles.isNotEmpty) {
        result[category] = tiles;
      }
    }
    return result;
  }

  /// Search tiles by tag
  List<TileBase> searchByTag(String tag) {
    return _registry.values.map((f) => f()).where((t) => t.tags.contains(tag.toLowerCase())).toList();
  }

  /// Get all stone/dungeon tiles
  List<TileBase> get stoneTiles {
    return searchByTag('stone') + searchByTag('dungeon');
  }

  /// Get all structure tiles including new stone types
  List<TileBase> get allStructureTiles {
    return getTilesInCategory(TileCategory.structure) + getTilesInCategory(TileCategory.dungeon);
  }

  /// Register a custom tile type
  void register(String id, TileBase Function() factory) {
    _registry[id] = factory;
  }

  /// Unregister a tile type
  void unregister(String id) {
    _registry.remove(id);
  }

  /// Check if a tile ID exists
  bool hasTile(String id) {
    return _registry.containsKey(id);
  }

  /// Get count of registered tiles
  int get count => _registry.length;

  /// Get all tile IDs matching a pattern
  List<String> searchIds(String pattern) {
    final lowerPattern = pattern.toLowerCase();
    return _registry.keys.where((id) => id.toLowerCase().contains(lowerPattern)).toList();
  }
}
